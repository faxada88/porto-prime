import {cents} from '../availability/customer-credit.js';
/** Amounts already returned or reserved by item refunds are excluded. All calculations use cents. */
export function cancellationAmounts(order:any,accepted:boolean,now=new Date()){
 const items:any[]=order.items??[];
 let cashReturned=cents(order.refundedTotal),creditReturned=0;
 for(const item of items){
  if(item.availabilityStatus==='VOUCHERED'){
   const restored=Math.min(cents(item.creditAmount),cents(item.storeCreditShare));
   creditReturned+=restored;cashReturned+=Math.max(0,cents(item.creditAmount)-restored);
  }else if(['REFUNDED','REFUND_PROCESSING'].includes(item.availabilityStatus)){
   creditReturned+=cents(item.creditAmount);
   if(item.availabilityStatus==='REFUND_PROCESSING')cashReturned+=cents(item.refundAmount);
  }
 }
 const cash=Math.max(0,cents(order.total)-cashReturned),credit=Math.max(0,cents(order.storeCreditUsed)-creditReturned);
 const paidAt=new Date(order.paidAt??order.createdAt);
 const late=Number.isFinite(paidAt.getTime())&&now.getTime()-paidAt.getTime()>120000;
 const collected=accepted&&['PICKED_UP','OUT_FOR_DELIVERY'].includes(order.status);
 const fee=collected?Math.min(cash+credit,cents(order.deliveryFee)):accepted&&late?Math.min(cash+credit,Math.round(cents(order.deliveryFee)/2)):0;
 const cashFee=Math.min(fee,cash),creditFee=fee-cashFee;
 return {fee:fee/100,cashRefund:(cash-cashFee)/100,creditRefund:(credit-creditFee)/100};
}
