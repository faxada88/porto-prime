"use client";

import {orderDisplayNumber} from "./order-display-number";
import "./order-print-receipt.css";

type Order = Record<string, any>;

const money = (value: unknown) =>
  Number(value || 0).toLocaleString("pt-BR", {style: "currency", currency: "BRL"});

const when = (value: unknown) => {
  if (!value) return "—";
  const d = new Date(String(value));
  if (Number.isNaN(d.getTime())) return "—";
  return new Intl.DateTimeFormat("pt-BR", {
    timeZone: "America/Bahia", day: "2-digit", month: "2-digit",
    year: "numeric", hour: "2-digit", minute: "2-digit"
  }).format(d);
};

const removed = new Set(["REFUND_PROCESSING", "REFUNDED", "VOUCHERED"]);

/**
 * Created when a paid order appears on the Admin orders list.
 * It is deliberately screen-hidden and becomes a 58/80-mm-friendly courier
 * slip ONLY for an explicit print action. No silent printer access.
 */
export default function OrderPrintReceipts({orders}: {orders: Order[]}) {
  if (!orders.length) return null;

  return <div className="ppReceiptPrintZone" aria-label="Comandas Porto Prime para impressão">
    {orders.map(order => {
      const address = order.address || {};
      const items = (order.items || []).filter((item: Order) => !removed.has(String(item.availabilityStatus || "")));
      const itemCount = items.reduce((n: number, item: Order) => n + Number(item.quantity || 0), 0);
      const isAdjusted = order.paymentStatus === "PARTIALLY_REFUNDED" ||
        Number(order.removedItemsTotal || 0) > 0;
      return <article className="ppThermalReceipt" key={order.id}>
        <header className="ppReceiptBrand">
          <strong>PORTO PRIME</strong>
          <span>COMANDA DE ENTREGA</span>
        </header>

        <div className="ppReceiptOrderNumber">
          <span>PEDIDO Nº</span>
          <strong>{orderDisplayNumber(order)}</strong>
          <small>{when(order.createdAt)}</small>
        </div>

        <div className="ppReceiptPayment">
          <strong>{order.paymentStatus === "PAID" ? "PAGAMENTO CONFIRMADO" : "PAGAMENTO COM AJUSTE"}</strong>
          <span>NÃO COBRAR DO CLIENTE</span>
        </div>

        <section className="ppReceiptSection">
          <h3>ENTREGAR PARA</h3>
          <strong className="ppReceiptCustomer">{order.customer?.name || "Cliente"}</strong>
          {order.customer?.phone && <p>Contato: {order.customer.phone}</p>}
        </section>

        <section className="ppReceiptSection">
          <h3>ENDEREÇO DE ENTREGA</h3>
          <strong>{[address.street, address.number].filter(Boolean).join(", ") || "Endereço não informado"}</strong>
          {address.complement && <p>Compl.: {address.complement}</p>}
          {[address.neighborhood, address.city].some(Boolean) &&
            <p>{[address.neighborhood, address.city, address.state].filter(Boolean).join(" - ")}</p>}
          {address.reference && <p>Ref.: {address.reference}</p>}
        </section>

        <section className="ppReceiptSection">
          <h3>PRODUTOS · {itemCount} {itemCount === 1 ? "UNIDADE" : "UNIDADES"}</h3>
          {items.length ? items.map((item: Order) =>
            <div className="ppReceiptProduct" key={item.id}>
              <b>{Number(item.quantity || 0)}x</b>
              <span>{item.productName || item.product?.name || "Produto"}</span>
            </div>
          ) : <p>Nenhum item disponível para entrega.</p>}
          {isAdjusted && <p className="ppReceiptAdjustment">Itens removidos/reembolsados não constam nesta comanda.</p>}
        </section>

        <div className="ppReceiptTotal">
          <span>TAXA DE ENTREGA</span>
          <strong>{money(order.deliveryFee)}</strong>
        </div>
        {order.courier?.user?.name && <p className="ppReceiptCourier">MOTOBOY: {order.courier.user.name}</p>}

        <footer className="ppReceiptEnd">
          <strong>CONFERIR OS ITENS ANTES DE SAIR</strong>
          <span>PORTO PRIME · PORTO SEGURO / BA</span>
          <span>Comanda operacional · Não é nota fiscal</span>
        </footer>
      </article>;
    })}
  </div>;
}
