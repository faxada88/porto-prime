import { afterEach, describe, expect, it, vi } from 'vitest';
import {
  isVerifiedPayment,
  retrieveStripeIntent,
} from './stripe-payment-verifier.js';

const order = {
  id: 'order-test',
  customerId: 'customer-test',
  stripePaymentIntentId: 'pi_test',
  total: '19.90',
};
const intent = {
  id: 'pi_test',
  status: 'succeeded',
  currency: 'brl',
  amount: 1990,
  amount_received: 1990,
  metadata: { orderId: order.id, customerId: order.customerId },
};

afterEach(() => {
  vi.unstubAllGlobals();
  vi.unstubAllEnvs();
});
describe('server-verified Stripe payment', () => {
  it('accepts only the correct, fully received payment', () => {
    expect(isVerifiedPayment(intent, order)).toBe(true);
  });
  it.each([
    'processing',
    'requires_payment_method',
    'requires_action',
    'canceled',
    'requires_capture',
  ])('does not confirm %s', (status) => {
    expect(isVerifiedPayment({ ...intent, status }, order)).toBe(false);
  });
  it.each([
    { id: 'pi_different' },
    { currency: 'usd' },
    { amount: 1900 },
    { metadata: { orderId: 'another-order', customerId: order.customerId } },
    { metadata: { orderId: order.id, customerId: 'another-customer' } },
    { metadata: undefined },
  ])('rejects a mismatched payment', (changes) => {
    expect(() => isVerifiedPayment({ ...intent, ...changes }, order)).toThrow(
      'não corresponde',
    );
  });
  it('does not confirm partial receipt even with succeeded', () => {
    expect(isVerifiedPayment({ ...intent, amount_received: 100 }, order)).toBe(
      false,
    );
  });
  it('rejects invalid order amounts', () => {
    expect(() =>
      isVerifiedPayment(intent, { ...order, total: 'not-a-price' }),
    ).toThrow();
  });
  it('retrieves the saved intent with the server key', async () => {
    vi.stubEnv('STRIPE_SECRET_KEY', 'test-secret');
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(new Response(JSON.stringify(intent))),
    );
    expect(await retrieveStripeIntent('pi_test')).toEqual(intent);
    expect(fetch).toHaveBeenCalledWith(
      'https://api.stripe.com/v1/payment_intents/pi_test',
      expect.objectContaining({
        headers: { Authorization: 'Bearer test-secret' },
        redirect: 'error',
      }),
    );
  });
  it('handles provider errors without exposing the key', async () => {
    vi.stubEnv('STRIPE_SECRET_KEY', 'test-secret');
    vi.stubGlobal(
      'fetch',
      vi
        .fn()
        .mockResolvedValue(
          new Response('secret upstream error', { status: 403 }),
        ),
    );
    await expect(retrieveStripeIntent('pi_test')).rejects.toThrow(
      'Não foi possível verificar',
    );
  });
  it('requires the server key', async () => {
    vi.stubEnv('STRIPE_SECRET_KEY', '');
    await expect(retrieveStripeIntent('pi_test')).rejects.toThrow(
      'não configurado',
    );
  });
});
