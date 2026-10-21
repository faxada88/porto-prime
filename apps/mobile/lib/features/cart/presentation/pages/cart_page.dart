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
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(4, 22, 4, 24),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const PrimeText('QUASE LÁ', style: TextStyle(fontSize: 10, letterSpacing: 1.4,
                      fontWeight: FontWeight.w800, color: AppColors.ocean700)),
                    const SizedBox(height: 7),
                    const PrimeText('Seu carrinho', style: TextStyle(fontSize: 30, height: 1.1,
                      fontWeight: FontWeight.w800, letterSpacing: -1, color: AppColors.ocean900)),
                    const SizedBox(height: 10),
                    PrimeText(entries.isEmpty ? 'Seu próximo pedido começa aqui.'
                      : '${app.cartCount} ${app.cartCount == 1 ? 'item escolhido' : 'itens escolhidos'} por você.',
                      style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted)),
                  ])),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(tooltip: translateLabel( 'Adicionar produtos'),
                    onPressed: AppNav.instance.home,
                    style: IconButton.styleFrom(backgroundColor: AppColors.ocean100,
                      foregroundColor: AppColors.ocean900, minimumSize: const Size(48, 48)),
                    icon: const Icon(AppIcons.plus, size: 22)),
                ]))),
              if (entries.isEmpty)
                SliverFillRemaining(hasScrollBody: false,
                  child: Padding(padding: const EdgeInsets.only(bottom: 24),
                    child: PrimeCartEmpty(onExplore: () => AppNav.instance.go(1))))
              else ...[
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(bottom: 16),
                  child: CheckoutProgress(step: 0))),
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 4,
                    children: [
                      const PrimeText('Sua seleção', style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w800, color: AppColors.ocean900)),
                      TextButton.icon(onPressed: working ? null : _clearCart,
                        icon: const Icon(AppIcons.trash, size: 15),
                        label: const PrimeText('Limpar carrinho', style: TextStyle(fontSize: 12))),
                    ]))),
                SliverList(delegate: SliverChildBuilderDelegate((context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CartItem(id: entries[index].key, qty: entries[index].value)),
                  childCount: entries.length)),
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

class _CartItem extends StatelessWidget {
  const _CartItem({required this.id,required this.qty});
  final String id;final int qty;
  @override
  Widget build(BuildContext context){
    final app=AppState.instance,product=app.product(id);
    if(product==null)return const SizedBox.shrink();
    final price=double.tryParse('${product['price']}')??0;
    final image='${product['imageUrl']??''}';
    final name='${product['name']??'Produto'}';
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface,
        borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.stroke)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 68, height: 76, padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surfaceOcean, borderRadius: BorderRadius.circular(16)),
            child: image.isEmpty ? const Icon(AppIcons.package, size: 27, color: AppColors.ocean700)
              : Image.network(image, fit: BoxFit.contain, filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const Icon(AppIcons.package, size: 27, color: AppColors.ocean700))),
          const SizedBox(width: 12),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              PrimeText(name, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, height: 1.3, letterSpacing: -.2,
                  fontWeight: FontWeight.w800, color: AppColors.ocean900)),
              if (qty > 1) Padding(padding: const EdgeInsets.only(top: 8),
                child: PrimeText('${_brl(price)} cada', style: const TextStyle(fontSize: 11, color: AppColors.muted))),
            ]))),
          IconButton(tooltip: translateLabel( 'Remover $name'), onPressed: () => app.removeProduct(id),
            icon: const Icon(AppIcons.close, size: 18, color: AppColors.muted)),
        ]),
        if(qty>=app.stockLimit(id))Padding(padding:const EdgeInsets.only(top:12),child:PrimeText(qty>app.stockLimit(id)?'Estoque atualizado: ${app.stockLimit(id)} disponíveis. Reduza a quantidade.':'Você adicionou todas as ${app.stockLimit(id)} unidades disponíveis.',style:TextStyle(fontSize:12,height:1.5,color:qty>app.stockLimit(id)?AppColors.danger:AppColors.muted))),
        const Padding(padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1, color: AppColors.stroke)),
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16, runSpacing: 14, children: [
            Container(decoration: BoxDecoration(color: AppColors.ocean50,
              borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.ocean100)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _QuantityButton(icon: AppIcons.minus, label: 'Diminuir quantidade de $name', onTap: () => app.changeQty(id,-1)),
                SizedBox(width: 40, child: PrimeText('$qty', maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800,
                    fontSize: 14, color: AppColors.ocean900))),
                _QuantityButton(icon: AppIcons.plus, label: app.canIncreaseQuantity(id)?'Aumentar quantidade de $name':'Limite de estoque atingido', onTap: app.canIncreaseQuantity(id)?() => app.changeQty(id,1):null),
              ])),
            PrimeText(_brl(price*qty), style: const TextStyle(fontSize: 20, height: 1.2,
              letterSpacing: -.5, fontWeight: FontWeight.w800, color: AppColors.ocean900)),
          ]),
      ]));
  }
}
class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon,required this.label,required this.onTap});
  final IconData icon;final String label;final VoidCallback? onTap;
  @override
  Widget build(BuildContext context)=>IconButton(tooltip: translateLabel(label),onPressed:onTap,icon:Icon(icon,size:16,color:onTap==null?AppColors.subtle:AppColors.ocean700),constraints:const BoxConstraints(minWidth:44,minHeight:44));
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

