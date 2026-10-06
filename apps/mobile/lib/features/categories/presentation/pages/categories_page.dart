import 'package:flutter/material.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  static const data = [
    ('Cervejas', 'Geladas, packs e especiais', Icons.sports_bar_rounded, Color(0xFFFFE3A3)),
    ('Whiskies', 'Clássicos & premium', Icons.liquor_rounded, Color(0xFFFFD8C5)),
    ('Gin & Vodka', 'Para drinks perfeitos', Icons.local_bar_rounded, Color(0xFFD9F3ED)),
    ('Vinhos', 'Brancos, tintos & rosés', Icons.wine_bar_rounded, Color(0xFFFFDEE5)),
    ('Sem álcool', 'Refresque sem álcool', Icons.local_drink_rounded, Color(0xFFDDEEFF)),
    ('Gelo & extras', 'Tudo para não parar', Icons.ac_unit_rounded, Color(0xFFE9E4FF)),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: RefreshIndicator(
      onRefresh: AppState.instance.loadProducts,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Descobrir', style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 5),
                        const Text(
                          'Seu clima, sua bebida.',
                          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAll(context),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 18),
            sliver: SliverToBoxAdapter(child: _Occasions()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _Category(data: data[i], onTap: () => _showCategory(context, data[i].$1)),
                childCount: data.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .94,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    ),
  );
}

class _Occasions extends StatelessWidget {
  const _Occasions();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF007C70), Color(0xFF12B5A3)]),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COMBINA COM HOJE', style: TextStyle(color: Color(0xFFCFF8F0), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text('Qual é o seu rolê?', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.6)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('Praia', Icons.beach_access_rounded),
            _chip('Churrasco', Icons.outdoor_grill_rounded),
            _chip('Festa', Icons.celebration_rounded),
            _chip('Relax', Icons.nights_stay_rounded),
          ],
        ),
      ],
    ),
  );

  Widget _chip(String s, IconData i) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(s, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _Category extends StatelessWidget {
  const _Category({required this.data, required this.onTap});
  final (String, String, IconData, Color) data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(25),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE9ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: data.$4, borderRadius: BorderRadius.circular(20)),
              child: Icon(data.$3, size: 48, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 12),
          Text(data.$1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(
            data.$2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

void _showCategory(BuildContext context, String label) {
  final normalized = label.toLowerCase();
  final products = AppState.instance.products.where((p) {
    final category = (p['category']?['name'] ?? '').toString().toLowerCase();
    if (normalized == 'cervejas') return category.contains('cervej');
    if (normalized == 'whiskies') return category.contains('whisk');
    if (normalized == 'gin & vodka') return category.contains('gin') || category.contains('vodka');
    if (normalized == 'vinhos') return category.contains('vinh');
    if (normalized == 'sem álcool') return category.contains('sem') || category.contains('refriger') || category.contains('água') || category.contains('agua');
    if (normalized == 'gelo & extras') return category.contains('gelo') || category.contains('extra');
    return category.contains(normalized);
  }).toList();

  _productSheet(context, label, products);
}

void _showAll(BuildContext context) {
  _productSheet(context, 'Todos os produtos', AppState.instance.products);
}

void _productSheet(BuildContext context, String title, List<dynamic> products) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .5,
      maxChildSize: .94,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 18),
              decoration: BoxDecoration(color: const Color(0xFFD3D9D6), borderRadius: BorderRadius.circular(10)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900))),
                  Text(
                    products.length.toString() + ' itens',
                    style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('Nenhum produto disponível nesta categoria.', style: TextStyle(color: AppColors.muted)))
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                      itemBuilder: (_, i) => _ProductRow(product: products[i]),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});
  final dynamic product;

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(product['price'].toString()) ?? 0;
    final image = (product['imageUrl'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9ECE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(17)),
            child: image.isEmpty
                ? const Icon(Icons.local_drink_rounded, color: AppColors.oceanDeep)
                : Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.local_drink_rounded, color: AppColors.oceanDeep),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((product['name'] ?? '').toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'R\$ ' + price.toStringAsFixed(2).replaceAll('.', ','),
                  style: const TextStyle(color: AppColors.oceanDeep, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => AppState.instance.addProduct(product['id'].toString()),
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
