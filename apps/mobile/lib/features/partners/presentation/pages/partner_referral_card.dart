import '../../../../core/localization/prime_localization.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
class PartnerReferralCard extends StatefulWidget {
 const PartnerReferralCard({super.key});
 @override State<PartnerReferralCard> createState()=>_PartnerReferralCardState();
}
class _PartnerReferralCardState extends State<PartnerReferralCard>{
 Map<String,dynamic>? data;String? error;bool loading=false;Timer? timer;
 @override void initState(){super.initState();refresh();timer=Timer.periodic(const Duration(seconds:15),(_)=>refresh());AppState.instance.addListener(refresh);}
 @override void dispose(){timer?.cancel();AppState.instance.removeListener(refresh);super.dispose();}
 Future<void> refresh()async{if(loading)return;loading=true;try{final result=await AppState.instance.api.request('GET','/partners/me/referral?appUrl=${Uri.encodeComponent(kIsWeb?Uri.base.origin:'')}');if(mounted)setState((){data=Map<String,dynamic>.from(result);error=null;});}catch(_){if(mounted)setState(()=>error='Não foi possível carregar sua divulgação. Toque em atualizar.');}finally{loading=false;}}
 Future<void> copy()async{final link=data?['link'];if(link==null)return;try{await Clipboard.setData(ClipboardData(text:link.toString()));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:PrimeText('Link copiado. Compartilhe em grupos e com seus clientes.')));}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:PrimeText('Selecione o link abaixo para copiar.')));}}
 @override Widget build(BuildContext context){final link=data?['link']?.toString();final ready=data?['enabled']==true&&link!=null;final qr=data?['qrDataUrl']?.toString();return Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.stroke)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Row(children:[Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(14)),child:const Icon(AppIcons.storefront_outlined,color:AppColors.oceanDeep)),const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[PrimeText('Sua vitrine de indicações',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),SizedBox(height:4),PrimeText('Um link. Muitas conexões.',style:TextStyle(color:AppColors.muted,fontSize:12))])),IconButton(tooltip: translateLabel('Atualizar divulgação'),onPressed:refresh,icon:const Icon(AppIcons.refresh_rounded))]),
 const SizedBox(height:16),const PrimeText('Compartilhe em grupos, com hóspedes ou clientes. Seu link e seu QR identificam a mesma indicação.',style:TextStyle(color:AppColors.muted,height:1.6,fontSize:13)),
 if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:PrimeText(error!,style:const TextStyle(color:Colors.red)))else if(data==null)Padding(padding:const EdgeInsets.only(top:20),child:LinearProgressIndicator(color:AppColors.oceanDeep,backgroundColor:AppColors.mint))else if(!ready)Padding(padding:const EdgeInsets.only(top:16),child:PrimeText(data?['enabled']==true?'O endereço público do aplicativo ainda precisa ser configurado.':'A divulgação será liberada após a aprovação e ativação do seu cadastro.',style:const TextStyle(height:1.5)))else ...[
 const SizedBox(height:18),Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:AppColors.canvas,borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const PrimeText('SEU LINK EXCLUSIVO',style:TextStyle(color:AppColors.oceanDeep,fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1.1)),const SizedBox(height:8),SelectableText(link,style:const TextStyle(fontSize:12,height:1.5))])),const SizedBox(height:14),
 SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:copy,icon:const Icon(AppIcons.externalLink,size:18),label:const PrimeText('Copiar link de indicação'))),const SizedBox(height:8),SizedBox(width:double.infinity,child:OutlinedButton(onPressed:()async{final uri=Uri.https('wa.me','/',{'text':'Peça na Porto Prime pelo meu link: $link'});try{if(!await launchUrl(uri,mode:LaunchMode.externalApplication)&&mounted)await copy();}catch(_){await copy();}},child:const PrimeText('Compartilhar no WhatsApp'))),
 if(qr!=null) ...[const SizedBox(height:20),Center(child:Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:AppColors.stroke),borderRadius:BorderRadius.circular(20)),child:Image.memory(base64Decode(qr.split(',').last),width:210,height:210,semanticLabel: translateLabel('Seu QR exclusivo de indicação'),errorBuilder:(_,__,___)=>const Padding(padding:EdgeInsets.all(20),child:PrimeText('Use o link de indicação acima.'))))),const SizedBox(height:10),const Center(child:PrimeText('Escaneie para comprar na Porto Prime',style:TextStyle(fontSize:11,color:AppColors.muted)))],
 const SizedBox(height:16),PrimeText('${data?['commissionPercent']}% sobre os produtos entregues. A comissão entra na carteira somente após a entrega concluída.',style:const TextStyle(fontSize:11,height:1.6,color:AppColors.muted)),
 ],
 ]));}
}

