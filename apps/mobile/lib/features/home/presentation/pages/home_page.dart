import 'package:flutter/material.dart';
import '../../../../core/widgets/prime_brand.dart';

import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_category_tile.dart';
import '../../../../core/widgets/prime_product_card.dart';
import '../../../../core/widgets/prime_ui.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: AnimatedBuilder(
      animation: AppState.instance,
      builder: (_, __) {
        final state = AppState.instance;
        final products = state.products;
        final categories = _categories(state.catalogCategories);
        final featured = products.take(8).toList();
        final recommended = products.length > 4
            ? products.skip(4).take(8).toList()
            : products;

        return RefreshIndicator(
          onRefresh: state.loadProducts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              if (state.storeStatusKnown && !state.storeOpen)
                SliverToBoxAdapter(
                  child: Center(child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppControl.maxContentWidth),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: const Color(0xFFFFF5DF), borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Loja fechada no momento', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF654D21))),
                        const SizedBox(height: 6),
                        Text(state.storeMessage.replaceAll('Sua sacola', 'Seu carrinho').replaceAll('sua sacola', 'seu carrinho'), style: const TextStyle(color: Color(0xFF654D21), height: 1.5)),
                      ]),
                    ),
                  )),
                ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        14,
                        AppSpacing.lg,
                        0,
                      ),
                      child: _Header(state: state),
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        16,
                        AppSpacing.lg,
                        0,
                      ),
                      child: PrimeSearchField(
                        readOnly: true,
                        onTap: () => AppNav.instance.go(1),
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        24,
                        AppSpacing.lg,
                        10,
                      ),
                      child: PrimeSectionHeader(
                        title: 'O que você procura?',
                        actionLabel: 'Ver tudo',
                        onAction: () => AppNav.instance.go(1),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: _CategoryGrid(categories: categories),
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        14,
                        AppSpacing.lg,
                        0,
                      ),
                      child: _Hero(onTap: () => AppNav.instance.go(1)),
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        26,
                        AppSpacing.lg,
                        10,
                      ),
                      child: const PrimeSectionHeader(
                        title: 'Escolha e adicione',
                        subtitle: 'Seus produtos, a um toque do carrinho.',
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _HorizontalProducts(
                  products: featured,
                  loading: products.isEmpty,
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        26,
                        AppSpacing.lg,
                        10,
                      ),
                      child: const PrimeSectionHeader(
                        title: 'Para o seu momento',
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: _Moments()),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        26,
                        AppSpacing.lg,
                        10,
                      ),
                      child: const PrimeSectionHeader(
                        title: 'Continue explorando',
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _HorizontalProducts(
                  products: recommended,
                  loading: products.isEmpty,
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        26,
                        AppSpacing.lg,
                        128,
                      ),
                      child: _PrimePromise(onTap: () => AppNav.instance.go(1)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  static List<String> _categories(List<dynamic> categories) {
    return categories.map((category) => (category['name'] ?? '').toString().trim()).where((name) => name.isNotEmpty).take(10).toList();
  }

}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    String address = 'Porto Seguro';
    if (state.isCustomer && state.addresses.isNotEmpty) {
      final selected = state.addresses.firstWhere(
        (a) => a['isDefault'] == true,
        orElse: () => state.addresses.first,
      );
      final street = (selected['street'] ?? '').toString();
      final number = (selected['number'] ?? '').toString();
      if (street.isNotEmpty) {
        address = number.isEmpty ? street : street + ', ' + number;
      }
    }

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => AppNav.instance.go(3),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const PrimeBrandMark(size: 44),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ENTREGAR EM',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.ocean600,
                                  letterSpacing: 1.1,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                AppIcons.mapPin,
                                size: 14,
                                color: AppColors.ink,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(AppIcons.chevronDown, size: 14),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimeIconButton(
              icon: AppIcons.bag,
              badgeCount: state.cartCount,
              semanticLabel: 'Abrir carrinho',
              onPressed: () => AppNav.instance.go(2),
            ),
            const SizedBox(width: 8),
            PrimeIconButton(
              icon: AppIcons.user,
              semanticLabel: 'Abrir perfil',
              background: AppColors.ocean900,
              foreground: Colors.white,
              onPressed: () => AppNav.instance.go(3),
            ),
          ],
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
 const _Hero({required this.onTap});
 final VoidCallback onTap;
 @override
 Widget build(BuildContext context) => Material(
  color: AppColors.ocean900, borderRadius: BorderRadius.circular(24),
  clipBehavior: Clip.antiAlias,
  child: InkWell(onTap: onTap, child: Stack(children: [
   const Positioned.fill(child: PrimeCoastArtwork()),
   Padding(padding: const EdgeInsets.all(20), child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
     const Text('SEU MOMENTO, SEM PAUSA', style: TextStyle(color: AppColors.ocean300,
      fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
     const SizedBox(height: 10),
     Text('O melhor de Porto.\nNa sua porta.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: Colors.white, fontSize: 26, height: 1.15, letterSpacing: -.8)),
     const SizedBox(height: 12),
     const Text('Explorar o catálogo →', style: TextStyle(color: AppColors.sun500,
      fontSize: 13, fontWeight: FontWeight.w800)),
    ])),
    const SizedBox(width: 12),
    Container(width: 54, height: 54, decoration: BoxDecoration(
     color: AppColors.sun500, borderRadius: BorderRadius.circular(18)),
     child: const Icon(AppIcons.cart, size: 28, color: AppColors.ocean900)),
   ])),
  ])),
 );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<String> categories;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final width = constraints.maxWidth;
      final columns = AppResponsive.categoryColumns(width);
      final visible = categories.take(10).toList();
      final rows = (visible.length / columns).ceil();
      final tileHeight = AppResponsive.categoryHeight(context);

      return SizedBox(
        height: rows * tileHeight + (rows - 1).clamp(0, rows) * AppSpacing.xs,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: visible.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: tileHeight,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisSpacing: AppSpacing.xs,
          ),
          itemBuilder: (_, index) {
            final name = visible[index];
            return PrimeCategoryTile(
              name: name,
              compact: width < 390,
              onTap: () {
                AppState.instance.selectCatalogCategory(name);
                AppNav.instance.go(1);
              },
            );
          },
        ),
      );
    },
  );
}

class _HorizontalProducts extends StatelessWidget {
  const _HorizontalProducts({required this.products, required this.loading});

  final List<dynamic> products;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppResponsive.productHeight(context, 184),
    child: loading
        ? ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, __) => const SizedBox(
              width: 184,
              child: Column(
                children: [
                  PrimeSkeleton(height: 170, radius: AppRadius.lg),
                  SizedBox(height: 10),
                  PrimeSkeleton(height: 16),
                  SizedBox(height: 7),
                  PrimeSkeleton(height: 14, width: 110),
                ],
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => SizedBox(
              width: 184,
              child: PrimeProductCard(product: products[i]),
            ),
          ),
  );
}

class _Moments extends StatelessWidget {
  const _Moments();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 110,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        _Moment(
          title: 'Pé na areia',
          subtitle: 'Geladas para a praia',
          icon: AppIcons.waves,
          color: AppColors.sand100,
        ),
        const SizedBox(width: AppSpacing.sm),
        _Moment(
          title: 'Churrasco',
          subtitle: 'Combos sem erro',
          icon: AppIcons.packageOpen,
          color: AppColors.coral100,
        ),
        const SizedBox(width: AppSpacing.sm),
        _Moment(
          title: 'Fim de tarde',
          subtitle: 'Vinhos & destilados',
          icon: AppIcons.wine,
          color: AppColors.ocean100,
        ),
      ],
    ),
  );
}

class _Moment extends StatelessWidget {
  const _Moment({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    child: InkWell(
      onTap: () => AppNav.instance.go(1),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        width: 184,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 21, color: AppColors.ink),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: AppFontWeight.display),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PrimePromise extends StatelessWidget {
  const _PrimePromise({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Ink(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.ocean50,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(
                AppIcons.sparkles,
                color: AppColors.ocean700,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Porto Prime, do seu jeito.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Catálogo simples, pagamento seguro e acompanhamento do pedido em tempo real.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              AppIcons.chevronRight,
              color: AppColors.ocean700,
              size: 19,
            ),
          ],
        ),
      ),
    ),
  );
}

