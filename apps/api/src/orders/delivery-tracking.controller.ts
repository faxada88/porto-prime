import {Body,Controller,Get,Headers,Param,Post} from '@nestjs/common';
import {DeliveryTrackingService} from './delivery-tracking.service.js';
@Controller('orders')
export class DeliveryTrackingController {
 constructor(private readonly tracking:DeliveryTrackingService){}
 @Post(':id/tracking/location') update(@Param('id') id:string,@Body() body:unknown,@Headers('authorization') authorization?:string){return this.tracking.update(id,body,authorization);}
 @Get(':id/tracking') snapshot(@Param('id') id:string,@Headers('authorization') authorization?:string){return this.tracking.snapshot(id,authorization);}
}
