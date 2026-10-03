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
  bool pageLoading=true,confirming=false;
  @override void initState(){
    super.initState();
    controller=WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted:(url){if(mounted)setState(()=>pageLoading=true);_check(url);},
        onPageFinished:(url){if(mounted)setState(()=>pageLoading=false);_check(url);},
        onWebResourceError:(e){if(mounted)setState(()=>pageLoading=false);},
      ))
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  Future<void> _check(String url)async{
    if(confirming)return;
    final uri=Uri.tryParse(url);
    if(uri?.queryParameters['checkout']=='success'){await _finish();}
    if(uri?.queryParameters['checkout']=='cancel'&&mounted)Navigator.pop(context,false);
  }

  Future<void> _finish()async{
    if(confirming)return;
    setState(()=>confirming=true);
    final paid=await AppState.instance.refreshPayment(widget.orderId);
    if(!mounted)return;
    if(paid){Navigator.pop(context,true);}else{setState(()=>confirming=false);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Pagamento recebido. Estamos aguardando a confirmação segura do Stripe.')));}
  }

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:AppColors.canvas,
    appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,elevation:0,leading:IconButton(onPressed:()=>Navigator.pop(context,false),icon:const Icon(Icons.close_rounded)),title:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Pagamento seguro',style:TextStyle(fontSize:15,fontWeight:FontWeight.w900)),Text('Stripe • ambiente protegido',style:TextStyle(fontSize:9,color:AppColors.muted,fontWeight:FontWeight.w600))]),actions:[const Padding(padding:EdgeInsets.only(right:16),child:Icon(Icons.lock_rounded,color:AppColors.oceanDeep,size:20))]),
    body:Stack(children:[
      WebViewWidget(controller:controller!),
      if(pageLoading)const LinearProgressIndicator(minHeight:2),
      if(confirming)Container(color:Colors.white.withValues(alpha:.94),alignment:Alignment.center,child:const Column(mainAxisSize:MainAxisSize.min,children:[CircularProgressIndicator(),SizedBox(height:16),Text('Confirmando seu pagamento...',style:TextStyle(fontWeight:FontWeight.w900)),SizedBox(height:5),Text('Não feche esta tela.',style:TextStyle(color:AppColors.muted,fontSize:11))])),
    ]),
  );
}

