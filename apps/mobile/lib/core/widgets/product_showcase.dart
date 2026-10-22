import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'catalogue_cart_shortcut.dart';
import '../localization/prime_localization.dart';
import '../navigation/app_nav.dart';
import '../state/app_state.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// The rail uses real catalogue products and the existing stock/cart operations.
class ProductShowcase extends StatefulWidget {
 const ProductShowcase({super.key, required this.products});
 final List<dynamic> products;
 @override State<ProductShowcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<ProductShowcase> with WidgetsBindingObserver {
 final controller = ScrollController();
 Timer? timer;
 int page = 0;
 double itemExtent = 200;
 bool foreground = true, dragging = false, paused = false;
 DateTime touched = DateTime.fromMillisecondsSinceEpoch(0);
 @override void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  controller.addListener(onScroll);
  timer = Timer.periodic(const Duration(seconds: 6), (_) {
   if (!mounted || paused || !foreground || dragging || widget.products.length < 2 ||
       !controller.hasClients || AppNav.instance.index.value != 0 ||
       ModalRoute.of(context)?.isCurrent == false || MediaQuery.disableAnimationsOf(context) ||
       MediaQuery.accessibleNavigationOf(context) || DateTime.now().difference(touched).inSeconds < 10 ||
       controller.position.isScrollingNotifier.value) return;
   move(1);
  });
 }
 void onScroll() {
  if (!controller.hasClients || widget.products.isEmpty) return;
  final next = (controller.offset / itemExtent).round().clamp(0, widget.products.length - 1).toInt();
  if (next != page) setState(() => page = next);
 }
 void move(int direction) {
  if (!controller.hasClients || widget.products.isEmpty) return;
  final max = controller.position.maxScrollExtent;
  final target = controller.offset + direction * itemExtent;
  final destination = direction > 0 && controller.offset >= max - 1 ? 0.0 : target.clamp(0.0, max).toDouble();
  controller.animateTo(destination,
   duration: Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 1 : 480),
   curve: Curves.easeInOutCubic);
 }
 @override void didUpdateWidget(covariant ProductShowcase oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (page >= widget.products.length) {
   page = 0;
   WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && controller.hasClients) controller.jumpTo(0);
   });
  }
 }
 @override void didChangeAppLifecycleState(AppLifecycleState state) {
  foreground = state == AppLifecycleState.resumed;
 }
 @override void dispose() {
  timer?.cancel();
  controller.removeListener(onScroll);
  controller.dispose();
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
 }
 @override Widget build(BuildContext context) {
  if (widget.products.isEmpty) return const SizedBox.shrink();
  return AnimatedBuilder(animation: Listenable.merge([AppState.instance, AppLanguage.instance]),
   builder: (context, _) => LayoutBuilder(builder: (context, box) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final baseWidth = scale > 1.3 ? box.maxWidth * .78 : (box.maxWidth - 16) / 2.05;
    final width = baseWidth.clamp(170.0, scale > 1.3 ? 340.0 : 240.0).toDouble();
    itemExtent = width + 12;
    final count = widget.products.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
     Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Expanded(child: PrimeText('Vale levar junto', style: TextStyle(
       fontSize: 19, height: 1.25, fontWeight: FontWeight.w800, color: AppColors.ink))),
      const SizedBox(width: 8),
      TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShowcaseProductsPage())),
       style: TextButton.styleFrom(foregroundColor: AppColors.ocean800,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
       child: const Row(mainAxisSize: MainAxisSize.min, children: [
        PrimeText('Ver todos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 16),
       ])),
     ]),
     const SizedBox(height: 3),
     const PrimeText('Produtos que combinam com o seu pedido',
      style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.muted)),
     const SizedBox(height: 16),
     SizedBox(height: width / 1.16 + 92 + 74 * scale, child: Listener(
      onPointerDown: (_) { dragging = true; touched = DateTime.now(); },
      onPointerUp: (_) { dragging = false; touched = DateTime.now(); },
      onPointerCancel: (_) { dragging = false; touched = DateTime.now(); },
      child: ListView.builder(controller: controller, scrollDirection: Axis.horizontal,
       itemExtent: itemExtent, itemCount: count,
       itemBuilder: (_, index) => Padding(padding: const EdgeInsets.only(right: 12),
        child: ShowcaseProductTile(product: widget.products[index])),
      ),
     )),
     if (count > 1) Padding(padding: const EdgeInsets.only(top: 6), child: Row(
      mainAxisAlignment: MainAxisAlignment.center, children: [
       IconButton(tooltip: translateLabel(paused ? 'Continuar apresentação' : 'Pausar apresentação'),
        onPressed: () => setState(() { paused = !paused; touched = DateTime.now(); }),
        icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18, color: AppColors.muted)),
       for (var i = 0; i < (count > 7 ? 7 : count); i++) AnimatedContainer(
        duration: const Duration(milliseconds: 220), margin: const EdgeInsets.symmetric(horizontal: 3),
        width: (count > 7 ? page * 7 ~/ count : page) == i ? 24 : 6, height: 6,
        decoration: BoxDecoration(color: (count > 7 ? page * 7 ~/ count : page) == i
         ? AppColors.ocean800 : AppColors.strokeStrong, borderRadius: BorderRadius.circular(6))),
       IconButton(tooltip: translateLabel('Próximo produto'), onPressed: () { touched = DateTime.now(); move(1); },
        icon: const Icon(Icons.chevron_right_rounded, color: AppColors.ocean800)),
      ],
     )),
    ]);
   }));
 }
}

class ShowcaseProductTile extends StatelessWidget {
 const ShowcaseProductTile({super.key, required this.product});
 final dynamic product;
 @override Widget build(BuildContext context) {
  final state = AppState.instance;
  final id = product['id'].toString();
  final name = (product['name'] ?? 'Produto').toString();
  final category = (product['category']?['name'] ?? '').toString();
  final url = (product['imageUrl'] ?? '').toString().trim();
  final price = double.tryParse(product['price'].toString()) ?? 0;
  final qty = state.cart[id] ?? 0;
  final canAdd = state.canIncreaseQuantity(id);
  final visual = AppIcons.categoryVisual(category, iconKey: product['category']?['iconKey']?.toString());
  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
  final fallback = Center(child: Icon(visual.icon, size: 48, color: visual.foreground));
  return Semantics(label: translateLabel(name), child: Container(
   clipBehavior: Clip.antiAlias,
   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19),
    border: Border.all(color: const Color(0xFFDDE8EA))),
   child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    AspectRatio(aspectRatio: 1.16, child: Stack(fit: StackFit.expand, children: [
     ColoredBox(color: visual.background, child: url.isEmpty ? fallback : Image.network(url,
      fit: BoxFit.cover, cacheWidth: 640, errorBuilder: (_, __, ___) => fallback)),
     Positioned(top: 8, right: 8, child: ProductFavoriteButton(productId: id, owner: (state.user?['id'] ?? 'guest').toString())),
    ])),
    Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(
     crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PrimeText(category, maxLines: 1, overflow: TextOverflow.ellipsis,
       style: const TextStyle(fontSize: 10.5, height: 1.2, color: AppColors.muted)),
      const SizedBox(height: 5),
      SizedBox(height: 35 * scale, child: PrimeText(name, maxLines: 2, overflow: TextOverflow.ellipsis,
       style: const TextStyle(fontSize: 14, height: 1.25, fontWeight: FontWeight.w700, color: AppColors.ink))),
      const Spacer(),
      Text(r'R$ ' + price.toStringAsFixed(2).replaceAll('.', ','), maxLines: 1, overflow: TextOverflow.ellipsis,
       style: const TextStyle(fontSize: 17, height: 1.2, fontWeight: FontWeight.w800, color: AppColors.ink)),
      const SizedBox(height: 10),
      if (qty > 0) DecoratedBox(decoration: BoxDecoration(color: const Color(0xFFEDF7F6),
       borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFB9D8D8))),
       child: Row(children: [
        IconButton(tooltip: translateLabel('Diminuir quantidade'), onPressed: () => state.changeQty(id, -1),
         icon: const Icon(Icons.remove_rounded, size: 20)),
        Expanded(child: Text(qty.toString(), textAlign: TextAlign.center,
         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ocean800))),
        IconButton(tooltip: translateLabel('Aumentar quantidade'), onPressed: canAdd ? () => state.changeQty(id, 1) : null,
         icon: const Icon(Icons.add_rounded, size: 20)),
       ]))
      else FilledButton.icon(
       style: FilledButton.styleFrom(backgroundColor: AppColors.ocean800, foregroundColor: Colors.white,
        minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
       onPressed: canAdd ? () => state.addProduct(id) : null, icon: const Icon(Icons.add_rounded, size: 18),
       label: PrimeText(state.stockLimit(id) == 0 ? 'Indisponível' : 'Adicionar',
        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
     ]))),
   ])));
 }
}

class ProductFavoriteButton extends StatefulWidget {
 const ProductFavoriteButton({super.key,required this.productId,required this.owner});
 final String productId,owner;
 @override State<ProductFavoriteButton> createState()=>ProductFavoriteButtonState();
}
class ProductFavoriteButtonState extends State<ProductFavoriteButton> {
 bool saved=false,busy=false;int epoch=0;
 String get storageKey=>'porto-prime:favorite:${widget.owner}:${widget.productId}';
 @override void initState(){super.initState();load();}
 @override void didUpdateWidget(covariant ProductFavoriteButton old){
  super.didUpdateWidget(old);if(old.productId!=widget.productId||old.owner!=widget.owner){saved=false;busy=false;load();}
 }
 Future<void> load()async{
  final revision=++epoch,key=storageKey;
  try{
   final prefs=await SharedPreferences.getInstance();
   if(mounted&&revision==epoch&&key==storageKey)setState(()=>saved=prefs.getBool(key)??false);
  }catch(_){/* The card remains usable if local preferences are unavailable. */}
 }
 Future<void> toggle()async{
  if(busy)return;
  final key=storageKey,previous=saved,revision=++epoch;
  setState((){busy=true;saved=!saved;});
  try{
   final prefs=await SharedPreferences.getInstance();
   final ok=await prefs.setBool(key,!previous);
   if(!ok&&mounted&&revision==epoch)setState(()=>saved=previous);
  }catch(_){if(mounted&&revision==epoch)setState(()=>saved=previous);}
  finally{if(mounted&&revision==epoch)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>SizedBox(width:32,height:32,child:IconButton(
  tooltip:translateLabel(saved?'Remover dos favoritos':'Salvar produto'),
  onPressed:busy?null:toggle,padding:EdgeInsets.zero,
  style:IconButton.styleFrom(backgroundColor:const Color(0x88000000),foregroundColor:Colors.white),
  icon:Icon(saved?Icons.favorite_rounded:Icons.favorite_border_rounded,size:20)));
}

class ShowcaseProductsPage extends StatefulWidget {
  const ShowcaseProductsPage({super.key, this.offersOnly = false});
  final bool offersOnly;
  @override
  State<ShowcaseProductsPage> createState() => _ShowcaseProductsPageState();
}
class _ShowcaseProductsPageState extends State<ShowcaseProductsPage> {
  String query = '';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([AppState.instance, AppLanguage.instance]),
    builder: (context, _) {
      final products = AppState.instance.products.where((p) => (widget.offersOnly ?
        AppIcons.categoryVisual('${p['category']?['name']??''}',iconKey:p['category']?['iconKey']?.toString()).key=='offers' ||
        (double.tryParse('${p['oldPrice']??p['compareAtPrice']}')??0)>(double.tryParse('${p['price']}')??0) : p['featuredHome']==true) &&
        p['active'] != false && p['archived'] != true && (int.tryParse('${p['stock']}') ?? 0) > 0 &&
        '${p['name']} ${p['description'] ?? ''}'.toLowerCase().contains(query)).toList();
      return Scaffold(backgroundColor: AppColors.ocean50,
        appBar: AppBar(title: PrimeText(widget.offersOnly?'Ofertas':'Vale levar junto'), backgroundColor: Colors.white),
        body: SafeArea(top: false, child: Column(children: [
          Expanded(child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                PrimeText(widget.offersOnly?'Ofertas':'Complete o seu pedido', style: TextStyle(fontSize: 28, height: 1.15,
                  fontWeight: FontWeight.w800, letterSpacing: -.7, color: AppColors.ink)),
                const SizedBox(height: 8),
                const PrimeText('Produtos que combinam com o seu pedido', style: TextStyle(color: AppColors.muted, height: 1.5)),
                const SizedBox(height: 20),
                TextField(onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
                  decoration: PrimeInputDecoration(hintText: 'Buscar produtos', prefixIcon: const Icon(AppIcons.search),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.stroke)))),
              ]))),
            if (products.isEmpty) SliverFillRemaining(hasScrollBody: false,
              child: Center(child: PrimeText(widget.offersOnly&&query.isEmpty?'Novas ofertas em breve':'Nenhum produto encontrado.')))
            else SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverLayoutBuilder(builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                final columns = scale > 1.6 ? 1 : constraints.crossAxisExtent >= 750 ? 4 : constraints.crossAxisExtent >= 520 ? 3 : 2;
                final width = (constraints.crossAxisExtent - (columns - 1) * 12) / columns;
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((_, i) => ShowcaseProductTile(product: products[i]), childCount: products.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns,
                    crossAxisSpacing: 12, mainAxisSpacing: 16, mainAxisExtent: width / 1.16 + 92 + 74 * scale));
              })),
          ])),
          const CatalogueCartShortcut(),
        ])),
      );
    });
}
