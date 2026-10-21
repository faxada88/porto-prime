import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';
import 'checkout_progress.dart';

/// Presentation only. Existing callbacks own payment, verification and navigation.
class PrimePaymentExperience extends StatelessWidget {
 const PrimePaymentExperience({super.key,required this.summary,required this.creditOnly,
  required this.web,required this.ready,required this.paying,required this.submitted,
  required this.testMode,required this.onBack,required this.onHome,required this.onPay,
  required this.onVerify,required this.onRetry,this.error,this.paymentElement,this.onReopen,
  this.selectedMethod='pix',this.methods=const {'pix','card'},this.onSelectMethod});
 final Map<String,dynamic> summary;
 final bool creditOnly,web,ready,paying,submitted,testMode;
 final VoidCallback onBack,onHome,onPay,onVerify,onRetry;
 final VoidCallback? onReopen;
 final String? error;
 final Widget? paymentElement;
 final String selectedMethod;
 final Set<String> methods;
 final ValueChanged<String>? onSelectMethod;
 double _number(dynamic value)=>double.tryParse('$value')??0;
 @override Widget build(BuildContext context){
  final credit=_number(summary['storeCreditUsed']);
  final address=summary['address'] is Map?Map<String,dynamic>.from(summary['address']):<String,dynamic>{};
  final distance=summary['distanceKm']??summary['routeDistanceKm'];
  final duration=summary['durationMinutes']??summary['routeDurationMinutes'];
  final nativeAction=(!web||creditOnly)&&ready&&!submitted;
  final label=creditOnly?'Confirmar com saldo Porto Prime':selectedMethod=='pix'?'Gerar Pix':'Pagar com cartão ou carteira';
  return Scaffold(backgroundColor:AppColors.canvas,
   appBar:AppBar(backgroundColor:AppColors.canvas,surfaceTintColor:AppColors.canvas,
    leading:IconButton(tooltip:'Voltar à entrega e revisão',onPressed:onBack,icon:const Icon(AppIcons.arrowLeft)),
    title:const Text('Pagamento',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
    actions:[IconButton(tooltip:'Voltar ao início',onPressed:onHome,icon:const Icon(AppIcons.home))]),
   body:SafeArea(bottom:false,child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:620),
    child:ListView(padding:const EdgeInsets.fromLTRB(20,8,20,24),children:[
     const CheckoutProgress(step:2),const SizedBox(height:22),
     Text(creditOnly?'TOTAL COM SEU SALDO':'TOTAL A PAGAR',style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1.3,color:AppColors.muted)),
     const SizedBox(height:6),
     Text(checkoutMoney(creditOnly?credit:summary['total']),style:const TextStyle(fontSize:36,fontWeight:FontWeight.w800,letterSpacing:-1,color:AppColors.ink)),
     if(credit>0&&!creditOnly)Padding(padding:const EdgeInsets.only(top:6),child:Text('${checkoutMoney(credit)} do seu saldo já foram descontados.',style:const TextStyle(fontSize:12,color:AppColors.muted,height:1.5))),
     if(testMode&&!creditOnly)const Padding(padding:EdgeInsets.only(top:8),child:Text('Modo de teste · sem cobrança real',style:TextStyle(fontSize:11,color:AppColors.warning))),
     const SizedBox(height:16),
     _Surface(child:ExpansionTile(tilePadding:EdgeInsets.zero,childrenPadding:const EdgeInsets.only(bottom:8),
      shape:const Border(),collapsedShape:const Border(),
      title:const Text('Resumo do pedido',style:TextStyle(fontWeight:FontWeight.w700,fontSize:14)),
      children:[
       _Line('Produtos',checkoutMoney(summary['subtotal'])),
       _Line('Entrega',checkoutMoney(summary['deliveryFee'])),
       if(credit>0)_Line('Saldo Porto Prime','− ${checkoutMoney(credit)}'),
       if((summary['items'] as List?)?.isNotEmpty==true)...[
        const Divider(),
        for(final item in summary['items'])_Line('${item['quantity']}× ${item['productName']}',checkoutMoney(item['total'])),
       ],
      ])),
     if(address.isNotEmpty)...[const SizedBox(height:12),_Surface(child:Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
      const Icon(AppIcons.mapPin,size:20,color:AppColors.ocean700),const SizedBox(width:10),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text('${address['street']??''}, ${address['number']??''}',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700,height:1.5)),
       if(distance!=null||duration!=null)Text([if(distance!=null)'$distance km por rota',if(duration!=null)'aproximadamente $duration min'].join(' · '),style:const TextStyle(fontSize:11,color:AppColors.muted,height:1.5)),
      ])),
      IconButton(tooltip:'Revisar endereço e entrega',onPressed:onBack,icon:const Icon(Icons.edit_outlined,size:18)),
     ]))],
     const SizedBox(height:22),
     if(submitted)...[
      _Surface(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
       const Text('Aguardando confirmação',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
       const SizedBox(height:8),const Text('Se já pagou, não precisa pagar novamente. Vamos atualizar seu pedido assim que o pagamento for confirmado.',style:TextStyle(fontSize:13,color:AppColors.muted,height:1.6)),
       if(paying)const Padding(padding:EdgeInsets.only(top:16),child:LinearProgressIndicator()),
      ])),
      if(!paying)...[
       const SizedBox(height:12),FilledButton.icon(onPressed:onVerify,icon:const Icon(AppIcons.refresh),label:const Text('Verificar meu pedido')),
       if(onReopen!=null)TextButton(onPressed:onReopen,child:const Text('Abrir formas de pagamento')),
      ],
     ]else if(creditOnly)_Surface(child:const Text('Seu saldo cobre os produtos e a entrega. Basta confirmar para concluir.',style:TextStyle(fontSize:13,height:1.6,color:AppColors.ink)))
     else if(!ready&&error==null)const PrimeSkeleton(height:140,radius:18)
     else if(ready&&web&&paymentElement!=null)paymentElement!
     else if(ready)...[
      const Text('Como prefere pagar?',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
      const SizedBox(height:12),
      PaymentMethodPicker(methods:methods,selected:selectedMethod,onSelect:paying?null:onSelectMethod),
      const SizedBox(height:14),
      const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Icon(AppIcons.lock,size:14,color:AppColors.muted),SizedBox(width:7),
       Expanded(child:Text('Pagamento seguro. Você continua dentro do app.',style:TextStyle(fontSize:11,height:1.5,color:AppColors.muted))),
      ]),
     ],
     if(error!=null)...[const SizedBox(height:14),PrimeErrorBanner(message:error!)],
     if(!ready&&!submitted&&error!=null)TextButton.icon(onPressed:onRetry,icon:const Icon(AppIcons.refresh),label:const Text('Carregar pagamento novamente')),
    ])))),
   bottomNavigationBar:nativeAction?ColoredBox(color:AppColors.surface,child:SafeArea(top:false,child:Padding(
    padding:const EdgeInsets.fromLTRB(20,12,20,12),child:Center(heightFactor:1,child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:580),
     child:FilledButton.icon(onPressed:paying?null:onPay,
      style:FilledButton.styleFrom(minimumSize:const Size(double.infinity,54),padding:const EdgeInsets.symmetric(horizontal:18,vertical:16)),
      icon:paying?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Icon(selectedMethod=='pix'&&!creditOnly?Icons.qr_code_2_rounded:AppIcons.lock,size:19),
      label:Text(paying?'Aguarde…':label,textAlign:TextAlign.center,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800)),
     )))))):null,
  );
 }
}

class PaymentMethodPicker extends StatelessWidget {
 const PaymentMethodPicker({super.key,required this.methods,required this.selected,required this.onSelect});
 final Set<String> methods;
 final String selected;
 final ValueChanged<String>? onSelect;
 @override Widget build(BuildContext context)=>Column(children:[
  if(methods.contains('pix'))_option('pix','Pix','QR Code ou Copia e Cola',Icons.qr_code_2_rounded),
  if(methods.contains('card')||methods.contains('link'))_option('card','Cartão e carteiras','Formulário oficial Stripe. Carteiras aparecem em aparelhos compatíveis.',Icons.credit_card_rounded),
 ]);
 Widget _option(String value,String title,String subtitle,IconData icon){
  final active=selected==value;
  return Padding(padding:const EdgeInsets.only(bottom:10),child:Semantics(
   button:true,selected:active,label:title,child:Material(color:active?AppColors.ocean50:AppColors.surface,borderRadius:BorderRadius.circular(18),
    child:InkWell(key:ValueKey('payment-method-$value'),onTap:onSelect==null?null:()=>onSelect!(value),borderRadius:BorderRadius.circular(18),
     child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),
      border:Border.all(color:active?AppColors.ocean700:AppColors.stroke,width:active?1.5:1)),
      child:Row(children:[
       Icon(icon,size:25,color:active?AppColors.ocean700:AppColors.muted),const SizedBox(width:13),
       Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800)),const SizedBox(height:4),
        Text(subtitle,style:const TextStyle(fontSize:11,height:1.5,color:AppColors.muted)),
       ])),const SizedBox(width:10),Icon(active?Icons.radio_button_checked:Icons.radio_button_unchecked,size:21,color:active?AppColors.ocean700:AppColors.subtle),
      ])),
    ),
   ),
  ));
 }
}
class _Surface extends StatelessWidget{
 const _Surface({required this.child});final Widget child;
 @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(18),border:Border.all(color:AppColors.stroke)),child:child);
}
class _Line extends StatelessWidget{
 const _Line(this.label,this.value);final String label,value;
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Expanded(child:Text(label,style:const TextStyle(fontSize:12,height:1.5,color:AppColors.muted))),const SizedBox(width:12),
  Flexible(child:Text(value,textAlign:TextAlign.end,style:const TextStyle(fontSize:12,height:1.5,fontWeight:FontWeight.w700))),
 ]));
}
