import {
  BadRequestException,
  ServiceUnavailableException,
} from '@nestjs/common';

export type StripeIntent = {
  id: string;
  status: string;
  client_secret?: string;
  currency: string;
  amount: number;
  amount_received: number;
  metadata?: { orderId?: string; customerId?: string };
};

export async function retrieveStripeIntent(id: string): Promise<StripeIntent> {
  const secret = process.env.STRIPE_SECRET_KEY;
  if (!secret)
    throw new ServiceUnavailableException(
      'Pagamento Stripe ainda não configurado no servidor',
    );
  try {
    const response = await fetch(
      `https://api.stripe.com/v1/payment_intents/${encodeURIComponent(id)}`,
      {
        headers: { Authorization: 'Bearer ' + secret },
        signal: AbortSignal.timeout(10_000),
        redirect: 'error',
      },
    );
    if (!response.ok) throw new Error('Stripe unavailable');
    return (await response.json()) as StripeIntent;
  } catch {
    throw new ServiceUnavailableException(
      'Não foi possível verificar o pagamento agora. Seu pedido foi preservado; tente verificar novamente.',
    );
  }
}

export function isVerifiedPayment(
  intent: StripeIntent,
  order: {
    id: string;
    customerId: string;
    stripePaymentIntentId: string | null;
    total: unknown;
  },
): boolean {
  const cents = Math.round(Number(order.total) * 100);
  if (
    intent.id !== order.stripePaymentIntentId ||
    intent.metadata?.orderId !== order.id ||
    intent.metadata?.customerId !== order.customerId ||
    intent.currency !== 'brl' ||
    !Number.isSafeInteger(cents) ||
    cents <= 0 ||
    intent.amount !== cents
  ) {
    throw new BadRequestException(
      'O pagamento não corresponde a este pedido. Entre em contato com o suporte.',
    );
  }
  return intent.status === 'succeeded' && intent.amount_received === cents;
}
