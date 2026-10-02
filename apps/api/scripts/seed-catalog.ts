import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma/client.js';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error('DATABASE_URL não configurada');

const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString }) });

const catalog = [
  { name: 'Cervejas', slug: 'cervejas', position: 1, products: [
    ['Heineken Long Neck 330ml','Cerveja lager premium, gelada e pronta para servir.',8.99,120],
    ['Stella Artois Long Neck 330ml','Lager premium de sabor equilibrado.',7.49,100],
    ['Budweiser Long Neck 330ml','American lager leve e refrescante.',6.99,100],
    ['Corona Extra 330ml','Cerveja leve para dias de praia.',9.49,90],
    ['Brahma Duplo Malte 350ml','Lata 350ml, refrescante e encorpada.',4.99,180],
  ]},
  { name: 'Whiskies', slug: 'whiskies', position: 2, products: [
    ['Johnnie Walker Red Label 1L','Blended Scotch Whisky.',109.90,30],
    ['Johnnie Walker Black Label 1L','Blended Scotch Whisky 12 anos.',189.90,24],
    ['Jack Daniel’s Old No. 7 1L','Tennessee whiskey clássico.',179.90,24],
    ['Ballantine’s Finest 1L','Blended Scotch Whisky.',99.90,30],
  ]},
  { name: 'Gins', slug: 'gins', position: 3, products: [
    ['Tanqueray London Dry 750ml','London Dry Gin clássico.',119.90,30],
    ['Bombay Sapphire 750ml','Gin aromático e equilibrado.',129.90,24],
    ['Beefeater London Dry 750ml','London Dry Gin cítrico.',109.90,24],
  ]},
  { name: 'Vodkas', slug: 'vodkas', position: 4, products: [
    ['Absolut Vodka 1L','Vodka sueca clássica.',89.90,35],
    ['Smirnoff Nº 21 998ml','Vodka clássica para drinks.',49.90,45],
  ]},
  { name: 'Vinhos', slug: 'vinhos', position: 5, products: [
    ['Casillero del Diablo Cabernet Sauvignon 750ml','Vinho tinto chileno.',69.90,30],
    ['Concha y Toro Reservado Merlot 750ml','Vinho tinto chileno macio.',44.90,36],
    ['Miolo Seleção Rosé 750ml','Vinho rosé brasileiro leve.',54.90,24],
  ]},
  { name: 'Refrigerantes', slug: 'refrigerantes', position: 6, products: [
    ['Coca-Cola Original 2L','Refrigerante Coca-Cola 2 litros.',12.99,120],
    ['Coca-Cola Sem Açúcar 2L','Coca-Cola Zero 2 litros.',12.99,100],
    ['Guaraná Antarctica 2L','Refrigerante de guaraná 2 litros.',10.99,100],
    ['Sprite 2L','Refrigerante sabor limão 2 litros.',10.99,80],
  ]},
  { name: 'Energéticos', slug: 'energeticos', position: 7, products: [
    ['Red Bull Energy Drink 250ml','Energético em lata 250ml.',10.99,80],
    ['Monster Energy 473ml','Energético em lata 473ml.',12.99,70],
  ]},
  { name: 'Águas e Gelo', slug: 'aguas-e-gelo', position: 8, products: [
    ['Água Mineral sem Gás 500ml','Água mineral gelada.',3.49,150],
    ['Água Mineral com Gás 500ml','Água mineral gaseificada.',3.99,100],
    ['Gelo Filtrado 5kg','Saco de gelo filtrado.',14.90,60],
  ]},
  { name: 'Conveniência', slug: 'conveniencia', position: 9, products: [
    ['Carvão Vegetal 3kg','Carvão para churrasco.',24.90,40],
    ['Copo Descartável 300ml 50un','Pacote com 50 copos.',12.90,50],
    ['Amendoim Torrado 150g','Petisco torrado e salgado.',8.90,60],
  ]},
];

async function main() {
  let products = 0;
  for (const c of catalog) {
    const category = await prisma.category.upsert({
      where: { slug: c.slug },
      update: { name: c.name, active: true, position: c.position },
      create: { name: c.name, slug: c.slug, active: true, position: c.position },
    });

    for (const [name, description, price, stock] of c.products) {
      const existing = await prisma.product.findFirst({ where: { categoryId: category.id, name: String(name) } });
      if (existing) {
        await prisma.product.update({ where: { id: existing.id }, data: { description: String(description), price: Number(price), stock: Number(stock), active: true } });
      } else {
        await prisma.product.create({ data: { categoryId: category.id, name: String(name), description: String(description), price: Number(price), stock: Number(stock), active: true } });
      }
      products++;
    }
  }
  console.log(`Catálogo carregado: ${catalog.length} categorias e ${products} produtos.`);
}

main().finally(async()=>prisma.$disconnect());
