import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../state/customer_activity.dart';
import '../theme/app_theme.dart';
import '../../features/orders/presentation/pages/order_tracking_page.dart';
import '../../features/wallet/presentation/pages/customer_prime_card_page.dart';
class CustomerActivityPage extends StatefulWidget{
 const CustomerActivityPage({super.key});
 @override State<CustomerActivityPage> createState()=>_ActivityPageState();
}
class _ActivityPageState extends State<CustomerActivityPage>{
 String? error;
 @override void initState(){super.initState();_refresh();}
 Future<void> _refresh()async{
  try{await Future.wait([AppState.instance.loadOrders(),AppState.instance.loadActiveOrder()]);if(mounted)setState(()=>error=null);}
  catch(_){if(mounted)setState(()=>error='Não foi possível atualizar agora. Puxe para tentar novamente.');}
 }
 @override Widget build(BuildContext context)=>AnimatedBuilder(animation:CustomerActivity.instance,builder:(context,_){
  final activity=CustomerActivity.instance;
  return Scaffold(backgroundColor:AppColors.canvas,appBar:AppBar(title:const Text('Notificações'),actions:[
   TextButton(onPressed:activity.unread==0?null:activity.markRead,child:const Text('Marcar lidas'))]),
   body:RefreshIndicator(onRefresh:_refresh,child:ListView(padding:const EdgeInsets.all(20),physics:const AlwaysScrollableScrollPhysics(),children:[
    if(error!=null)Text(error!,style:const TextStyle(color:AppColors.danger)),
    if(activity.entries.isEmpty)const Padding(padding:EdgeInsets.symmetric(vertical:60),child:Column(children:[
     Icon(Icons.notifications_none_rounded,size:42,color:AppColors.ocean700),SizedBox(height:18),Text('Tudo em dia',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),SizedBox(height:8),Text('Atualizações dos seus pedidos e créditos aparecerão aqui.',textAlign:TextAlign.center)])),
    for(final e in activity.entries)Padding(padding:const EdgeInsets.only(bottom:10),child:Material(
     color:e['read']==true?AppColors.surface:AppColors.ocean50,borderRadius:BorderRadius.circular(18),
     child:ListTile(contentPadding:const EdgeInsets.all(16),
      leading:Icon(e['kind']=='credit'?Icons.account_balance_wallet_outlined:Icons.receipt_long_outlined,color:AppColors.ocean700),
      title:Text('${e['title']}',style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${e['detail']}'),
      trailing:const Icon(Icons.chevron_right_rounded),onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>
       e['kind']=='credit'?const CustomerPrimeCardPage():OrderTrackingPage(orderId:'${e['orderId']}')))))),
   ])));
 });
}
