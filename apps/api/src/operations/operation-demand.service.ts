import {BadRequestException,ForbiddenException,Injectable} from '@nestjs/common';
import {AuthService} from '../auth/auth.service.js';
import {PrismaService} from '../prisma/prisma.service.js';
import {RealtimeGateway} from '../realtime/realtime.gateway.js';
@Injectable()
export class OperationDemandService {
 constructor(private readonly db:PrismaService,private readonly auth:AuthService,private readonly realtime:RealtimeGateway){}
 private async allowed(authorization:string|undefined,role:'ADMIN'|'COURIER'){
  const user=await this.auth.authenticate(authorization);
  if(user.role!==role)throw new ForbiddenException(role==='ADMIN'?'Acesso exclusivo do administrador':'Acesso exclusivo de motoboy');
  return user;
 }
 private safe(row:any){return {enabled:row?.enabled??false,revision:row?.revision??0,updatedAt:row?.updatedAt??null};}
 async read(authorization:string|undefined,role:'ADMIN'|'COURIER'){
  await this.allowed(authorization,role);
  return this.safe(await (this.db as any).courierDemandSignal.findUnique({where:{id:'default'}}));
 }
 async set(enabled:unknown,authorization?:string){
  const admin=await this.allowed(authorization,'ADMIN');
  if(typeof enabled!=='boolean')throw new BadRequestException('Informe se o aviso de alta demanda está ativado');
  const row=await (this.db as any).courierDemandSignal.upsert({where:{id:'default'},create:{id:'default',enabled,revision:1,updatedBy:admin.id},update:{enabled,revision:{increment:1},updatedBy:admin.id}});
  const payload=this.safe(row);
  this.realtime.emitToRole('COURIER','courier.demand.updated',payload);
  this.realtime.emitToRole('ADMIN','courier.demand.updated',payload);
  return payload;
 }
}
