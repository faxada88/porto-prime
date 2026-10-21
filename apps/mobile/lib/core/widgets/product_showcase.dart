import 'dart:async';
import 'package:flutter/material.dart';
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
      if (!mounted || paused || !foreground || dragging || widget.products.length < 2 ||
          !controller.hasClients || AppNav.instance.index.value != 0 ||
          ModalRoute.of(context)?.isCurrent == false || MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context) || DateTime.now().difference(touched).inSeconds < 10 ||
          controller.position.isScrollingNotifier.value) return;
      move(1);
    });
  }
  void move(int direction) {
    if (!controller.hasClients || widget.products.isEmpty) return;
    final next = (page + direction) % widget.products.length;
    controller.animateToPage(next, duration: Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 1 : 480),
      curve: Curves.easeInOutCubic);
  }
  @override
  void didUpdateWidget(covariant ProductShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (page >= widget.products.length) {
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
    return AnimatedBuilder(
      animation: Listenable.merge([AppState.instance, AppLanguage.instance]),
      builder: (context, _) => LayoutBuilder(builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final stacked = scale > 1.3 || box.maxWidth < 300;
        final height = stacked ? 260 + scale * 150 : 270 + (scale - 1) * 180;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: height, child: Listener(
            onPointerDown: (_) { dragging = true; touched = DateTime.now(); },
            onPointerUp: (_) { dragging = false; touched = DateTime.now(); },
            onPointerCancel: (_) { dragging = false; touched = DateTime.now(); },
            child: PageView.builder(
              controller: controller, itemCount: widget.products.length,
              onPageChanged: (value) => setState(() => page = value),
              itemBuilder: (context, index) => _ShowcaseProduct(product: widget.products[index], stacked: stacked),
            ),
          )),
          if (widget.products.length > 1) Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(children: [
              IconButton(tooltip: translateLabel(paused ? 'Continuar apresentação' : 'Pausar apresentação'),
                onPressed: () => setState(() { paused = !paused; touched = DateTime.now(); }),
                icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20, color: AppColors.ocean700)),
              Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                  value: (page + 1) / widget.products.length, minHeight: 3,
                  color: AppColors.ocean700, backgroundColor: AppColors.ocean100)))),
              Text('${page + 1} / ${widget.products.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
              const SizedBox(width: 8),
              IconButton(tooltip: translateLabel('Produto anterior'), onPressed: () { touched = DateTime.now(); move(-1); },
                icon: const Icon(Icons.arrow_back_rounded, size: 20)),
              IconButton(tooltip: translateLabel('Próximo produto'), onPressed: () { touched = DateTime.now(); move(1); },
                icon: const Icon(Icons.arrow_forward_rounded, size: 20)),
            ]),
          ),
        ]);
      }),
    );
  }
}

class _ShowcaseProduct extends StatelessWidget {
  const _ShowcaseProduct({required this.product, required this.stacked});
  final dynamic product;
  final bool stacked;
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
    final fallback = Center(child: Icon(visual.icon, size: 58, color: visual.foreground));
    final artwork = Container(
      decoration: BoxDecoration(color: visual.background, borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [
        Positioned(right: -30, bottom: -30, child: Container(width: 130, height: 130,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .45)))),
        Padding(padding: const EdgeInsets.all(12), child: url.isEmpty ? fallback :
          Image.network(url, fit: BoxFit.contain, cacheWidth: 640, errorBuilder: (_, __, ___) => fallback)),
      ]),
    );
    final details = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (category.isNotEmpty) PrimeText(category, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ocean700)),
      const SizedBox(height: 8),
      PrimeText(name, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 19, height: 1.15, letterSpacing: -.4, fontWeight: FontWeight.w800, color: AppColors.ink)),
      if (description.isNotEmpty) ...[
        const SizedBox(height: 8),
        PrimeText(description, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, height: 1.35, color: AppColors.muted)),
      ],
      const Spacer(),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text('R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink))),
      const SizedBox(height: 12),
      if (!available) const PrimeText('Indisponível', style: TextStyle(color: AppColors.muted))
      else if (qty == 0) SizedBox(width: double.infinity, height: 46, child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: AppColors.ocean800, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: () => state.addProduct(id),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_rounded, size: 19), const SizedBox(width: 5),
          Flexible(child: PrimeText('Adicionar', maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ))
      else Container(
        decoration: BoxDecoration(color: AppColors.ocean50, border: Border.all(color: AppColors.strokeStrong),
          borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          Expanded(child: IconButton(tooltip: translateLabel('Diminuir quantidade'),
            onPressed: () => state.changeQty(id, -1), icon: const Icon(Icons.remove_rounded, size: 20))),
          Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
          Expanded(child: IconButton(tooltip: translateLabel('Aumentar quantidade'),
            onPressed: state.canIncreaseQuantity(id) ? () => state.changeQty(id, 1) : null,
            icon: const Icon(Icons.add_rounded, size: 20))),
        ]),
      ),
    ]);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.strokeStrong),
        boxShadow: const [BoxShadow(color: Color(0x070F343A), blurRadius: 16, offset: Offset(0, 5))]),
      child: stacked ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(height: 150, child: artwork), const SizedBox(height: 16), Expanded(child: details),
      ]) : Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(flex: 5, child: artwork), const SizedBox(width: 16), Expanded(flex: 6, child: details),
      ]),
    );
  }
}
