import 'package:flutter/material.dart';
import '../localization/prime_localization.dart';
import '../navigation/app_nav.dart';
import '../state/app_state.dart';
import '../theme/app_icons.dart';

void openCatalogueCart(BuildContext context) {
 FocusScope.of(context).unfocus();
 AppNav.instance.go(2);
 final navigator=AppNav.instance.rootNavigatorKey.currentState??Navigator.of(context);
 navigator.popUntil((route)=>route.isFirst);
}

/// Used only inside catalogue pages. Home and checkout keep their own controls.
class CatalogueCartShortcut extends StatelessWidget {
  const CatalogueCartShortcut({super.key,this.compact=false});
  final bool compact;
  String _countLabel(int count) {
    switch (AppLanguage.instance.locale.languageCode) {
      case 'es': return '$count ${count == 1 ? 'artículo' : 'artículos'} en el carrito';
      case 'en': return '$count ${count == 1 ? 'item' : 'items'} in your cart';
      default: return '$count ${count == 1 ? 'item' : 'itens'} no carrinho';
    }
  }
  void _open(BuildContext context) => openCatalogueCart(context);
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([AppState.instance, AppLanguage.instance]),
    builder: (context, _) => _content(context));
  Widget _content(BuildContext context) {
    final app = AppState.instance;
    final duration = MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 180);
    final visible = app.cartCount > 0 && MediaQuery.viewInsetsOf(context).bottom == 0;
    return AnimatedSize(duration: duration, alignment: Alignment.bottomCenter,
      child: !visible ? const SizedBox.shrink() : SafeArea(top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Center(heightFactor: 1, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
          child: compact ? _compactSummary(context, app) : _summary(context, app, duration)))));
  }
  Widget _compactSummary(BuildContext context,AppState app){
    final price='R\$ ${app.cartSubtotal.toStringAsFixed(2).replaceAll('.',',')}';
    final label=_countLabel(app.cartCount);
    return Semantics(button:true,excludeSemantics:true,
      label:'$label. ${AppLanguage.instance.translate('Subtotal')}: $price. ${AppLanguage.instance.translate('Ver carrinho')}.',
      onTap:()=>_open(context),child:Material(color:const Color(0xFF003C46),
        borderRadius:BorderRadius.circular(22),clipBehavior:Clip.antiAlias,
        child:InkWell(onTap:()=>_open(context),child:Row(children:[
          const Padding(padding:EdgeInsets.only(left:16,right:12),child:Icon(AppIcons.cart,color:Colors.white,size:23)),
          Expanded(flex:4,child:Padding(padding:const EdgeInsets.symmetric(vertical:14),
            child:PrimeText(label,maxLines:2,overflow:TextOverflow.ellipsis,
              style:const TextStyle(fontSize:12,height:1.3,fontWeight:FontWeight.w700,color:Colors.white)))),
          const SizedBox(width:9),
          Flexible(flex:3,child:Container(padding:const EdgeInsets.symmetric(horizontal:15,vertical:12),
            decoration:BoxDecoration(color:const Color(0xFF006C75),borderRadius:BorderRadius.circular(22)),
            child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.end,children:[
              const PrimeText('Subtotal',style:TextStyle(fontSize:8,color:Color(0xFFCBE8E7))),
              const SizedBox(height:2),
              Row(mainAxisSize:MainAxisSize.min,children:[
                Flexible(child:FittedBox(fit:BoxFit.scaleDown,child:Text(price,
                  style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:Colors.white)))),
                const SizedBox(width:3),const Icon(Icons.chevron_right_rounded,color:Colors.white,size:18),
              ]),
            ]))),
        ]))));
  }

  Widget _summary(BuildContext context, AppState app, Duration duration) {
    final entries = app.cart.entries.where((entry) => entry.value > 0).toList();
    final names = entries.map((entry) => '${entry.value}× ${app.product(entry.key)?['name'] ?? AppLanguage.instance.translate('Produto')}').join(' · ');
    final price = 'R\$ ${app.cartSubtotal.toStringAsFixed(2).replaceAll('.', ',')}';
    final label = _countLabel(app.cartCount);
    final action = AppLanguage.instance.translate('Ver carrinho');
    return Semantics(button: true, container: true, excludeSemantics: true,
      label: '$label. $names. ${AppLanguage.instance.translate('Subtotal dos produtos')}: $price. $action.',
      onTap: () => _open(context),
      child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x280D3446), blurRadius: 24, offset: Offset(0, 7))]),
        child: Material(color: const Color(0xFF143D4B), borderRadius: BorderRadius.circular(24), clipBehavior: Clip.antiAlias,
          child: Ink(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF6EABAC), width: 1.5),
            gradient: const LinearGradient(colors: [Color(0xFF143D4B), Color(0xFF205760)])),
            child: InkWell(onTap: () => _open(context), child: Padding(padding: const EdgeInsets.all(15),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(width: 38, height: 38, alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFF0FAF7), borderRadius: BorderRadius.circular(13)),
                    child: AnimatedSwitcher(duration: duration, child: Text('${app.cartCount}',
                      key: ValueKey(app.cartCount), style: const TextStyle(color: Color(0xFF153E49), fontSize: 17, fontWeight: FontWeight.w800)))),
                  const SizedBox(width: 10),
                  Expanded(flex: 4, child: PrimeText(label, style: const TextStyle(color: Colors.white,
                    fontSize: 12, height: 1.3, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 10),
                  Flexible(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const PrimeText('Subtotal', style: TextStyle(color: Color(0xFFC7E3E4), fontSize: 9)),
                    const SizedBox(height: 3),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(price, style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.2, fontWeight: FontWeight.w800))),
                  ])),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  for (final entry in entries.take(2)) Padding(padding: const EdgeInsets.only(right: 6),
                    child: _ProductPreview(image: (app.product(entry.key)?['imageUrl'] ?? '').toString())),
                  const SizedBox(width: 3),
                  Expanded(child: Text(names, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFE0F0EE), fontSize: 10, height: 1.35))),
                  const SizedBox(width: 9),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(color: const Color(0xFFF0FAF7), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(AppIcons.arrowRight, size: 19, color: Color(0xFF153E49))),
                ]),
                const SizedBox(height: 9),
                PrimeText(action, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white,
                  fontSize: 11, fontWeight: FontWeight.w800)),
              ])))))));
  }
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview({required this.image});
  final String image;
  @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(9),
    child: SizedBox(width: 30, height: 34, child: ColoredBox(color: Colors.white,
      child: image.isEmpty ? const Icon(AppIcons.cart, size: 17, color: Color(0xFF527681))
        : Image.network(image, fit: BoxFit.contain, excludeFromSemantics: true,
            errorBuilder: (_, error, stack) => const Icon(AppIcons.cart, size: 17, color: Color(0xFF527681))))));
}
