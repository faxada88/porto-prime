import {afterEach,describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('./stripe-payment-verifier.js',()=>({retrieveStripeIntent:vi.fn(),isVerifiedPayment:vi.fn((intent:any)=>intent.status==='succeeded')}));
import {PaymentsService} from './payments.service.js';
import {retrieveStripeIntent,isVerifiedPayment} from './stripe-payment-verifier.js';

afterEach(()=>{vi.unstubAllEnvs();vi.unstubAllGlobals();vi.clearAllMocks();});
function fixture(){
 vi.stubEnv('STRIPE_SECRET_KEY','sk_test_fixture');vi.stubEnv('STRIPE_PUBLISHABLE_KEY','pk_test_fixture');
 const order:any={id:'order_1',customerId:'user_1',stripePaymentIntentId:'pi_1',status:'PENDING',paymentStatus:'PENDING',total:25};
 const db:any={order:{findFirst:vi.fn(async()=>order),findUnique:vi.fn(async()=>order),updateMany:vi.fn(async()=>({count:0}))},
  deliveryPricingConfig:{findUnique:vi.fn(async()=>({storeOpen:true}))}};
 const rt:any={emitOrderUpdated:vi.fn()};
 const service=new PaymentsService(db,{authenticate:async()=>({id:'user_1',role:'CUSTOMER'})} as any,rt);
 vi.mocked(retrieveStripeIntent).mockResolvedValue({id:'pi_1',status:'requires_payment_method',client_secret:'test_secret'} as any);
 return{service,db,order,rt};
}
describe('Unified payment flow',()=>{
 it('opens the existing intent for the authenticated owner without creating or paying an order',async()=>{
  const f=fixture();
  const link=await f.service.secureCheckout('order_1','http://10.0.2.2:3000','Bearer test');
  expect(link).toHaveProperty('url');
  expect(f.db.order.findFirst).toHaveBeenCalledWith({where:{id:'order_1',customerId:'user_1',adminDeletedAt:null}});
  expect(f.db.order.updateMany).not.toHaveBeenCalled();
  expect(f.rt.emitOrderUpdated).not.toHaveBeenCalled();
 });
 it('removes boleto from an existing unconfirmed Stripe intent without changing its amount',async()=>{
  const f=fixture();
  vi.mocked(retrieveStripeIntent).mockResolvedValue({id:'pi_1',status:'requires_payment_method',payment_method_types:['card','pix','boleto']} as any);
  const request=vi.fn(async()=>new Response(JSON.stringify({id:'pi_1',status:'requires_payment_method',payment_method_types:['card','pix']})));
  vi.stubGlobal('fetch',request);
  const options=await f.service.nativeOptions('order_1');
  expect(options.methods).toEqual(['card','pix']);
  const [url,init]=request.mock.calls[0] as unknown as [string,RequestInit];
  expect(url).toBe('https://api.stripe.com/v1/payment_intents/pi_1');
  const params=init.body as URLSearchParams;
  expect(params.get('excluded_payment_method_types[0]')).toBe('boleto');
  expect(params.has('amount')).toBe(false);
  expect(f.db.order.updateMany).not.toHaveBeenCalled();
 });
 it('rejects a missing, canceled or closed-store order',async()=>{
  const f=fixture();
  f.db.order.findFirst.mockResolvedValueOnce(null);
  await expect(f.service.secureCheckout('missing','http://10.0.2.2:3000')).rejects.toThrow();
  f.order.status='CANCELED';
  await expect(f.service.secureCheckout('order_1','http://10.0.2.2:3000')).rejects.toThrow();
  f.order.status='PENDING';
  f.db.deliveryPricingConfig.findUnique.mockResolvedValue({storeOpen:false});
  await expect(f.service.secureCheckout('order_1','http://10.0.2.2:3000')).rejects.toThrow();
 });
 it.each(['requires_action','processing','requires_payment_method'])('never releases unpaid %s intents',async(status)=>{
  const f=fixture();
  const result=await (f.service as any).completePayment({id:'pi_1',status});
  expect(result).toBe(false);expect(f.db.order.updateMany).not.toHaveBeenCalled();
 });
 it.each([['pix','PIX'],['boleto','BOLETO'],['card','CARD']])('records actual %s payment as %s',async(type,method)=>{
  const f=fixture();
  await (f.service as any).completePayment({id:'pi_1',status:'succeeded',payment_method:{type}});
  expect(isVerifiedPayment).toHaveBeenCalled();
  expect(f.db.order.updateMany).toHaveBeenCalledWith(expect.objectContaining({data:expect.objectContaining({paymentMethod:method,paymentStatus:'PAID'})}));
 });
});
