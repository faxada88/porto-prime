import {DeliveryTrackingController} from './delivery-tracking.controller.js';
import {DeliveryTrackingService} from './delivery-tracking.service.js';
import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { OrdersController } from './orders.controller.js';
import { OrdersService } from './orders.service.js';

@Module({
  imports: [AuthModule],
  controllers: [OrdersController, DeliveryTrackingController],
  providers: [OrdersService, DeliveryTrackingService],
})
export class OrdersModule {}
