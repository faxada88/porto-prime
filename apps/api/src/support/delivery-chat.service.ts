import {Injectable,ForbiddenException,BadRequestException} from '@nestjs/common';
import {PrismaService} from '../prisma/prisma.service.js';
import {AuthService} from '../auth/auth.service.js';
import {RealtimeGateway} from '../realtime/realtime.gateway.js';
import {SupportService} from './support.service.js';
@Injectable()
export class DeliveryChatService {
 constructor(private readonly db:PrismaService,private readonly auth:AuthService,private readonly realtime:RealtimeGateway,private readonly support:SupportService){}
 private value(value:unknown,max:number){if(typeof value!=='string'||!value.trim()||value.trim().length>max)throw new BadRequestException('Confira a mensagem e tente novamente');return value.trim();}
 private async access(orderId:string,authorization?:string,db:PrismaService|any=this.db,authenticated?:Awaited<ReturnType<AuthService['authenticate']>>){
  const user=authenticated??await this.auth.authenticate(authorization);
  if(!['CUSTOMER','COURIER'].includes(user.role))throw new ForbiddenException('Conversa exclusiva dos participantes da entrega');
  const order=await db.order.findFirst({where:{id:orderId,adminDeletedAt:null,...(user.role==='CUSTOMER'?{customerId:user.id}:{courier:{userId:user.id}})},select:{id:true,status:true,customerId:true,customer:{select:{name:true}},courier:{select:{userId:true,user:{select:{name:true}}}}}});
  if(!order)throw new ForbiddenException('Este pedido não está disponível para sua conta');
  return {user,order};
 }
 async detail(orderId:string,authorization?:string,before?:string){
  const {user,order}=await this.access(orderId,authorization);
  let cursor: {id:string}|undefined;
  if(before){const row=await this.db.deliveryChatMessage.findFirst({where:{id:before,orderId},select:{id:true}});if(!row)throw new BadRequestException('Mensagem anterior inválida');cursor={id:row.id};}
  const rows=await this.db.deliveryChatMessage.findMany({where:{orderId},take:101,orderBy:[{createdAt:'desc'},{id:'desc'}],...(cursor?{cursor,skip:1}:{})});
  const messages=rows.slice(0,100).reverse().map(m=>({id:m.id,text:m.text,senderRole:m.senderRole,mine:m.senderId===user.id,createdAt:m.createdAt}));
  return {available:!!order.courier,canSend:!!order.courier&&!['DELIVERED','CANCELED'].includes(order.status),counterpart:user.role==='CUSTOMER'?order.courier?.user.name:order.customer.name,role:user.role,status:order.status,messages,olderCursor:rows.length>100?messages[0]?.id:null};
 }
 async send(orderId:string,body:Record<string,unknown>,authorization?:string){
  const text=this.value(body?.text,4000),requestId=this.value(body?.requestId,100);
  // Authenticate before borrowing the transaction connection: local Prisma dev has pool max=1.
  const authenticated=await this.auth.authenticate(authorization);
  const result=await this.db.$transaction(async tx=>{
   await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${`delivery-chat:${orderId}`}))`;
   const {user,order}=await this.access(orderId,authorization,tx,authenticated);
   const duplicate=await tx.deliveryChatMessage.findUnique({where:{senderId_requestId:{senderId:user.id,requestId}}});
   if(duplicate){if(duplicate.orderId!==orderId||duplicate.text!==text)throw new BadRequestException('Identificador já utilizado');return {user,order,message:duplicate};}
   if(!order.courier||['DELIVERED','CANCELED'].includes(order.status))throw new BadRequestException('A conversa está disponível durante a entrega com motoboy definido');
   const message=await tx.deliveryChatMessage.create({data:{orderId,senderId:user.id,senderRole:user.role,text,requestId}});
   return {user,order,message};
  });
  for(const id of new Set([result.order.customerId,result.order.courier?.userId].filter(Boolean)))this.realtime.emitToUser(id as string,'delivery.chat.updated',{orderId,messageId:result.message.id,senderId:result.user.id,recipientId:id,senderRole:result.user.role,at:result.message.createdAt});
  return {sent:true,messageId:result.message.id};
 }
 async escalate(orderId:string,body:Record<string,unknown>,authorization?:string){
  const {user}=await this.access(orderId,authorization);
  const reason=this.value(body?.reason,80),text=this.value(body?.text,1000),requestId=this.value(body?.requestId,100);
  const reasons=['Endereço ou ponto de encontro','Não consigo contato','Problema na entrega','Preciso de ajuda da distribuidora'];
  if(!reasons.includes(reason))throw new BadRequestException('Selecione o motivo do atendimento');
  // Context is captured on the first request; retries reuse that exact saved body.
  const prior=await this.db.supportMessage.findUnique({where:{senderId_requestId:{senderId:user.id,requestId}}});
  if(prior){const thread=await this.db.supportThread.findUnique({where:{id:prior.threadId}});if(!thread||thread.ownerId!==user.id||thread.orderId!==orderId||!prior.text.startsWith('Encaminhado da conversa da entrega\n'))throw new BadRequestException('Identificador já utilizado');return thread;}
  const recent=await this.db.deliveryChatMessage.findMany({where:{orderId},orderBy:[{createdAt:'desc'},{id:'desc'}],take:12});
  const context=recent.reverse().map(m=>`${m.senderRole==='CUSTOMER'?'Cliente':'Motoboy'}: ${m.text.slice(0,160)}`).join('\n');
  return this.support.create({orderId,category:user.role==='CUSTOMER'?'Pedido e entrega':'Entrega em andamento',subject:'Ajuda na entrega',text:`Encaminhado da conversa da entrega\nMotivo: ${reason}\n${text}\n\nContexto recente:\n${context||'Ainda não houve troca de mensagens.'}`,requestId},authorization);
 }
}
