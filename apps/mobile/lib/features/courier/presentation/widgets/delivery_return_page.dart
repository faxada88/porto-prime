import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';
class DeliveryReturnPage extends StatefulWidget {
 const DeliveryReturnPage({super.key,required this.order});
 final Map<String,dynamic> order;
 @override State<DeliveryReturnPage> createState()=>_DeliveryReturnPageState();
}
class _DeliveryReturnPageState extends State<DeliveryReturnPage> {
 bool busy=false;String? error;
 Future<void> advance(String step)async{setState((){busy=true;error=null;});try{await AppState.instance.api.request('POST','/orders/cancellations/${widget.order['cancellation']['id']}/return/$step');await AppState.instance.refreshCourier();}catch(e){if(mounted)setState(()=>error=PrimeMessages.friendly(e));}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext context){final status=widget.order['cancellation']['returnStatus'];return Scaffold(backgroundColor:AppColors.canvas,appBar:AppBar(title:const Text('Devolução à distribuidora')),body:SafeArea(child:ListView(padding:const EdgeInsets.all(24),children:[
 Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:AppColors.ocean900,borderRadius:BorderRadius.circular(26)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(AppIcons.route,color:Colors.white,size:40),const SizedBox(height:20),Text(status=='ARRIVED'?'Aguardando recebimento':'Retorne à distribuidora',style:const TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.w800)),const SizedBox(height:12),const Text('O cliente cancelou após a coleta. Preserve os produtos e devolva-os no mesmo ponto de retirada.',style:TextStyle(color:Colors.white,height:1.6))])),
 const SizedBox(height:20),Text(status=='ARRIVED'?'Avise a equipe da loja. A operação termina quando o Admin confirmar os produtos recebidos.':status=='IN_TRANSIT'?'Ao chegar à distribuidora, entregue os produtos à equipe e informe sua chegada.':'Inicie a devolução. Você permanece ocupado até a loja confirmar o recebimento.',style:const TextStyle(height:1.6,color:AppColors.muted)),const SizedBox(height:20),const Text('A taxa de entrega foi repassada integralmente à sua carteira.',style:TextStyle(fontWeight:FontWeight.w700)),if(error!=null)Padding(padding:const EdgeInsets.only(top:16),child:PrimeErrorBanner(message:error!)),const SizedBox(height:24),SizedBox(height:54,child:FilledButton.icon(onPressed:busy||status=='ARRIVED'?null:()=>advance(status=='REQUIRED'?'start':'arrived'),icon:const Icon(AppIcons.store),label:Text(busy?'Atualizando…':status=='REQUIRED'?'Iniciar devolução':status=='IN_TRANSIT'?'Cheguei à distribuidora':'Aguardando confirmação do Admin'))),TextButton(onPressed:busy?null:()=>AppState.instance.refreshCourier(),child:const Text('Atualizar status'))
 ])));}
}
