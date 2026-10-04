import 'package:flutter/material.dart';
import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../checkout/presentation/pages/stripe_checkout_page.dart';
import '../../../orders/presentation/pages/order_tracking_page.dart';

class CartPage extends StatefulWidget{const CartPage({super.key});@override State<CartPage> createState()=>_CartPageState();}
class _CartPageState extends State<CartPage> with SingleTickerProviderStateMixin{late final AnimationController _controller;late final Animation<double> _fade;late final Animation<Offset> _rise;@override void initState(){super.initState();_controller=AnimationController(vsync:this,duration:const Duration(milliseconds:700));_fade=CurvedAnimation(parent:_controller,curve:Curves.easeOutCubic);_rise=Tween<Offset>(begin:const Offset(0,.035),end:Offset.zero).animate(_fade);_controller.forward();}@override void dispose(){_controller.dispose();super.dispose();}@override Widget build(BuildContext context)=>AnimatedBuilder(animation:AppState.instance,builder:(_,__){final s=AppState.instance,entries=s.cart.entries.toList();return SafeArea(bottom:false,child:FadeTransition(opacity:_fade,child:SlideTransition(position:_rise,child:ListView(padding:const EdgeInsets.fromLTRB(20,18,20,125),children:[
 _CartHeader(count:s.cartCount,empty:entries.isEmpty,onClear:entries.isEmpty?null:s.clearCart),
 const SizedBox(height:18),
 if(entries.isEmpty)_Empty()else ...[
  ...entries.map((e)=>_Item(id:e.key,qty:e.value)),
  const SizedBox(height:8),_Summary(total:s.cartSubtotal),
  const SizedBox(height:12),Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(20)),child:const Row(children:[Icon(Icons.lock_rounded,color:AppColors.oceanDeep,size:20),SizedBox(width:10),Expanded(child:Text('Pagamento protegido pelo Stripe. Seus dados de cartão não passam pela Porto Prime.',style:TextStyle(fontSize:10,height:1.35,color:AppColors.oceanDeep,fontWeight:FontWeight.w700)))])),
  const SizedBox(height:14),SizedBox(height:58,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:AppColors.oceanDeep,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(19))),onPressed:s.loading?null:()=>_checkout(context),child:s.loading?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Row(mainAxisAlignment:MainAxisAlignment.center,children:[Text('Continuar para checkout',style:TextStyle(fontWeight:FontWeight.w900)),SizedBox(width:8),Icon(Icons.arrow_forward_rounded,size:19)]))),
 ] ]))));});}

class _CartHeader extends StatelessWidget{const _CartHeader({required this.count,required this.empty,this.onClear});final int count;final bool empty;final VoidCallback? onClear;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.fromLTRB(19,18,16,18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(28),border:Border.all(color:AppColors.stroke)),child:Row(children:[Container(width:52,height:52,decoration:BoxDecoration(color:AppColors.peach,borderRadius:BorderRadius.circular(18)),child:const Icon(Icons.shopping_cart_rounded,color:AppColors.primary,size:25)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Sua sacola',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:3),Text(empty?'Escolha seus favoritos para começar':'$count ${count==1?'item selecionado':'itens selecionados'}',style:const TextStyle(color:AppColors.muted,fontSize:11,fontWeight:FontWeight.w600))])),if(onClear!=null)GestureDetector(behavior:HitTestBehavior.opaque,onTap:onClear,child:const Padding(padding:EdgeInsets.all(10),child:Text('Limpar',style:TextStyle(color:AppColors.muted,fontSize:11,fontWeight:FontWeight.w700))))]));}

class _Empty extends StatelessWidget{const _Empty();@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.fromLTRB(24,42,24,32),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Colors.white,Color(0xFFF1FBF7)]),borderRadius:BorderRadius.circular(32),border:Border.all(color:AppColors.stroke),boxShadow:AppShadows.soft),child:Column(children:[Stack(alignment:Alignment.center,children:[Container(width:112,height:112,decoration:const BoxDecoration(color:AppColors.mint,shape:BoxShape.circle)),Container(width:76,height:76,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(25),boxShadow:AppShadows.soft),child:const Icon(Icons.shopping_cart_outlined,size:34,color:AppColors.primary))]),const SizedBox(height:23),const Text('Seu próximo momento\ncomeça aqui',textAlign:TextAlign.center,style:TextStyle(fontSize:24,height:1.08,fontWeight:FontWeight.w800,letterSpacing:-.7)),const SizedBox(height:9),const Text('Escolha bebidas, gelo e combos. A gente cuida do caminho até você.',textAlign:TextAlign.center,style:TextStyle(color:AppColors.muted,fontSize:11,height:1.5,fontWeight:FontWeight.w500)),const SizedBox(height:22),SizedBox(width:double.infinity,height:54,child:FilledButton.icon(onPressed:()=>AppNav.instance.go(1),icon:const Icon(Icons.explore_outlined,size:19),label:const Text('Explorar catálogo'))),const SizedBox(height:16),const Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.bolt_rounded,color:AppColors.primary,size:16),SizedBox(width:5),Text('Rápido  •  gelado  •  seguro',style:TextStyle(color:AppColors.muted,fontSize:9.5,fontWeight:FontWeight.w700))]) ]));}

class _Item extends StatelessWidget {
  const _Item({required this.id, required this.qty});
  final String id;
  final int qty;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final p = s.product(id);
    if (p == null) return const SizedBox();
    final price = double.tryParse(p['price'].toString()) ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(18)),
            child: p['imageUrl'] != null
                ? Image.network(p['imageUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.local_drink_rounded))
                : const Icon(Icons.local_drink_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text('R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(color: AppColors.oceanDeep, fontSize: 12, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => s.removeProduct(id),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.coralStrong),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    _q(Icons.remove_rounded, () => s.changeQty(id, -1)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(qty.toString(), key: ValueKey(qty), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                    ),
                    _q(Icons.add_rounded, () => s.changeQty(id, 1)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _q(IconData icon, VoidCallback tap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: Padding(padding: const EdgeInsets.all(9), child: Icon(icon, size: 16)),
      );
}

class _Summary extends StatelessWidget{const _Summary({required this.total});final double total;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(23),border:Border.all(color:const Color(0xFFE8ECE8))),child:Column(children:[_row('Subtotal','R\$ '+total.toStringAsFixed(2).replaceAll('.',',')),const SizedBox(height:10),_row('Entrega','Calculada no pedido',muted:true),const Padding(padding:EdgeInsets.symmetric(vertical:13),child:Divider(height:1)),_row('Total','R\$ '+total.toStringAsFixed(2).replaceAll('.',','),strong:true)]));Widget _row(String a,String b,{bool muted=false,bool strong=false})=>Row(children:[Expanded(child:Text(a,style:TextStyle(fontSize:strong?15:11,fontWeight:strong?FontWeight.w900:FontWeight.w700,color:muted?AppColors.muted:AppColors.ink))),Text(b,style:TextStyle(fontSize:strong?18:11,fontWeight:strong?FontWeight.w900:FontWeight.w700,color:muted?AppColors.muted:AppColors.ink))]);}

Future<void> _checkout(BuildContext context) async {
  final s = AppState.instance;
  if (!s.loggedIn || !s.isCustomer) {
    AppNav.instance.go(3);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entre ou crie sua conta de cliente para continuar.')));
    return;
  }
  if (s.addresses.isEmpty) {
    AppNav.instance.go(3);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastre um endereço de entrega no Perfil.')));
    return;
  }

  String selected = s.addresses.firstWhere((a) => a['isDefault'] == true, orElse: () => s.addresses.first)['id'].toString();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => Material(
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
                Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFD8DDDA), borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 18),
                const Text('Confirmar entrega', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Escolha onde receber seu pedido.', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                const SizedBox(height: 14),
                ...s.addresses.map((a) => RadioListTile<String>(
                  value: a['id'].toString(),
                  groupValue: selected,
                  onChanged: (v) => set(() => selected = v!),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.oceanDeep,
                  title: Text('${a['street'] ?? ''}, ${a['number'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  subtitle: Text('${a['neighborhood'] ?? ''} • Porto Seguro', style: const TextStyle(fontSize: 10)),
                )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(17)),
                  child: const Row(children: [Icon(Icons.lock_rounded, color: AppColors.oceanDeep, size: 19), SizedBox(width: 9), Expanded(child: Text('Pagamento seguro dentro do app. A confirmação aparece imediatamente após o Stripe aprovar.', style: TextStyle(fontSize: 9, height: 1.35, color: AppColors.oceanDeep, fontWeight: FontWeight.w700)))]),
                ),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, height: 54, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.oceanDeep), onPressed: () => Navigator.pop(c, true), child: const Text('Continuar para pagamento', style: TextStyle(fontWeight: FontWeight.w900)))),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  if (ok != true) return;

  try {
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
      final tracking = Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderTrackingPage(orderId: orderId)),
      );
      s.clearCart();
      await tracking;
    } else if (result == 'shop') {
      s.clearCart();
      AppNav.instance.go(0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido criado. Você pode concluir o pagamento depois.')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }
}
