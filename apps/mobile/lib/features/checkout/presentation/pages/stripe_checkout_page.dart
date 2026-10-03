import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';

class StripeCheckoutPage extends StatefulWidget {
  const StripeCheckoutPage({
    super.key,
    required this.clientSecret,
    required this.publishableKey,
    required this.orderId,
  });
  final String clientSecret;
  final String publishableKey;
  final String orderId;

  @override
  State<StripeCheckoutPage> createState()=>_StripeCheckoutPageState();
}

class _StripeCheckoutPageState extends State<StripeCheckoutPage> {
  bool ready=false;
  bool paying=false;
  bool cardComplete=false;
  String? error;

  @override
  void initState(){
    super.initState();
    _configure();
  }

  Future<void> _configure()async{
    try{
      Stripe.publishableKey=widget.publishableKey;
      await Stripe.instance.applySettings();
      if(!kIsWeb){
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters:SetupPaymentSheetParameters(
            paymentIntentClientSecret:widget.clientSecret,
            merchantDisplayName:'Porto Prime',
            style:ThemeMode.light,
          ),
        );
      }
      if(mounted)setState(()=>ready=true);
    }catch(e){
      if(mounted)setState(()=>error=_message(e));
    }
  }

  String _message(Object e){
    if(e is StripeException)return e.error.localizedMessage??'Não foi possível iniciar o pagamento.';
    return e.toString().replaceFirst('Exception: ','');
  }

  Future<void> _pay()async{
    if(paying)return;
    setState(()=>paying=true,error=null);
    try{
      if(kIsWeb){
        await Stripe.instance.confirmPayment(
          paymentIntentClientSecret:widget.clientSecret,
          data:PaymentMethodParams.card(
            paymentMethodData:PaymentMethodData(),
          ),
        );
      }else{
        await Stripe.instance.presentPaymentSheet();
      }

      final paid=await AppState.instance.refreshPayment(widget.orderId);
      if(!mounted)return;
      if(paid){
        Navigator.pop(context,true);
      }else{
        setState(()=>paying=false,error:'Pagamento processado. Aguardando confirmação segura do Stripe; tente atualizar em alguns segundos.');
      }
    }on StripeException catch(e){
      if(!mounted)return;
      final canceled=e.error.code==FailureCode.Canceled;
      setState(()=>paying=false,error:canceled?null:(e.error.localizedMessage??'Pagamento não concluído.'));
    }catch(e){
      if(mounted)setState(()=>paying=false,error=_message(e));
    }
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    backgroundColor:AppColors.canvas,
    appBar:AppBar(
      backgroundColor:Colors.white,surfaceTintColor:Colors.white,elevation:0,
      leading:IconButton(onPressed:paying?null:()=>Navigator.pop(context,false),icon:const Icon(Icons.close_rounded)),
      title:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Pagamento seguro',style:TextStyle(fontSize:15,fontWeight:FontWeight.w900)),
        Text('Stripe • dentro da Porto Prime',style:TextStyle(fontSize:9,color:AppColors.muted,fontWeight:FontWeight.w600)),
      ]),
      actions:[const Padding(padding:EdgeInsets.only(right:16),child:Icon(Icons.lock_rounded,color:AppColors.oceanDeep,size:20))],
    ),
    body:SafeArea(child:ListView(padding:const EdgeInsets.all(20),children:[
      Container(
        padding:const EdgeInsets.all(18),
        decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:const Color(0xFFE8ECE8))),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[Icon(Icons.verified_user_rounded,color:AppColors.oceanDeep),SizedBox(width:10),Expanded(child:Text('Seus dados são enviados diretamente ao Stripe',style:TextStyle(fontSize:13,fontWeight:FontWeight.w900)))]),
          const SizedBox(height:8),
          const Text('A Porto Prime não armazena o número do seu cartão.',style:TextStyle(color:AppColors.muted,fontSize:10,height:1.4)),
          if(kIsWeb)...[
            const SizedBox(height:22),
            const Text('Dados do cartão',style:TextStyle(fontSize:12,fontWeight:FontWeight.w900)),
            const SizedBox(height:10),
            Container(
              padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),
              decoration:BoxDecoration(border:Border.all(color:const Color(0xFFDDE3DF)),borderRadius:BorderRadius.circular(14)),
              child:CardField(
                onCardChanged:(card){if(mounted)setState(()=>cardComplete=card?.complete??false);},
                decoration:const InputDecoration(border:InputBorder.none),
              ),
            ),
          ]else...[
            const SizedBox(height:18),
            const Row(children:[Icon(Icons.credit_card_rounded,color:AppColors.oceanDeep),SizedBox(width:10),Expanded(child:Text('O formulário nativo do Stripe abrirá sobre esta tela.',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700)))]),
          ],
        ]),
      ),
      if(error!=null)...[
        const SizedBox(height:12),
        Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:AppColors.sand,borderRadius:BorderRadius.circular(16)),child:Text(error!,style:const TextStyle(fontSize:10,height:1.4,fontWeight:FontWeight.w700))),
      ],
      const SizedBox(height:18),
      SizedBox(height:56,child:FilledButton(
        style:FilledButton.styleFrom(backgroundColor:AppColors.oceanDeep,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),
        onPressed:!ready||paying||(kIsWeb&&!cardComplete)?null:_pay,
        child:paying
          ?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
          :Text(kIsWeb?'Pagar com cartão':'Abrir pagamento seguro',style:const TextStyle(fontWeight:FontWeight.w900)),
      )),
      if(!ready&&error==null)...[const SizedBox(height:12),const Center(child:CircularProgressIndicator())],
      const SizedBox(height:12),
      const Center(child:Text('Pagamento processado com segurança pelo Stripe',style:TextStyle(color:AppColors.muted,fontSize:9,fontWeight:FontWeight.w600))),
    ])),
  );
}
