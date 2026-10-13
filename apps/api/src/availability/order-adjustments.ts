import {cents} from './customer-credit.js';
export const removedStatuses=['REFUND_PROCESSING','REFUNDED','VOUCHERED'];
/** Derived fulfillment totals. Original capture and refund accounting stay immutable. */
export function orderAdjustments<T extends Record<string,any>>(order:T){
 const items:Array<Record<string,any>>=Array.isArray(order.items)?order.items:[];
 if(order.cancellation)return {...order,fulfillmentItems:[],removedItems:items,removedItemsTotal:items.reduce((sum,i)=>sum+cents(i.total),0)/100,fulfillmentSubtotal:0,fulfillmentDeliveryFee:0,fulfillmentCreditUsed:0,adjustedTotal:Number(order.cancellation.fee)};
 const fulfillmentItems=items.filter(i=>!removedStatuses.includes(i.availabilityStatus));
 const removedItems=items.filter(i=>removedStatuses.includes(i.availabilityStatus));
 const subtotal=fulfillmentItems.reduce((sum,i)=>sum+cents(i.total),0);
 const productCredit=items.reduce((sum,i)=>sum+cents(i.storeCreditShare),0);
 const deliveryCredit=fulfillmentItems.length?Math.max(0,Math.min(cents(order.deliveryFee),cents(order.storeCreditUsed)-productCredit)):0;
 const retainedCredit=fulfillmentItems.reduce((sum,i)=>sum+cents(i.storeCreditShare),0)+deliveryCredit;
 const delivery=fulfillmentItems.length?cents(order.deliveryFee):0;
 return {...order,fulfillmentItems,removedItems,removedItemsTotal:removedItems.reduce((sum,i)=>sum+cents(i.total),0)/100,fulfillmentSubtotal:subtotal/100,fulfillmentDeliveryFee:delivery/100,fulfillmentCreditUsed:retainedCredit/100,adjustedTotal:Math.max(0,subtotal+delivery-retainedCredit)/100};
}
