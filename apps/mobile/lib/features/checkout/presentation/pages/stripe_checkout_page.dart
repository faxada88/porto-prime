import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';

class StripeCheckoutPage extends StatefulWidget {
  const StripeCheckoutPage({super.key,required this.checkoutUrl,required this.orderId});
  final String checkoutUrl,orderId;
  @override State<StripeCheckoutPage> createState()=>_StripeCheckoutPageState();
}

class _StripeCheckoutPageState extends State<StripeCheckoutPage> {
  WebViewController? controller;
  Timer? paymentTimer;
  bool pageLoading=true,confirming=false;

  @override void initState(){
    super.initState();
    controller=WebViewController();
    if(!kIsWeb){controller!
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted:(_){if(mounted)setState(()=>pageLoading=true);},
        onPageFinished:(_){if(mounted)setState(()=>pageLoading=false);},
        onWebResourceError:(_){if(mounted)setState(()=>pageLoading=false);},
      ));}
    controller!.loadRequest(Uri.parse(widget.checkoutUrl));
    paymentTimer=Timer.periodic(const Duration(seconds:2),(_)=>_checkPayment());
  }

  @override void dispose(){paymentTimer?.cancel();super.dispose();}

  Future<void> _checkPayment()async{
    if(confirming||!mounted)return;
    try{
      await AppState.instance.loadOrders();
      final paid=AppState.instance.orders.any((o)=>o['id'].toString()==widget.orderId&&o['paymentStatus']=='PAID');
      if(paid){paymentTimer?.cancel();if(mounted){setState(()=>confirming=true);await AppState.instance.loadActiveOrder();if(mounted)Navigator.pop(context,true);}}
    }catch(_){}
  }

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:AppColors.canvas,
    appBar:AppBar(
      backgroundColor:Colors.white,surfaceTintColor:Colors.white,elevation:0,
      leading:IconButton(onPressed:()=>Navigator.pop(context,false),icon:const Icon(Icons.close_rounded)),
      title:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Finalizar pagamento',style:TextStyle(fontSize:15,fontWeight:FontWeight.w900)),
        Text('Stripe • checkout incorporado',style:TextStyle(fontSize:9,color:AppColors.muted,fontWeight:FontWeight.w600))
      ]),
      actions:[Container(margin:const EdgeInsets.only(right:14),padding:const EdgeInsets.symmetric(horizontal:9,vertical:6),decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(11)),child:const Row(children:[Icon(Icons.lock_rounded,color:AppColors.oceanDeep,size:15),SizedBox(width:5),Text('SEGURO',style:TextStyle(color:AppColors.oceanDeep,fontSize:8,fontWeight:FontWeight.w900,letterSpacing:.5))]))],
    ),
    body:Stack(children:[
      WebViewWidget(controller:controller!),
      if(pageLoading)const LinearProgressIndicator(minHeight:2),
      if(confirming)Container(color:Colors.white.withValues(alpha:.96),alignment:Alignment.center,child:const Column(mainAxisSize:MainAxisSize.min,children:[
        Container(width:68,height:68,decoration:BoxDecoration(color:AppColors.mint,shape:BoxShape.circle),child:Icon(Icons.check_rounded,color:AppColors.oceanDeep,size:38)),
        SizedBox(height:17),Text('Pagamento confirmado!',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
        SizedBox(height:5),Text('Preparando o acompanhamento do seu pedido…',style:TextStyle(color:AppColors.muted,fontSize:11)),
      ])),
    ]),
  );
}
