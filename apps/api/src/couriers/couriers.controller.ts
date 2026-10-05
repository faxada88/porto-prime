import { Body, Controller, Get, Headers, Param, Patch, Post } from '@nestjs/common';
import { CouriersService } from './couriers.service.js';
@Controller('couriers')
export class CouriersController {
 constructor(private readonly service:CouriersService){}
 @Post('application/status') status(@Body('document') document:string){return this.service.status(document);}
 @Get('application/me') me(@Headers('authorization') authorization?:string){return this.service.me(authorization);}
 @Patch('application') update(@Body() body:Record<string,unknown>,@Headers('authorization') authorization?:string){return this.service.update(body,authorization);}
 @Post('requirements/:id/respond') respond(@Param('id') id:string,@Body('response') response:string,@Headers('authorization') authorization?:string){return this.service.respond(id,response,authorization);}
}