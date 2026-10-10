import {cents} from './customer-credit.js';
export const removedStatuses=['REFUND_PROCESSING','REFUNDED','VOUCHERED'];
/** Derived fulfillment totals. Original capture and refund accounting stay immutable. */
export function orderAdjustments<T extends Record<string,any>>(order:T){
 const items:Array<Record<string,any>>=Array.isArray(order.items)?order.items:[];
 const fulfillmentItems=items.filter(i=>!removedStatuses.includes(i.availabilityStatus));
 const removedItems=items.filter(i=>removedStatuses.includes(i.availabilityStatus));
 const subtotal=fulfillmentItems.reduce((sum,i)=>sum+cents(i.total),0);
 const retainedCredit=fulfillmentItems.reduce((sum,i)=>sum+cents(i.storeCreditShare),0);
 const delivery=fulfillmentItems.length?cents(order.deliveryFee):0;
 return {...order,fulfillmentItems,removedItems,removedItemsTotal:removedItems.reduce((sum,i)=>sum+cents(i.total),0)/100,fulfillmentSubtotal:subtotal/100,fulfillmentDeliveryFee:delivery/100,fulfillmentCreditUsed:retainedCredit/100,adjustedTotal:Math.max(0,subtotal+delivery-retainedCredit)/100};
}
