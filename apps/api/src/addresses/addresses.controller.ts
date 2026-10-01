import { Body, Controller, Get, Headers, Post } from '@nestjs/common';
import { AddressesService } from './addresses.service.js';
import { CreateAddressDto } from './dto/create-address.dto.js';

@Controller('addresses')
export class AddressesController {
  constructor(private readonly addressesService: AddressesService) {}

  @Get()
  list(@Headers('authorization') authorization?: string) {
    return this.addressesService.list(authorization);
  }

  @Post()
  create(@Body() body: CreateAddressDto, @Headers('authorization') authorization?: string) {
    return this.addressesService.create(body, authorization);
  }
}
