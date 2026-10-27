import {afterEach,describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../generated/prisma/client.js',()=>({UserRole:{CUSTOMER:'CUSTOMER'},PaymentStatus:{PAID:'PAID',PENDING:'PENDING',FAILED:'FAILED'},PaymentMethod:{CARD:'CARD'},OrderStatus:{CANCELED:"CANCELED",PENDING:"PENDING"}}));
vi.mock('./stripe-payment-verifier.js',()=>({retrieveStripeIntent:vi.fn(),isVerifiedPayment:vi.fn()}));
import {PaymentsService} from './payments.service.js';
import {retrieveStripeIntent} from './stripe-payment-verifier.js';
afterEach(()=>{vi.unstubAllEnvs();vi.unstubAllGlobals();vi.clearAllMocks()});
function fixture(open:boolean,existing=false){
 vi.stubEnv('STRIPE_SECRET_KEY','test');vi.stubEnv('STRIPE_PUBLISHABLE_KEY','test');
 const fetcher=vi.fn(async(_url:string,_init:RequestInit)=>({ok:true,json:async()=>({id:'pi_test',client_secret:'test'})}));vi.stubGlobal('fetch',fetcher);
 const prisma:any={order:{findFirst:vi.fn(async()=>({id:'o',customerId:'u',total:20,subtotal:14.5,deliveryFee:5.5,storeCreditUsed:0,routeDistanceKm:2,routeDurationMinutes:8,address:{label:'Casa',street:'Rua A',number:'10',city:'Porto Seguro'},items:[{productName:'Produto',quantity:1,unitPrice:14.5,total:14.5}],paymentStatus:'PENDING',stripePaymentIntentId:existing?'pi_old':null})),update:vi.fn()},deliveryPricingConfig:{findUnique:vi.fn(async()=>({storeOpen:open,storeMessage:'Loja fechada. Voltamos em breve.'}))}};
 return{prisma,fetcher,service:new PaymentsService(prisma,{authenticate:async()=>({id:'u',role:'CUSTOMER',email:'u@example.test'})} as any,{} as any)};
}
const request={orderId:'o',successUrl:'https://example.test/s',cancelUrl:'https://example.test/c'};
describe('Store closure and checkout',()=>{
 it('blocks starting payment for pending orders when closed',async()=>{const f=fixture(false);await expect(f.service.createCheckout(request)).rejects.toThrow('Loja fechada');expect(f.fetcher).not.toHaveBeenCalled();expect(f.prisma.order.update).not.toHaveBeenCalled()});
 it('blocks reopening an unpaid intent through a new checkout request when closed',async()=>{const f=fixture(false,true);await expect(f.service.createCheckout(request)).rejects.toThrow('Loja fechada');expect(retrieveStripeIntent).not.toHaveBeenCalled();expect(f.fetcher).not.toHaveBeenCalled()});
 it('open store retains the payment amount and order identity',async()=>{const f=fixture(true);expect(await f.service.createCheckout(request)).toMatchObject({orderId:'o',paymentIntentId:'pi_test'});const body=f.fetcher.mock.calls[0][1].body as URLSearchParams;expect(body.get('amount')).toBe('2000');expect(body.get('excluded_payment_method_types[0]')).toBe('boleto');expect(body.get('metadata[orderId]')).toBe('o');expect(f.prisma.order.update).toHaveBeenCalledWith({where:{id:'o',status:'PENDING',paymentStatus:{in:['PENDING','FAILED']},AND:[{stripePaymentIntentId:null}]},data:{paymentMethod:'CARD',stripePaymentIntentId:'pi_test'}})});
 it('database errors fail closed instead of silently starting payment',async()=>{const f=fixture(true);f.prisma.deliveryPricingConfig.findUnique.mockRejectedValue(new Error('database down'));await expect(f.service.createCheckout(request)).rejects.toThrow('database down');expect(f.fetcher).not.toHaveBeenCalled()});
});

describe('Stripe usa total com adicional já incluído',()=>{
 it('cobra subtotal mais entrega final exatamente uma vez',async()=>{const f=fixture(true);f.prisma.order.findFirst.mockResolvedValue({id:'o',customerId:'u',total:28,subtotal:20,storeCreditUsed:0,items:[],deliveryFee:8,courierDemandBonus:2.5,demandSurchargeIncluded:true,paymentStatus:'PENDING',stripePaymentIntentId:null});await f.service.createCheckout(request);const body=f.fetcher.mock.calls[0][1].body as URLSearchParams;expect(body.get('amount')).toBe('2800')});
});

describe('Authenticated checkout review',()=>{
 it('returns the frozen totals and delivery address without secrets or delivery PIN',async()=>{const f=fixture(true);const result=await f.service.createCheckout(request);expect(result.summary).toMatchObject({subtotal:14.5,deliveryFee:5.5,storeCreditUsed:0,total:20,distanceKm:2,durationMinutes:8,address:{street:'Rua A'},items:[{productName:'Produto',quantity:1,total:14.5}]});expect(result.summary).not.toHaveProperty('deliveryPin');expect(result.summary).not.toHaveProperty('customerId');expect(f.prisma.order.findFirst).toHaveBeenCalledWith(expect.objectContaining({where:{id:'o',customerId:'u',adminDeletedAt:null}}));});
 it('reuses the same payment intent and summary when returning to payment',async()=>{const f=fixture(true,true);vi.mocked(retrieveStripeIntent).mockResolvedValue({id:'pi_old',status:'requires_payment_method',client_secret:'existing_secret'} as any);const result=await f.service.createCheckout(request);expect(result.paymentIntentId).toBe('pi_old');expect(result.summary.total).toBe(20);expect(f.fetcher).not.toHaveBeenCalled();});
});

