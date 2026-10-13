import {Body,Controller,Get,Headers,Param,Post} from '@nestjs/common';
import {IsIn,IsNumber,Min} from 'class-validator';
import {OrderCancellationService} from './order-cancellation.service.js';
class CancelOrderDto {
 @IsIn(['Mudei de ideia','Endereço incorreto','Demora no atendimento','Outro motivo']) reason!:string;
 @IsNumber({maxDecimalPlaces:2}) @Min(0) expectedFee!:number;
 @IsNumber({maxDecimalPlaces:2}) @Min(0) expectedCashRefund!:number;
 @IsNumber({maxDecimalPlaces:2}) @Min(0) expectedCreditRefund!:number;
}
@Controller()
export class OrderCancellationController {
 constructor(private readonly service:OrderCancellationService){}
 @Get('orders/:id/cancellation-quote') quote(@Param('id') id:string,@Headers('authorization') auth?:string){return this.service.quote(id,auth);}
 @Post('orders/:id/cancel') cancel(@Param('id') id:string,@Body() input:CancelOrderDto,@Headers('authorization') auth?:string){return this.service.cancel(id,input,auth);}
 @Post('admin/cancellations/:id/retry') retry(@Param('id') id:string,@Headers('authorization') auth?:string){return this.service.retry(id,auth);}
}
