import 'package:flutter/material.dart';
import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import 'order_tracking_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override State<OrdersPage> createState()=>_OrdersPageState();
}
class _OrdersPageState extends State<OrdersPage>{
  bool loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{try{await Future.wait([AppState.instance.loadOrders(),AppState.instance.loadActiveOrder()]);}finally{if(mounted)setState(()=>loading=false);}}
  bool _finished(dynamic o)=>o['status']=='DELIVERED'||o['status']=='CANCELED';
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:AppColors.canvas,
    appBar:AppBar(backgroundColor:AppColors.canvas,surfaceTintColor:AppColors.canvas,title:const Text('Pedidos',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(tooltip:'Início',onPressed:(){Navigator.of(context).popUntil((r)=>r.isFirst);AppNav.instance.go(0);},icon:const Icon(Icons.home_rounded))]),
    body:AnimatedBuilder(animation:AppState.instance,builder:(_,__){
      final all=AppState.instance.orders,active=all.where((o)=>!_finished(o)).toList(),history=all.where(_finished).toList();
      if(loading&&all.isEmpty)return const Center(child:CircularProgressIndicator());
      if(all.isEmpty)return RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(24),children:[const SizedBox(height:80),const Icon(Icons.receipt_long_outlined,size:64,color:AppColors.muted),const SizedBox(height:18),const Text('Nenhum pedido ainda',textAlign:TextAlign.center,style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('Quando você fizer seu primeiro pedido, ele aparecerá aqui.',textAlign:TextAlign.center,style:TextStyle(color:AppColors.muted)),const SizedBox(height:20),FilledButton(onPressed:(){Navigator.pop(context);AppNav.instance.go(0);},child:const Text('Ir para o início'))]));
      return RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(20,10,20,36),children:[
        if(active.isNotEmpty)...[const Text('Pedido atual',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,letterSpacing:-.5)),const SizedBox(height:5),const Text('Acompanhe cada etapa em tempo real.',style:TextStyle(color:AppColors.muted,fontSize:11)),const SizedBox(height:14),...active.map((o)=>_OrderCard(order:o,active:true))],
        if(history.isNotEmpty)...[SizedBox(height:active.isEmpty?4:24),const Text('Pedidos anteriores',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:12),...history.map((o)=>_OrderCard(order:o,active:false))],
      ]));}),
  );
}
class _OrderCard extends StatelessWidget{
 const _OrderCard({required this.order,required this.active});final dynamic order;final bool active;
 @override Widget build(BuildContext context){final id=order['id'].toString(),items=(order['items'] as List?)??const [],status=order['status'].toString(),paid=order['paymentStatus']=='PAID';
 return Padding(padding:const EdgeInsets.only(bottom:12),child:Material(color:active?const Color(0xFF132D28):Colors.white,borderRadius:BorderRadius.circular(25),clipBehavior:Clip.antiAlias,child:InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OrderTrackingPage(orderId:id))),child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Row(children:[Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:6),decoration:BoxDecoration(color:active?Colors.white12:AppColors.mint,borderRadius:BorderRadius.circular(10)),child:Text(active?'EM ANDAMENTO':_status(status),style:TextStyle(fontSize:8,fontWeight:FontWeight.w900,letterSpacing:.6,color:active?Colors.white:AppColors.oceanDeep))),const Spacer(),Icon(Icons.chevron_right_rounded,color:active?Colors.white70:AppColors.muted)]),
  const SizedBox(height:14),Text('Pedido #${id.substring(0,id.length<8?id.length:8).toUpperCase()}',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900,color:active?Colors.white:AppColors.ink)),const SizedBox(height:5),
  Text(items.isEmpty?'Pedido Porto Prime':items.map((x)=>'${x['quantity']}x ${x['productName']}').join(' • '),maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:10,height:1.4,color:active?Colors.white70:AppColors.muted)),
  const SizedBox(height:15),Row(children:[Icon(paid?Icons.verified_rounded:Icons.schedule_rounded,size:16,color:active?const Color(0xFF8CFFE4):AppColors.oceanDeep),const SizedBox(width:6),Text(paid?'Pagamento aprovado':'Pagamento pendente',style:TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:active?Colors.white70:AppColors.muted)),const Spacer(),Text(_money(order['total']),style:TextStyle(fontSize:15,fontWeight:FontWeight.w900,color:active?Colors.white:AppColors.ink))])
 ])))));}
}
String _money(dynamic v){final n=double.tryParse(v.toString())??0;return 'R\$ ${n.toStringAsFixed(2).replaceAll('.',',')}';}
String _status(String s)=>switch(s){'DELIVERED'=>'ENTREGUE','CANCELED'=>'CANCELADO',_=>s.replaceAll('_',' ')};
