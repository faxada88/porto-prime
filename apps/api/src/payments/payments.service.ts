import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { createHmac, timingSafeEqual } from 'node:crypto';
import {
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
  UserRole,
} from '../generated/prisma/client.js';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { RealtimeGateway } from '../realtime/realtime.gateway.js';
import { isVerifiedPayment, retrieveStripeIntent } from './stripe-payment-verifier.js';
import type { StripeIntent } from './stripe-payment-verifier.js';
import { CreateCheckoutDto } from './dto/create-checkout.dto.js';

@Injectable()
export class PaymentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly realtime: RealtimeGateway,
  ) {}

  async createCheckout(data: CreateCheckoutDto, authorization?: string) {
    const secret = process.env.STRIPE_SECRET_KEY;
    const publishableKey = process.env.STRIPE_PUBLISHABLE_KEY;

    if (!secret || !publishableKey) {
      throw new ServiceUnavailableException(
        'Pagamento Stripe ainda não configurado no servidor',
      );
    }

    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) {
      throw new ForbiddenException('Apenas clientes podem pagar pedidos');
    }

    const order = await this.prisma.order.findFirst({
      where: { id: data.orderId, customerId: user.id },
    });

    if (!order) throw new BadRequestException('Pedido não encontrado');
    if (order.paymentStatus === PaymentStatus.PAID) {
      throw new BadRequestException('Este pedido já está pago');
    }

    const store = await this.prisma.deliveryPricingConfig.findUnique({ where: { id: 'default' }, select: { storeOpen: true, storeMessage: true } });
    if (store?.storeOpen === false) throw new BadRequestException(store.storeMessage || 'A loja está fechada no momento');

    if (order.stripePaymentIntentId) {
      const existing = await retrieveStripeIntent(order.stripePaymentIntentId);
      isVerifiedPayment(existing, order);
      if (existing.status !== 'canceled') {
        if (!existing.client_secret) throw new ServiceUnavailableException('Não foi possível recuperar o pagamento. Tente novamente mais tarde.');
        if (existing.status === 'succeeded') await this.completePayment(existing);
        return { orderId: order.id, paymentIntentId: existing.id, clientSecret: existing.client_secret, publishableKey };
      }
    }

    const params = new URLSearchParams();
    params.set('amount', String(Math.round(Number(order.total) * 100)));
    params.set('currency', 'brl');
    params.set('automatic_payment_methods[enabled]', 'true');
    params.set('metadata[orderId]', order.id);
    params.set('metadata[customerId]', user.id);
    params.set('description', 'Pedido Porto Prime ' + order.id);
    params.set('receipt_email', user.email);

    const response = await fetch('https://api.stripe.com/v1/payment_intents', {
      method: 'POST',
      headers: {
        Authorization: 'Bearer ' + secret,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Idempotency-Key': `porto-prime:${order.id}:${order.stripePaymentIntentId ?? 'initial'}`,
      },
      body: params,
    });

    const payload = (await response.json()) as Record<string, any>;

    if (!response.ok || !payload.client_secret || !payload.id) {
      throw new BadRequestException(
        payload?.error?.message ?? 'Não foi possível iniciar o pagamento',
      );
    }

    await this.prisma.order.update({
      where: { id: order.id },
      data: {
        paymentMethod: PaymentMethod.CARD,
        stripePaymentIntentId: payload.id,
      },
    });

    return {
      orderId: order.id,
      paymentIntentId: payload.id,
      clientSecret: payload.client_secret,
      publishableKey,
    };
  }

  async reconcile(orderId: string, authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) throw new ForbiddenException('Apenas clientes podem verificar seus pagamentos');
    const order = await this.prisma.order.findFirst({ where: { id: orderId, customerId: user.id } });
    if (!order) throw new BadRequestException('Pedido não encontrado');
    if (order.paymentStatus === PaymentStatus.PAID) return { paid: true, status: 'succeeded' };
    if (!order.stripePaymentIntentId) return { paid: false, status: 'requires_payment_method' };
    const intent = await retrieveStripeIntent(order.stripePaymentIntentId);
    if (!isVerifiedPayment(intent, order)) return { paid: false, status: intent.status };
    const paid = await this.completePayment(intent);
    return { paid, status: intent.status };
  }

  private async completePayment(intent: StripeIntent) {
    const order = await this.prisma.order.findUnique({ where: { id: intent.metadata?.orderId ?? '' } });
    if (!order || !isVerifiedPayment(intent, order)) return false;
    if (order.paymentStatus===PaymentStatus.REFUNDED||order.paymentStatus===PaymentStatus.PARTIALLY_REFUNDED) return false;
    const where = { id: order.id, stripePaymentIntentId: intent.id, paymentStatus: { notIn: [PaymentStatus.PAID,PaymentStatus.REFUNDED,PaymentStatus.PARTIALLY_REFUNDED] } };
    // Never regress an order already being prepared, dispatched or delivered.
    const pending = await this.prisma.order.updateMany({
      where: { ...where, status: OrderStatus.PENDING },
      data: { paymentStatus: PaymentStatus.PAID, paymentMethod: PaymentMethod.CARD, status: OrderStatus.CONFIRMED },
    });
    const other = await this.prisma.order.updateMany({
      where: { ...where, status: { not: OrderStatus.PENDING } },
      data: { paymentStatus: PaymentStatus.PAID, paymentMethod: PaymentMethod.CARD },
    });
    if (pending.count + other.count > 0) {
      const updated = await this.prisma.order.findUnique({ where: { id: order.id }, select: { id: true, customerId: true, courierId: true, status: true } });
      if (updated) this.realtime.emitOrderUpdated(updated);
    }
    // A replaced intent must not report success for the order being reconciled.
    const current = await this.prisma.order.findUnique({ where: { id: order.id }, select: { paymentStatus: true, stripePaymentIntentId: true } });
    return current?.paymentStatus === PaymentStatus.PAID && current.stripePaymentIntentId === intent.id;
  }

  async webhook(rawBody?: Buffer, signature?: string) {
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    if (!webhookSecret || !rawBody || !signature) {
      throw new UnauthorizedException('Webhook inválido');
    }

    const parts = Object.fromEntries(
      signature
        .split(',')
        .map((part) => part.split('=', 2) as [string, string]),
    );

    const timestamp = parts.t;
    const received = parts.v1;

    if (!timestamp || !received) {
      throw new UnauthorizedException('Assinatura Stripe inválida');
    }

    if (Math.abs(Date.now() / 1000 - Number(timestamp)) > 300) {
      throw new UnauthorizedException('Webhook expirado');
    }

    const expected = createHmac('sha256', webhookSecret)
      .update(timestamp + '.')
      .update(rawBody)
      .digest('hex');

    const a = Buffer.from(expected);
    const b = Buffer.from(received);

    if (a.length !== b.length || !timingSafeEqual(a, b)) {
      throw new UnauthorizedException('Assinatura Stripe inválida');
    }

    const event = JSON.parse(rawBody.toString('utf8')) as Record<string, any>;
    const intent = event.data?.object;
    const orderId = intent?.metadata?.orderId;

    if (event.type === 'payment_intent.succeeded' && orderId) {
      await this.completePayment(intent as StripeIntent);
    }

    if (
      (event.type === 'payment_intent.payment_failed' ||
        event.type === 'payment_intent.canceled') &&
      orderId
    ) {
      await this.prisma.order.updateMany({
        where: {
          id: orderId,
          stripePaymentIntentId: intent.id,
          paymentStatus: PaymentStatus.PENDING,
        },
        data: {
          paymentStatus: PaymentStatus.FAILED,
          paymentMethod: PaymentMethod.CARD,
        },
      });

      const order = await this.prisma.order.findUnique({
        where: { id: orderId },
        select: {
          id: true,
          customerId: true,
          courierId: true,
          status: true,
        },
      });
      if (order) this.realtime.emitOrderUpdated(order);
    }

    return { received: true };
  }
}
