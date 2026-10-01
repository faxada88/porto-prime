import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateProductDto } from './dto/create-product.dto.js';

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService) {}

  findAll() {
    return this.prisma.product.findMany({
      where: { active: true },
      include: { category: true },
      orderBy: [{ category: { position: 'asc' } }, { name: 'asc' }],
    });
  }

  async create(data: CreateProductDto) {
    const category = await this.prisma.category.findUnique({
      where: { id: data.categoryId },
      select: { id: true },
    });

    if (!category) {
      throw new NotFoundException('Categoria não encontrada');
    }

    return this.prisma.product.create({
      data: {
        categoryId: data.categoryId,
        name: data.name.trim(),
        description: data.description?.trim() || null,
        imageUrl: data.imageUrl || null,
        price: data.price,
        stock: data.stock,
      },
      include: { category: true },
    });
  }
}
