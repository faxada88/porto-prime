import { Body, Controller, Delete, Get, Headers, Patch, Post, Param } from '@nestjs/common';
import { CreateOrderDto } from './dto/create-order.dto.js';
import { OrdersService } from './orders.service.js';

@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  create(@Body() body: CreateOrderDto, @Headers('authorization') authorization?: string) {
    return this.ordersService.create(body, authorization);
  }

  @Delete('pending')
  clearPending(@Headers('authorization') authorization?: string) {
    return this.ordersService.clearPending(authorization);
  }

  @Get('mine')
  mine(@Headers('authorization') authorization?: string) {
    return this.ordersService.mine(authorization);
  }

  @Get('active')
  active(@Headers('authorization') authorization?: string) {
    return this.ordersService.active(authorization);
  }
  @Get('courier/available')
  courierAvailable(@Headers('authorization') authorization?: string) { return this.ordersService.courierAvailable(authorization); }

  @Get('courier/current')
  courierCurrent(@Headers('authorization') authorization?: string) { return this.ordersService.courierCurrent(authorization); }

  @Patch(':id/courier/accept')
  courierAccept(@Param('id') id: string, @Headers('authorization') authorization?: string) { return this.ordersService.courierAccept(id, authorization); }

  @Patch(':id/courier/status')
  courierStatus(
    @Param('id') id: string,
    @Body() body: { status: string; pin?: string },
    @Headers('authorization') authorization?: string,
  ) {
    return this.ordersService.courierStatus(
      id,
      body.status,
      body.pin,
      authorization,
    );
  }

  @Patch('courier/online')
  courierOnline(@Body() body: { online: boolean }, @Headers('authorization') authorization?: string) { return this.ordersService.courierOnline(body.online, authorization); }
}
