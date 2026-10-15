import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';

// Called only after requireAdmin. Products and financial/order records are preserved.
export async function deleteCatalogCategory(prisma: any, id: string, body: Record<string, any>) {
  const targetId = typeof body.targetCategoryId === 'string' ? body.targetCategoryId.trim() : '';
  if (targetId === id) throw new BadRequestException('Escolha outra categoria para receber os produtos');
  try {
    return await prisma.$transaction(async (tx: any) => {
      const category = await tx.category.findUnique({ where: { id }, select: { id: true, name: true } });
      if (!category) throw new NotFoundException('Categoria não encontrada');
      const count = await tx.product.count({ where: { categoryId: id } });
      if (count > 0) {
        if (!targetId) throw new BadRequestException('Selecione uma categoria de destino para preservar os produtos');
        const target = await tx.category.findUnique({ where: { id: targetId } });
        if (!target || target.archived) throw new BadRequestException('Selecione uma categoria de destino não arquivada');
        await tx.product.updateMany({ where: { categoryId: id }, data: { categoryId: targetId } });
      }
      await tx.category.delete({ where: { id } });
      return { deleted: true, id, name: category.name, movedProducts: count, targetCategoryId: count ? targetId : null };
    }, { isolationLevel: 'Serializable' });
  } catch (error: any) {
    if (error?.code === 'P2003' || error?.code === 'P2034') {
      throw new ConflictException('O catálogo mudou durante a exclusão. Atualize a lista e tente novamente');
    }
    throw error;
  }
}
