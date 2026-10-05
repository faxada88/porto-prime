import { Body, Controller, Delete, Get, Headers, Param, Patch, Post } from '@nestjs/common';
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
  @Patch(':id')
  update(@Param('id') id: string, @Body() body: CreateAddressDto, @Headers('authorization') authorization?: string) { return this.addressesService.update(id, body, authorization); }

  @Delete(':id')
  remove(@Param('id') id: string, @Headers('authorization') authorization?: string) { return this.addressesService.remove(id, authorization); }
}
