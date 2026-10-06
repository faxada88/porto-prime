import {
  Body,
  Controller,
  Get,
  Headers,
  Patch,
  Query,
} from '@nestjs/common';
import { DeliveryPricingService } from './delivery-pricing.service.js';

@Controller('delivery')
export class DeliveryPricingController {
  constructor(private readonly pricing: DeliveryPricingService) {}

  @Get('quote')
  quote(
    @Query('addressId') addressId: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.pricing.customerQuote(addressId, authorization);
  }

  @Get('pricing-config')
  adminConfig(@Headers('authorization') authorization?: string) {
    return this.pricing.adminConfig(authorization);
  }

  @Patch('pricing-config')
  updateConfig(
    @Body() body: Record<string, unknown>,
    @Headers('authorization') authorization?: string,
  ) {
    return this.pricing.updateAdminConfig(body, authorization);
  }
}
