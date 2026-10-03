import { Body, Controller, Delete, Get, Headers, Post } from '@nestjs/common';
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
}
