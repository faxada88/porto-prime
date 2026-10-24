import 'dart:async';
import 'package:flutter/material.dart';
import 'courier_delivery_surface.dart';
import '../../../../core/widgets/prime_ui.dart';

/// One request at a time. Expiry never dismisses a pending acceptance.
class IncomingDeliveryOfferSheet extends StatefulWidget {
 const IncomingDeliveryOfferSheet({super.key,required this.order,required this.onAccept,required this.onReject,this.updates,this.isAvailable,this.embedded=false,this.onResolved,this.onBusyChanged});
 final bool embedded;
 final VoidCallback? onResolved;
 final ValueChanged<bool>? onBusyChanged;
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
  if(widget.embedded){
   WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)widget.onResolved?.call();});
   return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_){if(mounted&&ModalRoute.of(context)?.isCurrent==true)Navigator.of(context).pop();});
 }
 Future<void> _respond(bool accept) async {
  if(_busy||_closing||_seconds==0)return;
  setState((){_busy=true;_action=accept?'accept':'reject';_error=null;});
  widget.onBusyChanged?.call(true);
  try{
   await (accept?widget.onAccept():widget.onReject());
   _close();
  }catch(error){
   if(mounted)setState(()=>_error=PrimeMessages.friendly(error));
  }finally{
   widget.onBusyChanged?.call(false);
   if(mounted)setState(()=>_busy=false);
  }
 }
 @override void dispose(){_timer?.cancel();widget.updates?.removeListener(_sync);super.dispose();}
 @override Widget build(BuildContext context){
  final card=CourierDeliverySurface(order:widget.order,incoming:true,seconds:_seconds,
   busy:_busy,action:_action,error:_error,
   onAccept:_seconds==0?null:()=>_respond(true),
   onReject:_seconds==0?null:()=>_respond(false));
  if(widget.embedded)return card;
  return PopScope(canPop:!_busy,child:Container(
   constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(context).height*.9),
   decoration:const BoxDecoration(color:Color(0xFFF5F9FA),
    borderRadius:BorderRadius.vertical(top:Radius.circular(28))),
   child:SafeArea(top:false,child:SingleChildScrollView(
    padding:const EdgeInsets.fromLTRB(14,12,14,20),
    child:Column(mainAxisSize:MainAxisSize.min,children:[
     Container(width:38,height:4,decoration:BoxDecoration(color:const Color(0xFFCBDDE2),
      borderRadius:BorderRadius.circular(4))),
     const SizedBox(height:12),card,
    ]),
   )),
  ));
 }
}
