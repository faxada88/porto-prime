import {afterEach,describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('./stripe-payment-verifier.js',()=>({retrieveStripeIntent:vi.fn(),isVerifiedPayment:vi.fn((intent:any)=>intent.status==='succeeded')}));
import {PaymentsService} from './payments.service.js';
import {retrieveStripeIntent} from './stripe-payment-verifier.js';

afterEach(()=>{vi.unstubAllEnvs();vi.unstubAllGlobals();vi.clearAllMocks();});
function fixture(){
 vi.stubEnv('STRIPE_SECRET_KEY','sk_test_fixture');
 const order={id:'o',customerId:'u',stripePaymentIntentId:'pi',status:'PENDING',paymentStatus:'PENDING',total:20};
 const db:any={order:{findFirst:vi.fn(async()=>order),updateMany:vi.fn()},customerProfile:{findUnique:vi.fn(async()=>({onboardingData:{}}))},deliveryPricingConfig:{findUnique:vi.fn(async()=>({storeOpen:true}))}};
 const intent:any={id:'pi',status:'requires_payment_method',payment_method_types:['card','pix','boleto']};
 vi.mocked(retrieveStripeIntent).mockImplementation(async()=>intent);
 const result={...intent,status:'requires_action',next_action:{pix_display_qr_code:{data:'PIX-TEST',image_url_png:'https://qr.stripe.com/test.png',expires_at:Math.floor(Date.now()/1000)+3600}}};
 const fetcher=vi.fn(async()=>new Response(JSON.stringify(result)));
 vi.stubGlobal('fetch',fetcher);
 const service=new PaymentsService(db,{authenticate:async()=>({id:'u',role:'CUSTOMER',name:'Cliente',email:'a@b.test'})} as any,{} as any);
 return{db,intent,fetcher,service,result};
}
describe('Native Pix without browser navigation',()=>{
 it('confirms the saved intent without client supplied amounts or a new charge',async()=>{
  const f=fixture();const result=await f.service.nativePix('o');
  expect(result).toMatchObject({paid:false,status:'requires_action',pix:{data:'PIX-TEST'}});
  const [url,init]=f.fetcher.mock.calls[0] as unknown as [string,RequestInit];
  expect(url).toBe('https://api.stripe.com/v1/payment_intents/pi/confirm');
  const params=init.body as URLSearchParams;
  expect(params.get('payment_method_data[type]')).toBe('pix');
  expect(params.has('amount')).toBe(false);
  expect((init.headers as Record<string,string>)['Idempotency-Key']).toBe('porto-pix:o:pi:initial');
  expect(f.db.order.updateMany).not.toHaveBeenCalled();
 });
 it('recovers an active QR without submitting again',async()=>{
  const f=fixture();Object.assign(f.intent,f.result);
  expect(await f.service.nativePix('o')).toMatchObject({pix:{data:'PIX-TEST'}});
  expect(f.fetcher).not.toHaveBeenCalled();
 });
 it('returns processing without confirming a second time',async()=>{
  const f=fixture();f.intent.status='processing';
  expect(await f.service.nativePix('o')).toEqual({paid:false,status:'processing'});
  expect(f.fetcher).not.toHaveBeenCalled();
 });
 it('rejects other users and unavailable Pix',async()=>{
  const f=fixture();f.db.order.findFirst.mockResolvedValueOnce(null);
  await expect(f.service.nativePix('o')).rejects.toThrow();
  f.intent.payment_method_types=['card'];
  await expect(f.service.nativePix('o')).rejects.toThrow('Pix não está disponível');
  expect(f.fetcher).not.toHaveBeenCalled();
 });
 it('hides an untrusted QR image URL while preserving copy/paste',async()=>{
  const f=fixture();f.result.next_action.pix_display_qr_code.image_url_png='https://example.test/unsafe.png';
  const result=await f.service.nativePix('o');
  expect(result).toMatchObject({pix:{data:'PIX-TEST',imageUrl:null}});
 });
});
