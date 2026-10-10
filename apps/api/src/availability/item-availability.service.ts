import {BadRequestException,ConflictException,ForbiddenException,Injectable,Logger,NotFoundException,OnModuleInit,OnModuleDestroy,ServiceUnavailableException} from '@nestjs/common';
import {randomUUID,createHash} from 'node:crypto';
import {AuthService} from '../auth/auth.service.js';
import {PrismaService} from '../prisma/prisma.service.js';
import {RealtimeGateway} from '../realtime/realtime.gateway.js';
import {cents,creditBalance,lockCustomerCredit,settlementAmounts} from './customer-credit.js';
const preDispatch=['PENDING','CONFIRMED','PREPARING','READY_FOR_PICKUP'];
const open=['AWAITING_CUSTOMER'];
@Injectable()
export class ItemAvailabilityService implements OnModuleInit,OnModuleDestroy {
 private timer?:NodeJS.Timeout;
 private checking=false;
 private readonly logger=new Logger(ItemAvailabilityService.name);
 private readonly refundsInFlight=new Set<string>();
 constructor(private readonly db:PrismaService,private readonly auth:AuthService,private readonly realtime:RealtimeGateway){}
 onModuleInit(){this.timer=setInterval(()=>void this.checkRefunds(),10000);this.timer.unref();}
 onModuleDestroy(){if(this.timer)clearInterval(this.timer);}
 private async allowed(authorization:string|undefined,role:string){const user=await this.auth.authenticate(authorization);if(user.role!==role)throw new ForbiddenException('Acesso não autorizado');return user;}
 private async locked(tx:any,id:string){
  await tx.$queryRawUnsafe('SELECT "id" FROM "Order" WHERE "id"=$1 FOR UPDATE',id);
  const order=await tx.order.findUnique({where:{id},include:{items:true}});
  if(!order)throw new NotFoundException('Pedido não encontrado');return order;
 }
 private item(order:any,id:string){const item=order.items.find((i:any)=>i.id===id);if(!item)throw new NotFoundException('Produto não pertence a este pedido');return item;}
 private editable(order:any){if(order.courierId||!preDispatch.includes(order.status)||order.paymentStatus!=='PAID')throw new ConflictException('A disponibilidade só pode ser ajustada em pedidos pagos antes do despacho');}
 private async refreshHold(tx:any,orderId:string){
  const order=await tx.order.findUnique({where:{id:orderId},include:{items:true}});
  const hold=order.items.some((i:any)=>open.includes(i.availabilityStatus));
  const removed=order.items.length>0&&order.items.every((i:any)=>['REFUND_PROCESSING','REFUNDED','VOUCHERED'].includes(i.availabilityStatus));
  await tx.order.update({where:{id:orderId},data:{fulfillmentHold:hold,...(removed?{status:'CANCELED',canceledAt:new Date(),...(cents(order.refundedTotal)>=cents(order.total)?{paymentStatus:'REFUNDED'}:{})}:{})}});
 }
 private async notify(id:string){const order=await (this.db as any).order.findUnique({where:{id},include:{items:true,address:true}});if(order)this.realtime.emitOrderUpdated(order);}
 async mark(orderId:string,itemId:string,body:any,authorization?:string){
  await this.allowed(authorization,'ADMIN');
  if(!body||typeof body.unavailable!=='boolean'||(body.note!==undefined&&(typeof body.note!=='string'||body.note.length>500)))throw new BadRequestException('Informe a disponibilidade e uma observação de até 500 caracteres');
  if(body.alternativeIds!==undefined&&(!Array.isArray(body.alternativeIds)||body.alternativeIds.length>8||body.alternativeIds.some((id:any)=>typeof id!=='string')))throw new BadRequestException('Selecione até oito substituições');
  await (this.db as any).$transaction(async(tx:any)=>{
   const order=await this.locked(tx,orderId);this.editable(order);const item=this.item(order,itemId);
   if(!body.unavailable){
    if(item.availabilityStatus!=='AWAITING_CUSTOMER')throw new ConflictException('Uma escolha já confirmada não pode ser desfeita');
    await tx.orderItem.update({where:{id:itemId},data:{availabilityStatus:'AVAILABLE',availabilityNote:null,availabilityOptions:[],customerChoice:null}});
    await this.refreshHold(tx,orderId);return;
   }
   if(!['AVAILABLE','REPLACED'].includes(item.availabilityStatus))throw new ConflictException('Este item já possui uma solicitação em andamento');
   const ids=[...new Set<string>(body.alternativeIds??[])];
   const options=ids.length?await tx.product.findMany({where:{id:{in:ids},active:true,archived:false,stock:{gte:item.quantity},category:{active:true,archived:false}}}):[];
   if(options.length!==ids.length||options.some((p:any)=>p.id===item.productId||cents(p.price)!==cents(item.unitPrice)))throw new BadRequestException('Ofereça produtos disponíveis com o mesmo valor unitário do item original');
   await tx.orderItem.update({where:{id:itemId},data:{availabilityStatus:'AWAITING_CUSTOMER',availabilityNote:body.note?.trim()||'Este produto não está disponível para este pedido.',availabilityOptions:options.map((p:any)=>({id:p.id,name:p.name,imageUrl:p.imageUrl,price:Number(p.price)})),issueId:randomUUID(),originalProductName:item.productName,customerChoice:null,stripeRefundId:null,refundStatus:null,refundAttempt:0,refundAmount:0,creditAmount:0,resolvedAt:null}});
   await tx.order.update({where:{id:orderId},data:{fulfillmentHold:true}});
  });
  await this.notify(orderId);return {message:body.unavailable?'Cliente avisado. Despacho pausado até a decisão.':'Indisponibilidade removida.'};
 }
 async choose(orderId:string,itemId:string,body:any,authorization?:string){
  const user=await this.allowed(authorization,'CUSTOMER');
  if(!body||!['REPLACEMENT','REFUND','VOUCHER'].includes(body.choice))throw new BadRequestException('Escolha substituição, reembolso ou voucher');
  await (this.db as any).$transaction(async(tx:any)=>{
   const order=await this.locked(tx,orderId);if(order.customerId!==user.id)throw new ForbiddenException('Este pedido não pertence à sua conta');const item=this.item(order,itemId);
   if(item.availabilityStatus!=='AWAITING_CUSTOMER'){
    if(item.customerChoice===body.choice)return;
    throw new ConflictException('A opção deste item já foi registrada');
   }
   this.editable(order);
   if(body.choice==='REPLACEMENT'){
    const ids=(Array.isArray(item.availabilityOptions)?item.availabilityOptions:[]).map((p:any)=>p.id);
    if(typeof body.productId!=='string'||!ids.includes(body.productId))throw new BadRequestException('Selecione uma substituição oferecida pela loja');
    // Lock catalog rows until the selected alternative is recorded.
    await tx.$queryRawUnsafe('SELECT "id" FROM "Product" WHERE "id"=$1 FOR UPDATE',body.productId);
    const product=await tx.product.findFirst({where:{id:body.productId,active:true,archived:false,stock:{gte:item.quantity},category:{active:true,archived:false}}});
    if(!product||cents(product.price)!==cents(item.unitPrice))throw new ConflictException('A substituição ficou indisponível. Escolha reembolso ou voucher.');
    await tx.orderItem.update({where:{id:itemId},data:{availabilityStatus:'REPLACED',customerChoice:body.choice,productId:product.id,productName:product.name,resolvedAt:new Date()}});
   }else{
    const amounts=settlementAmounts(item,order,order.items.filter((i:any)=>i.id!==itemId));
    if(body.choice==='VOUCHER'){
     await lockCustomerCredit(tx,user.id);
     await tx.customerCreditEntry.upsert({where:{idempotencyKey:'item:'+item.issueId+':voucher'},create:{customerId:user.id,amount:amounts.voucher,idempotencyKey:'item:'+item.issueId+':voucher',description:'Voucher por item indisponível: '+item.productName,orderId},update:{}});
     await tx.orderItem.update({where:{id:itemId},data:{availabilityStatus:'VOUCHERED',customerChoice:body.choice,creditAmount:amounts.voucher,resolvedAt:new Date()}});
     await tx.order.update({where:{id:orderId},data:{creditedTotal:{increment:amounts.voucher}}});
    }else{
     if(amounts.cash>0&&!order.stripePaymentIntentId)throw new ConflictException('Pagamento sem referência Stripe. Entre em contato com a loja antes de solicitar o reembolso');
     await tx.orderItem.update({where:{id:itemId},data:{availabilityStatus:'REFUND_PROCESSING',customerChoice:body.choice,refundAmount:amounts.cash,creditAmount:amounts.credit,refundStatus:'pending'}});
    }
   }
   await this.refreshHold(tx,orderId);
  });
  await this.notify(orderId);
  if(body.choice==='REFUND'){try{await this.processRefund(itemId);}catch{this.logger.warn('Escolha registrada; reembolso será retomado sem bloquear a entrega dos itens restantes.');}}
  return {message:'Sua escolha foi registrada. Acompanhe o pedido para ver a atualização.'};
 }
 async credits(authorization?:string){
  const user=await this.allowed(authorization,'CUSTOMER');
  const entries=await (this.db as any).customerCreditEntry.findMany({where:{customerId:user.id},select:{id:true,amount:true,description:true,orderId:true,createdAt:true},orderBy:{createdAt:'desc'},take:50});
  const digest=createHash('sha256').update('porto-prime-card:'+user.id).digest('hex').slice(0,12).toUpperCase();
  return {available:await creditBalance(this.db,user.id),cardCode:'PP-'+digest.match(/.{1,4}/g)!.join('-'),entries};
 }

 async retry(orderId:string,itemId:string,authorization?:string){
  await this.allowed(authorization,'ADMIN');
  await (this.db as any).$transaction(async(tx:any)=>{const order=await this.locked(tx,orderId);const item=this.item(order,itemId);if(item.availabilityStatus!=='REFUND_PROCESSING')throw new ConflictException('Não há reembolso pendente neste item');if(['failed','canceled'].includes(item.refundStatus))await tx.orderItem.update({where:{id:itemId},data:{stripeRefundId:null,refundAttempt:{increment:1},refundStatus:'pending'}});});
  await this.processRefund(itemId);return {message:'Reembolso consultado. O status foi sincronizado.'};
 }
 private async stripe(path:string,body?:URLSearchParams,key?:string){
  const secret=process.env.STRIPE_SECRET_KEY;if(!secret)throw new ServiceUnavailableException('Reembolso não configurado. A loja precisa verificar o Stripe');
  const response=await fetch('https://api.stripe.com/v1/'+path,{method:body?'POST':'GET',headers:{Authorization:'Bearer '+secret,...(body?{'Content-Type':'application/x-www-form-urlencoded','Idempotency-Key':key!}:{})},...(body?{body}:{}),signal:AbortSignal.timeout(10000)});
  const data:any=await response.json();if(!response.ok)throw new ServiceUnavailableException('O reembolso está pendente de processamento. A loja pode tentar novamente sem duplicar a solicitação');return data;
 }
 private async processRefund(itemId:string){
  if(this.refundsInFlight.has(itemId))return;this.refundsInFlight.add(itemId);
  try{
   const item=await (this.db as any).orderItem.findUnique({where:{id:itemId},include:{order:true}});
   if(!item||item.availabilityStatus!=='REFUND_PROCESSING'||['failed','canceled'].includes(item.refundStatus))return;
   let refund:any={status:'succeeded'};
   if(cents(item.refundAmount)>0){
    if(item.stripeRefundId)refund=await this.stripe('refunds/'+encodeURIComponent(item.stripeRefundId));
    else{const params=new URLSearchParams({payment_intent:item.order.stripePaymentIntentId,amount:String(cents(item.refundAmount))});params.set('metadata[orderId]',item.orderId);params.set('metadata[itemIssueId]',item.issueId);refund=await this.stripe('refunds',params,'porto-prime:item:'+item.issueId+':refund:'+item.refundAttempt);}
    if(typeof refund.id!=='string'||refund.payment_intent!==item.order.stripePaymentIntentId||refund.currency!=='brl'||refund.amount!==cents(item.refundAmount))throw new ServiceUnavailableException('O retorno do reembolso precisa ser conferido pela loja');
   }
   await (this.db as any).$transaction(async(tx:any)=>{
    const order=await this.locked(tx,item.orderId);const current=this.item(order,itemId);
    if(current.issueId!==item.issueId||current.refundAttempt!==item.refundAttempt||current.availabilityStatus!=='REFUND_PROCESSING')return;
    await tx.orderItem.update({where:{id:itemId},data:{stripeRefundId:refund.id??null,refundStatus:refund.status}});
    if(refund.status!=='succeeded')return;
    if(cents(current.creditAmount)>0){await lockCustomerCredit(tx,order.customerId);await tx.customerCreditEntry.upsert({where:{idempotencyKey:'item:'+item.issueId+':credit-restore'},create:{customerId:order.customerId,amount:current.creditAmount,idempotencyKey:'item:'+item.issueId+':credit-restore',description:'Créditos devolvidos por item indisponível',orderId:order.id},update:{}});}
    await tx.orderItem.update({where:{id:itemId},data:{availabilityStatus:'REFUNDED',resolvedAt:new Date()}});
    await tx.order.update({where:{id:order.id},data:{refundedTotal:{increment:current.refundAmount},creditedTotal:{increment:current.creditAmount}}});
    await this.refreshHold(tx,order.id);
   });
   await this.notify(item.orderId);
  }finally{this.refundsInFlight.delete(itemId);}
 }
 private async checkRefunds(){
  if(this.checking)return;this.checking=true;
  try{const items=await (this.db as any).orderItem.findMany({where:{availabilityStatus:'REFUND_PROCESSING',refundStatus:{notIn:['failed','canceled']}},select:{id:true},take:20,orderBy:{createdAt:'asc'}});for(const item of items){try{await this.processRefund(item.id);}catch{this.logger.warn('Reembolso pendente será verificado novamente; nenhum valor foi duplicado.');}}}catch{this.logger.warn('Não foi possível consultar reembolsos pendentes.');}finally{this.checking=false;}
 }
}
