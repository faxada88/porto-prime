import {BadRequestException,ForbiddenException,Injectable,NotFoundException,OnModuleDestroy} from '@nestjs/common';
import {PrismaService} from '../prisma/prisma.service.js';
import {AuthService} from '../auth/auth.service.js';
import {RealtimeGateway} from '../realtime/realtime.gateway.js';

type Point={latitude:number;longitude:number;accuracy:number;heading:number|null;capturedAt:string;receivedAt:string;sequence:number;courierId:string};
export function trackingMode(order:any):'DELIVERY'|'RETURN'|null {
 if(order.adminDeletedAt)return null;
 if(order.status==='CANCELED')return ['REQUIRED','IN_TRANSIT','ARRIVED'].includes(order.cancellation?.returnStatus)?'RETURN':null;
 return order.status==='OUT_FOR_DELIVERY'?'DELIVERY':null;
}
export function trackingPosition(body:any,now=Date.now()) {
 if(!body||typeof body!=='object')throw new BadRequestException('Localização inválida');
 const {latitude,longitude,accuracy,heading,capturedAt}=body;
 if(typeof latitude!=='number'||!Number.isFinite(latitude)||Math.abs(latitude)>90||typeof longitude!=='number'||!Number.isFinite(longitude)||Math.abs(longitude)>180||typeof accuracy!=='number'||!Number.isFinite(accuracy)||accuracy<0||accuracy>100)throw new BadRequestException('Aguardando uma posição GPS mais precisa');
 const timestamp=typeof capturedAt==='string'?Date.parse(capturedAt):NaN;
 if(!Number.isFinite(timestamp)||Math.abs(now-timestamp)>60000)throw new BadRequestException('Localização desatualizada');
 return {latitude,longitude,accuracy,heading:typeof heading==='number'&&Number.isFinite(heading)&&heading>=0&&heading<360?heading:null,capturedAt:new Date(timestamp).toISOString()};
}
@Injectable()
export class DeliveryTrackingService implements OnModuleDestroy {
 private points=new Map<string,Point>();
 private routes=new Map<string,{at:number;mode:string;value:any}>();
 private sequence=0;
 private timer=setInterval(()=>{const cutoff=Date.now()-120000;for(const [id,p] of this.points)if(Date.parse(p.receivedAt)<cutoff){this.points.delete(id);this.routes.delete(id);}},30000);
 constructor(private readonly db:PrismaService,private readonly auth:AuthService,private readonly realtime:RealtimeGateway){this.timer.unref?.();}
 onModuleDestroy(){clearInterval(this.timer);}
 private async access(id:string,authorization?:string,write=false){
  const user=await this.auth.authenticate(authorization);
  const order=await this.db.order.findUnique({where:{id},include:{address:true,cancellation:true}});
  if(!order||order.adminDeletedAt)throw new NotFoundException('Entrega não encontrada');
  if(user.role==='COURIER'){
   const courier=await this.db.courierProfile.findUnique({where:{userId:user.id}});
   if(!courier||courier.id!==order.courierId||courier.approvalStatus!=='APPROVED'||user.status!=='ACTIVE')throw new ForbiddenException('Entrega não atribuída a este motoboy');
  }else if(write||!(user.role==='ADMIN'||(user.role==='CUSTOMER'&&user.id===order.customerId)))throw new ForbiddenException('Acompanhamento não permitido');
  return order;
 }
 async update(id:string,body:any,authorization?:string){
  const order=await this.access(id,authorization,true),mode=trackingMode(order);
  if(!mode){this.points.delete(id);this.routes.delete(id);return {active:false,orderId:id};}
  const sample=trackingPosition(body),previous=this.points.get(id),now=Date.now();
  if(previous&&previous.courierId===order.courierId){
   if(Date.parse(sample.capturedAt)<=Date.parse(previous.capturedAt)||now-Date.parse(previous.receivedAt)<2000)return {active:true,accepted:false};
  }
  if(!this.points.has(id)&&this.points.size>=10000)throw new BadRequestException('Rastreamento temporariamente indisponível');
  const point={...sample,receivedAt:new Date(now).toISOString(),sequence:++this.sequence,courierId:order.courierId!};
  this.points.set(id,point);
  const payload={orderId:id,active:true,mode,point:this.publicPoint(point)};
  this.realtime.emitToUser(order.customerId,'delivery.location.updated',payload);
  this.realtime.emitToRole('ADMIN','delivery.location.updated',payload);
  return {active:true,accepted:true};
 }
 private publicPoint(point:Point){const {courierId,...visible}=point;return visible;}
 private coordinates(lat:unknown,lng:unknown){return lat!=null&&lng!=null&&Number.isFinite(Number(lat))&&Number.isFinite(Number(lng))&&Math.abs(Number(lat))<=90&&Math.abs(Number(lng))<=180?{latitude:Number(lat),longitude:Number(lng)}:null;}
 async snapshot(id:string,authorization?:string){
  const order=await this.access(id,authorization),mode=trackingMode(order);
  if(!mode){this.points.delete(id);this.routes.delete(id);return {orderId:id,active:false,point:null,route:null};}
  const stored=this.points.get(id);
  const point=stored?.courierId===order.courierId&&Date.now()-Date.parse(stored.receivedAt)<120000?stored:null;
  const cfg=await this.db.deliveryPricingConfig.findUnique({where:{id:'default'}});
  const origin=this.coordinates(cfg?.distributorLatitude,cfg?.distributorLongitude);
  const destination=this.coordinates(order.address.latitude,order.address.longitude);
  const target=mode==='RETURN'?origin:destination;
  let route:any=null;
  if(point&&target){
   const cached=this.routes.get(id);
   if(cached?.mode===mode&&Date.now()-cached.at<30000)route=cached.value;
   else {
    // Reserve the interval before I/O so simultaneous viewers do not fan out requests.
    this.routes.set(id,{at:Date.now(),mode,value:null});
    try{
     const base=(process.env.ROUTING_BASE_URL||'http://127.0.0.1:5000').replace(/\/$/,'');
     const url=`${base}/route/v1/driving/${point.longitude},${point.latitude};${target.longitude},${target.latitude}?overview=simplified&geometries=geojson&steps=false&alternatives=false`;
     const response=await fetch(url,{signal:AbortSignal.timeout(4000)});
     const data:any=await response.json();const first=data.routes?.[0];
     if(response.ok&&data.code==='Ok'&&first?.geometry?.type==='LineString'&&Array.isArray(first.geometry.coordinates)&&first.geometry.coordinates.length<=10000){route={coordinates:first.geometry.coordinates,distanceMeters:first.distance,durationSeconds:first.duration};this.routes.set(id,{at:Date.now(),mode,value:route});}
    }catch{/* The location remains available if routing is down. */}
   }
  }
  return {orderId:id,active:true,mode,point:point?this.publicPoint(point):null,stale:!point||Date.now()-Date.parse(point.receivedAt)>20000,origin,destination,target,route};
 }
}
