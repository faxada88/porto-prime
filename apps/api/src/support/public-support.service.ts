import {BadRequestException,ForbiddenException,HttpException,Injectable,NotFoundException} from '@nestjs/common';
import {createHash,randomBytes,timingSafeEqual} from 'node:crypto';
import {PrismaService} from '../prisma/prisma.service.js';
import {AuthService} from '../auth/auth.service.js';
import {RealtimeGateway} from '../realtime/realtime.gateway.js';

export const PUBLIC_TOPICS={ACCESS:'Não consigo entrar',ACCOUNT:'Minha conta ou cadastro',GENERAL:'Dúvidas e problemas gerais',PARTNERSHIP:'Quero fazer uma parceria',SPONSORSHIP:'Patrocínios e ações comerciais'};
const personas=['CUSTOMER','COURIER','PARTNER','OTHER'];
const statuses=['OPEN','IN_PROGRESS','RESOLVED'];
const hash=(text:string)=>createHash('sha256').update(text).digest('hex');
export function publicText(value:unknown,label:string,max:number,required=true){
 if(typeof value!=='string'||value.trim().length>max||(required&&!value.trim()))throw new BadRequestException(`${label} inválido`);
 return value.trim();
}
export function publicKeyMatches(key:unknown,expected:string){
 if(typeof key!=='string'||!/^[A-Za-z0-9_-]{32,100}$/.test(key))return false;
 const actual=Buffer.from(hash(key),'hex'), stored=Buffer.from(expected,'hex');
 return stored.length===actual.length&&timingSafeEqual(actual,stored);
}
@Injectable()
export class PublicSupportService {
 private sweepAt=0;
 private readonly limits=new Map<string,{count:number;until:number}>();
 constructor(private readonly db:PrismaService,private readonly auth:AuthService,private readonly realtime:RealtimeGateway){}
 private get contacts(){return (this.db as any).publicContact;}
 private rate(key:string,max:number,window:number){
  const now=Date.now();if(now>=this.sweepAt){for(const [k,v]of this.limits)if(v.until<now)this.limits.delete(k);this.sweepAt=now+60000;}
  if(this.limits.size>=10000&&!this.limits.has(key))throw new HttpException('Aguarde um momento e tente novamente.',429);
  const previous=this.limits.get(key);const item=previous&&previous.until>now?previous:{count:0,until:now+window};item.count++;this.limits.set(key,item);
  if(item.count>max)throw new HttpException('Muitas tentativas. Aguarde um pouco e tente novamente.',429);
 }
 private async admin(auth?:string){const user=await this.auth.authenticate(auth);if(user.role!=='ADMIN')throw new ForbiddenException('Acesso exclusivo do atendimento');return user;}
 private requestId(value:unknown){const id=publicText(value,'Identificador de envio',80);if(!/^[A-Za-z0-9_-]{16,80}$/.test(id))throw new BadRequestException('Identificador de envio inválido');return id;}
 private emit(id:string,role='GUEST',kind='message'){this.realtime.emitToRole('ADMIN','support.updated',{threadId:id,senderRole:role,kind,channel:'PUBLIC',at:new Date().toISOString()});}
 options(){return {topics:PUBLIC_TOPICS,personas};}
 private body(body:unknown){if(!body||typeof body!=='object'||Array.isArray(body))throw new BadRequestException('Solicitação inválida');}
 async create(body:Record<string,unknown>,ip:string){
  this.body(body);
  this.rate('create:'+hash(ip),100,3600000);
  if(body.website)throw new BadRequestException('Não foi possível enviar o contato');
  const name=publicText(body.name,'Nome',120),email=publicText(body.email,'E-mail',254).toLowerCase();
  if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))throw new BadRequestException('Informe um e-mail válido');
  const phone=publicText(body.phone??'','Telefone',30,false),company=publicText(body.company??'','Empresa',160,false);
  if(phone&&(phone.replace(/\D/g,'').length<10||phone.replace(/\D/g,'').length>15))throw new BadRequestException('Informe um telefone válido com DDD');
  const topic=publicText(body.topic,'Assunto',40),persona=publicText(body.persona,'Perfil',20);
  if(!Object.hasOwn(PUBLIC_TOPICS,topic)||!personas.includes(persona))throw new BadRequestException('Selecione o assunto e o perfil');
  const text=publicText(body.text,'Mensagem',4000),requestId=this.requestId(body.requestId);
  if(typeof body.accessKey!=='string'||!/^[A-Za-z0-9_-]{32,100}$/.test(body.accessKey))throw new BadRequestException('Código de acesso inválido');
  const keyHash=hash(body.accessKey),requestHash=hash(JSON.stringify({name,email,phone,company,topic,persona,text}));
  const previous=await this.contacts.findUnique({where:{requestId}});
  if(previous){if(previous.keyHash!==keyHash||previous.requestHash!==requestHash)throw new BadRequestException('Identificador já utilizado');return this.detail(previous);}
  if(await this.contacts.count({where:{email,createdAt:{gte:new Date(Date.now()-3600000)}}})>=5)throw new HttpException('Você já enviou solicitações recentemente. Acompanhe um protocolo existente.',429);
  let contact:any;
  try{contact=await this.contacts.create({data:{protocol:'PP-'+randomBytes(6).toString('hex').toUpperCase(),requestId,keyHash,requestHash,name,email,phone,company,topic,persona,messages:{create:{text,senderRole:'GUEST',requestId}}}});}
  catch(error:any){if(error?.code!=='P2002')throw error;contact=await this.contacts.findUnique({where:{requestId}});if(!contact||contact.keyHash!==keyHash||contact.requestHash!==requestHash)throw new BadRequestException('Não foi possível criar este protocolo. Tente novamente.');}
  this.emit(contact.id);return this.detail(contact);
 }
 private async visitor(protocol:string,key:unknown,ip:string){
  this.rate('lookup:'+hash(ip),600,60000);
  const contact=await this.contacts.findUnique({where:{protocol:protocol.trim().toUpperCase().slice(0,40)}});
  if(!contact||!publicKeyMatches(key,contact.keyHash))throw new NotFoundException('Protocolo ou código de acesso inválido');return contact;
 }
 private async detail(contact:any,before?:string,admin=false){
  const messages=(this.db as any).publicContactMessage;
  if(before&&!await messages.findFirst({where:{id:before,contactId:contact.id},select:{id:true}}))throw new BadRequestException('Página de mensagens inválida');
  const rows=await messages.findMany({where:{contactId:contact.id},orderBy:[{createdAt:'desc'},{id:'desc'}],take:101,...(before?{cursor:{id:before},skip:1}:{}),select:{id:true,text:true,senderRole:true,createdAt:true}});
  const selected=rows.slice(0,100).reverse();
  return {id:contact.id,protocol:contact.protocol,name:contact.name,email:contact.email,phone:contact.phone,company:contact.company,persona:contact.persona,topic:contact.topic,status:contact.status,createdAt:contact.createdAt,updatedAt:contact.updatedAt,...(admin?{notes:contact.notes||''}:{}),messages:selected,olderCursor:rows.length>100?selected[0]?.id:null};
 }
 async lookup(body:Record<string,unknown>,ip:string){
  this.body(body);let contact:any;
  if(body.requestId&&!body.protocol){this.rate('lookup:'+hash(ip),600,60000);const requestId=this.requestId(body.requestId);contact=await this.contacts.findUnique({where:{requestId}});if(!contact||!publicKeyMatches(body.accessKey,contact.keyHash))throw new NotFoundException('Protocolo ou código de acesso inválido');}
  else contact=await this.visitor(publicText(body.protocol,'Protocolo',40),body.accessKey,ip);
  return this.detail(contact,typeof body.before==='string'?body.before:undefined);
 }
 async visitorReply(protocol:string,body:Record<string,unknown>,ip:string){this.body(body);const c=await this.visitor(protocol,body.accessKey,ip);this.rate('reply:'+c.id,40,3600000);return this.reply(c,body,'GUEST');}
 private async reply(contact:any,body:Record<string,unknown>,role:string,senderId?:string){
  this.body(body);const text=publicText(body.text,'Mensagem',4000),requestId=this.requestId(body.requestId);
  await this.db.$transaction(async (tx:any)=>{
   const previous=await tx.publicContactMessage.findUnique({where:{contactId_senderRole_requestId:{contactId:contact.id,senderRole:role,requestId}}});
   if(previous){if(previous.text!==text)throw new BadRequestException('Identificador de mensagem já utilizado');return;}
   await tx.publicContactMessage.create({data:{contactId:contact.id,text,requestId,senderRole:role,senderId}});
   await tx.publicContact.update({where:{id:contact.id},data:{status:role==='ADMIN'?'IN_PROGRESS':'OPEN',updatedAt:new Date()}});
  });this.emit(contact.id,role);return {sent:true};
 }
 async list(auth:string|undefined,query:Record<string,string>){
  await this.admin(auth);const page=Math.max(0,Math.min(10000,Math.floor(Number(query.page)||0))),search=(query.search||'').trim().slice(0,120);
  const where={...(statuses.includes(query.status)?{status:query.status}:{}),...(Object.hasOwn(PUBLIC_TOPICS,query.topic)?{topic:query.topic}:{}),...(search?{OR:['name','email','protocol','company'].map(field=>({[field]:{contains:search,mode:'insensitive'}}))}:{})};
  const [rows,total]=await Promise.all([this.contacts.findMany({where,orderBy:[{updatedAt:'desc'},{id:'desc'}],take:50,skip:page*50,select:{id:true,protocol:true,name:true,email:true,phone:true,company:true,persona:true,topic:true,status:true,updatedAt:true,messages:{take:1,orderBy:[{createdAt:'desc'},{id:'desc'}],select:{text:true}}}}),this.contacts.count({where})]);return {rows,total};
 }
 async adminDetail(id:string,auth?:string,before?:string){await this.admin(auth);const c=await this.contacts.findUnique({where:{id}});if(!c)throw new NotFoundException('Contato não encontrado');return this.detail(c,before,true);}
 async adminReply(id:string,body:Record<string,unknown>,auth?:string){const u=await this.admin(auth);const c=await this.contacts.findUnique({where:{id}});if(!c)throw new NotFoundException('Contato não encontrado');return this.reply(c,body,'ADMIN',u.id);}
 async status(id:string,body:Record<string,unknown>,auth?:string){await this.admin(auth);this.body(body);const data:Record<string,unknown>={};if(body.status!==undefined){if(typeof body.status!=='string'||!statuses.includes(body.status))throw new BadRequestException('Status inválido');data.status=body.status;}if(body.notes!==undefined)data.notes=publicText(body.notes,'Anotação',4000,false);if(!Object.keys(data).length)throw new BadRequestException('Informe uma alteração');if(!await this.contacts.findUnique({where:{id},select:{id:true}}))throw new NotFoundException('Contato não encontrado');await this.contacts.update({where:{id},data});this.emit(id,'ADMIN','status');return {updated:true};}
}
