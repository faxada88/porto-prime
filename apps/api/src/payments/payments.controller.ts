import { Body, Controller, Get, Headers, Post, Query, Req, Res } from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import type { Request, Response } from 'express';
import { CreateCheckoutDto } from './dto/create-checkout.dto.js';
import { PaymentsService } from './payments.service.js';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}

  @Post('checkout')
  checkout(@Body() body: CreateCheckoutDto, @Headers('authorization') authorization?: string) {
    return this.payments.createCheckout(body, authorization);
  }

  @Get('embedded')
  async embedded(@Query('sessionId') sessionId: string | undefined, @Res() res: Response) {
    const html = await this.payments.embeddedPage(sessionId);
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-store');
    return res.send(html);
  }

  @Post('webhook')
  webhook(@Req() req: RawBodyRequest<Request>, @Headers('stripe-signature') signature?: string) {
    return this.payments.webhook(req.rawBody, signature);
  }
}
