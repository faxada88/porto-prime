import {cents} from '../availability/customer-credit.js';
export async function referralSnapshot(tx:any,code:string|undefined,customerId:string){
 if(!code)return {};
 const partner=await tx.partnerProfile.findFirst({where:{referralCode:code,approved:true,user:{status:'ACTIVE',role:'PARTNER',id:{not:customerId}}},select:{id:true,commissionPercent:true}});
 return partner?{referralPartnerId:partner.id,partnerCommissionPercent:partner.commissionPercent}:{};
}
export function deliveredCommission(order:any){
 const base=(order.items||[]).filter((item:any)=>['AVAILABLE','REPLACED'].includes(item.availabilityStatus??'AVAILABLE')).reduce((sum:number,item:any)=>sum+cents(item.total),0);
 return Math.round(base*Number(order.partnerCommissionPercent??0)/100)/100;
}
export async function creditPartnerDeliveryTx(tx:any,orderId:string){
 const order=await tx.order.findUnique({where:{id:orderId},include:{items:true,referralPartner:{select:{id:true,userId:true}}}});
 if(!order||order.adminDeletedAt||order.status!=='DELIVERED'||!['PAID','PARTIALLY_REFUNDED'].includes(order.paymentStatus)||!order.referralPartner||order.partnerCommissionCreditedAt)return null;
 const amount=deliveredCommission(order);if(amount<=0)return null;
 await tx.$queryRawUnsafe('SELECT "id" FROM "PartnerProfile" WHERE "id" = $1 FOR UPDATE',order.referralPartner.id);
 const key='partner-delivery:'+order.id;
 const entry=await tx.partnerLedgerEntry.upsert({where:{idempotencyKey:key},update:{},create:{userId:order.referralPartner.userId,type:'DELIVERY_CREDIT',amount,description:'Comissão do pedido #'+order.id.slice(-8).toUpperCase(),idempotencyKey:key,metadata:{orderId:order.id,commissionPercent:Number(order.partnerCommissionPercent),source:'REFERRAL',basis:'DELIVERED_PRODUCTS'}}});
 await tx.order.update({where:{id:order.id},data:{partnerCommissionAmount:entry.amount,partnerCommissionCreditedAt:entry.createdAt}});
 return {userId:order.referralPartner.userId,amount:Number(entry.amount)};
}
