import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_category_tile.dart';
import '../../../../core/widgets/prime_product_card.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppState.instance,
    builder: (_, __) {
      final s = AppState.instance;
      final categories = s.products
          .map((p) => (p['category']?['name'] ?? 'Outros').toString())
          .toSet()
          .toList()
        ..sort();
      final selected = categories.contains(s.catalogCategory) ? s.catalogCategory : 'Todos';
      final q = search.text.toLowerCase().trim();
      final products = s.products.where((p) {
        final cat = (p['category']?['name'] ?? 'Outros').toString();
        final name = (p['name'] ?? '').toString().toLowerCase();
        return (selected == 'Todos' || cat == selected) &&
            (q.isEmpty || name.contains(q) || cat.toLowerCase().contains(q));
      }).toList();

      return SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: s.loadProducts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(child: _Header(count: s.products.length)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    controller: search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar no catálogo',
                      prefixIcon: const Icon(Symbols.search_rounded, size: 22),
                      suffixIcon: q.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Symbols.close_rounded),
                            ),
                    ),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                sliver: SliverToBoxAdapter(child: _SectionTitle(title: 'Categorias', subtitle: 'Encontre rápido o que você procura')),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final columns = box.maxWidth >= 700 ? 6 : box.maxWidth >= 390 ? 5 : 4;
                      final all = <String>['Todos', ...categories];
                      final gap = box.maxWidth < 350 ? 7.0 : 9.0;
                      final width = (box.maxWidth - gap * (columns - 1)) / columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: all.map((name) {
                          return SizedBox(
                            width: width,
                            height: width * 1.25,
                            child: name == 'Todos'
                                ? _AllTile(
                                    selected: selected == 'Todos',
                                    onTap: () => s.selectCatalogCategory('Todos'),
                                  )
                                : PrimeCategoryTile(
                                    name: name,
                                    selected: selected == name,
                                    compact: true,
                                    onTap: () => s.selectCatalogCategory(name),
                                  ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 27, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _SectionTitle(
                          title: selected == 'Todos' ? 'Todos os produtos' : selected,
                          subtitle: q.isEmpty ? 'Seleção Porto Prime' : 'Resultados da busca',
                        ),
                      ),
                      Text(
                        '${products.length} itens',
                        style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              if (s.products.isEmpty && s.error == null)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: _CatalogSkeleton()),
                )
              else if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Empty(
                    hasError: s.error != null,
                    onRetry: s.loadProducts,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.crossAxisExtent;
                      final columns = w >= 900 ? 4 : w >= 620 ? 3 : 2;
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => PrimeProductCard(
                            product: products[i],
                            onOpen: () => _details(context, products[i]),
                          ),
                          childCount: products.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: w < 370 ? .67 : .72,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descobrir', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 5),
            Text(
              count == 0 ? 'Preparando o catálogo...' : '$count produtos para o seu momento.',
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Symbols.explore_rounded, color: AppColors.oceanDeep, weight: 550),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
    ],
  );
}

class _AllTile extends StatelessWidget {
  const _AllTile({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => PrimeCategoryTile(
    name: 'Todos',
    selected: selected,
    compact: true,
    onTap: onTap,
  );
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 4,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: .72,
    ),
    itemBuilder: (_, __) => Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.stroke)),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(child: Container(decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(18)))),
          const SizedBox(height: 10),
          Container(height: 11, decoration: BoxDecoration(color: AppColors.stroke, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 7),
          Align(alignment: Alignment.centerLeft, child: Container(width: 80, height: 10, decoration: BoxDecoration(color: AppColors.stroke, borderRadius: BorderRadius.circular(8)))),
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasError, required this.onRetry});
  final bool hasError;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(23)),
            child: Icon(hasError ? Symbols.cloud_off_rounded : Symbols.search_off_rounded, color: AppColors.oceanDeep, size: 32),
          ),
          const SizedBox(height: 15),
          Text(hasError ? 'Não foi possível carregar o catálogo.' : 'Nenhum produto encontrado.', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 12),
          if (hasError) FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    ),
  );
}

void _details(BuildContext context, dynamic p) {
  final price = double.tryParse(p['price'].toString()) ?? 0;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (c) => Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.stroke, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 18),
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(25)),
              alignment: Alignment.center,
              child: p['imageUrl'] != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.network(p['imageUrl'], fit: BoxFit.contain, width: double.infinity, height: 190))
                  : const Icon(Symbols.local_drink_rounded, size: 76, color: AppColors.oceanDeep),
            ),
            const SizedBox(height: 18),
            Text(p['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.5)),
            const SizedBox(height: 5),
            Text(p['description'] ?? 'Selecionado para chegar gelado e rápido até você.', style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Text('R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                FilledButton.icon(
                  onPressed: () {
                    AppState.instance.addProduct(p['id']);
                    Navigator.pop(c);
                  },
                  icon: const Icon(Symbols.add_rounded),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
