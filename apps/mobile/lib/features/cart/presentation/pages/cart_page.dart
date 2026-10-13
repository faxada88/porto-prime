import '../../../checkout/presentation/widgets/checkout_progress.dart';
import 'package:flutter/material.dart';
import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';
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
    setState(()=>_opening=true);
    try{await _checkout(context);}finally{if(mounted)setState(()=>_opening=false);}
  }
  Future<void> _clearCart() async {
    if(_opening||AppState.instance.loading||AppState.instance.cart.isEmpty)return;
    final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24)),
      icon:const Icon(AppIcons.cart,color:AppColors.ocean700,size:30),
      title:const Text('Limpar seu carrinho?'),content:const Text('Todos os produtos serão removidos. Você pode montar um novo carrinho quando quiser.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Manter produtos')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Limpar carrinho'))],
    ));
    if(confirmed==true&&mounted)AppState.instance.clearCart();
  }
  @override
  Widget build(BuildContext context)=>AnimatedBuilder(animation:AppState.instance,builder:(_,__){
    final app=AppState.instance;
    final entries=app.cart.entries.toList();
    final working=_opening||app.loading;
    return SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:680),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Padding(padding:const EdgeInsets.fromLTRB(20,18,20,18),child:Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Seu carrinho Prime',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800,letterSpacing:-.8)),const SizedBox(height:4),Text('${app.cartCount} ${app.cartCount==1?'item':'itens'}',style:const TextStyle(fontSize:12,color:AppColors.muted))])),
        IconButton(tooltip:'Adicionar produtos',onPressed:AppNav.instance.home,icon:const Icon(AppIcons.plus,color:AppColors.ocean700)),

      ])),
      if(entries.isNotEmpty)const Padding(padding:EdgeInsets.fromLTRB(20,0,20,18),child:CheckoutProgress(step:0)),
      if(entries.isNotEmpty)Padding(padding:const EdgeInsets.fromLTRB(20,0,20,12),child:Row(children:[const Expanded(child:Text('Seus produtos',style:TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:AppColors.muted))),TextButton.icon(onPressed:working?null:_clearCart,icon:const Icon(AppIcons.trash,size:14),label:const Text('Limpar carrinho',style:TextStyle(fontSize:12)))])),
      Expanded(child:entries.isEmpty?Padding(padding:const EdgeInsets.all(20),child:Center(child:PrimeEmptyState(icon:AppIcons.cart,title:'Seu carrinho está vazio',message:'Escolha o que você quer receber hoje.',actionLabel:'Ver produtos',onAction:()=>AppNav.instance.go(1)))):ListView.separated(
        physics:const BouncingScrollPhysics(),padding:const EdgeInsets.fromLTRB(20,0,20,20),itemCount:entries.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(_,index)=>_CartItem(id:entries[index].key,qty:entries[index].value),
      )),
      if(entries.isNotEmpty)Container(padding:const EdgeInsets.fromLTRB(20,16,20,18),decoration:BoxDecoration(color:Colors.white,borderRadius:const BorderRadius.vertical(top:Radius.circular(26)),border:const Border(top:BorderSide(color:AppColors.stroke)),boxShadow:[BoxShadow(color:AppColors.ocean900.withValues(alpha:.05),blurRadius:24,offset:const Offset(0,-5))]),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
          Container(width:42,height:42,decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(13)),child:const Icon(AppIcons.cart,size:20,color:AppColors.ocean700)),const SizedBox(width:12),
          const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Entrega é o próximo passo',style:TextStyle(fontSize:14,fontWeight:FontWeight.w800,color:AppColors.ocean900)),SizedBox(height:4),Text('Subtotal dos produtos',style:TextStyle(fontSize:11,color:AppColors.muted))])),
          Text(_brl(app.cartSubtotal),style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:AppColors.ocean900)),
        ]),
        if(app.storeStatusKnown&&!app.storeOpen)Padding(padding:const EdgeInsets.only(top:10),child:Text(app.storeMessage,style:const TextStyle(fontSize:12,color:AppColors.coralStrong,height:1.4))),
        const SizedBox(height:16),
        SizedBox(height:56,child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:AppColors.ocean800,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17))),onPressed:working||!app.storeStatusKnown||!app.storeOpen?null:_startCheckout,icon:working?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(AppIcons.arrowRight,size:18),label:Text(working?'Preparando…':!app.storeStatusKnown?'Verificando loja…':app.storeOpen?'Continuar para entrega':'Loja fechada'))),
        const SizedBox(height:9),const Text('Confirme endereço, entrega e saldo no próximo passo.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:AppColors.muted)),
      ])),
    ]))));
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
    return Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(AppRadius.lg),border:Border.all(color:AppColors.stroke)),child:Column(children:[
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Container(width:76,height:76,padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:AppColors.surfaceSoft,borderRadius:BorderRadius.circular(12)),child:image.isEmpty?const Icon(AppIcons.package,size:27,color:AppColors.ocean700):Image.network(image,fit:BoxFit.contain,filterQuality:FilterQuality.medium,errorBuilder:(_,__,___)=>const Icon(AppIcons.package,size:27,color:AppColors.ocean700))),
        const SizedBox(width:12),Expanded(child:Padding(padding:const EdgeInsets.only(top:4),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w700,height:1.4)),if(qty>1)Padding(padding:const EdgeInsets.only(top:5),child:Text('${_brl(price)} cada',style:const TextStyle(fontSize:11,color:AppColors.muted)))]))),
        IconButton(tooltip:'Remover $name',onPressed:()=>app.removeProduct(id),icon:const Icon(AppIcons.trash,size:17,color:AppColors.muted)),
      ]),const SizedBox(height:12),
      Row(children:[
        Container(decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(12)),child:Row(mainAxisSize:MainAxisSize.min,children:[
          _QuantityButton(icon:AppIcons.minus,label:'Diminuir quantidade de $name',onTap:()=>app.changeQty(id,-1)),
          SizedBox(width:28,child:Text('$qty',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14,color:AppColors.ocean900))),
          _QuantityButton(icon:AppIcons.plus,label:'Aumentar quantidade de $name',onTap:()=>app.changeQty(id,1)),
        ])),const Spacer(),Text(_brl(price*qty),style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:AppColors.ocean900)),
      ]),
    ]));
  }
}
class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon,required this.label,required this.onTap});
  final IconData icon;final String label;final VoidCallback onTap;
  @override
  Widget build(BuildContext context)=>IconButton(tooltip:label,onPressed:onTap,icon:Icon(icon,size:16,color:AppColors.ocean700),constraints:const BoxConstraints(minWidth:44,minHeight:44));
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

