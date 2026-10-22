import 'package:flutter/material.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/catalogue_cart_shortcut.dart';
import '../../../../core/widgets/prime_category_3d.dart';
import '../../../../core/widgets/prime_product_card.dart';

Future<void> openProductCatalogue(BuildContext context, {required String category}) async {
  AppState.instance.selectCatalogCategory(category);
  await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => Scaffold(
    backgroundColor: Colors.white,
    body: CategoriesPage(categoryName: category),
  )));
}

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key, required this.categoryName});
  final String categoryName;
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final search = TextEditingController();
  @override
  void dispose() { search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: AnimatedBuilder(
      animation: Listenable.merge([AppState.instance, AppLanguage.instance]),
      builder: (context, _) {
        final state = AppState.instance;
        final category = widget.categoryName;
        final matches = state.catalogCategories.where((c) => c['name'] == category);
        final iconKey = matches.isEmpty ? null : matches.first['iconKey']?.toString();
        final visual = AppIcons.categoryVisual(category, iconKey: iconKey);
        final query = search.text.trim().toLowerCase();
        final products = state.products.where((p) =>
          p['category']?['name'] == category &&
          (query.isEmpty || '${p['name']} ${p['description'] ?? ''}'.toLowerCase().contains(query))
        ).toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(children: [
              IconButton(tooltip: translateLabel('Voltar'), onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink)),
              const Spacer(),
              PrimeText('${products.length} ${AppLanguage.instance.translate(products.length == 1 ? 'produto' : 'produtos')}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
            ]),
          ),
          Expanded(child: RefreshIndicator(
            onRefresh: state.loadProducts,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(child: Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Container(width: 64, height: 64, padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: visual.background, borderRadius: BorderRadius.circular(22)),
                          child: PrimeCategory3D(iconKey: visual.key, fallback: Icon(visual.icon, color: visual.foreground, size: 32))),
                        const SizedBox(width: 16),
                        Expanded(child: PrimeText(category, style: const TextStyle(
                          fontSize: 28, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -.7, color: AppColors.ink))),
                      ]),
                      const SizedBox(height: 24),
                      TextField(controller: search, onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        decoration: PrimeInputDecoration(
                          hintText: 'Buscar em ${AppLanguage.instance.translate(category)}',
                          prefixIcon: const Icon(AppIcons.search, size: 21, color: AppColors.muted),
                          suffixIcon: query.isEmpty ? null : IconButton(
                            tooltip: translateLabel('Limpar busca'), icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () { search.clear(); setState(() {}); }),
                          filled: true, fillColor: AppColors.ocean50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.stroke)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.stroke)),
                        )),
                    ]),
                  ),
                ))),
                if (products.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(color: AppColors.ocean50, shape: BoxShape.circle),
                        child: Icon(query.isEmpty ? visual.icon : AppIcons.search, size: 32, color: visual.foreground)),
                      const SizedBox(height: 20),
                      const PrimeText('Nada por aqui', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 8),
                      PrimeText(query.isEmpty ? 'Nenhum produto disponível nesta categoria.' : 'Tente outro termo.',
                        textAlign: TextAlign.center, style: const TextStyle(height: 1.5, color: AppColors.muted)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: () {
                        if (query.isEmpty) { state.loadProducts(); } else { search.clear(); setState(() {}); }
                      }, child: PrimeText(query.isEmpty ? 'Atualizar' : 'Limpar busca')),
                    ]),
                  ))
                else
                  SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    sliver: SliverLayoutBuilder(builder: (context, constraints) {
                      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                      final columns = scale > 1.6 && constraints.crossAxisExtent < 600 ? 1 :
                        constraints.crossAxisExtent >= 900 ? 4 : constraints.crossAxisExtent >= 600 ? 3 : 2;
                      final width = (constraints.crossAxisExtent - (columns - 1) * 14) / columns;
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate((_, i) => PrimeProductCard(product: products[i], referenceStyle: true),
                          childCount: products.length),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns, crossAxisSpacing: 14, mainAxisSpacing: 16,
                          mainAxisExtent: width / .84 + 190 + (scale - 1).clamp(0, 2) * 200),
                      );
                    })),
              ],
            ),
          )),
          const CatalogueCartShortcut(),
        ]);
      },
    ),
  );
}
