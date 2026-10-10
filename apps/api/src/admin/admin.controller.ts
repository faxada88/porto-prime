import { Body, Controller, Delete, Get, Headers, Param, Query, Patch, Post } from '@nestjs/common';
import { AdminService } from './admin.service.js';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard')
  dashboard(@Headers('authorization') authorization?: string) {
    return this.adminService.dashboard(authorization);
  }

  @Get('pending')
  pending(@Headers('authorization') authorization?: string) {
    return this.adminService.pending(authorization);
  }

  @Get('couriers')
  couriers(@Headers('authorization') authorization?: string, @Query('pending') pending?:string) {
    return this.adminService.couriers(authorization,pending==='true');
  }

  @Get('couriers/directory')
  courierDirectory(@Query() query: {q?:string;page?:string;size?:string;status?:string;online?:string}, @Headers('authorization') authorization?: string) {
    return this.adminService.courierDirectory(query,authorization);
  }

  @Get('couriers/:id/record')
  courierRecord(@Param('id') id: string, @Headers('authorization') authorization?: string) {
    return this.adminService.courierRecord(id,authorization);
  }

  @Get('couriers/:id/finance')
  courierFinance(@Param('id') id: string, @Headers('authorization') authorization?: string) {
    return this.adminService.courierFinance(id, authorization);
  }

  @Patch('couriers/:id/profile')
  editCourier(@Param('id') id: string, @Body() body: Record<string, unknown>, @Headers('authorization') authorization?: string) {
    return this.adminService.editCourier(id, body, authorization);
  }

  @Get('customers/:id/activity')
  customerActivity(@Param('id') id:string,@Query('page') page?:string,@Headers('authorization') authorization?:string){
    return this.adminService.customerActivity(id,Number(page||1),authorization);
  }

  @Get('orders')
  orders(@Headers('authorization') authorization?: string) {
    return this.adminService.orders(authorization);
  }

  @Get('users')
  users(@Headers('authorization') authorization?: string, @Query('compactCouriers') compact?:string) {
    return this.adminService.users(authorization,compact==='true');
  }

  @Get('catalog')
  catalog(@Headers('authorization') authorization?: string) {
    return this.adminService.catalog(authorization);
  }

  @Patch('users/:id/status')
  updateUserStatus(
    @Param('id') id: string,
    @Body('status') status: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.updateUserStatus(id, status, authorization);
  }

  @Delete('users/:id')
  deleteUser(
    @Param('id') id: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.deleteUser(id, authorization);
  }

  @Post('users/bulk-delete')
  bulkDeleteUsers(
    @Body('ids') ids: string[],
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.bulkDeleteUsers(ids, authorization);
  }

  @Patch('users/:id/approve')
  approve(
    @Param('id') id: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.approve(id, authorization);
  }

  @Patch('users/:id/reject')
  reject(
    @Param('id') id: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.reject(id, authorization);
  }

  @Post('couriers/:id/requirements')
  requirement(
    @Param('id') id: string,
    @Body() body: { title: string; description: string },
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.createRequirement(id, body, authorization);
  }

  @Patch('requirements/:id/resolve')
  resolveRequirement(
    @Param('id') id: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.resolveRequirement(id, authorization);
  }

  @Patch('orders/:id/status')
  updateOrderStatus(
    @Param('id') id: string,
    @Body('status') status: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.updateOrderStatus(id, status, authorization);
  }

  @Patch('orders/:id/courier')
  assignCourier(
    @Param('id') id: string,
    @Body('courierId') courierId: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.assignCourier(id, courierId, authorization);
  }

  @Patch('orders/:id/release')
  releaseOrder(
    @Param('id') id: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.releaseOrder(id, authorization);
  }

  @Get('orders/:id/audit')
  dispatchAudit(
    @Param('id') id: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.dispatchAudit(id, authorization);
  }

  @Get('withdrawals')
  withdrawals(@Headers('authorization') authorization?: string) {
    return this.adminService.withdrawals(authorization);
  }

  @Patch('withdrawals/:id/status')
  updateWithdrawalStatus(
    @Param('id') id: string,
    @Body('status') status: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.updateWithdrawalStatus(
      id,
      status,
      authorization,
    );
  }

  @Delete('orders/:id')
  deleteOrder(
    @Param('id') id: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.deleteOrder(id, authorization);
  }

  @Post('orders/bulk-delete')
  bulkDeleteOrders(
    @Body('ids') ids: string[],
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.bulkDeleteOrders(ids, authorization);
  }

  @Post('products')
  createProduct(
    @Body() body: Record<string, any>,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.createProduct(body, authorization);
  }

  @Patch('products/:id')
  updateProduct(
    @Param('id') id: string,
    @Body() body: Record<string, any>,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.updateProduct(id, body, authorization);
  }

  @Post('categories')
  createCategory(
    @Body() body: Record<string, any>,
    @Headers('authorization') authorization?: string,
  ) {
    return this.adminService.createCategory(body, authorization);
  }
  @Patch('categories/:id')
  updateCategory(@Param('id') id: string, @Body() body: Record<string, any>, @Headers('authorization') authorization?: string) {
    return this.adminService.updateCategory(id, body, authorization);
  }

  @Patch('store')
  updateStore(@Body() body: Record<string, any>, @Headers('authorization') authorization?: string) {
    return this.adminService.updateStore(body, authorization);
  }
}
