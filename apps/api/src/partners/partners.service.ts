import {Injectable,ForbiddenException,NotFoundException,BadRequestException} from '@nestjs/common';
import {PrismaService} from '../prisma/prisma.service.js';
import {AuthService} from '../auth/auth.service.js';
import {RealtimeGateway} from '../realtime/realtime.gateway.js';
import {FinanceService} from '../wallet/finance.service.js';
import QRCode from 'qrcode';
import {normalizePix} from '../wallet/pix-key.js';
@Injectable()
export class PartnersService{
 constructor(private readonly db:PrismaService,private readonly auth:AuthService,private readonly realtime:RealtimeGateway,private readonly finance:FinanceService){}
 private async allowed(authorization:string|undefined,role:string){const u=await this.auth.authenticate(authorization);if(u.role!==role)throw new ForbiddenException('Acesso exclusivo de '+(role==='ADMIN'?'administrador':'parceiro'));return u;}
 async publicReferral(code:string){if(!/^[a-zA-Z0-9-]{8,64}$/.test(code))throw new NotFoundException('Indicação indisponível');const p=await this.db.partnerProfile.findFirst({where:{referralCode:code,approved:true,user:{status:'ACTIVE',role:'PARTNER'}},select:{businessName:true,user:{select:{name:true}}}});if(!p)throw new NotFoundException('Indicação indisponível');return {code,name:p.businessName||p.user.name};}
 private link(code:string,appUrl?:string){const raw=process.env.FRONTEND_PUBLIC_URL||appUrl||(process.env.CODESPACE_NAME?`https://${process.env.CODESPACE_NAME}-8086.app.github.dev`:undefined);if(!raw)return null;if(raw.length>1000)throw new BadRequestException('Endereço do aplicativo inválido');try{const url=new URL(raw);if(!['http:','https:'].includes(url.protocol)||url.username||url.password)throw Error();if(url.protocol==='http:'&&!['localhost','127.0.0.1'].includes(url.hostname))throw Error();url.pathname='/';url.search='';url.hash='';url.searchParams.set('ref',code);return url.toString();}catch{throw new BadRequestException('Informe o endereço público do aplicativo');}}
 private async record(id:string,authorization:string|undefined,self:boolean,appUrl?:string){
  const p=await this.db.partnerProfile.findUnique({where:{userId:id},include:{user:{select:{id:true,name:true,email:true,phone:true,status:true}}}});if(!p)throw new NotFoundException('Parceiro não encontrado');
  const results=await Promise.allSettled([this.finance.detail(id,authorization,self),this.db.order.findMany({where:{referralPartnerId:p.id},select:{id:true,status:true,paymentStatus:true,createdAt:true,deliveredAt:true,partnerCommissionPercent:true,partnerCommissionAmount:true,partnerCommissionCreditedAt:true,adminDeletedAt:true},orderBy:{createdAt:'desc'},take:50}),this.db.order.count({where:{referralPartnerId:p.id}}),this.db.order.count({where:{referralPartnerId:p.id,status:'DELIVERED'}}),this.db.order.count({where:{referralPartnerId:p.id,adminDeletedAt:null,status:{notIn:['CANCELED','DELIVERED']}}}),this.db.partnerLedgerEntry.aggregate({where:{userId:id,idempotencyKey:{startsWith:'partner-delivery:'}},_sum:{amount:true}})]);
  const resolved=(i:number)=>results[i].status==='fulfilled'?(results[i] as PromiseFulfilledResult<any>).value:null;
  const [finance,orders,total,delivered,pending,amount]=results.map((_,i)=>resolved(i));
  const warnings:string[]=[];
  if(!finance)warnings.push('A carteira não pôde ser atualizada. O cadastro continua disponível.');
  if(results.slice(1).some(r=>r.status==='rejected'))warnings.push('Não foi possível atualizar todas as indicações. Tente novamente.');
  const sharing=await this.sharing(p,appUrl,warnings);
  return {profile:p,finance,summary:results.slice(2).some(r=>r.status==='rejected')?null:{total,delivered,pending,earned:Number(amount?._sum?.amount||0)},orders:orders||[],warnings,...sharing};
 }
 private async sharing(p:any,appUrl?:string,warnings:string[]=[]){
  const enabled=p.approved&&p.user.status==='ACTIVE';
  let link:string|null=null,qrDataUrl:string|null=null;
  if(enabled){try{link=this.link(p.referralCode,appUrl);if(link)qrDataUrl=await QRCode.toDataURL(link,{width:560,margin:4,errorCorrectionLevel:'M'});else warnings.push('Configure o endereço público do aplicativo para divulgar.');}catch{warnings.push('Não foi possível preparar o QR. Atualize o endereço público do aplicativo.');}}
  return {enabled,link,qrDataUrl};
 }
 async referral(authorization?:string,appUrl?:string){const u=await this.allowed(authorization,'PARTNER');const p=await this.db.partnerProfile.findUnique({where:{userId:u.id},include:{user:{select:{name:true,status:true}}}});if(!p)throw new NotFoundException('Parceiro não encontrado');const warnings:string[]=[];return {businessName:p.businessName,code:p.referralCode,commissionPercent:Number(p.commissionPercent),...await this.sharing(p,appUrl,warnings),warnings};}
 async mine(authorization?:string,appUrl?:string){const u=await this.allowed(authorization,'PARTNER');return this.record(u.id,authorization,true,appUrl);}
 async adminRecord(id:string,authorization?:string,appUrl?:string){await this.allowed(authorization,'ADMIN');return this.record(id,authorization,false,appUrl);}
 async edit(id:string,body:Record<string,unknown>,authorization?:string){
  const actor=await this.allowed(authorization,'ADMIN');const allowed=['name','email','phone','businessName','businessType','document','commissionPercent','pixKey','pixKeyType','extraData'];if(!body||Object.keys(body).some(k=>!allowed.includes(k)))throw new BadRequestException('Campo não permitido');
  if(body.commissionPercent!==undefined&&(typeof body.commissionPercent!=='number'||!Number.isFinite(body.commissionPercent)||body.commissionPercent<0||body.commissionPercent>100||Math.abs(body.commissionPercent*100-Math.round(body.commissionPercent*100))>0.00001))throw new BadRequestException('Comissão deve ficar entre 0% e 100%, com até duas casas decimais');
  const strings:Record<string,string>={};for(const key of allowed.filter(k=>!['commissionPercent','extraData'].includes(k))){if(key in body){if(typeof body[key]!=='string'||String(body[key]).trim().length>250)throw new BadRequestException('Dados inválidos');strings[key]=String(body[key]).trim();}}
  if('name'in strings&&strings.name.length<2)throw new BadRequestException('Informe o nome');if('businessName'in strings&&!strings.businessName)throw new BadRequestException('Informe seu nome de divulgação');
  if('email'in strings){strings.email=strings.email.toLowerCase();if(!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(strings.email))throw new BadRequestException('E-mail inválido');}if('phone'in strings){strings.phone=strings.phone.replace(/\D/g,'');if(strings.phone&&strings.phone.length!==11)throw new BadRequestException('Telefone inválido');}
  if('document'in strings){strings.document=strings.document.replace(/\D/g,'');const a=await this.auth.availability(strings.document.length===11?'partnerCpf':'cnpj',strings.document);if(!a.valid)throw new BadRequestException('CPF ou CNPJ inválido');}
  try{await this.db.$transaction(async tx=>{
    await tx.$queryRawUnsafe('SELECT "id" FROM "PartnerProfile" WHERE "userId" = $1 FOR UPDATE',id);
    const p=await tx.partnerProfile.findUnique({where:{userId:id},include:{user:true}});if(!p)throw new NotFoundException('Parceiro não encontrado');
    if(strings.document){const other=await tx.partnerProfile.findFirst({where:{document:strings.document,userId:{not:id}},select:{id:true}});if(other)throw new BadRequestException('Documento já cadastrado');}
    const stored:any=p.onboardingData||{};const extra:any=body.extraData||{};if(typeof extra!=='object'||Array.isArray(extra)||JSON.stringify(extra).length>20000)throw new BadRequestException('Dados adicionais inválidos');for(const key of Object.keys(extra))if(!Object.hasOwn(stored,key)||allowed.includes(key)||/(password|senha|token|secret|^role$|status|approved|commission|balance|referral|cpf|cnpj|pix)/i.test(key)||typeof extra[key]!==typeof stored[key])throw new BadRequestException('Campo adicional protegido ou formato inválido');
    const data:any={onboardingData:{...stored,...extra,...strings}};if('businessName'in strings)data.businessName=strings.businessName;if('document'in strings)data.document=strings.document;
    if('pixKey'in strings||'pixKeyType'in strings){const pix=normalizePix(strings.pixKey??stored.pixKey,strings.pixKeyType??stored.pixKeyType);if(!pix)throw new BadRequestException('Chave PIX inválida');data.onboardingData.pixKey=pix.key;data.onboardingData.pixKeyType=pix.type;}
    if(body.commissionPercent!==undefined){data.commissionPercent=body.commissionPercent;if(Number(p.commissionPercent)!==body.commissionPercent)await tx.financialAudit.create({data:{actorId:actor.id,actorName:actor.name??actor.id,accountUserId:id,action:'PARTNER_COMMISSION_CHANGED',amount:0,reason:'Percentual alterado de '+p.commissionPercent+'% para '+body.commissionPercent+'%'}});}
    const account:any={};for(const key of ['name','email','phone'])if(key in strings)account[key]=strings[key]||null;if(Object.keys(account).length)await tx.user.update({where:{id},data:account});await tx.partnerProfile.update({where:{userId:id},data});
  });}catch(e:any){if(e.code==='P2002')throw new BadRequestException('E-mail, telefone ou documento já cadastrado');throw e;}
  this.realtime.emitToUser(id,'partner.profile.updated',{userId:id});this.realtime.emitToRole('ADMIN','partner.profile.updated',{userId:id});return {success:true};
 }
}
