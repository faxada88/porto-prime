import {describe,it,expect,vi,afterEach} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
import {PaymentsService} from './payments.service.js';
function fixture(){
 const order:any={id:'o',customerId:'u',adminDeletedAt:null,status:'PENDING',paymentStatus:'PENDING',total:0,subtotal:45,deliveryFee:16,storeCreditUsed:61,stripePaymentIntentId:null,address:{},items:[]};
 const debit:any={customerId:'u',amount:-61};
 const db:any={$queryRaw:vi.fn().mockResolvedValue([]),order:{findFirst:vi.fn(async()=>order),update:vi.fn(async({data}:any)=>Object.assign(order,data))},customerCreditEntry:{findUnique:vi.fn(async()=>debit)},deliveryPricingConfig:{findUnique:vi.fn().mockResolvedValue({storeOpen:true})}};db.$transaction=async(fn:any)=>fn(db);
 const rt:any={emitOrderUpdated:vi.fn(),emitToUser:vi.fn()};const auth:any={authenticate:vi.fn().mockResolvedValue({id:'u',role:'CUSTOMER'})};
 return {order,debit,db,rt,auth,service:new PaymentsService(db,auth,rt)};
}
afterEach(()=>vi.unstubAllGlobals());
describe('Confirmação de compra com saldo',()=>{
 it('não confirma pagamento nem notifica Admin ao preparar checkout sem Stripe',async()=>{const f=fixture();const fetch=vi.fn();vi.stubGlobal('fetch',fetch);expect(await f.service.createCheckout({orderId:'o',successUrl:'https://example.test',cancelUrl:'https://example.test'})).toMatchObject({creditOnly:true,summary:{total:0}});expect(f.order.paymentStatus).toBe('PENDING');expect(f.rt.emitOrderUpdated).not.toHaveBeenCalled();expect(fetch).not.toHaveBeenCalled();});
 it('confirma somente após ação do cliente e reutiliza confirmação sem débito ou evento duplicado',async()=>{const f=fixture();expect(await f.service.confirmCredit('o','token')).toMatchObject({paid:true});expect(f.order).toMatchObject({paymentStatus:'PAID',status:'CONFIRMED',deliveryFee:16});await f.service.confirmCredit('o','token');expect(f.db.order.update).toHaveBeenCalledTimes(1);expect(f.rt.emitOrderUpdated).toHaveBeenCalledTimes(1);expect(f.db.customerCreditEntry).not.toHaveProperty('create');});
 it('recusa diferença ainda a pagar, ausência de reserva ou conta diferente',async()=>{for(const kind of ['remaining','debit','owner']){const f=fixture();if(kind==='remaining')f.order.total=11;if(kind==='debit')f.db.customerCreditEntry.findUnique.mockResolvedValue(null);if(kind==='owner')f.db.order.findFirst.mockResolvedValue(null);await expect(f.service.confirmCredit('o','token')).rejects.toThrow();expect(f.rt.emitOrderUpdated).not.toHaveBeenCalled();expect(f.db.order.update).not.toHaveBeenCalled();}});
 it('bloqueia parceiros e verifica propriedade, exclusão e valores sob lock',async()=>{const f=fixture();await f.service.confirmCredit('o','token');expect(f.db.order.findFirst).toHaveBeenCalledWith({where:{id:'o',customerId:'u',adminDeletedAt:null}});expect(f.db.$queryRaw).toHaveBeenCalled();const other=fixture();other.auth.authenticate.mockResolvedValue({id:'u',role:'PARTNER'});await expect(other.service.confirmCredit('o','token')).rejects.toThrow();});
});
