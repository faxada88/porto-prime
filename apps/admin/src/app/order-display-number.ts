/**
 * Human-readable daily print number; not the database ID or the delivery PIN.
 * A new number is reserved atomically when the order is created.
 */
export function orderDisplayNumber(order: {displayNumber?: number | null}): string {
  const number = Number(order.displayNumber);
  return Number.isInteger(number) && number >= 1 && number <= 9999
    ? String(number).padStart(4, '0')
    : '—';
}

/** Keep canceled/fully refunded/paused deliveries off the courier print queue. */
export function canPrintCourierSlip(order: {
  paymentStatus?: string;
  status?: string;
  fulfillmentHold?: boolean;
}): boolean {
  return ['PAID', 'PARTIALLY_REFUNDED'].includes(String(order.paymentStatus || '')) &&
    !['CANCELED'].includes(String(order.status || '')) &&
    !order.fulfillmentHold;
}
