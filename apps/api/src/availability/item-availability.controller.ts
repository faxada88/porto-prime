import {Body,Controller,Get,Headers,Param,Patch,Post} from '@nestjs/common';
import {ItemAvailabilityService} from './item-availability.service.js';
@Controller()
export class ItemAvailabilityController {
 constructor(private readonly service:ItemAvailabilityService){}
 @Patch('admin/orders/:order/items/:item/availability')
 mark(@Param('order') order:string,@Param('item') item:string,@Body() body:any,@Headers('authorization') auth?:string){return this.service.mark(order,item,body,auth);}
 @Post('orders/:order/items/:item/availability-choice')
 choose(@Param('order') order:string,@Param('item') item:string,@Body() body:any,@Headers('authorization') auth?:string){return this.service.choose(order,item,body,auth);}
 @Post('admin/orders/:order/items/:item/refund-retry')
 retry(@Param('order') order:string,@Param('item') item:string,@Headers('authorization') auth?:string){return this.service.retry(order,item,auth);}
 @Get('orders/credits')
 credits(@Headers('authorization') auth?:string){return this.service.credits(auth);}
}
