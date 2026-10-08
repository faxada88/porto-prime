import { FinanceService } from './finance.service.js';
import { FinanceController } from './finance.controller.js';
import { Global, Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { WalletController } from './wallet.controller.js';
import { WalletService } from './wallet.service.js';

@Global()
@Module({
  imports: [AuthModule],
  controllers: [WalletController, FinanceController],
  providers: [WalletService, FinanceService],
  exports: [WalletService],
})
export class WalletModule {}
