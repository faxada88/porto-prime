import {Body,Controller,Get,Headers,Param,Patch,Post,Query,Req} from '@nestjs/common';
import type {Request} from 'express';
import {PublicSupportService} from './public-support.service.js';
@Controller('support/public')
export class PublicSupportController {
 constructor(private readonly service:PublicSupportService){}
 @Get('options') options(){return this.service.options();}
 @Post('contacts') create(@Body() body:Record<string,unknown>,@Req() req:Request){return this.service.create(body,req.ip||req.socket.remoteAddress||'unknown');}
 @Post('lookup') lookup(@Body() body:Record<string,unknown>,@Req() req:Request){return this.service.lookup(body,req.ip||req.socket.remoteAddress||'unknown');}
 @Post('contacts/:protocol/messages') reply(@Param('protocol') protocol:string,@Body() body:Record<string,unknown>,@Req() req:Request){return this.service.visitorReply(protocol,body,req.ip||req.socket.remoteAddress||'unknown');}
 @Get('admin') list(@Headers('authorization') auth:string|undefined,@Query() query:Record<string,string>){return this.service.list(auth,query);}
 @Get('admin/:id') detail(@Param('id') id:string,@Headers('authorization') auth?:string,@Query('before') before?:string){return this.service.adminDetail(id,auth,before);}
 @Post('admin/:id/messages') adminReply(@Param('id') id:string,@Body() body:Record<string,unknown>,@Headers('authorization') auth?:string){return this.service.adminReply(id,body,auth);}
 @Patch('admin/:id/status') status(@Param('id') id:string,@Body() body:Record<string,unknown>,@Headers('authorization') auth?:string){return this.service.status(id,body,auth);}
}
