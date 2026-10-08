import { RealtimeGateway } from '../realtime/realtime.gateway.js';
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateProductDto } from './dto/create-product.dto.js';

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService, private readonly realtime?: RealtimeGateway) {}

  async store() {
    const config = await this.prisma.deliveryPricingConfig.findUnique({ where: { id: 'default' }, select: { storeOpen: true, storeMessage: true, updatedAt: true } });
    return config ?? { storeOpen: true, storeMessage: 'Voltaremos em breve. Sua sacola continua salva.' };
  }

  categories() {
    return this.prisma.category.findMany({ where: { active: true, archived: false }, select: { id: true, name: true, imageUrl: true, position: true, active: true, updatedAt: true }, orderBy: [{ position: 'asc' }, { name: 'asc' }] });
  }

  findAll() {
    return this.prisma.product.findMany({
      where: { active: true, archived: false, category: { active: true, archived: false } },
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

    const result = await this.prisma.product.create({
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
    this.realtime?.emitCatalogUpdated();
    return result;
  }
}
