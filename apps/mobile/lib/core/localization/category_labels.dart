/// Curated catalogue labels only. Never used as category IDs or filter values.
/// Unknown custom names stay unchanged until an explicit translation is added.
abstract final class CategoryLabels {
  static String normalize(String value) => value.trim().toLowerCase()
    .replaceAll('&', 'e')
    .replaceAll(RegExp('[áàãâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[íìîï]'), 'i')
    .replaceAll(RegExp('[óòõôö]'), 'o')
    .replaceAll(RegExp('[úùûü]'), 'u')
    .replaceAll('ç', 'c').replaceAll(RegExp(r'\s+'), ' ');

  static const _places = {'porto seguro', 'porto seguro - ba', 'porto seguro/ba',
    'porto seguro / ba', 'bahia', 'porto prime', 'porto prime delivery'};
  static String? translate(String value, String language) {
    final key = normalize(value);
    if (_places.contains(key)) return value;
    final pair = _labels[key];
    if (pair == null || !['es', 'en'].contains(language)) return null;
    return pair[language == 'es' ? 0 : 1];
  }
  static const Map<String, List<String>> _labels = {
    'cerveja': ['Cerveza', 'Beer'],
    'cervejas': ['Cervezas', 'Beer'],
    'cervejas especiais': ['Cervezas especiales', 'Specialty beer'],
    'cervejas artesanais': ['Cervezas artesanales', 'Craft beer'],
    'churrasco': ['Parrilla', 'Barbecue'],
    'churrasco e carnes': ['Parrilla y carnes', 'Barbecue & meat'],
    'carnes e churrasco': ['Carnes y parrilla', 'Meat & barbecue'],
    'carne': ['Carne', 'Meat'],
    'carnes': ['Carnes', 'Meat'],
    'acougue': ['Carnicería', 'Butcher'],
    'fitness': ['Fitness', 'Fitness'],
    'fitness e suplementos': ['Fitness y suplementos', 'Fitness & supplements'],
    'suplementos': ['Suplementos', 'Supplements'],
    'vinho': ['Vino', 'Wine'],
    'vinhos': ['Vinos', 'Wine'],
    'energetico': ['Bebida energética', 'Energy drink'],
    'energeticos': ['Bebidas energéticas', 'Energy drinks'],
    'gelo': ['Hielo', 'Ice'],
    'destilado': ['Destilado', 'Spirit'],
    'destilados': ['Destilados', 'Spirits'],
    'ofertas': ['Ofertas', 'Offers'],
    'promocoes': ['Promociones', 'Special offers'],
    'bebidas': ['Bebidas', 'Drinks'],
    'bebidas alcoolicas': ['Bebidas alcohólicas', 'Alcoholic drinks'],
    'bebidas sem alcool': ['Bebidas sin alcohol', 'Non-alcoholic drinks'],
    'sem alcool': ['Sin alcohol', 'Alcohol-free'],
    'refrigerante': ['Refresco', 'Soft drink'],
    'refrigerantes': ['Refrescos', 'Soft drinks'],
    'refrigerantes e sucos': ['Refrescos y jugos', 'Soft drinks & juices'],
    'suco': ['Jugo', 'Juice'],
    'sucos': ['Jugos', 'Juices'],
    'agua': ['Agua', 'Water'],
    'aguas': ['Aguas', 'Water'],
    'agua e gelo': ['Agua y hielo', 'Water & ice'],
    'aguas e gelo': ['Agua y hielo', 'Water & ice'],
    'agua mineral': ['Agua mineral', 'Mineral water'],
    'agua de coco': ['Agua de coco', 'Coconut water'],
    'drinks': ['Cócteles', 'Cocktails'],
    'coqueteis': ['Cócteles', 'Cocktails'],
    'combos': ['Combos', 'Bundles'],
    'kits': ['Kits', 'Kits'],
    'conveniencia': ['Conveniencia', 'Convenience'],
    'mercearia': ['Despensa', 'Groceries'],
    'petiscos': ['Aperitivos', 'Snacks'],
    'salgadinhos': ['Snacks salados', 'Savory snacks'],
    'lanches': ['Bocadillos', 'Snacks & sandwiches'],
    'pizzas': ['Pizzas', 'Pizza'],
    'frutas': ['Frutas', 'Fruit'],
    'verduras': ['Verduras', 'Leafy greens'],
    'legumes': ['Hortalizas', 'Vegetables'],
    'hortifruti': ['Frutas y verduras', 'Fresh produce'],
    'frutas e verduras': ['Frutas y verduras', 'Fruit & vegetables'],
    'peixes': ['Pescados', 'Fish'],
    'frutos do mar': ['Mariscos', 'Seafood'],
    'padaria': ['Panadería', 'Bakery'],
    'paes': ['Panes', 'Bread'],
    'cafe': ['Café', 'Coffee'],
    'cafes': ['Cafés', 'Coffee'],
    'laticinios': ['Lácteos', 'Dairy'],
    'leite e derivados': ['Leche y lácteos', 'Milk & dairy'],
    'doces': ['Dulces', 'Sweets'],
    'sobremesas': ['Postres', 'Desserts'],
    'chocolates': ['Chocolates', 'Chocolate'],
    'sorvetes': ['Helados', 'Ice cream'],
    'congelados': ['Congelados', 'Frozen food'],
    'veganos': ['Veganos', 'Vegan'],
    'vegetarianos': ['Vegetarianos', 'Vegetarian'],
    'farmacia': ['Farmacia', 'Pharmacy'],
    'pets': ['Mascotas', 'Pets'],
    'limpeza': ['Limpieza', 'Cleaning'],
    'higiene': ['Higiene', 'Personal hygiene'],
    'beleza': ['Belleza', 'Beauty'],
    'bebe': ['Bebés', 'Baby'],
    'bebes': ['Bebés', 'Baby'],
    'outros': ['Otros', 'Other'],
  };
}
