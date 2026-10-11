import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../wallet/presentation/pages/partner_wallet_page.dart';
class PartnerDashboardPage extends StatefulWidget {
 const PartnerDashboardPage({super.key});
 @override State<PartnerDashboardPage> createState()=>_PartnerDashboardPageState();
}
class _PartnerDashboardPageState extends State<PartnerDashboardPage>{
 Map<String,dynamic>? data; String? error; Timer? timer; bool fetching=false;
 @override void initState(){super.initState();refresh();timer=Timer.periodic(const Duration(seconds:10),(_)=>refresh());AppState.instance.addListener(changed);}
 void changed(){refresh();}
 @override void dispose(){timer?.cancel();AppState.instance.removeListener(changed);super.dispose();}
 Future<void> refresh()async{if(fetching)return;fetching=true;try{final result=await AppState.instance.api.request('GET','/partners/me?appUrl=${Uri.encodeComponent(kIsWeb?Uri.base.origin:'')}');if(mounted)setState((){data=Map<String,dynamic>.from(result);error=null;});}catch(_){if(mounted)setState(()=>error='Não foi possível atualizar suas indicações. Tente novamente.');}finally{fetching=false;}}
 String money(dynamic v)=>'R\$ ${(double.tryParse('$v')??0).toStringAsFixed(2).replaceAll('.',',')}';
 Widget metric(String title,String value)=>Expanded(child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(18),border:Border.all(color:AppColors.stroke)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(title,style:const TextStyle(fontSize:12,color:AppColors.muted))])));
 @override Widget build(BuildContext context){final d=data,p=d?['profile']??{},stats=d?['summary']??{},finance=d?['finance']??{};return Scaffold(appBar:AppBar(title:const Text('Parceiros Porto Prime')),body:RefreshIndicator(onRefresh:refresh,child:ListView(padding:const EdgeInsets.fromLTRB(20,14,20,40),children:[
 Container(padding:const EdgeInsets.all(25),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppColors.oceanDeep,AppColors.ocean]),borderRadius:BorderRadius.circular(26)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('SUA REDE. NOVAS POSSIBILIDADES.',style:TextStyle(color:Colors.white70,fontSize:11,letterSpacing:1.1)),const SizedBox(height:16),Text(p['businessName']?.toString()??'Olá, parceiro',style:const TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w800)),const SizedBox(height:10),Text('${p['commissionPercent']??'—'}% sobre os produtos entregues de cada pedido indicado.',style:const TextStyle(color:Colors.white,height:1.5)),const SizedBox(height:20),FilledButton(style:FilledButton.styleFrom(backgroundColor:Colors.white,foregroundColor:AppColors.oceanDeep),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const PartnerWalletPage())),child:Text('Carteira · ${money(finance['availableBalance'])}'))])),
 const SizedBox(height:18),Row(children:[metric('Entregas indicadas','${stats['delivered']??0}'),const SizedBox(width:12),metric('Comissões recebidas',money(stats['earned']))]),
 if(error!=null)Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(error!,style:const TextStyle(color:Colors.red))),
 const SizedBox(height:24),const Text('Seu ponto de conexão',style:TextStyle(fontSize:23,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('Mostre seu QR na praia, no hotel ou onde seus clientes estiverem. Eles escaneiam e compram direto na Porto Prime.',style:TextStyle(color:AppColors.muted,height:1.5)),const SizedBox(height:18),
 if(d==null)Container(height:280,decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(22)))else if(d['enabled']!=true)const Card(child:Padding(padding:EdgeInsets.all(24),child:Text('Seu QR estará disponível quando o cadastro estiver aprovado e o acesso ativo.')))else Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.stroke)),child:Column(children:[if(d['qrDataUrl']!=null)Image.memory(base64Decode(d['qrDataUrl'].toString().split(',').last),width:230,height:230,semanticLabel:'QR code exclusivo de indicação'),const SizedBox(height:12),SelectableText(p['referralCode'].toString(),style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:()async{await Clipboard.setData(ClipboardData(text:d['link'].toString()));if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Link copiado. Compartilhe com seus clientes.')));},child:const Text('Copiar meu link de indicação')))])),
 const SizedBox(height:20),const Text('Como seus ganhos chegam',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),const SizedBox(height:10),const Text('Cliente escaneia → pedido pago → entrega concluída → comissão disponível na carteira. Você pode solicitar saque por PIX. A indicação vale por 30 dias neste dispositivo; uma nova indicação substitui a anterior. Itens removidos ou reembolsados e a taxa de entrega não geram comissão.',style:TextStyle(color:AppColors.muted,height:1.7)),
 const SizedBox(height:24),Text('Em andamento · ${stats['pending']??0}',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18)),const SizedBox(height:12),
 ...(d?['orders'] as List? ?? []).map((o)=>Card(child:ListTile(title:Text('Pedido #${o['id'].toString().substring(o['id'].toString().length-8).toUpperCase()}'),subtitle:Text(o['adminDeletedAt']!=null?'Pedido removido':o['status']=='DELIVERED'?'Entrega concluída':o['status']=='CANCELED'?'Cancelado':'Aguardando conclusão'),trailing:Text(money(o['partnerCommissionAmount']),style:const TextStyle(fontWeight:FontWeight.w800))))),
 ])));}
}
