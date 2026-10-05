import { Body, Controller, Delete, Get, Headers, Param, Patch, Post, Query } from '@nestjs/common';
import { OrderStatus, UserRole, UserStatus } from '../generated/prisma/client.js';
import { AdminService } from './admin.service.js';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}
  @Get('dashboard') dashboard(@Headers('authorization') a?:string){return this.adminService.dashboard(a)}
  @Get('pending') pending(@Headers('authorization') a?:string){return this.adminService.pending(a)}
  @Get('users') users(@Query('role') role:string|undefined,@Headers('authorization') a?:string){return this.adminService.users(role as UserRole|undefined,a)}
  @Patch('users/:id/status') userStatus(@Param('id') id:string,@Body() b:{status:UserStatus},@Headers('authorization') a?:string){return this.adminService.setUserStatus(id,b.status,a)}
  @Patch('users/:id/approve') approve(@Param('id') id:string,@Headers('authorization') a?:string){return this.adminService.approve(id,a)}
  @Patch('users/:id/reject') reject(@Param('id') id:string,@Headers('authorization') a?:string){return this.adminService.reject(id,a)}
  @Get('orders') orders(@Headers('authorization') a?:string){return this.adminService.orders(a)}
  @Delete('orders/:id') deleteOrder(@Param('id') id:string,@Headers('authorization') a?:string){return this.adminService.deleteOrder(id,a)}
  @Delete('users/:id') deleteUser(@Param('id') id:string,@Headers('authorization') a?:string){return this.adminService.deleteUser(id,a)}
  @Patch('orders/:id/release') release(@Param('id') id:string,@Headers('authorization') a?:string){return this.adminService.releaseOrder(id,a)}
  @Patch('orders/:id/status') orderStatus(@Param('id') id:string,@Body() b:{status:OrderStatus},@Headers('authorization') a?:string){return this.adminService.setOrderStatus(id,b.status,a)}
  @Patch('orders/:id/courier') courier(@Param('id') id:string,@Body() b:{courierId:string},@Headers('authorization') a?:string){return this.adminService.assignCourier(id,b.courierId,a)}
  @Get('catalog') catalog(@Headers('authorization') a?:string){return this.adminService.catalog(a)}
  @Post('categories') category(@Body() b:Record<string,unknown>,@Headers('authorization') a?:string){return this.adminService.createCategory(b,a)}
  @Post('products') product(@Body() b:Record<string,unknown>,@Headers('authorization') a?:string){return this.adminService.createProduct(b,a)}
  @Patch('products/:id') updateProduct(@Param('id') id:string,@Body() b:Record<string,unknown>,@Headers('authorization') a?:string){return this.adminService.updateProduct(id,b,a)}
}
