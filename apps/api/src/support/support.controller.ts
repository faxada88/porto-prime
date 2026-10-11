import {Controller,Get,Post,Patch,Param,Headers,Query,Body} from '@nestjs/common';
import {DeliveryChatService} from './delivery-chat.service.js';
import {SupportService} from './support.service.js';
@Controller('support')
export class SupportController {
 constructor(private readonly service:SupportService,private readonly delivery:DeliveryChatService){}
 @Get('orders/:id/delivery') deliveryDetail(@Param('id') id:string,@Headers('authorization') auth?:string,@Query('before') before?:string){return this.delivery.detail(id,auth,before);}
 @Post('orders/:id/delivery/messages') deliverySend(@Param('id') id:string,@Body() body:Record<string,unknown>,@Headers('authorization') auth?:string){return this.delivery.send(id,body,auth);}
 @Post('orders/:id/delivery/escalate') escalate(@Param('id') id:string,@Body() body:Record<string,unknown>,@Headers('authorization') auth?:string){return this.delivery.escalate(id,body,auth);}
 @Get('options') options(@Headers('authorization') auth?:string){return this.service.options(auth);}
 @Get('me') mine(@Query() query:Record<string,string>,@Headers('authorization') auth?:string){return this.service.list(auth,query);}
 @Get('admin') admin(@Query() query:Record<string,string>,@Headers('authorization') auth?:string){return this.service.list(auth,query,true);}
 @Post('threads') create(@Body() body:Record<string,unknown>,@Headers('authorization') auth?:string){return this.service.create(body,auth);}
 @Get('threads/:id') detail(@Param('id') id:string,@Headers('authorization') auth?:string,@Query('before') before?:string){return this.service.detail(id,auth,before);}
 @Post('threads/:id/messages') reply(@Param('id') id:string,@Body() body:Record<string,unknown>,@Headers('authorization') auth?:string){return this.service.reply(id,body,auth);}
 @Patch('threads/:id/status') status(@Param('id') id:string,@Body() body:Record<string,unknown>,@Headers('authorization') auth?:string){return this.service.status(id,body,auth);}
}
