import { Body, Controller, Get, Header, Post } from '@nestjs/common';
import { CreateProductDto } from './dto/create-product.dto.js';
import { ProductsService } from './products.service.js';

@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  findAll() {
    return this.productsService.findAll();
  }

  @Get('categories')
  categories() { return this.productsService.categories(); }

  @Get('store')
  @Header('Cache-Control', 'no-store, max-age=0')
  store() { return this.productsService.store(); }

  @Post()
  create(@Body() body: CreateProductDto) {
    return this.productsService.create(body);
  }
}
