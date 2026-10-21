import 'dart:async';
import 'package:flutter/material.dart';
import 'catalogue_cart_shortcut.dart';
import '../localization/prime_localization.dart';
import '../navigation/app_nav.dart';
import '../state/app_state.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Admin-selected products, with the same stock and cart operations as the catalogue.
class ProductShowcase extends StatefulWidget {
  const ProductShowcase({super.key, required this.products});
  final List<dynamic> products;
  @override
  State<ProductShowcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<ProductShowcase> with WidgetsBindingObserver {
  final controller = PageController();
  Timer? timer;
  int page = 0;
  bool foreground = true, dragging = false, paused = false;
  DateTime touched = DateTime.fromMillisecondsSinceEpoch(0);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || paused || !foreground || dragging || widget.products.length < 5 ||
          !controller.hasClients || AppNav.instance.index.value != 0 ||
          ModalRoute.of(context)?.isCurrent == false || MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context) || DateTime.now().difference(touched).inSeconds < 10 ||
          controller.position.isScrollingNotifier.value) return;
      move(1);
    });
  }
  void move(int direction) {
    if (!controller.hasClients || widget.products.isEmpty) return;
    final next = (page + direction) % ((widget.products.length + 3) ~/ 4);
    controller.animateToPage(next, duration: Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 1 : 480),
      curve: Curves.easeInOutCubic);
  }
  @override
  void didUpdateWidget(covariant ProductShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (page >= (widget.products.length + 3) ~/ 4) {
      page = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.hasClients) controller.jumpToPage(0);
      });
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { foreground = state == AppLifecycleState.resumed; }
  @override
  void dispose() {
    timer?.cancel(); controller.dispose(); WidgetsBinding.instance.removeObserver(this); super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();
    return AnimatedBuilder(animation: Listenable.merge([AppState.instance, AppLanguage.instance]),
      builder: (context, _) => LayoutBuilder(builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final count = (widget.products.length + 3) ~/ 4;
        final width = (box.maxWidth - 24) / 4;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.ocean50, shape: BoxShape.circle),
              child: const Icon(AppIcons.cart, color: AppColors.ocean800, size: 23)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const PrimeText('Vale levar junto', style: TextStyle(fontSize: 19, height: 1.2, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 4),
              const PrimeText('Produtos que combinam com o seu pedido', style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.muted)),
            ])),
            const SizedBox(width: 4),
            TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShowcaseProductsPage())),
              style: TextButton.styleFrom(backgroundColor: AppColors.ocean50, foregroundColor: AppColors.ocean800,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              child: const PrimeText('Ver todos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 18),
          SizedBox(height: width * 1.2 + 184 * scale, child: Listener(
            onPointerDown: (_) { dragging = true; touched = DateTime.now(); },
            onPointerUp: (_) { dragging = false; touched = DateTime.now(); },
            onPointerCancel: (_) { dragging = false; touched = DateTime.now(); },
            child: PageView.builder(controller: controller, itemCount: count,
              onPageChanged: (value) => setState(() => page = value),
              itemBuilder: (_, group) => Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var column = 0; column < 4; column++) ...[
                  if (column > 0) const SizedBox(width: 8),
                  Expanded(child: group * 4 + column < widget.products.length ?
                    ShowcaseProductTile(product: widget.products[group * 4 + column]) : const SizedBox.shrink()),
                ],
              ]),
            ),
          )),
          if (count > 1) Padding(padding: const EdgeInsets.only(top: 8), child: Row(
            mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(tooltip: translateLabel(paused ? 'Continuar apresentação' : 'Pausar apresentação'),
                onPressed: () => setState(() { paused = !paused; touched = DateTime.now(); }),
                icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18, color: AppColors.muted)),
              for (var i = 0; i < count; i++) AnimatedContainer(
                duration: const Duration(milliseconds: 220), margin: const EdgeInsets.symmetric(horizontal: 3),
                width: page == i ? 28 : 6, height: 6,
                decoration: BoxDecoration(color: page == i ? AppColors.ocean800 : AppColors.strokeStrong, borderRadius: BorderRadius.circular(6))),
              IconButton(tooltip: translateLabel('Próximo produto'), onPressed: () { touched = DateTime.now(); move(1); },
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.ocean800)),
            ],
          )),
        ]);
      }),
    );
  }
}

class ShowcaseProductTile extends StatelessWidget {
  const ShowcaseProductTile({super.key, required this.product});
  final dynamic product;
  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final id = product['id'].toString();
    final name = (product['name'] ?? 'Produto').toString();
    final category = (product['category']?['name'] ?? '').toString();
    final description = (product['description'] ?? '').toString();
    final url = (product['imageUrl'] ?? '').toString().trim();
    final price = double.tryParse('${product['price']}') ?? 0;
    final qty = state.cart[id] ?? 0;
    final available = state.storeStatusKnown && state.storeOpen && product['active'] != false &&
      (int.tryParse('${product['stock']}') ?? 0) > 0;
    final visual = AppIcons.categoryVisual(category, iconKey: product['category']?['iconKey']?.toString());
    return LayoutBuilder(builder: (context, box) {
      final compact = box.maxWidth < 120;
      final fallback = Center(child: Icon(visual.icon, size: compact ? 30 : 52, color: visual.foreground));
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke.withValues(alpha: .6))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(aspectRatio: .84, child: ColoredBox(color: visual.background,
            child: url.isEmpty ? fallback : Image.network(url, fit: BoxFit.cover, cacheWidth: 480,
              errorBuilder: (_, __, ___) => fallback))),
          Expanded(child: Padding(padding: EdgeInsets.all(compact ? 7 : 12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              PrimeText(category, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: compact ? 8 : 11, color: AppColors.muted)),
              const SizedBox(height: 5),
              PrimeText(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: compact ? 10.5 : 15, height: 1.2, fontWeight: FontWeight.w700, color: AppColors.ink)),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 5),
                PrimeText(description, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: compact ? 8.5 : 11, height: 1.3, color: AppColors.muted)),
              ],
              const Spacer(),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                child: Text('R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(fontSize: compact ? 11 : 17, fontWeight: FontWeight.w800, color: AppColors.ink))),
              const SizedBox(height: 8),
              if (qty == 0) Align(alignment: Alignment.centerRight, child: SizedBox(
                width: 44, height: 44, child: IconButton.filled(
                  tooltip: translateLabel('Adicionar $name'),
                  style: IconButton.styleFrom(backgroundColor: AppColors.ocean800, foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.ocean50),
                  onPressed: available ? () => state.addProduct(id) : null,
                  icon: const Icon(Icons.add_rounded, size: 23))))
              else Column(children: [
                Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ocean800)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: IconButton(tooltip: translateLabel('Diminuir quantidade'), padding: EdgeInsets.zero,
                    onPressed: () => state.changeQty(id, -1), icon: const Icon(Icons.remove_rounded, size: 19))),
                  Expanded(child: IconButton(tooltip: translateLabel('Aumentar quantidade'), padding: EdgeInsets.zero,
                    onPressed: available && state.canIncreaseQuantity(id) ? () => state.changeQty(id, 1) : null,
                    icon: const Icon(Icons.add_rounded, size: 19))),
                ]),
              ]),
            ],
          ))),
        ]),
      );
    });
  }
}

class ShowcaseProductsPage extends StatefulWidget {
  const ShowcaseProductsPage({super.key});
  @override
  State<ShowcaseProductsPage> createState() => _ShowcaseProductsPageState();
}
class _ShowcaseProductsPageState extends State<ShowcaseProductsPage> {
  String query = '';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([AppState.instance, AppLanguage.instance]),
    builder: (context, _) {
      final products = AppState.instance.products.where((p) => p['featuredHome'] == true &&
        p['active'] != false && p['archived'] != true && (int.tryParse('${p['stock']}') ?? 0) > 0 &&
        '${p['name']} ${p['description'] ?? ''}'.toLowerCase().contains(query)).toList();
      return Scaffold(backgroundColor: AppColors.ocean50,
        appBar: AppBar(title: const PrimeText('Vale levar junto'), backgroundColor: Colors.white),
        body: SafeArea(top: false, child: Column(children: [
          Expanded(child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const PrimeText('Complete o seu pedido', style: TextStyle(fontSize: 28, height: 1.15,
                  fontWeight: FontWeight.w800, letterSpacing: -.7, color: AppColors.ink)),
                const SizedBox(height: 8),
                const PrimeText('Produtos que combinam com o seu pedido', style: TextStyle(color: AppColors.muted, height: 1.5)),
                const SizedBox(height: 20),
                TextField(onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
                  decoration: PrimeInputDecoration(hintText: 'Buscar produtos', prefixIcon: const Icon(AppIcons.search),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.stroke)))),
              ]))),
            if (products.isEmpty) const SliverFillRemaining(hasScrollBody: false,
              child: Center(child: PrimeText('Nenhum produto encontrado.')))
            else SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverLayoutBuilder(builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                final columns = scale > 1.6 ? 1 : constraints.crossAxisExtent >= 750 ? 4 : constraints.crossAxisExtent >= 520 ? 3 : 2;
                final width = (constraints.crossAxisExtent - (columns - 1) * 12) / columns;
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((_, i) => ShowcaseProductTile(product: products[i]), childCount: products.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns,
                    crossAxisSpacing: 12, mainAxisSpacing: 16, mainAxisExtent: width / .84 + 220 * scale));
              })),
          ])),
          const CatalogueCartShortcut(),
        ])),
      );
    });
}
