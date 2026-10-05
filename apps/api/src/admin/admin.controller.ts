import { Body, Controller, Get, Headers, Param, Patch, Post } from '@nestjs/common';
import { AdminService } from './admin.service.js';
@Controller('admin')
export class AdminController {
 constructor(private readonly adminService:AdminService){}
 @Get('pending') pending(@Headers('authorization') a?:string){return this.adminService.pending(a);}
 @Get('couriers') couriers(@Headers('authorization') a?:string){return this.adminService.couriers(a);}
 @Patch('users/:id/approve') approve(@Param('id') id:string,@Headers('authorization') a?:string){return this.adminService.approve(id,a);}
 @Patch('users/:id/reject') reject(@Param('id') id:string,@Headers('authorization') a?:string){return this.adminService.reject(id,a);}
 @Post('couriers/:id/requirements') requirement(@Param('id') id:string,@Body() body:{title:string;description:string},@Headers('authorization') a?:string){return this.adminService.createRequirement(id,body,a);}
 @Patch('requirements/:id/resolve') resolve(@Param('id') id:string,@Headers('authorization') a?:string){return this.adminService.resolveRequirement(id,a);}
}