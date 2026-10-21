import { Body, Controller, Get, Headers, Post, Query, Req, Res } from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import type { Request, Response } from 'express';
import { CreateCheckoutDto } from './dto/create-checkout.dto.js';
import { ReconcilePaymentDto } from './dto/reconcile-payment.dto.js';
import { PaymentsService } from './payments.service.js';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}

  @Post('checkout')
  checkout(
    @Body() body: CreateCheckoutDto,
    @Headers('authorization') authorization?: string,
  ) {
    return this.payments.createCheckout(body, authorization);
  }

  @Post('native-options')
  nativeOptions(@Body() body:ReconcilePaymentDto,@Headers('authorization') authorization?:string){
    return this.payments.nativeOptions(body.orderId,authorization);
  }

  @Post('pix')
  nativePix(@Body() body:ReconcilePaymentDto,@Headers('authorization') authorization?:string){
    return this.payments.nativePix(body.orderId,authorization);
  }

  @Post('secure-checkout')
  secureCheckout(@Body() body:ReconcilePaymentDto,@Req() req:Request,@Headers('authorization') authorization?:string){
    return this.payments.secureCheckout(body.orderId,req.protocol+'://'+req.get('host'),authorization);
  }

  @Get('secure')
  async securePage(@Query('orderId') orderId:string,@Query('expires') expires:string,@Query('token') token:string,@Res() res:Response){
    const page=await this.payments.securePage(orderId,expires,token);
    res.set({
      'Cache-Control':'no-store, max-age=0',
      'Referrer-Policy':'no-referrer',
      'X-Content-Type-Options':'nosniff',
      'X-Frame-Options':'DENY',
      'Content-Security-Policy':"default-src 'self'; script-src 'nonce-"+page.nonce+"' https://js.stripe.com https://*.stripe.com https://pay.google.com; frame-src https://*.stripe.com https://*.google.com; connect-src 'self' https://*.stripe.com https://*.google.com; img-src 'self' data: https://*.stripe.com; style-src 'self' 'unsafe-inline'; frame-ancestors 'none'; base-uri 'none'; form-action 'self' https://*.stripe.com",
    }).type('html').send(page.html);
  }

  @Post('confirm-credit')
  confirmCredit(@Body() body:ReconcilePaymentDto,@Headers('authorization') authorization?:string){return this.payments.confirmCredit(body.orderId,authorization);}

  @Post('reconcile')
  reconcile(@Body() body: ReconcilePaymentDto, @Headers('authorization') authorization?: string) {
    return this.payments.reconcile(body.orderId, authorization);
  }

  @Post('webhook')
  webhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('stripe-signature') signature?: string,
  ) {
    return this.payments.webhook(req.rawBody, signature);
  }
}

