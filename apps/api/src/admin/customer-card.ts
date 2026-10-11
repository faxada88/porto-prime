import {BadRequestException,NotFoundException} from '@nestjs/common';
import {createHash} from 'node:crypto';
import {cents,creditBalance,lockCustomerCredit} from '../availability/customer-credit.js';
async function customer(db:any,id:string){const user=await db.user.findUnique({where:{id},select:{id:true,role:true}});if(!user||user.role!=='CUSTOMER')throw new NotFoundException('Cliente não encontrado');}
export async function customerCard(db:any,id:string){
 await customer(db,id);
 const digest=createHash('sha256').update('porto-prime-card:'+id).digest('hex').slice(0,12).toUpperCase();
 const entries=await db.customerCreditEntry.findMany({where:{customerId:id},orderBy:[{createdAt:'desc'},{id:'desc'}],take:50,select:{id:true,amount:true,description:true,createdAt:true,orderId:true,idempotencyKey:true}});
 return {available:await creditBalance(db,id),cardCode:'PP-'+digest.match(/.{1,4}/g)!.join('-'),entries:entries.map(({idempotencyKey,...entry}:any)=>({...entry,source:idempotencyKey.startsWith('admin-card:')?'ADMIN':'ORDER',administratorId:idempotencyKey.startsWith('admin-card:')?idempotencyKey.split(':')[1]:null}))};
}
export async function adjustCustomerCard(db:any,id:string,administratorId:string,body:Record<string,unknown>){
 const {operation,amount,requestId}=body;const reason=typeof body.reason==='string'?body.reason.trim():'';
 if(!['ADD','REMOVE'].includes(String(operation))||typeof amount!=='number'||!Number.isFinite(amount)||amount<=0||amount>=100000000||Math.abs(amount*100-cents(amount))>0.000001)throw new BadRequestException('Informe um valor positivo com até duas casas decimais');
 if(reason.length<3||reason.length>300)throw new BadRequestException('Informe o motivo do ajuste, com 3 a 300 caracteres');
 if(typeof requestId!=='string'||!/^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/i.test(requestId))throw new BadRequestException('Identificação do ajuste inválida');
 await customer(db,id);
 const key='admin-card:'+administratorId+':'+id+':'+requestId;
 const signed=(operation==='ADD'?1:-1)*cents(amount)/100;
 return db.$transaction(async(tx:any)=>{
  await lockCustomerCredit(tx,id);
  const existing=await tx.customerCreditEntry.findUnique({where:{idempotencyKey:key}});
  if(existing){if(cents(existing.amount)!==cents(signed)||existing.description!==reason)throw new BadRequestException('Este ajuste já foi registrado com outros dados');return {available:await creditBalance(tx,id),entry:existing,replayed:true};}
  const balance=await creditBalance(tx,id);
  if(operation==='REMOVE'&&cents(amount)>cents(balance))throw new BadRequestException('Saldo insuficiente para remover este valor');
  const entry=await tx.customerCreditEntry.create({data:{customerId:id,amount:signed,idempotencyKey:key,description:reason}});
  return {available:await creditBalance(tx,id),entry,replayed:false};
 });
}
