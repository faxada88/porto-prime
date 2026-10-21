import {afterEach,describe,it,expect,vi} from 'vitest';
import {checkoutLink,verifyCheckout,jsonForScript,checkoutOrigin} from './secure-checkout.js';
import {secureCheckoutPage} from './secure-checkout-page.js';

afterEach(()=>vi.unstubAllEnvs());
describe('Signed checkout capability',()=>{
 it('binds a one-hour link to the order and existing intent without leaking Stripe keys',()=>{
  vi.stubEnv('STRIPE_SECRET_KEY','sk_test_fixture');
  const link=checkoutLink('http://10.0.2.2:3000','order_1','pi_1');
  const url=new URL(link.url);
  expect(()=>verifyCheckout('order_1','pi_1',url.searchParams.get('expires')!,url.searchParams.get('token')!)).not.toThrow();
  expect(link.url).not.toContain('sk_test');
  expect(link.url).not.toContain('client_secret');
  expect(()=>verifyCheckout('order_2','pi_1',url.searchParams.get('expires')!,url.searchParams.get('token')!)).toThrow();
  expect(()=>verifyCheckout('order_1','pi_replaced',url.searchParams.get('expires')!,url.searchParams.get('token')!)).toThrow();
  expect(()=>verifyCheckout('order_1','pi_1',url.searchParams.get('expires')!,url.searchParams.get('token')!,Date.now()+3601_000)).toThrow();
 });
 it('rejects missing and malformed capabilities',()=>{
  vi.stubEnv('STRIPE_SECRET_KEY','sk_test_fixture');
  for(const token of ['', 'z'.repeat(64),'1']){
   expect(()=>verifyCheckout('o','pi','1',token)).toThrow();
  }
 });
 it('permits local HTTP only in test mode and never accepts credential URLs',()=>{
  vi.stubEnv('STRIPE_SECRET_KEY','sk_test_fixture');
  expect(checkoutOrigin('http://10.0.2.2:3000')).toBe('http://10.0.2.2:3000');
  expect(()=>checkoutOrigin('http://example.com')).toThrow();
  expect(()=>checkoutOrigin('https://name:password@example.com')).toThrow();
  vi.stubEnv('STRIPE_SECRET_KEY','sk_live_fixture');
  expect(()=>checkoutOrigin('http://localhost:3000')).toThrow();
  expect(checkoutOrigin('https://api.example.com')).toBe('https://api.example.com');
 });
 it('escapes embedded data without altering its value',()=>{
  const value={name:'</script><script>alert(1)</script>&\u2028',email:'x@example.test'};
  const encoded=jsonForScript(value);
  expect(encoded).not.toContain('<');
  expect(JSON.parse(encoded)).toEqual(value);
 });
 it('uses dynamic Stripe Elements with Pix priority and no custom card fields',()=>{
  const html=secureCheckoutPage({publishableKey:'pk_test_fixture',clientSecret:'pi_secret',amount:20,testMode:true,name:'Cliente',email:'a@b.test',nonce:'test-nonce'});
  expect(html).toContain("paymentMethodOrder:['pix','card','link','boleto']");
  expect(html).toContain("elements.create('expressCheckout')");
  expect(html).toContain("stripe.confirmPayment");
  expect(html).toContain("pix_display_qr_code");
  expect(html).toContain("boleto_display_details");
  expect(html).toContain('nonce="test-nonce"');
  expect(html).not.toContain('sk_test_fixture');
  expect(html).not.toContain('type="password"');
 });
});
