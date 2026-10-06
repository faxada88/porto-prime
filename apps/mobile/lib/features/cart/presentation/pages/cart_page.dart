import 'package:flutter/material.dart';

import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../checkout/presentation/pages/stripe_checkout_page.dart';
import '../../../orders/presentation/pages/order_tracking_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppState.instance,
    builder: (_, __) {
      final s = AppState.instance;
      final entries = s.cart.entries.toList();
      final quotedFee =
          double.tryParse(s.deliveryQuote['deliveryFee']?.toString() ?? '');
      final delivery = entries.isEmpty ? 0.0 : (quotedFee ?? 0.0);
      final total = s.cartSubtotal + delivery;

      return SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sua sacola',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s.cartCount.toString() +
                        (s.cartCount == 1 ? ' item' : ' itens'),
                    style: const TextStyle(
                      color: AppColors.oceanDeep,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Já já seu brinde chega.',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            _Delivery(quote: s.deliveryQuote),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8EBE6)),
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
                    _Price('Total', _brl(total), strong: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: s.loading ? null : () => _checkout(context),
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.oceanDeep, AppColors.turquoise],
                    ),
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33007F73),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: s.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continuar para entrega',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ],
        ),
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
            :_brl(fee)+' • '+distance.toStringAsFixed(1)+' km • ~'+duration.toString()+' min';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(22),
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
              child: Icon(Icons.route_rounded, color: AppColors.coral),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entrega Prime',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: image.isEmpty
                ? const Icon(Icons.local_drink_rounded, size: 38)
                : Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.local_drink_rounded, size: 38),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (p['name'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _brl(price),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => s.changeQty(id, -1),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.remove_rounded, size: 17),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    qty.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                InkWell(
                  onTap: () => s.changeQty(id, 1),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.add_rounded, size: 17),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: strong ? 18 : 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 34, 20, 34),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8EBE6)),
    ),
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.oceanDeep,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sua sacola está vazia',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Escolha suas bebidas favoritas e volte aqui para finalizar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => AppNav.instance.go(1),
          child: const Text('Descobrir produtos'),
        ),
      ],
    ),
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

  if (s.addresses.isEmpty) {
    AppNav.instance.go(3);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cadastre um endereço de entrega no Perfil.'),
      ),
    );
    return;
  }

  String selected = s.addresses
      .firstWhere(
        (a) => a['isDefault'] == true,
        orElse: () => s.addresses.first,
      )['id']
      .toString();

  Map<String,dynamic> quote={};
  String? quoteError;
  bool quoteLoading=true;
  try{
    quote=await s.quoteDelivery(selected);
    quoteLoading=false;
  }catch(e){
    quoteLoading=false;
    quoteError=e.toString().replaceFirst('Exception: ','');
  }

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DDDA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Confirmar entrega',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Escolha onde receber seu pedido.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 14),
                ...s.addresses.map(
                  (a) => RadioListTile<String>(
                    value: a['id'].toString(),
                    groupValue: selected,
                    onChanged: (v) async {
                      if(v==null)return;
                      setSheetState((){
                        selected=v;
                        quoteLoading=true;
                        quoteError=null;
                      });
                      try{
                        final next=await s.quoteDelivery(v);
                        if(sheetContext.mounted){
                          setSheetState((){
                            quote=next;
                            quoteLoading=false;
                          });
                        }
                      }catch(e){
                        if(sheetContext.mounted){
                          setSheetState((){
                            quoteLoading=false;
                            quoteError=e.toString().replaceFirst('Exception: ','');
                          });
                        }
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.oceanDeep,
                    title: Text(
                      (a['street'] ?? '').toString() +
                          ', ' +
                          (a['number'] ?? '').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      (a['neighborhood'] ?? '').toString() +
                          ' • Porto Seguro',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width:double.infinity,
                  padding:const EdgeInsets.all(14),
                  decoration:BoxDecoration(
                    color:quoteError!=null?AppColors.peach:AppColors.sand,
                    borderRadius:BorderRadius.circular(17),
                  ),
                  child:quoteLoading
                      ?const Row(children:[
                          SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)),
                          SizedBox(width:10),
                          Text('Calculando rota e taxa de entrega...',style:TextStyle(fontSize:9.5,fontWeight:FontWeight.w700)),
                        ])
                      :quoteError!=null
                          ?Row(children:[
                              const Icon(Icons.error_outline_rounded,color:AppColors.coralStrong,size:19),
                              const SizedBox(width:9),
                              Expanded(child:Text(quoteError!,style:const TextStyle(color:AppColors.coralStrong,fontSize:9.5,height:1.35,fontWeight:FontWeight.w700))),
                            ])
                          :Row(children:[
                              const Icon(Icons.route_rounded,color:Color(0xFF986414),size:20),
                              const SizedBox(width:9),
                              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                                Text('Entrega '+_brl(double.tryParse(quote['deliveryFee']?.toString()??'')??0),style:const TextStyle(fontSize:11.5,fontWeight:FontWeight.w900)),
                                const SizedBox(height:2),
                                Text(
                                  quote['distanceKm']==null
                                      ?'Taxa base configurada pela operação.'
                                      :(double.tryParse(quote['distanceKm'].toString())??0).toStringAsFixed(1)+' km por rota • ~'+(quote['durationMinutes']??'—').toString()+' min',
                                  style:const TextStyle(fontSize:9,color:AppColors.muted,fontWeight:FontWeight.w600),
                                ),
                              ])),
                            ]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        color: AppColors.oceanDeep,
                        size: 19,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Pagamento seguro dentro do app. A confirmação aparece após o Stripe aprovar.',
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.35,
                            color: AppColors.oceanDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: quoteLoading || quoteError!=null
                        ? null
                        : () => Navigator.pop(sheetContext, true),
                    child: const Text(
                      'Continuar para pagamento',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  if (ok != true) return;

  try {
    await s.quoteDelivery(selected);
    final order = await s.createOrder(selected);
    if (!context.mounted) return;

    final orderId = order['id'].toString();
    final payment = await s.createCheckout(orderId);
    if (!context.mounted) return;

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => StripeCheckoutPage(
          clientSecret: payment['clientSecret'].toString(),
          publishableKey: payment['publishableKey'].toString(),
          orderId: orderId,
        ),
      ),
    );

    if (!context.mounted) return;

    if (result == 'track') {
      s.clearCart();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderTrackingPage(orderId: orderId),
        ),
      );
    } else if (result == 'shop') {
      s.clearCart();
      AppNav.instance.go(0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pedido criado. Você pode concluir o pagamento depois.',
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }
}
