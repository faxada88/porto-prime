import { randomBytes } from 'node:crypto';
import { checkoutLink, verifyCheckout } from './secure-checkout.js';
import { secureCheckoutPage } from './secure-checkout-page.js';
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


    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) {
      throw new ForbiddenException('Apenas clientes podem pagar pedidos');
    }

    const order = await this.prisma.order.findFirst({
      where: { id: data.orderId, customerId: user.id, adminDeletedAt:null },
      include:{address:{select:{label:true,street:true,number:true,complement:true,neighborhood:true,city:true,state:true}},items:{select:{productName:true,quantity:true,unitPrice:true,total:true}}},
    });

    if (!order) throw new BadRequestException('Pedido não encontrado');
    const summary={subtotal:Number(order.subtotal),deliveryFee:Number(order.deliveryFee),storeCreditUsed:Number(order.storeCreditUsed),total:Number(order.total),distanceKm:order.routeDistanceKm==null?null:Number(order.routeDistanceKm),durationMinutes:order.routeDurationMinutes,address:order.address,items:order.items.map(item=>({productName:item.productName,quantity:item.quantity,unitPrice:Number(item.unitPrice),total:Number(item.total)}))};
    if (order.status === OrderStatus.CANCELED || ['REFUNDED','PARTIALLY_REFUNDED'].includes(order.paymentStatus)) throw new BadRequestException('Este pedido não aceita pagamentos.');
    if (order.paymentStatus === PaymentStatus.PAID) {
      throw new BadRequestException('Este pedido já está pago');
    }

    const store = await this.prisma.deliveryPricingConfig.findUnique({ where: { id: 'default' }, select: { storeOpen: true, storeMessage: true } });
    if (store?.storeOpen === false) throw new BadRequestException(store.storeMessage || 'A loja está fechada no momento');

    if(Number(order.total)===0&&Number(order.storeCreditUsed)>0)return {orderId:order.id,creditOnly:true,summary};
    if (!secret || !publishableKey) {
      throw new ServiceUnavailableException(
        'Pagamento Stripe ainda não configurado no servidor',
      );
    }

    if (order.stripePaymentIntentId) {
      const existing = await retrieveStripeIntent(order.stripePaymentIntentId);
      isVerifiedPayment(existing, order);
      if (existing.status !== 'canceled') {
        if (!existing.client_secret) throw new ServiceUnavailableException('Não foi possível recuperar o pagamento. Tente novamente mais tarde.');
        if (existing.status === 'succeeded') await this.completePayment(existing);
        return { orderId: order.id, paymentIntentId: existing.id, clientSecret: existing.client_secret, publishableKey, summary };
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
      summary,
    };
  }

  private async nativePaymentOrder(orderId:string,authorization?:string) {
    const user=await this.auth.authenticate(authorization);
    if(user.role!==UserRole.CUSTOMER)throw new ForbiddenException('Acesso exclusivo de cliente');
    const order=await this.prisma.order.findFirst({where:{id:orderId,customerId:user.id,adminDeletedAt:null}});
    if(!order||!order.stripePaymentIntentId||order.status===OrderStatus.CANCELED||['REFUNDED','PARTIALLY_REFUNDED'].includes(order.paymentStatus))throw new BadRequestException('Este pedido não aceita pagamentos.');
    const intent=await retrieveStripeIntent(order.stripePaymentIntentId);
    isVerifiedPayment(intent,order);
    return {user,order,intent};
  }

  async nativeOptions(orderId:string,authorization?:string){
    const {order,intent}=await this.nativePaymentOrder(orderId,authorization);
    if(intent.status==='succeeded')return {paid:await this.completePayment(intent),status:intent.status,methods:[]};
    return {paid:false,status:intent.status,methods:intent.payment_method_types??['card'],
      pendingPix:!!intent.next_action?.pix_display_qr_code};
  }

  async nativePix(orderId:string,authorization?:string){
    const {user,order,intent}=await this.nativePaymentOrder(orderId,authorization);
    if(intent.status==='succeeded')return {paid:await this.completePayment(intent),status:intent.status};
    const current=intent.next_action?.pix_display_qr_code;
    if(current?.data&&(!current.expires_at||current.expires_at>Date.now()/1000))return this.pixResponse(intent);
    if(intent.status==='processing')return {paid:false,status:'processing'};
    if(intent.status!=='requires_payment_method')throw new BadRequestException('Há um pagamento em andamento. Verifique o status antes de trocar a forma de pagamento.');
    if(!intent.payment_method_types?.includes('pix'))throw new BadRequestException('Pix não está disponível para este pagamento no Stripe. Escolha outra forma ou refaça o checkout.');
    if(order.status!==OrderStatus.PENDING)throw new BadRequestException('Este pedido já foi encaminhado.');
    const store=await this.prisma.deliveryPricingConfig.findUnique({where:{id:'default'},select:{storeOpen:true,storeMessage:true}});
    if(store?.storeOpen===false)throw new BadRequestException(store.storeMessage||'A loja está fechada');
    const secret=process.env.STRIPE_SECRET_KEY;
    if(!secret)throw new ServiceUnavailableException('Stripe não configurado');
    const profile=await this.prisma.customerProfile.findUnique({where:{userId:user.id},select:{onboardingData:true}});
    const saved=profile?.onboardingData as Record<string,unknown>|null;
    const taxId=String(saved?.cpf??saved?.document??'').replace(/\D/g,'');
    const params=new URLSearchParams({
      'payment_method_data[type]':'pix',
      'payment_method_data[billing_details][name]':user.name,
      'payment_method_data[billing_details][email]':user.email,
      'payment_method_data[billing_details][address][country]':'BR',
      'return_url':'portoprime://stripe-redirect',
    });
    if(taxId.length===11||taxId.length===14)params.set('payment_method_data[billing_details][tax_id]',taxId);
    const previous=typeof intent.payment_method==='string'?intent.payment_method:intent.payment_method?.id;
    const attempt=previous??intent.last_payment_error?.payment_method?.id??'initial';
    let response:Response;
    try{response=await fetch('https://api.stripe.com/v1/payment_intents/'+encodeURIComponent(intent.id)+'/confirm',{
      method:'POST',headers:{Authorization:'Bearer '+secret,'Content-Type':'application/x-www-form-urlencoded',
      'Idempotency-Key':'porto-pix:'+order.id+':'+intent.id+':'+attempt},
      body:params,signal:AbortSignal.timeout(15000),redirect:'error',
    });}catch{throw new ServiceUnavailableException('Não foi possível gerar o Pix agora. Tente novamente; o mesmo pagamento será recuperado.');}
    const payload=await response.json() as StripeIntent&{error?:{message?:string}};
    if(!response.ok)throw new BadRequestException(payload.error?.message??'Não foi possível gerar o Pix.');
    isVerifiedPayment(payload,order);
    if(payload.status==='succeeded')return {paid:await this.completePayment(payload),status:payload.status};
    return this.pixResponse(payload);
  }

  private pixResponse(intent:StripeIntent){
    const pix=intent.next_action?.pix_display_qr_code;
    if(!pix?.data)throw new ServiceUnavailableException('O Stripe ainda não retornou o código Pix. Verifique novamente.');
    let imageUrl:string|null=null;
    try{const url=new URL(pix.image_url_png??'');if(url.protocol==='https:'&&url.hostname.endsWith('.stripe.com'))imageUrl=url.toString();}catch{}
    return {paid:false,status:intent.status,pix:{data:pix.data,imageUrl,expiresAt:pix.expires_at??null}};
  }

  async secureCheckout(orderId: string, origin: string, authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) throw new ForbiddenException('Acesso exclusivo de cliente');
    const order = await this.prisma.order.findFirst({where:{id:orderId,customerId:user.id,adminDeletedAt:null}});
    if (!order || order.status !== OrderStatus.PENDING || !['PENDING','FAILED'].includes(order.paymentStatus) || !order.stripePaymentIntentId) {
      throw new BadRequestException('Este pedido não está disponível para pagamento. Consulte o acompanhamento.');
    }
    const store = await this.prisma.deliveryPricingConfig.findUnique({where:{id:'default'},select:{storeOpen:true,storeMessage:true}});
    if (store?.storeOpen === false) throw new BadRequestException(store.storeMessage || 'A loja está fechada');
    const intent = await retrieveStripeIntent(order.stripePaymentIntentId);
    isVerifiedPayment(intent, order);
    if (intent.status === 'succeeded') {
      await this.completePayment(intent);
      return {paid:true};
    }
    if (intent.status === 'canceled') throw new BadRequestException('Reabra o checkout para atualizar seu pagamento.');
    return checkoutLink(process.env.PAYMENTS_PUBLIC_URL || origin, order.id, intent.id);
  }

  async securePage(orderId: string, expires: string, token: string) {
    if (typeof orderId !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(orderId) || typeof expires !== 'string' || typeof token !== 'string') throw new UnauthorizedException('Link inválido');
    // Verify the capability before retrieving any Stripe client secret.
    const order = await this.prisma.order.findFirst({where:{id:orderId,adminDeletedAt:null},include:{customer:{select:{name:true,email:true}}}});
    if (!order?.stripePaymentIntentId) throw new UnauthorizedException('Link de pagamento indisponível');
    verifyCheckout(order.id, order.stripePaymentIntentId, expires, token);
    if (order.status === OrderStatus.CANCELED || ['REFUNDED','PARTIALLY_REFUNDED'].includes(order.paymentStatus)) throw new BadRequestException('Este pedido não aceita pagamentos.');
    const intent = await retrieveStripeIntent(order.stripePaymentIntentId);
    isVerifiedPayment(intent, order);
    if (!intent.client_secret || !process.env.STRIPE_PUBLISHABLE_KEY) throw new ServiceUnavailableException('Pagamento indisponível');
    const nonce = randomBytes(18).toString('base64');
    return {nonce,html:secureCheckoutPage({
      publishableKey:process.env.STRIPE_PUBLISHABLE_KEY,
      clientSecret:intent.client_secret,amount:Number(order.total),
      testMode:process.env.STRIPE_PUBLISHABLE_KEY.startsWith('pk_test_'),
      name:order.customer.name,email:order.customer.email,nonce,
    })};
  }

  async confirmCredit(orderId:string,authorization?:string){
    const user=await this.auth.authenticate(authorization);
    if(user.role!==UserRole.CUSTOMER)throw new ForbiddenException('Acesso exclusivo de cliente');
    const result=await this.prisma.$transaction(async tx=>{
      await tx.$queryRaw`SELECT "id" FROM "Order" WHERE "id"=${orderId} FOR UPDATE`;
      const order=await tx.order.findFirst({where:{id:orderId,customerId:user.id,adminDeletedAt:null}});
      if(!order)throw new BadRequestException('Pedido não encontrado');
      if(Number(order.total)!==0||Number(order.storeCreditUsed)<=0||order.stripePaymentIntentId)throw new BadRequestException('Este pedido precisa do pagamento restante pelo Stripe');
      if(order.paymentStatus===PaymentStatus.PAID)return {order,changed:false};
      if(order.status!==OrderStatus.PENDING||!['PENDING','FAILED'].includes(order.paymentStatus))throw new BadRequestException('Este pedido não pode ser confirmado');
      const debit=await tx.customerCreditEntry.findUnique({where:{idempotencyKey:'order:'+order.id+':credit-use'}});
      if(!debit||debit.customerId!==user.id||Math.round(-Number(debit.amount)*100)!==Math.round(Number(order.storeCreditUsed)*100)||Math.round(Number(order.storeCreditUsed)*100)!==Math.round((Number(order.subtotal)+Number(order.deliveryFee))*100))throw new BadRequestException('Confirme o saldo do cartão antes de finalizar');
      const updated=await tx.order.update({where:{id:order.id},data:{paymentStatus:PaymentStatus.PAID,status:OrderStatus.CONFIRMED,paidAt:new Date()}});
      return {order:updated,changed:true};
    });
    if(result.changed){this.realtime.emitOrderUpdated(result.order);this.realtime.emitToUser(user.id,'customer.credit.updated',{orderId,at:new Date().toISOString()});}
    return {paid:true,status:'succeeded',orderId};
  }

  async reconcile(orderId: string, authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) throw new ForbiddenException('Apenas clientes podem verificar seus pagamentos');
    const order = await this.prisma.order.findFirst({ where: { id: orderId, customerId: user.id, adminDeletedAt:null } });
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
    const expanded = typeof intent.payment_method === 'string' ? await retrieveStripeIntent(intent.id) : intent;
    const type = typeof expanded.payment_method === 'object' ? expanded.payment_method?.type : undefined;
    const paymentMethod = type === 'pix' ? PaymentMethod.PIX : type === 'boleto' ? PaymentMethod.BOLETO : PaymentMethod.CARD;
    const where = { id: order.id, stripePaymentIntentId: intent.id, paymentStatus: { notIn: [PaymentStatus.PAID,PaymentStatus.REFUNDED,PaymentStatus.PARTIALLY_REFUNDED] } };
    // Never regress an order already being prepared, dispatched or delivered.
    const pending = await this.prisma.order.updateMany({
      where: { ...where, status: OrderStatus.PENDING },
      data: { paymentStatus: PaymentStatus.PAID, paymentMethod, status: OrderStatus.CONFIRMED, paidAt:new Date() },
    });
    const other = await this.prisma.order.updateMany({
      where: { ...where, status: { not: OrderStatus.PENDING } },
      data: { paymentStatus: PaymentStatus.PAID, paymentMethod, paidAt:new Date() },
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

