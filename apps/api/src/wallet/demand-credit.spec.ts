import {describe,expect,it,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
import {WalletService} from './wallet.service.js';
function fixture(commission=0){let entry:any=null;const tx:any={deliveryPricingConfig:{upsert:vi.fn(async()=>({platformCommissionPercent:commission}))},courierLedgerEntry:{findUnique:vi.fn(async()=>entry),upsert:vi.fn(async({create}:any)=>{entry=create;return entry})},dispatchEvent:{findFirst:vi.fn(async()=>null),create:vi.fn(async()=>({}))}};return{tx,service:new WalletService({}as any,{}as any,{}as any)}}
describe('Crédito da entrega com bônus garantido',()=>{
 it('credita a taxa e o bônus integral uma única vez',async()=>{const f=fixture();const order={id:'order',courierId:'courier',deliveryFee:5.5,courierDemandBonus:2.5};const entry=await f.service.creditDeliveryTx(f.tx,order);expect(entry.amount).toBe(8);expect(entry.metadata.demandBonus).toBe(2.5);expect(order.deliveryFee).toBe(5.5);await f.service.creditDeliveryTx(f.tx,order);expect(f.tx.courierLedgerEntry.upsert).toHaveBeenCalledTimes(1);expect(f.tx.dispatchEvent.create).toHaveBeenCalledTimes(1)});
 it('preserva comissão anterior sobre entrega e não desconta comissão do bônus',async()=>{const f=fixture(10);expect((await f.service.creditDeliveryTx(f.tx,{id:'order',courierId:'courier',deliveryFee:10,courierDemandBonus:3})).amount).toBe(12)});
 it('pedidos sem bônus mantêm o crédito anterior',async()=>{const f=fixture();expect((await f.service.creditDeliveryTx(f.tx,{id:'old',courierId:'courier',deliveryFee:5.5})).amount).toBe(5.5)});
 it('não cria crédito sem motoboy',async()=>{const f=fixture();await expect(f.service.creditDeliveryTx(f.tx,{id:'x',courierId:null,deliveryFee:5.5,courierDemandBonus:2})).rejects.toThrow('motoboy');expect(f.tx.courierLedgerEntry.upsert).not.toHaveBeenCalled()});
});

describe('Repasse do adicional já cobrado ao cliente',()=>{
 it('repasse é exatamente o total de entrega de R$ 8,00, não R$ 10,50',async()=>{const f=fixture();const order={id:'new',courierId:'c',deliveryFee:8,courierDemandBonus:2.5,demandSurchargeIncluded:true};const credit=await f.service.creditDeliveryTx(f.tx,order);expect(credit.amount).toBe(8);expect(credit.metadata.baseCourierCredit).toBe(5.5);expect(credit.metadata.demandBonus).toBe(2.5);await f.service.creditDeliveryTx(f.tx,order);expect(f.tx.courierLedgerEntry.upsert).toHaveBeenCalledTimes(1)});
 it('eventual comissão anterior incide somente na taxa base: adicional sempre integral',async()=>{const f=fixture(10);expect((await f.service.creditDeliveryTx(f.tx,{id:'new',courierId:'c',deliveryFee:13,courierDemandBonus:3,demandSurchargeIncluded:true})).amount).toBe(12)});
});
