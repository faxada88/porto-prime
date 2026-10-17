import {afterEach,describe,expect,it,vi} from 'vitest';
import {DeliveryTrackingService,trackingMode,trackingPosition} from './delivery-tracking.service.js';
const running:DeliveryTrackingService[]=[];
afterEach(()=>{for(const s of running.splice(0))s.onModuleDestroy();vi.unstubAllGlobals();});
function setup(role='COURIER',userId='driver-user'){
 const order:any={id:'order1',customerId:'customer1',courierId:'courier1',status:'OUT_FOR_DELIVERY',adminDeletedAt:null,cancellation:null,address:{latitude:-16.45,longitude:-39.07}};
 const events:any[]=[];
 const db:any={order:{findUnique:async()=>order},courierProfile:{findUnique:async()=>({id:'courier1',approvalStatus:'APPROVED'})},deliveryPricingConfig:{findUnique:async()=>({distributorLatitude:-16.44,distributorLongitude:-39.08})}};
 const user={id:userId,role,status:'ACTIVE'};
 const service=new DeliveryTrackingService(db,{authenticate:async()=>user} as any,{emitToUser:(...e:any[])=>events.push(['USER',...e]),emitToRole:(...e:any[])=>events.push(['ROLE',...e])} as any);
 running.push(service);return {service,order,events,user};
}
const sample=()=>({latitude:-16.445,longitude:-39.075,accuracy:8,heading:45,capturedAt:new Date().toISOString()});
describe('Delivery tracking boundaries',()=>{
 it('activates only on route, not on acceptance or collection',()=>{
  for(const status of ['PENDING','CONFIRMED','COURIER_ASSIGNED','PICKED_UP','DELIVERED'])expect(trackingMode({status})).toBeNull();
  expect(trackingMode({status:'OUT_FOR_DELIVERY'})).toBe('DELIVERY');
 });
 it('tracks an outstanding return and stops once returned',()=>{
  expect(trackingMode({status:'CANCELED',cancellation:{returnStatus:'IN_TRANSIT'}})).toBe('RETURN');
  expect(trackingMode({status:'CANCELED',cancellation:{returnStatus:'COMPLETED'}})).toBeNull();
  expect(trackingMode({status:'OUT_FOR_DELIVERY',adminDeletedAt:new Date()})).toBeNull();
 });
 it('rejects invalid, old and inaccurate samples',()=>{
  for(const body of [null,{...sample(),latitude:'-16'},{...sample(),longitude:181},{...sample(),accuracy:101},{...sample(),capturedAt:'2000-01-01'},{...sample(),latitude:NaN}])expect(()=>trackingPosition(body)).toThrow();
  expect(trackingPosition(sample()).heading).toBe(45);
 });
 it('notifies only the customer and Admin, without changing order state',async()=>{
  const {service,events,order}=setup();await service.update('order1',sample());
  expect(events.map(e=>e.slice(0,3))).toEqual([['USER','customer1','delivery.location.updated'],['ROLE','ADMIN','delivery.location.updated']]);
  expect(events[0][3].point.courierId).toBeUndefined();expect(order.status).toBe('OUT_FOR_DELIVERY');
 });
 it('does not collect positions before route confirmation',async()=>{
  const {service,order,events}=setup();order.status='PICKED_UP';expect((await service.update('order1',sample())).active).toBe(false);expect(events).toEqual([]);
 });
 it('denies another courier',async()=>{
  const {service,order}=setup();order.courierId='other';await expect(service.update('order1',sample())).rejects.toThrow();
 });
 it('denies customer and partner writes',async()=>{
  for(const role of ['CUSTOMER','PARTNER']){const {service}=setup(role,'customer1');await expect(service.update('order1',sample())).rejects.toThrow();}
 });
 it('denies another customer and any partner read',async()=>{
  for(const role of ['CUSTOMER','PARTNER']){const {service}=setup(role,'outsider');await expect(service.snapshot('order1')).rejects.toThrow();}
 });
 it('rejects removed orders',async()=>{
  const {service,order}=setup();order.adminDeletedAt=new Date();await expect(service.snapshot('order1')).rejects.toThrow();
 });
 it('ignores repeated samples without emitting twice',async()=>{
  const {service,events}=setup();const body=sample();await service.update('order1',body);expect((await service.update('order1',body)).accepted).toBe(false);expect(events.length).toBe(2);
 });
 it('keeps live position when OSRM is unavailable and clears on completion',async()=>{
  vi.stubGlobal('fetch',async()=>{throw Error('routing unavailable')});
  const {service,order}=setup();await service.update('order1',sample());const active=await service.snapshot('order1');expect(active.point?.latitude).toBe(-16.445);expect(active.route).toBeNull();
  order.status='DELIVERED';const done=await service.snapshot('order1');expect(done.active).toBe(false);expect(done.point).toBeNull();
 });
 it('discards a previous courier position after reassignment',async()=>{
  const {service,order,user}=setup();await service.update('order1',sample());
  user.role='ADMIN';order.courierId='replacement';
  expect((await service.snapshot('order1')).point).toBeNull();
 });
});
