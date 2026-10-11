import {Injectable, BadRequestException, ForbiddenException, NotFoundException} from '@nestjs/common';
import {PrismaService} from '../prisma/prisma.service.js';
import {AuthService} from '../auth/auth.service.js';
import {RealtimeGateway} from '../realtime/realtime.gateway.js';

const categories:Record<string,string[]> = {
 CUSTOMER:['Pedido e entrega','Produto recebido','Pagamento e reembolso','Endereço','Outros assuntos'],
 COURIER:['Entrega em andamento','Problema na retirada','Problema no destino','Carteira e saque','Cadastro e documentos','Outros assuntos'],
 PARTNER:['Comissão e indicações','QR code e link','Carteira e saque','Cadastro e dados','Pedido indicado','Outros assuntos'],
};
const summary = {owner:{select:{id:true,name:true,role:true}},messages:{orderBy:[{createdAt:'desc' as const},{id:'desc' as const}],take:1,select:{text:true,senderRole:true,createdAt:true}}};
@Injectable()
export class SupportService {
 constructor(private readonly db:PrismaService,private readonly auth:AuthService,private readonly realtime:RealtimeGateway){}
 private text(value:unknown,name:string,max:number){if(typeof value!=='string'||!value.trim()||value.trim().length>max)throw new BadRequestException(`${name}: informe de 1 a ${max} caracteres`);return value.trim();}
 private body(value:unknown):asserts value is Record<string,unknown>{if(!value||typeof value!=='object'||Array.isArray(value))throw new BadRequestException('Informe os dados do atendimento');}
 private async user(authorization?:string,admin=false){const u=await this.auth.authenticate(authorization);if(admin&&u.role!=='ADMIN')throw new ForbiddenException('Acesso exclusivo do atendimento');return u;}
 private async thread(id:string,user:{id:string;role:string}){const thread=await this.db.supportThread.findUnique({where:{id}});if(!thread||user.role!=='ADMIN'&&thread.ownerId!==user.id)throw new NotFoundException('Atendimento não encontrado');return thread;}
 private emit(thread:{id:string;ownerId:string|null},senderRole:string,kind='message'){const payload={threadId:thread.id,senderRole,kind,at:new Date().toISOString()};if(thread.ownerId)this.realtime.emitToUser(thread.ownerId,'support.updated',payload);this.realtime.emitToRole('ADMIN','support.updated',payload);}
 async options(authorization?:string){const u=await this.user(authorization);return {categories:categories[u.role]||[],statuses:['OPEN','IN_PROGRESS','RESOLVED']};}
 async list(authorization:string|undefined,query:Record<string,string>,admin=false){
  const u=await this.user(authorization,admin);const status=['OPEN','IN_PROGRESS','RESOLVED'].includes(query.status)?query.status:undefined;
  const role=['CUSTOMER','COURIER','PARTNER'].includes(query.role)?query.role as 'CUSTOMER'|'COURIER'|'PARTNER':undefined;
  const search=typeof query.search==='string'?query.search.slice(0,100).trim():'';
  const where={...(!admin?{ownerId:u.id}:{}),...(status?{status}:{}),...(admin&&role?{ownerRole:role}:{}),...(!admin&&query.orderId?{orderId:query.orderId}:{}),...(search?{OR:[{subject:{contains:search,mode:'insensitive' as const}},{id:{contains:search,mode:'insensitive' as const}},{orderId:{contains:search,mode:'insensitive' as const}},{owner:{name:{contains:search,mode:'insensitive' as const}}}]}:{})};
  const page=Math.min(10000,Math.max(0,Math.floor(Number(query.page)||0)));
  const rows=await this.db.supportThread.findMany({where,include:summary,orderBy:[{updatedAt:'desc'},{id:'desc'}],take:100,skip:page*100});
  const total=await this.db.supportThread.count({where});
  return {rows,total};
 }
 async create(body:Record<string,unknown>,authorization?:string){
  this.body(body);
  const u=await this.user(authorization);if(!categories[u.role])throw new ForbiddenException('Abra o atendimento pela conta do solicitante');
  const category=this.text(body.category,'Assunto',80);if(!categories[u.role].includes(category))throw new BadRequestException('Selecione um assunto válido');
  const subject=this.text(body.subject,'Título',120),text=this.text(body.text,'Mensagem',4000),requestId=this.text(body.requestId,'Identificador',100);
  const orderId=body.orderId==null?null:this.text(body.orderId,'Pedido',100);
  if(orderId){const order=await this.db.order.findFirst({where:{id:orderId,adminDeletedAt:null,...(u.role==='CUSTOMER'?{customerId:u.id}:u.role==='COURIER'?{courier:{userId:u.id}}:{id:'__not_allowed__'})},select:{id:true}});if(!order)throw new ForbiddenException('Este pedido não está vinculado à sua conta');}
  const thread=await this.db.$transaction(async tx=>{
   // Serialize retries for this account. No lock on order/dispatch/payment rows.
   await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtext(${u.id}))`;
   const duplicate=await tx.supportMessage.findUnique({where:{senderId_requestId:{senderId:u.id,requestId}}});
   if(duplicate){const previous=await tx.supportThread.findUniqueOrThrow({where:{id:duplicate.threadId}});if(previous.orderId!==orderId||duplicate.text!==text)throw new BadRequestException('Identificador de envio já utilizado');return previous;}
   const existing=orderId?await tx.supportThread.findUnique({where:{ownerId_orderId:{ownerId:u.id,orderId}}}):null;
   const t=existing||await tx.supportThread.create({data:{ownerId:u.id,ownerRole:u.role,orderId,category,subject}});
   await tx.supportMessage.create({data:{threadId:t.id,senderId:u.id,senderRole:u.role,text,requestId}});
   return tx.supportThread.update({where:{id:t.id},data:{updatedAt:new Date(),...(t.status==='RESOLVED'?{status:'OPEN'}:{})}});
  });this.emit(thread,u.role);return thread;
 }
 async detail(id:string,authorization?:string,before?:string){
  const u=await this.user(authorization),thread=await this.thread(id,u);
  let cursor: {id:string}|undefined;
  if(before){const row=await this.db.supportMessage.findFirst({where:{id:before,threadId:id},select:{id:true}});if(!row)throw new BadRequestException('Mensagem anterior inválida');cursor={id:row.id};}
  const messages=await this.db.supportMessage.findMany({where:{threadId:id},orderBy:[{createdAt:'desc'},{id:'desc'}],take:101,...(cursor?{cursor,skip:1}:{}),select:{id:true,text:true,senderRole:true,createdAt:true}});
  const more=messages.length>100;const selected=messages.slice(0,100).reverse();
  const owner=thread.ownerId?await this.db.user.findUnique({where:{id:thread.ownerId},select:{id:true,name:true,role:true}}):null;
  return {...thread,owner,messages:selected,olderCursor:more?selected[0]?.id:null};
 }
 async reply(id:string,body:Record<string,unknown>,authorization?:string){
  this.body(body);
  const u=await this.user(authorization);await this.thread(id,u);
  const text=this.text(body.text,'Mensagem',4000),requestId=this.text(body.requestId,'Identificador',100);
  const thread=await this.db.$transaction(async tx=>{
   await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtext(${u.id}))`;
   const duplicate=await tx.supportMessage.findUnique({where:{senderId_requestId:{senderId:u.id,requestId}}});
   if(duplicate){if(duplicate.threadId!==id||duplicate.text!==text)throw new BadRequestException('Identificador de envio já utilizado');return tx.supportThread.findUniqueOrThrow({where:{id}});}
   await tx.supportMessage.create({data:{threadId:id,senderId:u.id,senderRole:u.role,text,requestId}});
   return tx.supportThread.update({where:{id},data:{updatedAt:new Date(),status:u.role==='ADMIN'?'IN_PROGRESS':'OPEN'}});
  });this.emit(thread,u.role);return thread;
 }
 async status(id:string,body:Record<string,unknown>,authorization?:string){this.body(body);const u=await this.user(authorization,true);await this.thread(id,u);const status=this.text(body.status,'Status',30);if(!['OPEN','IN_PROGRESS','RESOLVED'].includes(status))throw new BadRequestException('Status inválido');const thread=await this.db.supportThread.update({where:{id},data:{status}});this.emit(thread,u.role,'status');return thread;}
}
