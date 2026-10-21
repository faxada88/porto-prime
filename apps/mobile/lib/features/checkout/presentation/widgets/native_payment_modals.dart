import '../../../../core/localization/prime_localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// Selection stays in Flutter. Stripe owns all card/wallet/boleto fields.
class NativePaymentChoices extends StatelessWidget {
 const NativePaymentChoices({super.key,required this.methods,required this.onSelect});
 final Set<String> methods;
 final ValueChanged<String> onSelect;
 @override Widget build(BuildContext context)=>SafeArea(top:false,child:SingleChildScrollView(
  padding:const EdgeInsets.fromLTRB(22,12,22,24),
  child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   Center(child:Container(width:40,height:4,decoration:BoxDecoration(color:AppColors.strokeStrong,borderRadius:BorderRadius.circular(8)))),
   const SizedBox(height:22),
   Row(children:[const Expanded(child:PrimeText('Como você quer pagar?',style:TextStyle(fontSize:23,fontWeight:FontWeight.w800,letterSpacing:-.5))),IconButton(tooltip: translateLabel('Fechar formas de pagamento'),onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close_rounded))]),
   const SizedBox(height:6),
   const PrimeText('Escolha com tranquilidade. O pagamento acontece dentro do aplicativo.',style:TextStyle(color:AppColors.muted,fontSize:13,height:1.5)),
   const SizedBox(height:20),
   if(methods.contains('pix'))_choice('pix','Pix','QR Code e Copia e Cola, sem login no Google.',Icons.qr_code_2_rounded,true),
   if(methods.contains('card'))_choice('card','Cartão','Crédito ou débito no formulário seguro do Stripe.',Icons.credit_card_rounded,false),
   if(methods.contains('card')||methods.contains('link'))_choice('wallet','Carteiras digitais','Google Pay, Apple Pay e Link, quando compatíveis.',Icons.account_balance_wallet_outlined,false),

   const SizedBox(height:10),
   const PrimeText('Carteiras são opcionais. Você pode pagar com cartão ou Pix sem entrar em uma conta Google.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,height:1.5,color:AppColors.muted)),
  ]),
 ));
 Widget _choice(String value,String title,String subtitle,IconData icon,bool featured)=>Padding(
  padding:const EdgeInsets.only(bottom:10),child:Material(
   color:featured?AppColors.ocean50:Colors.white,borderRadius:BorderRadius.circular(18),
   child:InkWell(borderRadius:BorderRadius.circular(18),onTap:()=>onSelect(value),
    child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(border:Border.all(color:featured?AppColors.strokeStrong:AppColors.stroke),borderRadius:BorderRadius.circular(18)),
     child:Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
      Icon(icon,size:26,color:AppColors.ocean700),const SizedBox(width:14),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       PrimeText(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:15)),const SizedBox(height:4),
       PrimeText(subtitle,style:const TextStyle(color:AppColors.muted,fontSize:12,height:1.5)),
      ])),const SizedBox(width:8),const Icon(Icons.chevron_right_rounded,size:20,color:AppColors.muted),
     ])),
   ),
  ),
 );
}

class NativePixModal extends StatefulWidget {
 const NativePixModal({super.key,required this.load,required this.verify});
 final Future<Map<String,dynamic>> Function() load;
 final Future<bool> Function() verify;
 @override State<NativePixModal> createState()=>_NativePixModalState();
}
class _NativePixModalState extends State<NativePixModal> with WidgetsBindingObserver {
 Map<String,dynamic>? _pix;
 String? _error;
 bool _loading=true,_checking=false,_closing=false,_foreground=true,_copied=false,_awaiting=false;
 Timer? _timer;
 @override void initState(){
  super.initState();WidgetsBinding.instance.addObserver(this);_load();
  _timer=Timer.periodic(const Duration(seconds:5),(_){if(_foreground)_check();});
 }
 @override void dispose(){_timer?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
 @override void didChangeAppLifecycleState(AppLifecycleState state){_foreground=state==AppLifecycleState.resumed;if(_foreground)_check();}
 void _paid(){
  if(_closing||!mounted)return;_closing=true;_timer?.cancel();
  WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)Navigator.pop(context,true);});
 }
 Future<void> _load()async{
  try{
   final result=await widget.load();
   if(!mounted)return;
   if(result['paid']==true){_paid();return;}
   setState((){_pix=result['pix'] is Map?Map<String,dynamic>.from(result['pix'] as Map):null;_error=null;_loading=false;_awaiting=true;});
  }catch(e){if(mounted)setState((){_loading=false;_error=e.toString().replaceFirst('Exception: ','');});}
 }
 Future<void> _check()async{
  if(_checking||_loading||_closing||!mounted)return;
  setState(()=>_checking=true);
  try{if(await widget.verify()){_paid();}else if(mounted&&_awaiting)setState(()=>_error=null);}
  catch(_){if(mounted)setState(()=>_error='Não foi possível verificar agora. Se já pagou, não pague novamente.');}
  finally{if(mounted)setState(()=>_checking=false);}
 }
 Future<void> _copy()async{
  final code=(_pix?['data']??'').toString();if(code.isEmpty)return;
  try{await Clipboard.setData(ClipboardData(text:code));if(mounted)setState(()=>_copied=true);}
  catch(_){if(mounted)setState(()=>_error='Não foi possível copiar. Selecione o código abaixo para copiar manualmente.');}
 }
 @override Widget build(BuildContext context){
  final image=(_pix?['imageUrl']??'').toString();
  final code=(_pix?['data']??'').toString();
  final expiry=(_pix?['expiresAt'] as num?)?.toInt();
  final expires=expiry==null?null:DateTime.fromMillisecondsSinceEpoch(expiry*1000).toLocal();
  final expired=expires!=null&&DateTime.now().isAfter(expires);
  return SafeArea(top:false,child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(22,12,22,24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   Center(child:Container(width:40,height:4,decoration:BoxDecoration(color:AppColors.strokeStrong,borderRadius:BorderRadius.circular(8)))),
   const SizedBox(height:18),
   Row(children:[const Expanded(child:PrimeText('Pagar com Pix',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800))),IconButton(tooltip: translateLabel('Fechar Pix'),onPressed:()=>Navigator.pop(context,false),icon:const Icon(Icons.close_rounded))]),
   const SizedBox(height:8),
   const PrimeText('Copie o código e pague no aplicativo do seu banco. A confirmação aparece aqui automaticamente.',style:TextStyle(fontSize:13,height:1.6,color:AppColors.muted)),
   const SizedBox(height:18),
   if(_loading)const Padding(padding:EdgeInsets.all(32),child:Center(child:CircularProgressIndicator()))
   else if(code.isNotEmpty)...[
    if(image.isNotEmpty&&!expired)Center(child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:AppColors.stroke)),child:Image.network(image,width:216,height:216,fit:BoxFit.contain,errorBuilder:(_,error,stack)=>const SizedBox(width:216,height:90,child:Center(child:PrimeText('Use o código Copia e Cola abaixo.',textAlign:TextAlign.center)))))),
    if(expires!=null)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:PrimeText(expired?'Código expirado. Verifique o pagamento antes de gerar outro.':'Válido até ${expires.hour.toString().padLeft(2,'0')}:${expires.minute.toString().padLeft(2,'0')}',textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:expired?AppColors.danger:AppColors.muted))),
    FilledButton.icon(onPressed:expired?null:_copy,icon:Icon(_copied?Icons.check_rounded:Icons.copy_rounded),label:PrimeText(_copied?'Código Pix copiado':'Copiar código Pix')),
    const SizedBox(height:12),
    ExpansionTile(tilePadding:EdgeInsets.zero,title:const PrimeText('Ver código Pix',style:TextStyle(fontSize:12)),children:[SelectableText(code,style:const TextStyle(fontSize:11,height:1.4))]),
   ]else if(_error==null)const Padding(padding:EdgeInsets.all(20),child:PrimeText('Pagamento em processamento. Aguarde a confirmação.',textAlign:TextAlign.center)),
   if(_error!=null)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:PrimeText(_error!,style:const TextStyle(color:AppColors.danger,fontSize:12,height:1.5))),
   const SizedBox(height:12),
   OutlinedButton.icon(onPressed:_checking||_loading?null:_check,icon:_checking?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.refresh_rounded),label:const PrimeText('Já paguei · verificar')),
   if(!_loading&&(_error!=null||expired))TextButton(onPressed:(){setState(()=>_loading=true);_load();},child:const PrimeText('Recuperar ou atualizar Pix')),
   const SizedBox(height:12),
   const PrimeText('Gerar o código não confirma o pagamento. Seu pedido só será liberado depois da confirmação.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:AppColors.muted,height:1.5)),
  ])));
 }
}
