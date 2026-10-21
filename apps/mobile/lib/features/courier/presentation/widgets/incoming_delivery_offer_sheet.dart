import '../../../../core/localization/prime_localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';

/// One request at a time. Expiry never dismisses a pending acceptance.
class IncomingDeliveryOfferSheet extends StatefulWidget {
 const IncomingDeliveryOfferSheet({super.key,required this.order,required this.onAccept,required this.onReject,this.updates,this.isAvailable});
 final Map<String,dynamic> order;
 final Future<void> Function() onAccept,onReject;
 final Listenable? updates;
 final bool Function()? isAvailable;
 @override State<IncomingDeliveryOfferSheet> createState()=>_IncomingDeliveryOfferSheetState();
}
class _IncomingDeliveryOfferSheetState extends State<IncomingDeliveryOfferSheet> {
 Timer? _timer;
 bool _busy=false,_closing=false;
 String? _action,_error;
 int _seconds=0;
 @override void initState(){
  super.initState();
  _seconds=_remaining();
  widget.updates?.addListener(_sync);
  _timer=Timer.periodic(const Duration(seconds:1),(_)=>_sync());
  WidgetsBinding.instance.addPostFrameCallback((_)=>_sync());
 }
 int _remaining(){final expiry=DateTime.tryParse(widget.order['expiresAt']?.toString()??'');return expiry==null?0:(expiry.difference(DateTime.now()).inMilliseconds/1000).ceil().clamp(0,3600);}
 void _sync(){
  if(!mounted||_closing)return;
  final seconds=_remaining();
  if(seconds!=_seconds)setState(()=>_seconds=seconds);
  if(!_busy&&(seconds==0||widget.isAvailable?.call()==false))_close();
 }
 void _close(){
  if(!mounted||_closing)return;
  _closing=true;
  WidgetsBinding.instance.addPostFrameCallback((_){if(mounted&&ModalRoute.of(context)?.isCurrent==true)Navigator.of(context).pop();});
 }
 Future<void> _respond(bool accept) async {
  if(_busy||_closing||_seconds==0)return;
  setState((){_busy=true;_action=accept?'accept':'reject';_error=null;});
  try{
   await (accept?widget.onAccept():widget.onReject());
   _close();
  }catch(error){
   if(mounted)setState(()=>_error=PrimeMessages.friendly(error));
  }finally{
   if(mounted)setState(()=>_busy=false);
  }
 }
 @override void dispose(){_timer?.cancel();widget.updates?.removeListener(_sync);super.dispose();}
 String _money(dynamic value)=>'R\$ ${(double.tryParse(value?.toString()??'')??0).toStringAsFixed(2).replaceAll('.',',')}';
 String _metric(dynamic value,String unit){final number=double.tryParse(value?.toString()??'');return number==null?'—': '${number.toStringAsFixed(unit=='km'?1:0).replaceAll('.',',')} $unit';}
 @override Widget build(BuildContext context){
  final order=widget.order;
  final pickup=Map<String,dynamic>.from(order['pickup']??{}),dropoff=Map<String,dynamic>.from(order['dropoff']??{});
  return PopScope(canPop:!_busy,child:Container(
   constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(context).height*.9),
   decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(28))),
   child:SafeArea(top:false,child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(22,12,22,20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Center(child:Container(width:38,height:4,decoration:BoxDecoration(color:AppColors.stroke,borderRadius:BorderRadius.circular(4)))),
    const SizedBox(height:20),
    Row(children:[const Expanded(child:PrimeText('Nova entrega',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:AppColors.ocean900))),const SizedBox(width:12),Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:_seconds<=8?AppColors.coral100:AppColors.ocean50,borderRadius:BorderRadius.circular(12)),child:PrimeText('$_seconds s',style:TextStyle(fontWeight:FontWeight.w800,color:_seconds<=8?AppColors.coral600:AppColors.ocean900)))]),
    const SizedBox(height:18),
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:AppColors.ocean900,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     const PrimeText('VOCÊ RECEBE',style:TextStyle(fontSize:10,letterSpacing:1.2,fontWeight:FontWeight.w700,color:Colors.white70)),const SizedBox(height:7),
     PrimeText(_money(order['courierEarnings']??order['deliveryFee']),style:const TextStyle(fontSize:34,fontWeight:FontWeight.w800,color:Colors.white)),
     const SizedBox(height:12),Wrap(spacing:18,runSpacing:8,children:[PrimeText(_metric(order['routeDistanceKm'],'km'),style:const TextStyle(color:Colors.white,fontSize:13)),PrimeText(_metric(order['routeDurationMinutes'],'min'),style:const TextStyle(color:Colors.white,fontSize:13))]),
    ])),
    const SizedBox(height:20),
    _OfferStop(icon:AppIcons.storefront_rounded,label:'RETIRAR EM',title:(pickup['name']??'Porto Prime').toString(),detail:(pickup['region']??'Base Porto Prime').toString()),
    const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Divider(height:1)),
    _OfferStop(icon:AppIcons.mapPin,label:'ENTREGAR EM',title:(dropoff['neighborhood']??'Região informada').toString(),detail:(dropoff['city']??'Porto Seguro').toString()),
    const SizedBox(height:16),
    const PrimeText('O endereço completo será liberado após aceitar.',style:TextStyle(fontSize:11,color:AppColors.muted,height:1.4)),
    if(_error!=null)Padding(padding:const EdgeInsets.only(top:14),child:PrimeText(_error!,style:const TextStyle(color:AppColors.coral600,fontSize:12,height:1.4))),
    const SizedBox(height:20),
    FilledButton(onPressed:_busy||_seconds==0?null:()=>_respond(true),style:FilledButton.styleFrom(backgroundColor:AppColors.ocean900,minimumSize:const Size(double.infinity,54),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),child:_busy&&_action=='accept'?const Row(mainAxisSize:MainAxisSize.min,children:[SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)),SizedBox(width:10),PrimeText('Confirmando…')]):const PrimeText('Aceitar entrega',style:TextStyle(fontSize:15,fontWeight:FontWeight.w800))),
    const SizedBox(height:6),TextButton(onPressed:_busy||_seconds==0?null:()=>_respond(false),style:TextButton.styleFrom(minimumSize:const Size(double.infinity,46),foregroundColor:AppColors.muted),child:PrimeText(_busy&&_action=='reject'?'Enviando…':'Agora não')),
   ]))),
  ));
 }
}
class _OfferStop extends StatelessWidget {
 const _OfferStop({required this.icon,required this.label,required this.title,required this.detail});
 final IconData icon;final String label,title,detail;
 @override Widget build(BuildContext context)=>Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:38,height:38,decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(12)),child:Icon(icon,size:19,color:AppColors.ocean700)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[PrimeText(label,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:AppColors.muted,letterSpacing:1)),const SizedBox(height:4),PrimeText(title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700)),const SizedBox(height:3),PrimeText(detail,style:const TextStyle(fontSize:12,color:AppColors.muted,height:1.4))]))]);
}
