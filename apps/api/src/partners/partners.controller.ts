import {Controller,Get,Post,Patch,Param,Headers,Query,Body} from '@nestjs/common';
import {PartnersService} from './partners.service.js';
@Controller('partners')
export class PartnersController{
 constructor(private readonly service:PartnersService){}
 @Get('public/:code') referral(@Param('code') code:string){return this.service.publicReferral(code);}
 @Get('me/referral') sharing(@Headers('authorization') auth?:string,@Query('appUrl') appUrl?:string){return this.service.referral(auth,appUrl);}
 @Get('me') mine(@Headers('authorization') auth?:string,@Query('appUrl') appUrl?:string){return this.service.mine(auth,appUrl);}
 @Get('admin/:id') record(@Param('id') id:string,@Headers('authorization') auth?:string,@Query('appUrl') appUrl?:string){return this.service.adminRecord(id,auth,appUrl);}
 @Patch('admin/:id') edit(@Param('id') id:string,@Body() body:Record<string,unknown>,@Headers('authorization') auth?:string){return this.service.edit(id,body,auth);}
}
