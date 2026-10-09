import {
  Body,
  Controller,
  Get,
  Headers,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { CreateAddressDto } from '../addresses/dto/create-address.dto.js';
import { DeliveryPricingService } from './delivery-pricing.service.js';

@Controller('delivery')
export class DeliveryPricingController {
  constructor(private readonly pricing: DeliveryPricingService) {}

  @Post('preview')
  preview(@Body() body: CreateAddressDto, @Headers('authorization') authorization?: string) {
    return this.pricing.preview(body, authorization);
  }

  @Post('locate')
  locate(@Body() body: Record<string, unknown>, @Headers('authorization') authorization?: string) {
    return this.pricing.locate(body, authorization);
  }

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
