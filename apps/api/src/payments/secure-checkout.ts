import { createHmac, timingSafeEqual } from 'node:crypto';
import { UnauthorizedException, ServiceUnavailableException } from '@nestjs/common';

const lifetime = 60 * 60;
export function signCheckout(orderId: string, intentId: string, expires: number) {
  const secret = process.env.STRIPE_SECRET_KEY;
  if (!secret) throw new ServiceUnavailableException('Stripe não configurado');
  return createHmac('sha256', secret).update(JSON.stringify(['porto-secure-v1', orderId, intentId, expires])).digest('hex');
}
export function verifyCheckout(orderId: string, intentId: string, expires: string, token: string, now = Date.now()) {
  const exp = Number(expires);
  if (!Number.isSafeInteger(exp) || exp < Math.floor(now / 1000) || exp > Math.floor(now / 1000) + lifetime + 5 || !/^[a-f0-9]{64}$/.test(token ?? '')) {
    throw new UnauthorizedException('Este link expirou. Volte ao aplicativo para abrir o pagamento novamente.');
  }
  const expected = Buffer.from(signCheckout(orderId, intentId, exp), 'hex');
  if (!timingSafeEqual(expected, Buffer.from(token, 'hex'))) throw new UnauthorizedException('Link de pagamento inválido');
}
export function checkoutOrigin(origin: string) {
  let url: URL;
  try { url = new URL(origin); } catch { throw new ServiceUnavailableException('Endereço do checkout inválido'); }
  const local = ['localhost', '127.0.0.1', '10.0.2.2', '[::1]'].includes(url.hostname);
  const test = process.env.STRIPE_SECRET_KEY?.startsWith('sk_test_') === true;
  if (url.username || url.password || (url.protocol !== 'https:' && !(test && local && url.protocol === 'http:'))) {
    throw new ServiceUnavailableException('Configure PAYMENTS_PUBLIC_URL com o endereço HTTPS público da API.');
  }
  return url.origin;
}
export function checkoutLink(origin: string, orderId: string, intentId: string) {
  const expires = Math.floor(Date.now() / 1000) + lifetime;
  const url = new URL('/api/payments/secure', checkoutOrigin(origin));
  url.search = new URLSearchParams({ orderId, expires: String(expires), token: signCheckout(orderId, intentId, expires) }).toString();
  return { url: url.toString(), expiresAt: new Date(expires * 1000).toISOString() };
}
export function jsonForScript(value: unknown) {
  return JSON.stringify(value).replace(/[<>&\u2028\u2029]/g, c => '\\u' + c.charCodeAt(0).toString(16).padStart(4, '0'));
}
