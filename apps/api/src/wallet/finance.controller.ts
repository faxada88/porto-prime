import {Body,Controller,Get,Headers,Param,Patch,Post,Query} from '@nestjs/common';
import {FinanceService} from './finance.service.js';
@Controller('finance')
export class FinanceController {
  constructor(private readonly finance:FinanceService){}
  @Get('admin/accounts') accounts(@Headers('authorization') auth?:string,@Query('search') search?:string){return this.finance.accounts(auth,search);}
  @Get('admin/overview') overview(@Headers('authorization') auth?:string){return this.finance.overview(auth);}
  @Get('admin/accounts/:id') detail(@Param('id') id:string,@Headers('authorization') auth?:string){return this.finance.detail(id,auth);}
  @Post('admin/accounts/:id/credits') credit(@Param('id') id:string,@Body() body:Record<string,any>,@Headers('authorization') auth?:string){return this.finance.credit(id,body,auth);}
  @Post('admin/accounts/:id/withdrawals') withdraw(@Param('id') id:string,@Body() body:Record<string,any>,@Headers('authorization') auth?:string){return this.finance.withdraw(id,body,auth);}
  @Patch('admin/withdrawals/:kind/:id') status(@Param('kind') kind:string,@Param('id') id:string,@Body() body:Record<string,any>,@Headers('authorization') auth?:string){return this.finance.status(kind,id,body,auth);}
  @Get('me') mine(@Headers('authorization') auth?:string){return this.finance.mine(auth);}
  @Post('me/withdrawals') myWithdrawal(@Body() body:Record<string,any>,@Headers('authorization') auth?:string){return this.finance.myWithdrawal(body,auth);}
}
