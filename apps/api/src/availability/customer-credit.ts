export const cents=(value:unknown)=>Math.round(Number(value??0)*100);
export async function lockCustomerCredit(tx:any,customerId:string){
 await tx.$queryRawUnsafe("SELECT pg_advisory_xact_lock(hashtext($1))::text AS credit_lock",'customer-credit:'+customerId);
}
export async function creditBalance(db:any,customerId:string){
 const sum=await db.customerCreditEntry.aggregate({where:{customerId},_sum:{amount:true}});
 return Math.max(0,cents(sum._sum.amount))/100;
}
export function allocateCredit(items:{total:number;storeCreditShare?:number}[],credit:number){
 let remaining=cents(credit);
 for(const item of items){const share=Math.min(remaining,cents(item.total));item.storeCreditShare=share/100;remaining-=share;}
}
export function settlementAmounts(item:any,order:any,others:any[]){
 const allRemoved=others.every(i=>['REFUND_PROCESSING','REFUNDED','VOUCHERED'].includes(i.availabilityStatus));
 const delivery=allRemoved?cents(order.deliveryFee):0;
 const entitlement=cents(item.total)+delivery;
 const restored=cents(item.storeCreditShare);
 return {cash:(entitlement-restored)/100,credit:restored/100,voucher:entitlement/100};
}
