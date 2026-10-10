import {BadRequestException,ForbiddenException,Injectable,Logger,OnModuleInit,OnModuleDestroy} from '@nestjs/common';
import {AuthService} from '../auth/auth.service.js';
import {PrismaService} from '../prisma/prisma.service.js';
import {RealtimeGateway} from '../realtime/realtime.gateway.js';
import {demandEnabled,DEMAND_THRESHOLD,waitingOrders} from './demand-policy.js';
@Injectable()
export class OperationDemandService implements OnModuleInit,OnModuleDestroy {
 private timer?:NodeJS.Timeout;
 private running=false;
 private readonly logger=new Logger(OperationDemandService.name);
 constructor(private readonly db:PrismaService,private readonly auth:AuthService,private readonly realtime:RealtimeGateway){}
 onModuleInit(){this.timer=setInterval(()=>void this.tick(),3000);this.timer.unref();void this.tick();}
 onModuleDestroy(){if(this.timer)clearInterval(this.timer);}
 private async tick(){if(this.running)return;this.running=true;try{await this.reconcile();}catch{this.logger.warn('Não foi possível sincronizar a alta demanda. Nova tentativa em 3 segundos.');}finally{this.running=false;}}
 private async allowed(authorization:string|undefined,role:'ADMIN'|'COURIER'){
  const user=await this.auth.authenticate(authorization);
  if(user.role!==role)throw new ForbiddenException(role==='ADMIN'?'Acesso exclusivo do administrador':'Acesso exclusivo de motoboy');
  return user;
 }
 private safe(row:any){return {enabled:row.enabled,mode:row.mode,reason:row.enabled?(row.mode==='AUTO'?'AUTOMATIC':'MANUAL'):null,bonusAmount:Number(row.bonusAmount),waitingCount:row.waitingCount,threshold:DEMAND_THRESHOLD,revision:row.revision,updatedAt:row.updatedAt};}
 private publicSignal(row:any){return {enabled:row.enabled,revision:row.revision,updatedAt:row.updatedAt};}
 private async reconcile(patch?:{mode?:string;bonusAmount?:number;updatedBy:string}){
  const result=await (this.db as any).$transaction(async(tx:any)=>{
   // Serialize automatic checks and manual writes across Nest instances.
   await tx.$queryRawUnsafe('SELECT pg_advisory_xact_lock(710101600)::text AS demand_lock');
   const previous=await tx.courierDemandSignal.upsert({where:{id:'default'},create:{id:'default'},update:{}});
   const waitingCount=await tx.order.count({where:waitingOrders});
   const mode=patch?.mode??previous.mode;
   const bonusAmount=patch?.bonusAmount??Number(previous.bonusAmount);
   const enabled=demandEnabled(mode,waitingCount);
   const changed=previous.enabled!==enabled||previous.mode!==mode||Number(previous.bonusAmount)!==bonusAmount||previous.waitingCount!==waitingCount;
   const row=changed?await tx.courierDemandSignal.update({where:{id:'default'},data:{enabled,mode,bonusAmount,waitingCount,revision:{increment:1},...(patch?{updatedBy:patch.updatedBy}:{})}}):previous;
   return {row,changed};
  });
  if(result.changed){const payload=this.safe(result.row);this.realtime.emitToRole('COURIER','courier.demand.updated',payload);this.realtime.emitToRole('ADMIN','courier.demand.updated',payload);this.realtime.emitDemandUpdated(this.publicSignal(result.row));}
  return result.row;
 }
 private async snapshot(){return await (this.db as any).courierDemandSignal.findUnique({where:{id:'default'}})??{enabled:false,mode:'AUTO',bonusAmount:2.5,waitingCount:0,revision:0,updatedAt:null};}
 async read(authorization:string|undefined,role:'ADMIN'|'COURIER'){await this.allowed(authorization,role);return this.safe(role==='ADMIN'?await this.reconcile():await this.snapshot());}
 async publicRead(){return this.publicSignal(await this.snapshot());}
 async set(body:any,authorization?:string){
  const admin=await this.allowed(authorization,'ADMIN');
  if(!body||typeof body!=='object')throw new BadRequestException('Informe a configuração de alta demanda');
  let mode=body.mode;
  if(mode===undefined&&typeof body.enabled==='boolean')mode=body.enabled?'MANUAL_ON':'MANUAL_OFF';
  if(mode!==undefined&&!['AUTO','MANUAL_ON','MANUAL_OFF'].includes(mode))throw new BadRequestException('Selecione Automático, ON ou OFF');
  let bonusAmount:number|undefined;
  if(body.bonusAmount!==undefined){
   const value=String(body.bonusAmount).replace(',','.');
   if(!/^\d{1,3}(\.\d{1,2})?$/.test(value)||Number(value)<=0||Number(value)>100)throw new BadRequestException('Informe um bônus entre R$ 0,01 e R$ 100,00, com até duas casas decimais');
   bonusAmount=Number(value);
  }
  if(mode===undefined&&bonusAmount===undefined)throw new BadRequestException('Informe o modo ou o valor adicional');
  return this.safe(await this.reconcile({mode,bonusAmount,updatedBy:admin.id}));
 }
}
