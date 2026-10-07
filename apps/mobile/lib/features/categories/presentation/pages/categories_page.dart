import 'package:flutter/material.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_category_tile.dart';
import '../../../../core/widgets/prime_product_card.dart';
import '../../../../core/widgets/prime_ui.dart';

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
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: AnimatedBuilder(
      animation: AppState.instance,
      builder: (_, __) {
        final state = AppState.instance;
        final products = state.products;
        final categories = _categories(products);
        final query = search.text.trim().toLowerCase();
        final selected = state.catalogCategory;

        final filtered = products.where((product) {
          final name = (product['name'] ?? '').toString().toLowerCase();
          final description = (product['description'] ?? '')
              .toString()
              .toLowerCase();
          final category = (product['category']?['name'] ?? '').toString();
          final categoryMatches = selected == 'Todos' || category == selected;
          final searchMatches =
              query.isEmpty ||
              name.contains(query) ||
              description.contains(query) ||
              category.toLowerCase().contains(query);
          return categoryMatches && searchMatches;
        }).toList();

        return RefreshIndicator(
          onRefresh: state.loadProducts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Buscar',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Encontre rápido o que combina com o seu momento.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.ocean900,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                              AppIcons.sparkles,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: PrimeSearchField(
                        controller: search,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                      child: const PrimeSectionHeader(
                        eyebrow: 'CATEGORIAS',
                        title: 'Escolha por tipo',
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _CategoryGrid(
                        categories: categories,
                        selected: selected,
                        onSelect: state.selectCatalogCategory,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: PrimeSectionHeader(
                        eyebrow: selected == 'Todos'
                            ? 'CATÁLOGO'
                            : selected.toUpperCase(),
                        title: query.isEmpty
                            ? (selected == 'Todos'
                                  ? 'Todos os produtos'
                                  : selected)
                            : 'Resultados',
                        subtitle:
                            filtered.length.toString() +
                            (filtered.length == 1
                                ? ' item encontrado'
                                : ' itens encontrados'),
                      ),
                    ),
                  ),
                ),
              ),
              if (state.products.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _CatalogSkeleton(),
                  ),
                )
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: PrimeEmptyState(
                          icon: AppIcons.search,
                          title: 'Nada por aqui',
                          message:
                              'Tente outro termo ou escolha uma categoria diferente.',
                          actionLabel: 'Limpar filtros',
                          onAction: () {
                            search.clear();
                            state.selectCatalogCategory('Todos');
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 124),
                  sliver: SliverLayoutBuilder(
                    builder: (_, constraints) {
                      final width = constraints.crossAxisExtent;
                      final columns = AppResponsive.productColumns(width);
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => PrimeProductCard(product: filtered[i]),
                          childCount: filtered.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: AppResponsive.productHeight(
                            context,
                            (width - (columns - 1) * 12) / columns,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );

  List<String> _categories(List<dynamic> products) {
    final names = <String>['Todos'];
    for (final product in products) {
      final value = (product['category']?['name'] ?? '').toString().trim();
      if (value.isNotEmpty && !names.contains(value)) names.add(value);
    }
    return names;
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final width = constraints.maxWidth;
      final columns = AppResponsive.categoryColumns(width);
      final rows = (categories.length / columns).ceil();
      final height = AppResponsive.categoryHeight(context);

      return SizedBox(
        height: rows * height + (rows - 1).clamp(0, rows) * AppSpacing.xs,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: height,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisSpacing: AppSpacing.xs,
          ),
          itemBuilder: (_, i) => PrimeCategoryTile(
            name: categories[i],
            selected: selected == categories[i],
            compact: width < 390,
            onTap: () => onSelect(categories[i]),
          ),
        ),
      );
    },
  );
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final columns = constraints.maxWidth >= 520 ? 3 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: AppResponsive.productHeight(
            context,
            (constraints.maxWidth - (columns - 1) * 12) / columns,
          ),
        ),
        itemBuilder: (_, __) =>
            const PrimeSkeleton(height: 260, radius: AppRadius.lg),
      );
    },
  );
}
