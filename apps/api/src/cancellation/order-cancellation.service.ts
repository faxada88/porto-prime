import {BadRequestException,ConflictException,ForbiddenException,Injectable,Logger,NotFoundException,OnModuleInit,OnModuleDestroy,ServiceUnavailableException} from '@nestjs/common';
import {AuthService} from '../auth/auth.service.js';
import {PrismaService} from '../prisma/prisma.service.js';
import {RealtimeGateway} from '../realtime/realtime.gateway.js';
import {cents,lockCustomerCredit} from '../availability/customer-credit.js';
import {cancellationAmounts} from './cancellation-policy.js';
@Injectable()
export class OrderCancellationService implements OnModuleInit,OnModuleDestroy {
 private timer?:NodeJS.Timeout;private checking=false;private busy=new Set<string>();
 private readonly logger=new Logger(OrderCancellationService.name);
 constructor(private readonly db:PrismaService,private readonly auth:AuthService,private readonly realtime:RealtimeGateway){}
 onModuleInit(){this.timer=setInterval(()=>void this.check(),10000);this.timer.unref();}
 onModuleDestroy(){if(this.timer)clearInterval(this.timer);}
 private async customer(auth?:string){const u=await this.auth.authenticate(auth);if(u.role!=='CUSTOMER')throw new ForbiddenException('Acesso exclusivo do cliente');return u;}
 private editable(order:any){if(order.adminDeletedAt||order.deliveredAt||['DELIVERED','CANCELED'].includes(order.status)||!['PAID','PARTIALLY_REFUNDED'].includes(order.paymentStatus))throw new ConflictException('Este pedido não pode mais ser cancelado pelo aplicativo');}
 private async amounts(db:any,order:any){const offer=order.courierId?await db.deliveryOffer.findFirst({where:{orderId:order.id,courierId:order.courierId,status:'ACCEPTED',acceptedAt:{not:null}},select:{id:true}}):null;return cancellationAmounts(order,!!offer);}
 async quote(id:string,authorization?:string){const u=await this.customer(authorization);const order=await this.db.order.findFirst({where:{id,customerId:u.id,adminDeletedAt:null},include:{items:true,cancellation:true}});if(!order)throw new NotFoundException('Pedido não encontrado');if(order.cancellation)return {alreadyCanceled:true,...order.cancellation};this.editable(order);return {orderId:id,...await this.amounts(this.db,order)};}
 private async transaction<T>(fn:(tx:any)=>Promise<T>):Promise<T>{
  for(let attempt=0;;attempt++){try{return await this.db.$transaction(fn);}catch(e:any){if(attempt>=2||!(e.code==='P2034'||e.code==='40P01'||e.meta?.code==='40P01'))throw e;}}
 }
 async cancel(id:string,input:{reason:string;expectedFee:number;expectedCashRefund:number;expectedCreditRefund:number},authorization?:string){
  const u=await this.customer(authorization);
  const result=await this.transaction(async tx=>{
   // Match offer acceptance's lock order; no network/authentication calls within the transaction.
   await tx.$queryRawUnsafe('SELECT "id" FROM "DeliveryOffer" WHERE "orderId"=$1 ORDER BY "id" FOR UPDATE',id);
   await tx.$queryRawUnsafe('SELECT "id" FROM "Order" WHERE "id"=$1 FOR UPDATE',id);
   const order=await tx.order.findFirst({where:{id,customerId:u.id,adminDeletedAt:null},include:{items:true,cancellation:true}});
   if(!order)throw new NotFoundException('Pedido não encontrado');
   if(order.cancellation)return {record:order.cancellation,order,couriers:[] as string[]};
   this.editable(order);const amounts=await this.amounts(tx,order);
   if(cents(input.expectedFee)!==cents(amounts.fee)||cents(input.expectedCashRefund)!==cents(amounts.cashRefund)||cents(input.expectedCreditRefund)!==cents(amounts.creditRefund))throw new ConflictException('Os valores foram atualizados. Revise o cancelamento antes de confirmar');
   if(amounts.cashRefund>0&&!order.stripePaymentIntentId)throw new ConflictException('A loja precisa verificar a referência do pagamento antes deste cancelamento');
   const offers=await tx.deliveryOffer.findMany({where:{orderId:id,status:'PENDING'},select:{courierId:true}});
   const record=await tx.orderCancellation.create({data:{orderId:id,customerId:u.id,courierId:order.courierId,paymentIntentId:order.stripePaymentIntentId,reason:input.reason,returnStatus:order.courierId&&['PICKED_UP','OUT_FOR_DELIVERY'].includes(order.status)?'REQUIRED':'NOT_REQUIRED',...amounts}});
   if(record.returnStatus==='REQUIRED')await tx.courierProfile.update({where:{id:record.courierId},data:{presenceStatus:'DELIVERING'}});
   await this.restoreCredit(tx,record);
   if(cents(record.fee)>0&&record.courierId)await tx.courierLedgerEntry.upsert({where:{idempotencyKey:'cancel:'+record.id+':courier'},create:{courierId:record.courierId,orderId:id,type:'ADJUSTMENT_CREDIT',amount:record.fee,description:'Taxa de cancelamento · pedido #'+id.slice(-8).toUpperCase(),idempotencyKey:'cancel:'+record.id+':courier',metadata:{kind:'ORDER_CANCELLATION',cancellationId:record.id}},update:{}});
   await tx.deliveryOffer.updateMany({where:{orderId:id,status:'PENDING'},data:{status:'CANCELED',respondedAt:new Date(),canceledAt:new Date()}});
   const updated=await tx.order.update({where:{id},data:{status:'CANCELED',canceledAt:new Date(),activeOfferId:null,fulfillmentHold:true}});
   return {record,order:updated,couriers:[...new Set<string>([...offers.map((o:any)=>o.courierId),...(order.courierId?[order.courierId]:[])])]};
  });
  this.realtime.emitOrderUpdated(result.order);
  if(cents(result.record.creditRefund)>0)this.realtime.emitToUser(result.record.customerId,'customer.credit.updated',{orderId:id});
  for(const courierId of result.couriers){
   this.realtime.emitToCourier(courierId,'delivery.offer.closed',{orderId:id,reason:'Pedido cancelado pelo cliente'});
   try{await this.release(courierId);}catch{this.logger.warn('Cancelamento registrado; disponibilidade será verificada novamente.');}
  }
  try{if(cents(result.record.fee)>0&&result.record.courierId){const courier=await this.db.courierProfile.findUnique({where:{id:result.record.courierId},select:{userId:true}});if(courier)this.realtime.emitToUser(courier.userId,'wallet.updated',{orderId:id});this.realtime.emitToRole('ADMIN','wallet.updated',{courierId:result.record.courierId});}}catch{this.logger.warn('Crédito registrado; atualização de carteira será recuperada na próxima consulta.');}
  void this.process(result.record.id).catch(()=>this.logger.warn('Cancelamento registrado; devolução será verificada novamente.'));
  return result.record;
 }
 private async restoreCredit(tx:any,record:any){
  if(cents(record.creditRefund)===0)return;
  await lockCustomerCredit(tx,record.customerId);
  const key='cancel:'+record.id+':credit';
  const existing=await tx.customerCreditEntry.findUnique({where:{idempotencyKey:key},select:{id:true}});
  if(existing)return;
  await tx.customerCreditEntry.upsert({where:{idempotencyKey:key},create:{customerId:record.customerId,orderId:record.orderId,amount:record.creditRefund,idempotencyKey:key,description:'Saldo devolvido por cancelamento do pedido'},update:{}});
  await tx.order.update({where:{id:record.orderId},data:{creditedTotal:{increment:record.creditRefund}}});
 }
 private async release(courierId:string){
  await this.db.$transaction(async tx=>{
   await tx.$queryRaw`SELECT "id" FROM "CourierProfile" WHERE "id"=${courierId} FOR UPDATE`;
   const returning=await tx.orderCancellation.findFirst({where:{courierId,returnStatus:{in:['REQUIRED','IN_TRANSIT','ARRIVED']}},select:{id:true}});
   if(returning)return;
   const active=await tx.order.findFirst({where:{courierId,adminDeletedAt:null,status:{notIn:['DELIVERED','CANCELED']}},select:{id:true}});
   const offered=await tx.deliveryOffer.findFirst({where:{courierId,status:'PENDING',expiresAt:{gt:new Date()}},select:{id:true}});
   if(active||offered)return;
   const courier=await tx.courierProfile.findUnique({where:{id:courierId},select:{isOnline:true}});
   if(courier)await tx.courierProfile.update({where:{id:courierId},data:{presenceStatus:courier.isOnline?'AVAILABLE':'OFFLINE',availableSince:courier.isOnline?new Date():null}});
  });
  this.realtime.emitToRole('ADMIN','courier.presence',{courierId});
 }
 private async refund(record:any){
  if(cents(record.cashRefund)===0)return {status:'succeeded'};
  const secret=process.env.STRIPE_SECRET_KEY;if(!secret)throw new ServiceUnavailableException('A devolução será verificada pela loja');
  const params=new URLSearchParams({payment_intent:record.paymentIntentId,amount:String(cents(record.cashRefund))});params.set('metadata[orderId]',record.orderId);params.set('metadata[cancellationId]',record.id);
  const url='https://api.stripe.com/v1/refunds'+(record.stripeRefundId?'/'+encodeURIComponent(record.stripeRefundId):'');
  const response=await fetch(url,{method:record.stripeRefundId?'GET':'POST',headers:{Authorization:'Bearer '+secret,...(!record.stripeRefundId?{'Content-Type':'application/x-www-form-urlencoded','Idempotency-Key':`porto-prime:cancel:${record.id}:${record.refundAttempt}`}:{})},...(!record.stripeRefundId?{body:params}:{}),signal:AbortSignal.timeout(10000)});
  const data:any=await response.json();
  if(!response.ok){if(response.status>=400&&response.status<500&&response.status!==429){await this.db.orderCancellation.updateMany({where:{id:record.id,status:'PENDING'},data:{status:'REVIEW',lastError:'A loja precisa conferir a devolução no pagamento original.'}});await this.notify(record.orderId);}throw new ServiceUnavailableException('A devolução permanece registrada para verificação');}
  if(typeof data.id!=='string'||data.payment_intent!==record.paymentIntentId||data.currency!=='brl'||data.amount!==cents(record.cashRefund)||!['pending','succeeded','failed','canceled','requires_action'].includes(data.status))throw new ServiceUnavailableException('A confirmação da devolução precisa ser verificada');
  return data;
 }
 async process(id:string){
  if(this.busy.has(id))return;this.busy.add(id);
  try{
   const record=await this.db.orderCancellation.findUnique({where:{id}});if(!record||record.status!=='PENDING')return;
   const closed=await this.db.deliveryOffer.findMany({where:{orderId:record.orderId,status:'CANCELED'},select:{courierId:true}});
   for(const courierId of new Set<string>([...closed.map(o=>o.courierId),...(record.courierId?[record.courierId]:[])]))await this.release(courierId);
   await this.db.$transaction(async tx=>{await tx.$queryRaw`SELECT "id" FROM "Order" WHERE "id"=${record.orderId} FOR UPDATE`;await this.restoreCredit(tx,record);});
   const refund=await this.refund(record);
   if(cents(record.cashRefund)>0){await this.db.orderCancellation.updateMany({where:{id,status:'PENDING'},data:{stripeRefundId:refund.id,stripeRefundStatus:refund.status,...(['failed','canceled','requires_action'].includes(refund.status)?{status:'REVIEW',lastError:'A devolução precisa de verificação pela loja.'}:{})}});}
   if(refund.status!=='succeeded'){await this.notify(record.orderId);return;}
   const settled=await this.db.$transaction(async tx=>{
    await tx.$queryRaw`SELECT "id" FROM "Order" WHERE "id"=${record.orderId} FOR UPDATE`;
    const current=await tx.orderCancellation.findUnique({where:{id}});if(!current||current.status!=='PENDING')return false;
    await this.restoreCredit(tx,current);
    if(cents(current.fee)>0&&current.courierId)await tx.courierLedgerEntry.upsert({where:{idempotencyKey:'cancel:'+id+':courier'},create:{courierId:current.courierId,orderId:current.orderId,type:'ADJUSTMENT_CREDIT',amount:current.fee,description:'Taxa de cancelamento · pedido #'+current.orderId.slice(-8).toUpperCase(),idempotencyKey:'cancel:'+id+':courier',metadata:{kind:'ORDER_CANCELLATION',cancellationId:id}},update:{}});
    const pending=await tx.orderItem.count({where:{orderId:current.orderId,availabilityStatus:'REFUND_PROCESSING',refundStatus:{not:'succeeded'}}});
    await tx.order.update({where:{id:current.orderId},data:{refundedTotal:{increment:current.cashRefund},paymentStatus:cents(current.fee)>0||pending>0?'PARTIALLY_REFUNDED':'REFUNDED'}});
    await tx.orderCancellation.update({where:{id},data:{status:'COMPLETED',completedAt:new Date(),lastError:null}});return true;
   });
   if(settled){this.realtime.emitToUser(record.customerId,'customer.credit.updated',{orderId:record.orderId});if(record.courierId){const courier=await this.db.courierProfile.findUnique({where:{id:record.courierId},select:{userId:true}});if(courier)this.realtime.emitToUser(courier.userId,'wallet.updated',{orderId:record.orderId});this.realtime.emitToRole('ADMIN','wallet.updated',{courierId:record.courierId});}await this.notify(record.orderId);}
  }finally{this.busy.delete(id);}
 }
 async returnStep(id:string,step:'IN_TRANSIT'|'ARRIVED'|'CONFIRMED',authorization?:string){
  const user=await this.auth.authenticate(authorization);
  if(step==='CONFIRMED'&&user.role!=='ADMIN')throw new ForbiddenException('Confirmação exclusiva da distribuidora');
  if(step!=='CONFIRMED'&&user.role!=='COURIER')throw new ForbiddenException('Acesso exclusivo do entregador');
  const profile=step!=='CONFIRMED'?await this.db.courierProfile.findUnique({where:{userId:user.id},select:{id:true}}):null;
  const result=await this.transaction(async tx=>{
   await tx.$queryRawUnsafe('SELECT "id" FROM "OrderCancellation" WHERE "id"=$1 FOR UPDATE',id);
   const record=await tx.orderCancellation.findUnique({where:{id}});
   if(!record)throw new NotFoundException('Devolução não encontrada');
   if(step!=='CONFIRMED'&&record.courierId!==profile?.id)throw new ForbiddenException('Esta devolução pertence a outro entregador');
   if(record.returnStatus===step)return record;
   const previous=step==='IN_TRANSIT'?'REQUIRED':step==='ARRIVED'?'IN_TRANSIT':'ARRIVED';
   if(record.returnStatus!==previous)throw new ConflictException('A etapa da devolução foi atualizada. Atualize a tela');
   return tx.orderCancellation.update({where:{id},data:{returnStatus:step,...(step==='IN_TRANSIT'?{returnStartedAt:new Date()}:step==='ARRIVED'?{returnArrivedAt:new Date()}:{returnedAt:new Date(),returnConfirmedBy:user.id})}});
  });
  if(result.courierId){if(step==='CONFIRMED')await this.release(result.courierId);const courier=await this.db.courierProfile.findUnique({where:{id:result.courierId},select:{userId:true}});if(courier)this.realtime.emitToUser(courier.userId,'order.updated',{orderId:result.orderId});}
  await this.notify(result.orderId);return result;
 }
 private async notify(id:string){const order=await this.db.order.findUnique({where:{id}});if(order)this.realtime.emitOrderUpdated(order);}
 async retry(id:string,authorization?:string){const user=await this.auth.authenticate(authorization);if(user.role!=='ADMIN')throw new ForbiddenException('Acesso exclusivo do administrador');const record=await this.db.orderCancellation.findUnique({where:{id}});if(!record)throw new NotFoundException('Cancelamento não encontrado');if(record.status==='COMPLETED')return record;
  await this.db.orderCancellation.updateMany({where:{id,status:'REVIEW'},data:{status:'PENDING',lastError:null,...(['failed','canceled'].includes(record.stripeRefundStatus??'')?{stripeRefundId:null,stripeRefundStatus:null,refundAttempt:{increment:1},refundHistory:[...(Array.isArray(record.refundHistory)?record.refundHistory:[]),record.stripeRefundId]}:{})}});
  await this.process(id);return this.db.orderCancellation.findUnique({where:{id}});
 }
 private async check(){if(this.checking)return;this.checking=true;try{const records=await this.db.orderCancellation.findMany({where:{status:'PENDING'},select:{id:true},orderBy:{createdAt:'asc'},take:20});for(const record of records){try{await this.process(record.id);}catch{this.logger.warn('Devolução de cancelamento aguardando verificação; registros preservados.');}}}catch{this.logger.warn('Não foi possível consultar cancelamentos pendentes.');}finally{this.checking=false;}}
}
