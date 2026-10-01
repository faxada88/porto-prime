import { Controller, Get, Headers, Param, Patch } from '@nestjs/common';
import { AdminService } from './admin.service.js';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('pending')
  pending(@Headers('authorization') authorization?: string) {
    return this.adminService.pending(authorization);
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
}
