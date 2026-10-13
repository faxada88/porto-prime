import '../../../checkout/presentation/pages/checkout_flow_page.dart';
import '../../../checkout/presentation/widgets/checkout_progress.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/prime_brand.dart';

import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';
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
    setState(()=>_opening=true);
    try{await _checkout(context);}finally{if(mounted)setState(()=>_opening=false);}
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppState.instance,
    builder: (_, __) {
      final s = AppState.instance;
      final entries = s.cart.entries.toList();
      final quotedFee =
          double.tryParse(s.deliveryQuote['deliveryFee']?.toString() ?? '');
      final delivery = entries.isEmpty ? 0.0 : (quotedFee ?? 0.0);
      final credit = s.selectedCustomerCredit();
      final total = s.cartSubtotal + delivery - credit;

      return SafeArea(
        bottom: false,
        child: PrimePageViewport(child: Column(children:[Expanded(child:ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          children: [
            const PrimeEditorialHeader(title: 'Seu carrinho', subtitle: 'Seus favoritos, a poucos passos de chegar.', icon: AppIcons.cart, eyebrow: 'PORTO PRIME · SUA COMPRA'),
            const SizedBox(height: 20),
            const CheckoutProgress(step:0),
            Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:AppNav.instance.home,icon:const Icon(AppIcons.plus,size:16),label:const Text('Continuar comprando'))),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumo da compra',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'A próxima etapa confirma o endereço e a entrega.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ocean50,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    s.cartCount.toString() +
                        (s.cartCount == 1 ? ' item' : ' itens'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.ocean800,
                          fontWeight: AppFontWeight.display,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if(entries.isNotEmpty) _Delivery(quote: s.deliveryQuote),
            const SizedBox(height: 14),

            if (entries.isEmpty)
              const _EmptyCart()
            else ...[
              for (final entry in entries) ...[
                _LiveItem(id: entry.key, qty: entry.value),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.stroke),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  children: [
                    _Price(
                      'Subtotal',
                      _brl(s.cartSubtotal),
                    ),
                    const SizedBox(height: 10),
                    _Price(
                      'Entrega',
                      entries.isNotEmpty && quotedFee == null
                          ? 'Calculada no endereço'
                          : _brl(delivery),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1),
                    ),
                    if(credit>0) _Price('Voucher aplicado', '−${_brl(credit)}'),
                    _Price(quotedFee==null?'Produtos':'Total estimado', _brl(total), strong: true),
                  ],
                ),
              ),
              if (s.storeStatusKnown && !s.storeOpen) Padding(
                padding: const EdgeInsets.only(top:14),
                child: Text(s.storeMessage, style: const TextStyle(color: Color(0xFF795D28), height:1.5)),
              ),
              const SizedBox(height: 14),
            ],
          ],
        )),
        if(entries.isNotEmpty)Container(padding:const EdgeInsets.fromLTRB(20,14,20,16),decoration:const BoxDecoration(color:Colors.white,border:Border(top:BorderSide(color:AppColors.stroke))),child:Column(mainAxisSize:MainAxisSize.min,children:[
          Row(children:[Expanded(child:Text(quotedFee==null?'Produtos no carrinho':'Total estimado',style:const TextStyle(fontSize:12,color:AppColors.muted))),Text(_brl(total),style:const TextStyle(fontSize:23,fontWeight:FontWeight.w800,color:AppColors.ocean900))]),const SizedBox(height:10),
          SizedBox(width:double.infinity,height:54,child:FilledButton.icon(onPressed:_opening||s.loading||!s.storeStatusKnown||!s.storeOpen?null:_startCheckout,icon:s.loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(AppIcons.arrowRight,size:18),label:Text(_opening||s.loading?'Preparando…':!s.storeStatusKnown?'Verificando loja…':s.storeOpen?'Escolher entrega':'Loja fechada no momento'))),
        ])),
        ])),
      );
    },
  );
}

String _brl(double value) =>
    'R\$ ' + value.toStringAsFixed(2).replaceAll('.', ',');

class _Delivery extends StatelessWidget {
  const _Delivery({required this.quote});
  final Map<String,dynamic> quote;

  @override
  Widget build(BuildContext context) {
    final fee=double.tryParse(quote['deliveryFee']?.toString()??'');
    final distance=double.tryParse(quote['distanceKm']?.toString()??'');
    final duration=quote['durationMinutes'];
    final detail=fee==null
        ?'O valor é calculado pelo endereço e pela rota viária.'
        :distance==null
            ?_brl(fee)+' • taxa configurada'
            :_brl(fee)+' • '+distance.toStringAsFixed(1)+' km por rota • aproximadamente '+duration.toString()+' min';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(AppIcons.route, color: AppColors.coral),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entrega Prime',
                  style: TextStyle(fontWeight: AppFontWeight.display),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.muted,
                    height: 1.35,
                    fontWeight: AppFontWeight.medium,
                  ),
                ),

              ],
            ),
          ),
          const Icon(AppIcons.chevronRight),
        ],
      ),
    );
  }
}

class _LiveItem extends StatelessWidget {
  const _LiveItem({required this.id, required this.qty});
  final String id;
  final int qty;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final p = s.product(id);
    if (p == null) return const SizedBox.shrink();

    final price = double.tryParse(p['price'].toString()) ?? 0;
    final image = (p['imageUrl'] ?? '').toString();
    final detail = (p['category']?['name'] ?? 'Porto Prime').toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.stroke),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.surfaceSoft, AppColors.surfaceMuted],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.stroke),
            ),
            child: image.isEmpty
                ? const Icon(
                    AppIcons.package,
                    size: 30,
                    color: AppColors.ocean700,
                  )
                : Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.network(
                      image,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => const Icon(
                        AppIcons.package,
                        size: 30,
                        color: AppColors.ocean700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.ocean600,
                        fontSize: AppFontSize.caption,
                        letterSpacing: .65,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  (p['name'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 13.2,
                        fontWeight: AppFontWeight.display,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _brl(price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14.5,
                        fontWeight: AppFontWeight.display,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Semantics(
                button: true,
                label: 'Remover produto do carrinho',
                child: InkWell(
                  onTap: () => s.removeProduct(id),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: const SizedBox(
                    width: AppControl.minTap,
                    height: AppControl.minTap,
                    child: Icon(
                      AppIcons.trash,
                      size: 16,
                      color: AppColors.subtle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Container(
                height: AppControl.minTap,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.ocean50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.ocean100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CartQtyButton(
                      icon: AppIcons.minus,
                      label: 'Diminuir quantidade',
                      onTap: () => s.changeQty(id, -1),
                    ),
                    SizedBox(
                      width: 23,
                      child: Text(
                        qty.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.ocean800,
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.display,
                        ),
                      ),
                    ),
                    _CartQtyButton(
                      icon: AppIcons.plus,
                      label: 'Aumentar quantidade',
                      onTap: () => s.changeQty(id, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartQtyButton extends StatelessWidget {
  const _CartQtyButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            width: AppControl.minTap,
            height: AppControl.minTap,
            child: Icon(
              icon,
              size: 14,
              color: AppColors.ocean800,
            ),
          ),
        ),
      );
}

class _Price extends StatelessWidget {
  const _Price(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: strong ? AppColors.ink : AppColors.muted,
            fontWeight: strong ? AppFontWeight.display : AppFontWeight.medium,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: strong ? 18 : 13,
          fontWeight: AppFontWeight.display,
        ),
      ),
    ],
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) => PrimeEmptyState(
        icon: AppIcons.cart,
        title: 'Seu carrinho está vazio',
        message:
            'Escolha seus produtos favoritos e volte aqui para finalizar.',
        actionLabel: 'Descobrir produtos',
        onAction: () => AppNav.instance.go(1),
      );
}

Future<void> _checkout(BuildContext context) async {
  final s = AppState.instance;

  if (!s.loggedIn || !s.isCustomer) {
    AppNav.instance.go(3);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entre ou crie sua conta de cliente para continuar.'),
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
