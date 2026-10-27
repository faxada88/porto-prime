import { describe, it } from 'vitest';
import assert from 'node:assert/strict';
import { DispatchService } from './dispatch.service.js';

function gateway(){return {emitOrderUpdated:()=>{},emitToUser:()=>{},emitToRole:()=>{}};}
const config={offerTimeoutSeconds:30,heartbeatTimeoutSeconds:60,distributorName:'Base',distributorAddress:'Centro',distributorLatitude:null,distributorLongitude:null};

describe('Dispatch reliability',()=>{
 it('returns the already accepted order on an HTTP retry',async()=>{
  let mutations=0;
  const accepted={id:'order',courierId:'courier',status:'COURIER_ASSIGNED',adminDeletedAt:null};
  const tx={order:{findUnique:async()=>accepted},deliveryOffer:{findFirst:async()=>{mutations++;throw Error('must not create another acceptance');}}};
  const service=new DispatchService({$transaction:async(fn:any)=>fn(tx)} as any,gateway() as any);
  assert.equal(await service.acceptOffer('courier','user','order'),accepted);
  assert.equal(mutations,0);
 });
 it('commits expiry cleanup before rejecting an acceptance and redispatches',async()=>{
  let released=false,available=false,committed=false,retried=false;
  const tx={
   $queryRawUnsafe:async()=>[],
   order:{findUnique:async()=>({id:'order',courierId:null,status:'SEARCHING_COURIER'}),updateMany:async()=>{released=true;return {count:1};}},
   deliveryOffer:{findFirst:async()=>({id:'expired',expiresAt:new Date(0)}),updateMany:async()=>({count:1})},
   courierProfile:{findFirst:async()=>({id:'courier'}),updateMany:async()=>{available=true;return {count:1};}},dispatchEvent:{create:async()=>({})},
  };
  const service=new DispatchService({$transaction:async(fn:any)=>{const result=await fn(tx);committed=true;return result;}} as any,gateway() as any);
  (service as any).scheduleRedispatch=()=>{retried=true;};
  await assert.rejects(()=>service.acceptOffer('courier','user','order'),/tempo desta oferta/);
  assert.ok(committed&&released&&available&&retried);
 });
 it('keeps rotating after every courier declined or timed out',async()=>{
  let next='';
  const candidates=['a','b'].map(id=>({id,user:{id:'user-'+id},deliveryOffers:[],availableSince:new Date(),currentLatitude:null,currentLongitude:null}));
  const history=[{courierId:'a',_max:{offeredAt:new Date(1000)}},{courierId:'b',_max:{offeredAt:new Date(2000)}}];
  const db:any={deliveryPricingConfig:{upsert:async()=>config},order:{findUnique:async()=>({id:'order',status:'SEARCHING_COURIER',courierId:null,activeOfferId:null,deliveryFee:10})},courierProfile:{findMany:async()=>candidates},deliveryOffer:{groupBy:async()=>history}};
  db.$transaction=async(fn:any)=>fn({courierProfile:{updateMany:async()=>({count:1})},order:{updateMany:async()=>({count:1})},deliveryOffer:{create:async({data}:any)=>{next=data.courierId;return {...data,order:{deliveryFee:10,items:[]},courier:{user:{id:next}}};}},dispatchEvent:{create:async()=>({})}});
  const service=new DispatchService(db,gateway() as any);
  await service.dispatchOrder('order');assert.equal(next,'a');
  history[0]._max.offeredAt=new Date(3000);
  await service.dispatchOrder('order');assert.equal(next,'b');
  history[1]._max.offeredAt=new Date(4000);
  await service.dispatchOrder('order');assert.equal(next,'a');
 });
 it('one broken order does not block the other searching orders',async()=>{
  const attempted:string[]=[];
  const service=new DispatchService({order:{findMany:async()=>[{id:'broken'},{id:'ok'}]}} as any,gateway() as any);
  (service as any).expireOffers=async()=>{};
  (service as any).markStaleCouriersOffline=async()=>{};
  (service as any).dispatchOrder=async(id:string)=>{attempted.push(id);if(id==='broken')throw Error('temporary failure');};
  await (service as any).tick();assert.deepEqual(attempted,['broken','ok']);
 });
});

