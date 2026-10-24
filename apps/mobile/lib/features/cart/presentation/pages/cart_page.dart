import '../../../../core/localization/prime_localization.dart';
import '../../../checkout/presentation/widgets/checkout_progress.dart';
import 'package:flutter/material.dart';
import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_cart_widgets.dart';
import '../../../checkout/presentation/pages/checkout_flow_page.dart';
import '../../../orders/presentation/pages/order_tracking_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState()=>_CartPageState();
}
class _CartPageState extends State<CartPage> {
  bool _opening=false;
  Future<void> _startCheckout() async {
    if(_opening)return;
    if(AppState.instance.cartExceedsStock){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:PrimeText('O estoque mudou. Ajuste as quantidades indicadas no carrinho para continuar.')));
      return;
    }
    setState(()=>_opening=true);
    try{await _checkout(context);}finally{if(mounted)setState(()=>_opening=false);}
  }
  Future<void> _clearCart() async {
    if(_opening||AppState.instance.loading||AppState.instance.cart.isEmpty)return;
    final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24)),
      icon:const Icon(AppIcons.cart,color:AppColors.ocean700,size:30),
      title:const PrimeText('Limpar seu carrinho?'),content:const PrimeText('Todos os produtos serão removidos. Você pode montar um novo carrinho quando quiser.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const PrimeText('Manter produtos')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const PrimeText('Limpar carrinho'))],
    ));
    if(confirmed==true&&mounted)AppState.instance.clearCart();
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: AppState.instance, builder: (_, __) {
    final app = AppState.instance;
    final entries = app.cart.entries.toList();
    final working = _opening || app.loading;
    return SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1080),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(builder: (context, box) {
          final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
          final wide = box.maxWidth >= 900 && !largeText;
          final inlineSummary = box.maxHeight < 600 || largeText;
          Widget summary() => PrimeCartSummary(subtotal: _brl(app.cartSubtotal),
            working: working, storeKnown: app.storeStatusKnown,
            storeOpen: app.storeOpen, storeMessage: app.storeMessage,
            onContinue: _startCheckout);
          Widget contents({bool showSummary = false}) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(4, 18, 4, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const PrimeText('QUASE LÁ', style: TextStyle(fontSize: 10, letterSpacing: 1.4,
                    fontWeight: FontWeight.w800, color: AppColors.ocean700)),
                  const SizedBox(height: 7),
                  const PrimeText('Seu carrinho', style: TextStyle(fontSize: 30, height: 1.1,
                    fontWeight: FontWeight.w800, letterSpacing: -1, color: AppColors.ocean900)),
                  const SizedBox(height: 10),
                  PrimeText(entries.isEmpty ? 'Seu próximo pedido começa aqui.'
                    : '${app.cartCount} ${app.cartCount == 1 ? 'item escolhido' : 'itens escolhidos'} por você.',
                    style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted)),
                  if (entries.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ContinueShoppingAction(onTap: working ? null : AppNav.instance.home),
                  ],
                ]))),
              if (entries.isEmpty)
                SliverFillRemaining(hasScrollBody: false,
                  child: Padding(padding: const EdgeInsets.only(bottom: 24),
                    child: PrimeCartEmpty(onExplore: AppNav.instance.home)))
              else ...[
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(bottom: 10),
                  child: CheckoutProgress(step: 0))),
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 4,
                    children: [
                      const PrimeText('Sua seleção', style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w800, color: AppColors.ocean900)),
                      TextButton.icon(onPressed: working ? null : _clearCart,
                        icon: const Icon(AppIcons.trash, size: 15),
                        label: const PrimeText('Limpar carrinho', style: TextStyle(fontSize: 12))),
                    ]))),
                DecoratedSliver(
                  decoration: BoxDecoration(color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.strokeStrong)),
                  sliver: SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate(
                      (context, index) => Column(
                        key: ValueKey(entries[index].key),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CartItem(id: entries[index].key, qty: entries[index].value),
                          if (index < entries.length - 1)
                            const Divider(height: 1, thickness: 1, color: AppColors.stroke),
                        ]),
                      childCount: entries.length)),
                  ),
                ),
                if (showSummary) SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 20), child: summary())),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
            ],
          );
          if (entries.isEmpty) return contents();
          if (wide) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: contents()), const SizedBox(width: 24),
            SizedBox(width: 330, child: SingleChildScrollView(padding: const EdgeInsets.only(top: 22, bottom: 20), child: summary())),
          ]);
          if (inlineSummary) return contents(showSummary: true);
          return Column(children: [Expanded(child: contents()),
            Padding(padding: const EdgeInsets.only(top: 8, bottom: 10), child: summary()),
          ]);
        }),
      ),
    )));
  });
}
String _brl(double value)=>'R\$ ${value.toStringAsFixed(2).replaceAll('.',',')}';


class _ContinueShoppingAction extends StatelessWidget {
 const _ContinueShoppingAction({required this.onTap});
 final VoidCallback? onTap;
 @override Widget build(BuildContext context) => Material(
  color: const Color(0xFFF0F8FA), borderRadius: BorderRadius.circular(18),
  child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
   child: Container(padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
     border: Border.all(color: const Color(0xFFA7CBD5), width: 1.2)),
    child: Row(children: [
     Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.add_shopping_cart_rounded,
       size: 23, color: Color(0xFF2C6E7B))),
     const SizedBox(width: 12),
     const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PrimeText('Continuar comprando', style: TextStyle(fontSize: 15, height: 1.25,
       fontWeight: FontWeight.w800, color: Color(0xFF173E49))),
      SizedBox(height: 4),
      PrimeText('Seus itens continuam no carrinho.', style: TextStyle(fontSize: 11.5,
       height: 1.4, color: Color(0xFF527582))),
     ])),
     const SizedBox(width: 8),
     const Icon(Icons.arrow_forward_rounded, size: 20, color: Color(0xFF2C6E7B)),
    ]))));
}

class _CartItem extends StatelessWidget {
  const _CartItem({required this.id, required this.qty});
  final String id;
  final int qty;

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final product = app.product(id);
    if (product == null) return const SizedBox.shrink();
    final price = double.tryParse('${product['price']}') ?? 0;
    final image = '${product['imageUrl'] ?? ''}';
    final name = '${product['name'] ?? 'Produto'}';
    final stock = app.stockLimit(id);
    final canIncrease = app.canIncreaseQuantity(id);
    final stockExceeded = qty > stock;

    final thumbnail = ExcludeSemantics(child: Container(
      width: 56, height: 72, padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke)),
      child: image.isEmpty
        ? const Icon(AppIcons.package, size: 25, color: AppColors.ocean700)
        : Image.network(image, fit: BoxFit.contain, filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) =>
              const Icon(AppIcons.package, size: 25, color: AppColors.ocean700)),
    ));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          thumbnail,
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: PrimeText(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.3,
                  fontWeight: FontWeight.w800, color: AppColors.ocean900))),
              IconButton(tooltip: translateLabel('Remover $name'),
                onPressed: () => app.removeProduct(id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: const Icon(AppIcons.close, size: 17, color: AppColors.muted)),
            ]),
            if (qty > 1) Padding(padding: const EdgeInsets.only(bottom: 5),
              child: PrimeText('${_brl(price)} cada',
                style: const TextStyle(fontSize: 11, height: 1.3, color: AppColors.muted))),
            LayoutBuilder(builder: (context, box) {
              const amountStyle = TextStyle(fontSize: 16, height: 1.25,
                letterSpacing: -.3, fontWeight: FontWeight.w800, color: AppColors.ocean900);
              const quantityStyle = TextStyle(fontSize: 13, height: 1.2,
                fontWeight: FontWeight.w800, color: AppColors.ocean900);
              final scaler = MediaQuery.textScalerOf(context);
              double textWidth(String text, TextStyle style) {
                final painter = TextPainter(
                  text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
                  textDirection: Directionality.of(context), textScaler: scaler,
                  maxLines: 1,
                )..layout();
                final width = painter.width;
                painter.dispose();
                return width;
              }

              // Keep the complete quantity and 44px tap targets at normal sizes.
              final countWidth = textWidth('$qty', quantityStyle) + 12;
              final desiredWidth = 90.0 + (countWidth < 24.0 ? 24.0 : countWidth);
              final selectorWidth = desiredWidth > box.maxWidth ? box.maxWidth : desiredWidth;
              final controls = Container(
                width: selectorWidth,
                decoration: BoxDecoration(color: AppColors.ocean50,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.strokeStrong)),
                child: Row(children: [
                  _QuantityButton(icon: AppIcons.minus,
                    label: 'Diminuir quantidade de $name', onTap: () => app.changeQty(id, -1)),
                  Expanded(child: PrimeText('$qty', maxLines: 1, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center, style: quantityStyle)),
                  _QuantityButton(icon: AppIcons.plus,
                    label: canIncrease ? 'Aumentar quantidade de $name' : 'Limite de estoque atingido',
                    onTap: canIncrease ? () => app.changeQty(id, 1) : null),
                ]),
              );
              final amount = PrimeText(_brl(price * qty), style: amountStyle);
              final fits = textWidth(_brl(price * qty), amountStyle) + selectorWidth + 8 <= box.maxWidth;
              if (fits) {
                return Row(children: [
                  Expanded(child: amount), const SizedBox(width: 8), controls,
                ]);
              }
              // Larger text and narrow screens reflow without hiding the price.
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                amount, const SizedBox(height: 6),
                Align(alignment: Alignment.centerRight, child: controls),
              ]);
            }),
          ])),
        ]),
        if (qty >= stock) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 2),
              child: Icon(stockExceeded ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                size: 14, color: stockExceeded ? AppColors.danger : AppColors.ocean700)),
            const SizedBox(width: 6),
            Expanded(child: PrimeText(stockExceeded
              ? 'Estoque atualizado: $stock disponíveis. Reduza a quantidade.'
              : 'Você adicionou todas as $stock unidades disponíveis.',
              style: TextStyle(fontSize: 11, height: 1.4,
                color: stockExceeded ? AppColors.danger : AppColors.muted))),
          ]),
        ),
      ]),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: translateLabel(label), onPressed: onTap,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 44, maxWidth: 44, minHeight: 44, maxHeight: 44),
    icon: Icon(icon, size: 16, color: onTap == null ? AppColors.subtle : AppColors.ocean700),
  );
}

Future<void> _checkout(BuildContext context) async {
  final s = AppState.instance;

  if (!s.loggedIn || !s.isCustomer) {
    AppNav.instance.go(3);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: PrimeText('Entre ou crie sua conta de cliente para continuar.'),
      ),
    );
    return;
  }

  final result=await Navigator.of(context).push<Map<String,dynamic>>(MaterialPageRoute(builder:(_)=>const CheckoutFlowPage()));
  if(!context.mounted||result==null)return;
  final action=result['result'];
  if(action=='track'){
    s.clearCart();
    await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>OrderTrackingPage(orderId:result['orderId'].toString())));
  }else if(action=='shop'){
    s.clearCart();AppNav.instance.home();
  }else if(action=='home'){
    AppNav.instance.home();
  }
}

