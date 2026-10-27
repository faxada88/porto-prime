"use client";

/**
 * Dedicated ESC/POS printing via an explicitly chosen serial thermal printer.
 *
 * Supported transports: USB virtual COM, RS-232, paired Bluetooth SPP (COM).
 * A standard office printer will not be offered by Web Serial.
 * No window.print() fallback, no unattended printer access.
 */
type Order = Record<string, any>;
type SerialPortLike = {
  open(options: {baudRate: number}): Promise<void>;
  close(): Promise<void>;
  writable: WritableStream<Uint8Array> | null;
};
type NavigatorWithSerial = Navigator & {
  serial?: {requestPort(): Promise<SerialPortLike>};
};

let selectedPrinter: SerialPortLike | null = null;
let inProgress = false;

export function thermalSupported(): boolean {
  return typeof navigator !== "undefined" && !!(navigator as NavigatorWithSerial).serial;
}

export async function selectThermalPrinter(): Promise<void> {
  const serial = (navigator as NavigatorWithSerial).serial;
  if (!serial) {
    throw new Error("Abra o Admin no Chrome ou Edge, pelo localhost/HTTPS, e conecte uma impressora térmica ESC/POS em uma porta COM.");
  }
  // Must be called directly from a user click, before any await.
  selectedPrinter = await serial.requestPort();
}

export function thermalPrinterSelected(): boolean {
  return selectedPrinter != null;
}

function ascii(value: unknown): string {
  return String(value ?? "").normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[\u2013\u2014]/g, "-")
    .replace(/[^\x20-\x7E]/g, "").replace(/\s+/g, " ").trim();
}
function currency(value: unknown): string {
  const number = Number(value ?? 0);
  return "R$ " + (Number.isFinite(number) ? number : 0)
    .toFixed(2).replace(".", ",");
}
function fourDigits(order: Order) {
  const n = Number(order.displayNumber);
  return Number.isInteger(n) && n >= 1 && n <= 9999
    ? String(n).padStart(4, "0") : "----";
}
function printedAt(value: unknown): string {
  const dt = new Date(String(value ?? ""));
  if (!Number.isFinite(dt.getTime())) return "";
  return new Intl.DateTimeFormat("pt-BR", {
    timeZone: "America/Bahia", day: "2-digit", month: "2-digit", year: "numeric",
    hour: "2-digit", minute: "2-digit"
  }).format(dt);
}
function wrapped(source: unknown, width: number): string[] {
  const words = ascii(source).split(" ").filter(Boolean);
  const result: string[] = [];
  let line = "";
  for (let word of words) {
    while (word.length > width) {
      if (line) {result.push(line); line = "";}
      result.push(word.slice(0, width)); word = word.slice(width);
    }
    if (!word) continue;
    if (line && line.length + word.length + 1 > width) {
      result.push(line); line = word;
    } else {
      line = line ? line + " " + word : word;
    }
  }
  if (line) result.push(line);
  return result.length ? result : [""];
}
function paired(label: unknown, value: string, columns: number): string {
  const v = ascii(value);
  const l = ascii(label);
  return l.slice(0, Math.max(1, columns-v.length-1))
    .padEnd(Math.max(1, columns-v.length), " ") + v;
}

class ThermalWriter {
  private readonly bytes: number[] = [];
  constructor(readonly columns: number) {}
  cmd(...values: number[]) {this.bytes.push(...values);}
  text(value: unknown) {
    for (const char of ascii(value)) this.bytes.push(char.charCodeAt(0));
    this.bytes.push(10);
  }
  blank() {this.bytes.push(10);}
  line() {this.text("-".repeat(this.columns));}
  align(value: 0 | 1 | 2) {this.cmd(0x1b, 0x61, value);}
  bold(on: boolean) {this.cmd(0x1b, 0x45, on ? 1 : 0);}
  size(width: number, height: number) {
    this.cmd(0x1d, 0x21, ((width-1) << 4) | (height-1));
  }
  rows(value: unknown) {for (const line of wrapped(value,this.columns)) this.text(line);}
  receipt(order: Order) {
    this.cmd(0x1b, 0x40); // ESC @ initialize only ESC/POS printer
    this.align(1); this.bold(true); this.size(2, 2);
    this.text("PORTO PRIME");
    this.size(1, 1);this.bold(false);
    this.text("COMANDA DE ENTREGA");
    this.blank();this.line();
    this.bold(true);this.text("PEDIDO");
    // 4-digit code stays large even on 58-mm paper.
    this.size(2, 2);this.text(fourDigits(order));this.size(1, 1);
    this.bold(false);this.text(printedAt(order.createdAt));
    this.line();this.bold(true);this.text("PAGAMENTO CONFIRMADO");
    this.text("NAO COBRAR DO CLIENTE");this.bold(false);
    this.line();this.align(0);
    this.bold(true);this.text("CLIENTE");this.bold(false);
    this.rows(order.customer?.name || "Cliente");
    if (order.customer?.phone) this.rows("Telefone: " + order.customer.phone);
    this.line();
    this.bold(true);this.text("ENDERECO");this.bold(false);
    const address = order.address || {};
    this.rows([address.street, address.number].filter(Boolean).join(", ") || "Endereco nao informado");
    if (address.complement) this.rows("Compl.: " + address.complement);
    if (address.neighborhood) this.rows("Bairro: " + address.neighborhood);
    if (address.city) this.rows([address.city,address.state].filter(Boolean).join(" / "));
    if (address.reference) this.rows("Ref.: " + address.reference);
    this.line();
    const excluded = new Set(["REFUND_PROCESSING", "REFUNDED", "VOUCHERED"]);
    const items = (Array.isArray(order.items) ? order.items : [])
      .filter((item: Order) => !excluded.has(String(item.availabilityStatus || "")));
    const count = items.reduce((n: number, item: Order) => n + Number(item.quantity || 0), 0);
    this.bold(true);this.text("PRODUTOS (" + count + ")");this.bold(false);
    for (const item of items) {
      const quantity = Math.max(0,Number(item.quantity || 0));
      const name = item.productName || item.product?.name || "Produto";
      const price = item.total == null ? quantity * Number(item.unitPrice || 0) : Number(item.total);
      this.rows(quantity + "x " + name);
      this.bold(true);this.text(paired("  Valor",currency(price),this.columns));this.bold(false);
    }
    if (!items.length) this.text("Nenhum item disponivel para entrega");
    this.line();
    // Snapshot prices from checkout: this is not a tax invoice.
    this.text(paired("PRODUTOS",currency(order.subtotal),this.columns));
    this.bold(true);this.text(paired("TAXA DE ENTREGA",currency(order.deliveryFee),this.columns));
    this.bold(false);
    this.line();
    this.align(1);this.bold(true);
    this.text("CONFERIR OS ITENS ANTES DE SAIR");
    this.bold(false);this.text("PORTO PRIME - PORTO SEGURO / BA");
    this.text("Comanda operacional - Nao e nota fiscal");
    this.blank();this.blank();this.blank();
    this.cmd(0x1d,0x56,0x42,0x00); // cut if cutter exists; ignored by simpler models
  }
  output(): Uint8Array {return new Uint8Array(this.bytes);}
}

export async function printThermalOrders(
  orders: Order[], paper: 58 | 80, baudRate: 9600 | 19200 | 115200 = 9600
): Promise<void> {
  if (inProgress) throw new Error("A impressora ja esta processando uma comanda.");
  if (!orders.length) return;
  const serial = (navigator as NavigatorWithSerial).serial;
  if (!serial) throw new Error("Impressao termica requer Chrome/Edge em localhost/HTTPS e uma impressora ESC/POS por COM.");
  if (!selectedPrinter) {
    // Explicit physical device permission. No fallback to office printers.
    selectedPrinter = await serial.requestPort();
  }
  const printer = selectedPrinter;
  if (!printer) throw new Error("Nenhuma impressora termica selecionada.");
  inProgress = true;
  let opened = false;
  try {
    await printer.open({baudRate});
    opened = true;
    if (!printer.writable) throw new Error("A porta termica nao permite gravacao.");
    const writer = printer.writable.getWriter();
    try {
      for (const order of orders) {
        const ticket = new ThermalWriter(paper === 58 ? 32 : 48);
        ticket.receipt(order);
        await writer.write(ticket.output());
      }
    } finally {
      writer.releaseLock();
    }
  } catch(error) {
    selectedPrinter = null; // bad COM permissions/driver; reselect next attempt
    throw error;
  } finally {
    if (opened) {
      try {await printer.close();} catch { /* port may have disconnected */ }
    }
    inProgress = false;
  }
}
