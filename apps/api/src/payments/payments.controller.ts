import { Body, Controller, Headers, Post, Req } from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import type { Request } from 'express';
import { CreateCheckoutDto } from './dto/create-checkout.dto.js';
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

  @Post('webhook')
  webhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('stripe-signature') signature?: string,
  ) {
    return this.payments.webhook(req.rawBody, signature);
  }
}
