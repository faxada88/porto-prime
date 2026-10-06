import { Module } from '@nestjs/common';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { AdminModule } from './admin/admin.module.js';
import { AddressesModule } from './addresses/addresses.module.js';
import { AuthModule } from './auth/auth.module.js';
import { CategoriesModule } from './categories/categories.module.js';
import { CouriersModule } from './couriers/couriers.module.js';
import { DeliveryModule } from './delivery/delivery.module.js';
import { DispatchModule } from './dispatch/dispatch.module.js';
import { HealthModule } from './health/health.module.js';
import { OrdersModule } from './orders/orders.module.js';
import { PaymentsModule } from './payments/payments.module.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { ProductsModule } from './products/products.module.js';
import { RealtimeModule } from './realtime/realtime.module.js';
import { WalletModule } from './wallet/wallet.module.js';

@Module({
  imports: [
    PrismaModule,
    HealthModule,
    AuthModule,
    RealtimeModule,
    DeliveryModule,
    WalletModule,
    DispatchModule,
    AdminModule,
    CouriersModule,
    AddressesModule,
    OrdersModule,
    PaymentsModule,
    CategoriesModule,
    ProductsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
