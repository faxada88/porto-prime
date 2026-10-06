import { Global, Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { DeliveryPricingController } from './delivery-pricing.controller.js';
import { DeliveryPricingService } from './delivery-pricing.service.js';

@Global()
@Module({
  imports: [AuthModule],
  controllers: [DeliveryPricingController],
  providers: [DeliveryPricingService],
  exports: [DeliveryPricingService],
})
export class DeliveryModule {}
