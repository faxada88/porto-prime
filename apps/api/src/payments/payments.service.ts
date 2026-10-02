import { BadRequestException, ForbiddenException, Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { createHmac, timingSafeEqual } from 'node:crypto';
import { OrderStatus, PaymentMethod, PaymentStatus, UserRole } from '../generated/prisma/client.js';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateCheckoutDto } from './dto/create-checkout.dto.js';

@Injectable()
export class PaymentsService {
  constructor(private readonly prisma: PrismaService, private readonly auth: AuthService) {}

  async createCheckout(data: CreateCheckoutDto, authorization?: string) {
    const secret = process.env.STRIPE_SECRET_KEY;
    if (!secret) throw new ServiceUnavailableException('Pagamento Stripe ainda não configurado no servidor');

    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) throw new ForbiddenException('Apenas clientes podem pagar pedidos');

    const order = await this.prisma.order.findFirst({ where: { id: data.orderId, customerId: user.id } });
    if (!order) throw new BadRequestException('Pedido não encontrado');
    if (order.paymentStatus === PaymentStatus.PAID) throw new BadRequestException('Este pedido já está pago');

    const params = new URLSearchParams();
    params.set('mode', 'payment');
    params.set('success_url', data.successUrl);
    params.set('cancel_url', data.cancelUrl);
    params.set('customer_email', user.email);
    params.set('client_reference_id', order.id);
    params.set('metadata[orderId]', order.id);
    params.set('line_items[0][price_data][currency]', 'brl');
    params.set('line_items[0][price_data][product_data][name]', 'Pedido Porto Prime');
    params.set('line_items[0][price_data][unit_amount]', String(Math.round(Number(order.total) * 100)));
    params.set('line_items[0][quantity]', '1');

    const response = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${secret}`, 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params,
    });
    const payload = await response.json() as Record<string, any>;
    if (!response.ok || !payload.url) throw new BadRequestException(payload?.error?.message ?? 'Não foi possível iniciar o pagamento');

    await this.prisma.order.update({ where: { id: order.id }, data: { paymentMethod: PaymentMethod.CARD } });
    return { checkoutUrl: payload.url, sessionId: payload.id, orderId: order.id };
  }

  async webhook(rawBody?: Buffer, signature?: string) {
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!webhookSecret || !rawBody || !signature) throw new UnauthorizedException('Webhook inválido');

    const parts = Object.fromEntries(signature.split(',').map((p) => p.split('=', 2) as [string, string]));
    const timestamp = parts.t;
    const received = parts.v1;
    if (!timestamp || !received) throw new UnauthorizedException('Assinatura Stripe inválida');
    if (Math.abs(Date.now() / 1000 - Number(timestamp)) > 300) throw new UnauthorizedException('Webhook expirado');

    const expected = createHmac('sha256', webhookSecret).update(`${timestamp}.`).update(rawBody).digest('hex');
    const a = Buffer.from(expected);
    const b = Buffer.from(received);
    if (a.length !== b.length || !timingSafeEqual(a, b)) throw new UnauthorizedException('Assinatura Stripe inválida');

    const event = JSON.parse(rawBody.toString('utf8')) as Record<string, any>;
    if (event.type === 'checkout.session.completed') {
      const session = event.data?.object;
      const orderId = session?.metadata?.orderId ?? session?.client_reference_id;
      if (orderId && session?.payment_status === 'paid') {
        await this.prisma.order.updateMany({
          where: { id: orderId, paymentStatus: { not: PaymentStatus.PAID } },
          data: {
            paymentStatus: PaymentStatus.PAID,
            paymentMethod: PaymentMethod.CARD,
            status: OrderStatus.CONFIRMED,
            stripePaymentIntentId: typeof session.payment_intent === 'string' ? session.payment_intent : undefined,
          },
        });
      }
    }
    return { received: true };
  }
}
