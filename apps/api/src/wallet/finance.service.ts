import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { RealtimeGateway } from '../realtime/realtime.gateway.js';
import { normalizePix } from './pix-key.js';

@Injectable()
export class FinanceService {
  constructor(private readonly prisma: PrismaService, private readonly auth: AuthService, private readonly realtime: RealtimeGateway) {}
  private get db(): any { return this.prisma; }
  private async admin(authorization?: string) {
    const actor = await this.auth.authenticate(authorization);
    if(actor.role !== 'ADMIN') throw new ForbiddenException('Acesso exclusivo de administrador');
    return actor;
  }
  private text(raw: unknown, label: string, max=500) {
    if(typeof raw !== 'string' || raw.trim().length < 3 || raw.trim().length > max) throw new BadRequestException(`${label}: informe de 3 a ${max} caracteres`);
    return raw.trim();
  }
  private amount(raw: unknown) {
    const amount=Number(raw);
    if(!['string','number'].includes(typeof raw) || !Number.isFinite(amount) || amount<=0 || amount>99999999.99 || Math.abs(amount*100-Math.round(amount*100))>0.00001) throw new BadRequestException('Informe um valor positivo com até duas casas decimais');
    return Math.round(amount*100)/100;
  }
  private requestKey(body: any, actorId: string, userId: string, action: string) {
    if(typeof body.requestId !== 'string' || !/^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$/i.test(body.requestId)) throw new BadRequestException('Identificador da operação inválido');
    return `manual:${action}:${userId}:${actorId}:${body.requestId}`;
  }
  private async account(userId: string, client=this.db) {
    const user=await client.user.findUnique({where:{id:userId},select:{id:true,name:true,email:true,phone:true,role:true,status:true,courierProfile:{select:{id:true,pixKey:true,pixKeyType:true,onboardingData:true}},partnerProfile:{select:{id:true,onboardingData:true}}}});
    if(!user || !['COURIER','PARTNER'].includes(user.role)) throw new NotFoundException('Conta de motoboy ou parceiro não encontrada');
    const profile=user.role==='COURIER'?user.courierProfile:user.partnerProfile;
    if(!profile) throw new NotFoundException('Perfil financeiro não encontrado');
    const partner=user.role==='PARTNER';
    return {user,profile,partner,owner:partner?{userId:user.id}:{courierId:profile.id},ledger:partner?client.partnerLedgerEntry:client.courierLedgerEntry,withdrawals:partner?client.partnerWithdrawal:client.withdrawal};
  }
  private async lock(tx:any, account:any) {
    // Same courier lock used by app withdrawals: admin and app serialize together.
    await tx.$queryRawUnsafe(account.partner?'SELECT "id" FROM "PartnerProfile" WHERE "id" = $1 FOR UPDATE':'SELECT "id" FROM "CourierProfile" WHERE "id" = $1 FOR UPDATE',account.profile.id);
  }
  private async balance(account:any) {
    const sum=await account.ledger.aggregate({where:{...account.owner,availableAt:{lte:new Date()}},_sum:{amount:true}});
    return Math.round(Number(sum._sum.amount??0)*100)/100;
  }
  private notify(userId:string) {
    const payload={accountUserId:userId,at:new Date().toISOString()};
    this.realtime.emitToUser(userId,'wallet.updated',payload);
    this.realtime.emitToRole('ADMIN','wallet.updated',payload);
  }
  async accounts(authorization?:string, search='') {
    await this.admin(authorization);
    if(search.length>100)throw new BadRequestException('Busca muito longa');
    const term=search.trim();
    return this.db.user.findMany({where:{role:{in:['COURIER','PARTNER']},...(term?{OR:[{name:{contains:term,mode:'insensitive'}},{email:{contains:term,mode:'insensitive'}},{phone:{contains:term}},{id:term}]}:{})},select:{id:true,name:true,email:true,phone:true,role:true,status:true},orderBy:[{name:'asc'},{id:'asc'}],take:200});
  }
  async detail(userId:string,authorization?:string,self=false) {
    const actor=self?await this.auth.authenticate(authorization):await this.admin(authorization);
    if(self && (actor.role!=='PARTNER' || actor.id!==userId)) throw new ForbiddenException('Acesso exclusivo à sua carteira de parceiro');
    const a=await this.account(userId);
    const [balance,entries,withdrawals,audit,pending,credits,paid]=await Promise.all([
      this.balance(a),a.ledger.findMany({where:a.owner,orderBy:{createdAt:'desc'},take:100}),
      a.withdrawals.findMany({where:a.owner,orderBy:{requestedAt:'desc'},take:100}),
      self?Promise.resolve([]):this.db.financialAudit.findMany({where:{accountUserId:userId},orderBy:{createdAt:'desc'},take:100}),
      a.withdrawals.aggregate({where:{...a.owner,status:{in:['PENDING','PROCESSING']}},_sum:{amount:true}}),
      a.ledger.aggregate({where:{...a.owner,type:{in:['DELIVERY_CREDIT','ADJUSTMENT_CREDIT','BONUS_CREDIT']}},_sum:{amount:true}}),
      a.withdrawals.aggregate({where:{...a.owner,status:'PAID'},_sum:{amount:true},_count:{_all:true}}),
    ]);
    const onboard=a.profile.onboardingData??{};
    return {user:{id:a.user.id,name:a.user.name,email:a.user.email,role:a.user.role,status:a.user.status},availableBalance:balance,totalCredited:Number(credits._sum.amount??0),paidTotal:Number(paid._sum.amount??0),paidCount:paid._count?._all??0,pendingWithdrawals:Number(pending._sum.amount??0),pixKey:a.profile.pixKey||onboard.pixKey||'',pixKeyType:a.profile.pixKeyType||onboard.pixKeyType||'',entries,withdrawals,audit};
  }
  async mine(authorization?:string) {
    const user=await this.auth.authenticate(authorization);
    return this.detail(user.id,authorization,true);
  }
  async overview(authorization?:string) {
    await this.admin(authorization);
    const selectUser={id:true,name:true,email:true,role:true};
    const [courier,partner,cstats,pstats]=await Promise.all([
      this.db.withdrawal.findMany({include:{courier:{select:{user:{select:selectUser}}}},orderBy:{requestedAt:'desc'},take:200}),
      this.db.partnerWithdrawal.findMany({include:{user:{select:selectUser}},orderBy:{requestedAt:'desc'},take:200}),
      this.db.withdrawal.groupBy({by:['status'],_sum:{amount:true},_count:{_all:true}}),
      this.db.partnerWithdrawal.groupBy({by:['status'],_sum:{amount:true},_count:{_all:true}}),
    ]);
    const stats:Record<string,{amount:number,count:number}>={};
    for(const row of [...cstats,...pstats]) { const v=stats[row.status]??{amount:0,count:0};v.amount+=Number(row._sum.amount??0);v.count+=row._count._all;stats[row.status]=v; }
    const rows=[...courier.map((w:any)=>{const {courier,...rest}=w;return {...rest,user:courier.user,kind:'COURIER'};}),...partner.map((w:any)=>({...w,kind:'PARTNER'}))].sort((a,b)=>new Date(b.requestedAt).getTime()-new Date(a.requestedAt).getTime()).slice(0,200);
    return {rows,stats};
  }
  async credit(userId:string,body:any,authorization?:string) {
    const actor=await this.admin(authorization); body=body??{}; const amount=this.amount(body.amount),reason=this.text(body.reason,'Motivo');
    const key=this.requestKey(body,actor.id,userId,'credit');
    const type=body.type??'ADJUSTMENT_CREDIT';
    if(!['ADJUSTMENT_CREDIT','BONUS_CREDIT'].includes(type)) throw new BadRequestException('Tipo de crédito inválido');
    const result=await this.db.$transaction(async(tx:any)=>{
      const a=await this.account(userId,tx);await this.lock(tx,a);
      const previous=await a.ledger.findUnique({where:{idempotencyKey:key}});
      if(previous){if(Number(previous.amount)!==amount || previous.description!==reason || previous.type!==type)throw new ConflictException('Este identificador já foi usado em outra operação');return previous;}
      const entry=await a.ledger.create({data:{...a.owner,type,amount,description:reason,idempotencyKey:key,metadata:{actorId:actor.id,actorName:actor.name,source:'ADMIN',reason}}});
      await tx.financialAudit.create({data:{actorId:actor.id,actorName:actor.name??actor.id,accountUserId:userId,action:type,amount,reason}});
      return entry;
    });
    this.notify(userId);return result;
  }
  async withdraw(userId:string,body:any,authorization?:string,self=false) {
    const actor=self?await this.auth.authenticate(authorization):await this.admin(authorization);
    if(self && (actor.role!=='PARTNER'||actor.id!==userId)) throw new ForbiddenException('Acesso exclusivo à sua carteira de parceiro');
    body=body??{};
    const amount=this.amount(body.amount),reason=self?'Saque solicitado pelo parceiro':this.text(body.reason,'Motivo');
    const key=this.requestKey(body,actor.id,userId,'withdrawal');
    const result=await this.db.$transaction(async(tx:any)=>{
      const a=await this.account(userId,tx);await this.lock(tx,a);
      const previous=await a.ledger.findUnique({where:{idempotencyKey:key}});
      if(previous){if(Number(previous.amount)!==-amount || previous.metadata?.reason!==reason)throw new ConflictException('Este identificador já foi usado em outra operação');return a.withdrawals.findUnique({where:{id:previous.metadata.withdrawalId}});}
      const data=a.profile.onboardingData??{};
      const pix=normalizePix(body.pixKey||a.profile.pixKey||data.pixKey,body.pixKey?body.pixKeyType:a.profile.pixKeyType||data.pixKeyType);
      if(!pix)throw new BadRequestException('Informe uma chave PIX válida para o saque');
      if(Math.round(amount*100)>Math.round((await this.balance(a))*100))throw new BadRequestException('Saldo disponível insuficiente');
      const withdrawal=await a.withdrawals.create({data:{id:randomUUID(),...a.owner,amount,status:'PENDING',pixKey:pix.key,pixKeyType:pix.type}});
      await a.ledger.create({data:{...a.owner,type:'WITHDRAWAL_DEBIT',amount:-amount,description:reason,idempotencyKey:key,metadata:{withdrawalId:withdrawal.id,actorId:actor.id,actorName:actor.name,source:self?'PARTNER':'ADMIN',reason}}});
      await tx.financialAudit.create({data:{actorId:actor.id,actorName:actor.name??actor.id,accountUserId:userId,action:'WITHDRAWAL_REQUESTED',withdrawalId:withdrawal.id,amount,reason}});
      return withdrawal;
    });
    this.notify(userId);return result;
  }
  async myWithdrawal(body:any,authorization?:string) {
    const user=await this.auth.authenticate(authorization);return this.withdraw(user.id,body,authorization,true);
  }
  async status(kind:string,id:string,body:any,authorization?:string) {
    const actor=await this.admin(authorization); body=body??{};
    if(!['COURIER','PARTNER'].includes(kind)||!['PROCESSING','PAID','REJECTED'].includes(body.status))throw new BadRequestException('Status inválido');
    const reason=this.text(body.reason,'Motivo');
    const reference=body.status==='PAID'?this.text(body.reference,'Referência do pagamento',120):null;
    let receiptUrl:string|undefined;
    if(body.receiptUrl){try{const url=new URL(String(body.receiptUrl));if(url.protocol!=='https:'||url.username||url.password||url.href.length>2048)throw Error();receiptUrl=url.href;}catch{throw new BadRequestException('Comprovante: utilize uma URL HTTPS válida');}}
    const result=await this.db.$transaction(async(tx:any)=>{
      const partner=kind==='PARTNER',withdrawals=partner?tx.partnerWithdrawal:tx.withdrawal;
      await tx.$queryRawUnsafe(partner?'SELECT "id" FROM "PartnerWithdrawal" WHERE "id" = $1 FOR UPDATE':'SELECT "id" FROM "Withdrawal" WHERE "id" = $1 FOR UPDATE',id);
      const current=await withdrawals.findUnique({where:{id}});if(!current)throw new NotFoundException('Saque não encontrado');
      const userId=partner?current.userId:(await tx.courierProfile.findUnique({where:{id:current.courierId},select:{userId:true}}))?.userId;
      if(!userId)throw new NotFoundException('Conta não encontrada');
      if(current.status===body.status)return {row:current,userId};
      if(['PAID','REJECTED','CANCELED'].includes(current.status))throw new ConflictException('Este saque já foi encerrado');
      if(body.status==='PAID'&&current.status!=='PROCESSING')throw new BadRequestException('Coloque o saque em processamento antes de confirmar o pagamento');
      const a=await this.account(userId,tx);await this.lock(tx,a);
      const row=await withdrawals.update({where:{id},data:{status:body.status,processedAt:body.status==='PROCESSING'?null:new Date(),...(receiptUrl?{receiptUrl}:{})}});
      if(body.status==='REJECTED') {
        const key=`withdrawal:${id}:reversal`;
        await a.ledger.upsert({where:{idempotencyKey:key},create:{...a.owner,type:'REVERSAL',amount:current.amount,description:'Estorno de saque rejeitado',idempotencyKey:key,metadata:{withdrawalId:id,actorId:actor.id,reason}},update:{}});
      }
      await tx.financialAudit.create({data:{actorId:actor.id,actorName:actor.name??actor.id,accountUserId:userId,action:body.status,amount:current.amount,reason,reference,withdrawalId:id}});
      return {row,userId};
    });
    this.notify(result.userId);return result.row;
  }
}
