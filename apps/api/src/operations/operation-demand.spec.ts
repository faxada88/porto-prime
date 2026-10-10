import {describe,expect,it,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
import {DispatchService} from '../dispatch/dispatch.service.js';
import {OperationDemandService} from './operation-demand.service.js';
import {demandEnabled,offeredDemandBonus,waitingOrders} from './demand-policy.js';
function fixture(role='ADMIN',waiting=0){
 let row:any={id:'default',enabled:false,mode:'AUTO',bonusAmount:2.5,waitingCount:0,revision:0,updatedBy:'private',updatedAt:null};
 const tx:any={$queryRawUnsafe:vi.fn(async()=>[]),order:{count:vi.fn(async()=>waiting)},courierDemandSignal:{findUnique:vi.fn(async()=>row),upsert:vi.fn(async()=>row),update:vi.fn(async({data}:any)=>{row={...row,...data,revision:row.revision+1};return row;})}};
 const db:any={...tx,$transaction:vi.fn(async(fn:any)=>fn(tx))};
 const realtime:any={emitToRole:vi.fn(),emitDemandUpdated:vi.fn()};
 return {db,tx,realtime,service:new OperationDemandService(db,{authenticate:async()=>({id:'admin',role})}as any,realtime)};
}
describe('Alta demanda com bônus',()=>{
 it('ativa exatamente com 10 pedidos pagos aguardando motoboy',async()=>{const f=fixture('ADMIN',10);expect(await f.service.read(undefined,'ADMIN')).toMatchObject({enabled:true,reason:'AUTOMATIC',bonusAmount:2.5,waitingCount:10});expect(f.tx.order.count).toHaveBeenCalledWith({where:waitingOrders});expect(waitingOrders.paymentStatus).toBe('PAID');expect(waitingOrders.courierId).toBeNull()});
 it('desativa ao cair para 9 e publica remoção',async()=>{const f=fixture('ADMIN',10);await f.service.read(undefined,'ADMIN');f.tx.order.count.mockResolvedValue(9);expect(await f.service.read(undefined,'ADMIN')).toMatchObject({enabled:false,reason:null});expect(f.realtime.emitDemandUpdated).toHaveBeenLastCalledWith(expect.objectContaining({enabled:false}))});
 it('ON manual continua ativo abaixo do limite e OFF impede ativação automática',async()=>{const f=fixture();expect(await f.service.set({mode:'MANUAL_ON',bonusAmount:'3.00'})).toMatchObject({enabled:true,reason:'MANUAL',bonusAmount:3});f.tx.order.count.mockResolvedValue(20);expect(await f.service.set({mode:'MANUAL_OFF'})).toMatchObject({enabled:false});expect(await f.service.read(undefined,'ADMIN')).toMatchObject({enabled:false});expect(await f.service.set({mode:'AUTO'})).toMatchObject({enabled:true,reason:'AUTOMATIC'})});
 it('cliente e visitante recebem somente estado público, sem bônus ou identidade',async()=>{const f=fixture('ADMIN',10);await f.service.read(undefined,'ADMIN');expect(Object.keys(await f.service.publicRead()).sort()).toEqual(['enabled','revision','updatedAt']);expect(f.realtime.emitDemandUpdated.mock.calls[0][0]).not.toHaveProperty('bonusAmount');expect(await f.service.read(undefined,'ADMIN')).not.toHaveProperty('updatedBy')});
 it('não incrementa revisão nem notifica quando nada mudou',async()=>{const f=fixture();await f.service.read(undefined,'ADMIN');expect(f.tx.courierDemandSignal.update).not.toHaveBeenCalled();expect(f.realtime.emitToRole).not.toHaveBeenCalled()});
 it.each(['COURIER','CUSTOMER','PARTNER'])('%s não pode editar bônus',async role=>{const f=fixture(role);await expect(f.service.set({mode:'MANUAL_ON'})).rejects.toThrow('administrador');expect(f.db.$transaction).not.toHaveBeenCalled()});
 it.each([-1,0,101,'2.555','Infinity','NaN',null,true])('recusa bônus inválido %s',async bonusAmount=>{const f=fixture();await expect(f.service.set({bonusAmount})).rejects.toThrow('bônus');expect(f.db.$transaction).not.toHaveBeenCalled()});
 it('motoboy pode ler mas não acessar Admin',async()=>{const f=fixture('COURIER');expect(await f.service.read(undefined,'COURIER')).toMatchObject({bonusAmount:2.5});await expect(f.service.read(undefined,'ADMIN')).rejects.toThrow('administrador')});
 it('não publica sucesso se a gravação falhar',async()=>{const f=fixture();f.db.$transaction.mockRejectedValue(new Error('DB'));await expect(f.service.set({mode:'MANUAL_ON'})).rejects.toThrow('DB');expect(f.realtime.emitToRole).not.toHaveBeenCalled()});
 it('consulta pública não realiza contagens ou gravações',async()=>{const f=fixture();await f.service.publicRead();expect(f.db.$transaction).not.toHaveBeenCalled()});
 it('fotografa o bônus da oferta sem alterar taxa ou total do cliente',async()=>{const f=fixture('ADMIN',10);expect(await offeredDemandBonus(f.tx)).toBe(2.5);await f.service.set({mode:'MANUAL_OFF'});expect(await offeredDemandBonus(f.tx)).toBe(0);expect(demandEnabled('AUTO',9)).toBe(false)});
});

describe('Bônus prometido na oferta',()=>{
 it('mantém bônus original no aceite mesmo após desligar ou alterar a configuração',async()=>{
  const offer={id:'offer',demandBonus:3,expiresAt:new Date(Date.now()+60000)};
  const tx:any={deliveryOffer:{findFirst:vi.fn(async()=>offer),updateMany:vi.fn(async()=>({count:1})),findMany:vi.fn(async()=>[])},order:{updateMany:vi.fn(async()=>({count:1})),findUnique:vi.fn(async()=>({id:'order'}))},courierProfile:{update:vi.fn(async()=>({}))},dispatchEvent:{create:vi.fn(async()=>({}))},courierDemandSignal:{findUnique:vi.fn(async()=>({mode:'MANUAL_OFF',bonusAmount:5}))}};
  const db:any={$transaction:async(fn:any)=>fn(tx)};
  const realtime:any={emitOrderUpdated:vi.fn(),emitToUser:vi.fn()};
  await new DispatchService(db,realtime).acceptOffer('courier','user','order');
  expect(tx.order.updateMany.mock.calls[0][0].data.courierDemandBonus).toBe(3);
  expect(tx.courierDemandSignal.findUnique).not.toHaveBeenCalled();
 });
});
