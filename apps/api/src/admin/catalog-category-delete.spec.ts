import { describe, it, expect } from 'vitest';
import { deleteCatalogCategory } from './catalog-category-delete.js';

function fixture(options: { empty?: boolean, archived?: boolean, fail?: string } = {}) {
  let categories = [{ id: 'source', name: 'Churrasco', archived: false }, { id: 'target', name: 'Alimentos', archived: Boolean(options.archived) }];
  let products = options.empty ? [] : [{ id: 'p1', categoryId: 'source', price: 20 }, { id: 'p2', categoryId: 'source', price: 40 }];
  return {
    categories: () => categories, products: () => products,
    $transaction: async (run: any, config: any) => {
      expect(config.isolationLevel).toBe('Serializable');
      const backup = structuredClone({ categories, products });
      try {
        return await run({
          category: {
            findUnique: async ({ where }: any) => categories.find(c => c.id === where.id) || null,
            delete: async ({ where }: any) => {
              if (options.fail) throw { code: options.fail };
              categories = categories.filter(c => c.id !== where.id);
            },
          },
          product: {
            count: async ({ where }: any) => products.filter(p => p.categoryId === where.categoryId).length,
            updateMany: async ({ where, data }: any) => { products = products.map(p => p.categoryId === where.categoryId ? { ...p, ...data } : p); },
          },
        });
      } catch (error) { categories = backup.categories; products = backup.products; throw error; }
    },
  };
}

describe('Category deletion preserves products', () => {
  it('deletes an empty category', async () => {
    const db = fixture({ empty: true });
    expect(await deleteCatalogCategory(db, 'source', {})).toMatchObject({ deleted: true, movedProducts: 0 });
    expect(db.categories().map(c => c.id)).toEqual(['target']);
  });
  it('moves all products without changing their IDs or prices', async () => {
    const db = fixture();
    expect(await deleteCatalogCategory(db, 'source', { targetCategoryId: 'target' })).toMatchObject({ movedProducts: 2 });
    expect(db.products()).toEqual([{ id: 'p1', categoryId: 'target', price: 20 }, { id: 'p2', categoryId: 'target', price: 40 }]);
  });
  it.each(['', 'source', 'missing'])('rejects invalid destination %s without deleting products', async targetCategoryId => {
    const db = fixture();
    await expect(deleteCatalogCategory(db, 'source', { targetCategoryId })).rejects.toThrow();
    expect(db.products().every(p => p.categoryId === 'source')).toBe(true);
    expect(db.categories()).toHaveLength(2);
  });
  it('rejects an archived destination', async () => {
    await expect(deleteCatalogCategory(fixture({ archived: true }), 'source', { targetCategoryId: 'target' })).rejects.toThrow();
  });
  it('rejects missing source', async () => {
    await expect(deleteCatalogCategory(fixture(), 'missing', {})).rejects.toThrow();
  });
  it.each(['P2003', 'P2034'])('rolls back product transfers after %s', async fail => {
    const db = fixture({ fail });
    await expect(deleteCatalogCategory(db, 'source', { targetCategoryId: 'target' })).rejects.toThrow('O catálogo mudou');
    expect(db.products().every(p => p.categoryId === 'source')).toBe(true);
    expect(db.categories()).toHaveLength(2);
  });
});
