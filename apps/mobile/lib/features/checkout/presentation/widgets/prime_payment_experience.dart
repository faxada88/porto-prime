import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_brand.dart';
import '../../../../core/widgets/prime_ui.dart';
import 'checkout_progress.dart';

/// Presentation only: all navigation, payment and reconciliation actions belong
/// to StripeCheckoutPage. No card fields or payment requests are implemented here.
class PrimePaymentExperience extends StatelessWidget {
 const PrimePaymentExperience({super.key,required this.summary,required this.creditOnly,
  required this.web,required this.ready,required this.paying,required this.submitted,
  required this.testMode,required this.onBack,required this.onHome,required this.onPay,
  required this.onVerify,required this.onRetry,this.error,this.paymentElement,this.onReopen});
 final Map<String,dynamic> summary;
 final bool creditOnly,web,ready,paying,submitted,testMode;
 final VoidCallback onBack,onHome,onPay,onVerify,onRetry;
 final String? error;
 final Widget? paymentElement;
 final VoidCallback? onReopen;
 double _number(dynamic value)=>double.tryParse('$value')??0;
 @override Widget build(BuildContext context){
  final credit=_number(summary['storeCreditUsed']);
  final amount=creditOnly?summary['storeCreditUsed']:summary['total'];
  final address=summary['address'] is Map?Map<String,dynamic>.from(summary['address']):<String,dynamic>{};
  final distance=summary['distanceKm']??summary['routeDistanceKm'];
  final duration=summary['durationMinutes']??summary['routeDurationMinutes'];
  final nativeAction=(!web||creditOnly)&&ready&&!submitted;
  return Scaffold(backgroundColor:AppColors.canvas,
   appBar:AppBar(backgroundColor:AppColors.canvas,surfaceTintColor:AppColors.canvas,
    leading:IconButton(tooltip:'Voltar à entrega e revisão',onPressed:onBack,icon:const Icon(AppIcons.arrowLeft)),
    title:const Text('Finalizar pedido',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
    actions:[IconButton(tooltip:'Voltar ao início',onPressed:onHome,icon:const Icon(AppIcons.home))]),
   body:SafeArea(bottom:false,child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:620),
    child:ListView(padding:const EdgeInsets.fromLTRB(20,8,20,28),children:[
     const CheckoutProgress(step:2),const SizedBox(height:22),
     _PaymentHero(amount:amount,creditOnly:creditOnly),const SizedBox(height:18),
     if(testMode&&!creditOnly)...[Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:AppColors.sand100,borderRadius:BorderRadius.circular(14)),child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(AppIcons.info,size:18,color:AppColors.warning),SizedBox(width:9),Expanded(child:Text('Ambiente de teste. Nenhuma cobrança real será realizada.',style:TextStyle(color:AppColors.warning,fontSize:12,height:1.5)))])),const SizedBox(height:18)],
     if(address.isNotEmpty)...[_PaymentSurface(child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(AppIcons.mapPin,color:AppColors.ocean700,size:22),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${address['label']??'Entrega neste endereço'}',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:13)),const SizedBox(height:5),Text('${address['street']??''}, ${address['number']??''}',style:const TextStyle(fontSize:13,height:1.5)),if(duration!=null||distance!=null)Padding(padding:const EdgeInsets.only(top:5),child:Text([if(distance!=null)'$distance km por rota',if(duration!=null)'aproximadamente $duration min'].join(' • '),style:const TextStyle(fontSize:11,height:1.5,color:AppColors.muted)))])),IconButton(tooltip:'Revisar endereço e entrega',onPressed:onBack,icon:const Icon(AppIcons.chevronRight,size:18))])),const SizedBox(height:16)],
     _PaymentSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Text('Sua compra, sem surpresas',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),const SizedBox(height:12),
      if(summary['total']!=null)...[_PaymentLine(label:'Produtos',value:checkoutMoney(summary['subtotal'])),_PaymentLine(label:'Entrega',value:checkoutMoney(summary['deliveryFee'])),if(credit>0)_PaymentLine(label:'Saldo Porto Prime utilizado',value:'− ${checkoutMoney(credit)}'),const Padding(padding:EdgeInsets.symmetric(vertical:8),child:Divider(height:1)),_PaymentLine(label:creditOnly?'Restante a pagar':'Total no Stripe',value:checkoutMoney(summary['total']),strong:true)],
      if((summary['items'] as List?)?.isNotEmpty==true)ExpansionTile(tilePadding:EdgeInsets.zero,childrenPadding:const EdgeInsets.only(bottom:6),shape:const Border(),collapsedShape:const Border(),title:const Text('Ver produtos do pedido',style:TextStyle(fontSize:12,fontWeight:FontWeight.w700)),children:[for(final item in summary['items'])_PaymentLine(label:'${item['quantity']}× ${item['productName']}',value:checkoutMoney(item['total']))]),
     ])),const SizedBox(height:16),
     _PaymentSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(12)),child:Icon(creditOnly?AppIcons.creditCard:AppIcons.lock,color:AppColors.ocean700,size:21)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(creditOnly?'Seu saldo está pronto':'Escolha como pagar',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(creditOnly?'Confirme a compra usando seu cartão Porto Prime.':web?'Informe seus dados no formulário seguro abaixo.':'Abra o ambiente seguro para escolher Pix, cartão, boleto ou uma carteira compatível. Depois, retorne ao app.',style:const TextStyle(fontSize:12,height:1.6,color:AppColors.muted))]))]),
      const SizedBox(height:18),
      if(!creditOnly&&!submitted)...[const _PaymentMethodsGuide(),const SizedBox(height:18)],
      if(submitted)_PaymentProcessing(busy:paying)
      else if(!ready&&error==null)const PrimeSkeleton(height:100,radius:14)
      else if(ready&&creditOnly)const Text('Seu saldo cobre os produtos e a entrega. Não haverá cobrança no Stripe.',style:TextStyle(fontSize:12,color:AppColors.ocean700,height:1.6))
      else if(ready&&web&&paymentElement!=null)paymentElement!
      else if(ready)const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(AppIcons.shield,size:17,color:AppColors.ocean700),SizedBox(width:8),Expanded(child:Text('Os dados do cartão são tratados pelo Stripe. A Porto Prime não recebe o número completo nem o código de segurança.',style:TextStyle(fontSize:11,height:1.6,color:AppColors.muted)))]),
     ])),
     if(error!=null)...[const SizedBox(height:14),PrimeErrorBanner(message:error!)],
     if(submitted&&!paying&&error!=null)Padding(padding:const EdgeInsets.only(top:12),child:FilledButton.icon(onPressed:onVerify,icon:const Icon(AppIcons.refresh,size:18),label:const Text('Verificar meu pedido'))),
     if(submitted&&!paying&&onReopen!=null)TextButton.icon(onPressed:onReopen,icon:const Icon(AppIcons.lock,size:18),label:const Text('Reabrir pagamento seguro')),
     if(!ready&&!submitted&&error!=null)TextButton.icon(onPressed:onRetry,icon:const Icon(AppIcons.refresh,size:18),label:const Text('Carregar pagamento novamente')),
     const SizedBox(height:20),const Text('Após a confirmação, você poderá acompanhar cada etapa do pedido pelo aplicativo.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,height:1.6,color:AppColors.muted)),
    ])))),
   bottomNavigationBar:nativeAction?SafeArea(top:false,child:Container(padding:const EdgeInsets.fromLTRB(20,12,20,12),decoration:const BoxDecoration(color:AppColors.surface,border:Border(top:BorderSide(color:AppColors.stroke))),child:Center(heightFactor:1,child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:580),child:FilledButton.icon(onPressed:paying?null:onPay,style:FilledButton.styleFrom(minimumSize:const Size(double.infinity,54),padding:const EdgeInsets.symmetric(horizontal:18,vertical:16),backgroundColor:AppColors.ocean700,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),icon:paying?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(AppIcons.lock,size:18),label:Text(paying?'Processando…':creditOnly?'Confirmar com saldo Porto Prime':summary['total']==null?'Pagar com Stripe':'Pagar ${checkoutMoney(summary['total'])}',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:15))))))):null,
  );
 }
}
class _PaymentHero extends StatelessWidget {
 const _PaymentHero({required this.amount,required this.creditOnly});final dynamic amount;final bool creditOnly;
 @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[AppColors.ocean900,AppColors.ocean700]),borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  const Row(children:[PrimeBrandMark(size:32),SizedBox(width:12),Expanded(child:Text('PORTO PRIME',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:11,letterSpacing:1.6)))]),const SizedBox(height:22),
  Text(creditOnly?'COMPRA COM SEU SALDO':'TOTAL A PAGAR',style:const TextStyle(color:AppColors.sun200,fontSize:10,fontWeight:FontWeight.w700,letterSpacing:1.2)),const SizedBox(height:7),
  Text(amount==null?'Quase pronto.':checkoutMoney(amount),style:const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.w800,letterSpacing:-1,height:1.2)),const SizedBox(height:8),
  const Text('Só falta confirmar. A gente cuida do resto.',style:TextStyle(color:AppColors.sun200,fontSize:12,height:1.6)),
 ]));
}
class _PaymentSurface extends StatelessWidget {
 const _PaymentSurface({required this.child});final Widget child;
 @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(20),border:Border.all(color:AppColors.stroke)),child:child);
}
class _PaymentLine extends StatelessWidget {
 const _PaymentLine({required this.label,required this.value,this.strong=false});final String label,value;final bool strong;
 @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,constraints){
  final stacked=constraints.maxWidth<280||MediaQuery.textScalerOf(context).scale(14)>20;
  final labelWidget=Text(label,style:TextStyle(fontSize:12,height:1.5,color:strong?AppColors.ink:AppColors.muted,fontWeight:strong?FontWeight.w800:FontWeight.w500));
  final valueWidget=Text(value,style:TextStyle(fontSize:strong?19:13,height:1.5,fontWeight:FontWeight.w800,color:strong?AppColors.ocean800:AppColors.ink));
  return Padding(padding:const EdgeInsets.symmetric(vertical:5),child:stacked?Column(crossAxisAlignment:CrossAxisAlignment.start,children:[labelWidget,valueWidget]):Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:labelWidget),const SizedBox(width:12),valueWidget]));
 });
}
class _PaymentProcessing extends StatelessWidget {
 const _PaymentProcessing({required this.busy});final bool busy;
 @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Aguardando confirmação',style:TextStyle(fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:8),const Text('Conclua o pagamento no ambiente seguro e volte ao app. Pix e boleto só liberam o pedido após a confirmação. Não pague novamente se já concluiu.',style:TextStyle(fontSize:12,height:1.6,color:AppColors.muted)),if(busy)const Padding(padding:EdgeInsets.only(top:16),child:LinearProgressIndicator())]));
}

class _PaymentMethodsGuide extends StatelessWidget {
 const _PaymentMethodsGuide();
 @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(14),border:Border.all(color:AppColors.strokeStrong)),child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Icon(Icons.qr_code_2_rounded,color:AppColors.ocean700,size:28),SizedBox(width:12),
   Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Pix · simples e rápido',style:TextStyle(fontWeight:FontWeight.w800,fontSize:14)),
    SizedBox(height:4),Text('QR Code ou Copia e Cola no aplicativo do seu banco.',style:TextStyle(fontSize:12,height:1.5,color:AppColors.muted)),
   ])),
  ])),
  const SizedBox(height:10),
  const Wrap(spacing:8,runSpacing:8,children:[
   Chip(label:Text('Cartões')),Chip(label:Text('Apple Pay')),Chip(label:Text('Google Pay')),Chip(label:Text('Link')),Chip(label:Text('Boleto')),
  ]),
  const SizedBox(height:8),const Text('O Stripe exibe as opções habilitadas e elegíveis para esta compra e aparelho. Boleto depende de compensação.',style:TextStyle(fontSize:11,height:1.6,color:AppColors.muted)),
 ]);
}
