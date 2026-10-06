import {
  Body,
  Controller,
  Get,
  Headers,
  Post,
  Query,
} from '@nestjs/common';
import { WalletService } from './wallet.service.js';

@Controller('wallet')
export class WalletController {
  constructor(private readonly wallet: WalletService) {}

  @Get('summary')
  summary(@Headers('authorization') authorization?: string) {
    return this.wallet.summary(authorization);
  }

  @Get('ledger')
  ledger(
    @Query('take') take?: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.wallet.ledger(
      authorization,
      Number(take || 100),
    );
  }

  @Get('withdrawals')
  withdrawals(@Headers('authorization') authorization?: string) {
    return this.wallet.withdrawals(authorization);
  }

  @Post('withdrawals')
  requestWithdrawal(
    @Body('amount') amount: number,
    @Headers('authorization') authorization?: string,
  ) {
    return this.wallet.requestWithdrawal(amount, authorization);
  }

  @Get('admin/withdrawals')
  adminWithdrawals(
    @Headers('authorization') authorization?: string,
  ) {
    return this.wallet.adminWithdrawals(authorization);
  }

}
