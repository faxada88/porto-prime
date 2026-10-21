import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../state/customer_activity.dart';
import '../theme/app_theme.dart';
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
  return Scaffold(backgroundColor:AppColors.canvas,appBar:AppBar(title:const PrimeText('Notificações'),actions:[]),
   body:RefreshIndicator(onRefresh:_refresh,child:ListView(padding:const EdgeInsets.all(20),physics:const AlwaysScrollableScrollPhysics(),children:[
    if(activity.unread>0)Align(alignment:Alignment.centerRight,child:TextButton(onPressed:activity.markRead,child:const PrimeText('Marcar todas como lidas'))),
    if(error!=null)PrimeText(error!,style:const TextStyle(color:AppColors.danger)),
    if(activity.unread==0)const Padding(padding:EdgeInsets.symmetric(vertical:60),child:Column(children:[
     Icon(Icons.notifications_none_rounded,size:42,color:AppColors.ocean700),SizedBox(height:18),PrimeText('Tudo em dia',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),SizedBox(height:8),PrimeText('Atualizações dos seus pedidos e créditos aparecerão aqui.',textAlign:TextAlign.center)])),
    for(final e in activity.entries.where((entry)=>entry['read']!=true))Padding(padding:const EdgeInsets.only(bottom:10),child:Material(
     color:e['read']==true?AppColors.surface:AppColors.ocean50,borderRadius:BorderRadius.circular(18),
     child:ListTile(contentPadding:const EdgeInsets.all(16),
      leading:Icon(e['kind']=='credit'?Icons.account_balance_wallet_outlined:Icons.receipt_long_outlined,color:AppColors.ocean700),
      title:PrimeText('${e['title']}',style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:PrimeText('${e['detail']}'),
      trailing:const Icon(Icons.chevron_right_rounded),onTap:(){
       activity.openEntry('${e['id']}');
       showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,
        builder:(context)=>SafeArea(top:false,child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(24,8,24,28),
         child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          PrimeText('${e['title']}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
          const SizedBox(height:14),PrimeText('${e['detail']}',style:const TextStyle(height:1.6,fontSize:15)),
          const SizedBox(height:24),FilledButton(onPressed:()=>Navigator.pop(context),child:const PrimeText('Entendi')),
         ]))));
      }))),
   ])));
 });
}
