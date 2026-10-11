import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import 'support_page.dart';

class DeliveryChatPage extends StatefulWidget {
 const DeliveryChatPage({super.key,required this.orderId});
 final String orderId;
 @override
 State<DeliveryChatPage> createState()=>_DeliveryChatPageState();
}
class _DeliveryChatPageState extends State<DeliveryChatPage> with WidgetsBindingObserver {
 final _draft=TextEditingController();
 final _scroll=ScrollController();
 Map<String,dynamic>? _data;
 final Map<String,Map<String,dynamic>> _messages={};
 String? _error,_pendingId,_pendingText;
 bool _busy=false,_fetching=false,_queued=false,_escalating=false;
 Timer? _timer;
 int _epoch=0;
 String get _path=>'/support/orders/${Uri.encodeComponent(widget.orderId)}/delivery';
 String _id()=>'${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1<<30)}';
 @override
 void initState(){super.initState();WidgetsBinding.instance.addObserver(this);_epoch=AppState.instance.supportEpoch;AppState.instance.addListener(_updated);_timer=Timer.periodic(const Duration(seconds:15),(_)=>_load());_load();}
 void _updated(){if(!AppState.instance.loggedIn){Navigator.of(context).popUntil((r)=>r.isFirst);return;}if(_epoch!=AppState.instance.supportEpoch){_epoch=AppState.instance.supportEpoch;_load();}}
 @override
 void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed)_load();}
 Future<void> _load({bool older=false}) async {
  if(_fetching){_queued=true;return;}_fetching=true;
  try {
   final before=older?_data?['olderCursor']:null;
   final result=await AppState.instance.api.request('GET','$_path${before==null?'':'?before=${Uri.encodeComponent(before.toString())}'}');
   if(!mounted)return;
   final data=Map<String,dynamic>.from(result as Map);
   setState((){for(final raw in (data['messages'] as List? ?? [])){final m=Map<String,dynamic>.from(raw as Map);_messages['${m['id']}']=m;}if(older){_data?['olderCursor']=data['olderCursor'];}else{final previous=_data?['olderCursor'];_data=data;if(_messages.length>100)_data!['olderCursor']=previous;}_error=null;});
  }catch(_){if(mounted)setState(()=>_error='Não foi possível atualizar a conversa. Tente novamente.');}
  finally{_fetching=false;if(_queued&&mounted){_queued=false;_load();}}
 }
 Future<void> _send() async {
  final text=_draft.text.trim();if(text.isEmpty||_busy)return;
  if(text.length>4000)return;
  if(text!=_pendingText){_pendingText=text;_pendingId=_id();}
  setState(()=>_busy=true);
  try{await AppState.instance.api.request('POST','$_path/messages',body:{'text':text,'requestId':_pendingId});if(!mounted)return;_draft.clear();_pendingId=null;_pendingText=null;await _load();WidgetsBinding.instance.addPostFrameCallback((_){if(_scroll.hasClients)_scroll.animateTo(_scroll.position.maxScrollExtent,duration:const Duration(milliseconds:180),curve:Curves.easeOut);});}
  catch(_){if(mounted)setState(()=>_error='Mensagem não enviada. Seu texto foi preservado para tentar novamente.');}
  finally{if(mounted)setState(()=>_busy=false);}
 }
 Future<void> _help() async {
  if(_escalating)return;
  const reasons=['Endereço ou ponto de encontro','Não consigo contato','Problema na entrega','Preciso de ajuda da distribuidora'];
  String reason=reasons.first;final explanation=TextEditingController();final requestId=_id();bool saving=false;String? error;
  await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,builder:(sheetContext)=>StatefulBuilder(builder:(sheetContext,update)=>Padding(padding:EdgeInsets.fromLTRB(24,24,24,24+MediaQuery.viewInsetsOf(sheetContext).bottom),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Text('Vamos ajudar na sua entrega',style:TextStyle(fontSize:23,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('Se a conversa não resolveu, nossa equipe recebe o contexto e assume o atendimento.'),const SizedBox(height:24),
   DropdownButtonFormField<String>(initialValue:reason,isExpanded:true,decoration:const InputDecoration(labelText:'O que aconteceu?'),items:reasons.map((r)=>DropdownMenuItem(value:r,child:Text(r,overflow:TextOverflow.ellipsis))).toList(),onChanged:saving?null:(v)=>update(()=>reason=v??reason)),const SizedBox(height:16),
   TextField(controller:explanation,minLines:2,maxLines:4,maxLength:1000,enabled:!saving,decoration:const InputDecoration(labelText:'Conte o que precisamos resolver',hintText:'Ex.: não encontramos o ponto de encontro.')),
   if(error!=null)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(error!,style:const TextStyle(color:Colors.red))),const SizedBox(height:12),
   SizedBox(width:double.infinity,child:FilledButton.icon(icon:const Icon(AppIcons.help),label:Text(saving?'Enviando…':'Pedir ajuda à distribuidora'),onPressed:saving?null:()async{
    if(explanation.text.trim().isEmpty){update(()=>error='Descreva brevemente o que aconteceu.');return;}
    update((){saving=true;error=null;});_escalating=true;
    try{final result=await AppState.instance.api.request('POST','$_path/escalate',body:{'reason':reason,'text':explanation.text.trim(),'requestId':requestId});if(!sheetContext.mounted||!mounted)return;Navigator.of(sheetContext).pop();Navigator.of(context).push(MaterialPageRoute(builder:(_)=>SupportConversationPage(threadId:'${(result as Map)['id']}')));}
    catch(_){if(sheetContext.mounted)update(()=>error='Não foi possível abrir o atendimento. Tente novamente.');}
    finally{_escalating=false;if(sheetContext.mounted)update(()=>saving=false);}
   })),
  ])))));
  Timer(const Duration(seconds:1),explanation.dispose);
 }
 @override
 void dispose(){_timer?.cancel();AppState.instance.removeListener(_updated);WidgetsBinding.instance.removeObserver(this);_draft.dispose();_scroll.dispose();super.dispose();}
 @override
 Widget build(BuildContext context){
  final courier=_data?['role']=='COURIER';final canSend=_data?['canSend']==true;
  final messages=_messages.values.toList()..sort((a,b){final date='${a['createdAt']}'.compareTo('${b['createdAt']}');return date==0?'${a['id']}'.compareTo('${b['id']}'):date;});
  final suggestions=courier?['Estou a caminho','Cheguei ao local','Onde fica a entrada?','Pode confirmar um ponto de referência?']:['Onde você está?','Estou na entrada','Pode me avisar ao chegar?','Vou informar um ponto de referência'];
  return Scaffold(backgroundColor:AppColors.canvas,appBar:AppBar(title:Text(courier?'Conversar com cliente':'Sua entrega · conversa')),body:SafeArea(child:Column(children:[
   Container(margin:const EdgeInsets.fromLTRB(16,8,16,12),padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppColors.ocean900,AppColors.ocean700]),borderRadius:BorderRadius.circular(24)),child:Row(children:[Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.12),borderRadius:BorderRadius.circular(18)),child:Icon(courier?AppIcons.user:AppIcons.bike,color:Colors.white)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${_data?['counterpart']??'Conexão da entrega'}',style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(_data?['available']==true?'Combine a chegada e o ponto de encontro.':'A conversa abre quando um motoboy aceitar.',style:const TextStyle(color:Colors.white70,height:1.4))]))])),
   if(_error!=null)MaterialBanner(content:Text(_error!),actions:[TextButton(onPressed:_load,child:const Text('Tentar novamente'))]),
   Expanded(child:_data==null&&_error==null?const Center(child:CircularProgressIndicator()):messages.isEmpty?Center(child:Padding(padding:const EdgeInsets.all(32),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(AppIcons.mail,size:42,color:AppColors.ocean700),const SizedBox(height:16),Text(canSend?'Uma chegada mais fácil começa aqui':'Estamos acompanhando seu pedido',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800),textAlign:TextAlign.center),const SizedBox(height:8),Text(canSend?'Use uma mensagem rápida ou escreva para combinar os detalhes da entrega.':'Você pode pedir ajuda à distribuidora a qualquer momento.',textAlign:TextAlign.center)]))):ListView(controller:_scroll,padding:const EdgeInsets.all(16),children:[
    if(_data?['olderCursor']!=null)TextButton(onPressed:()=>_load(older:true),child:const Text('Ver mensagens anteriores')),
    ...messages.map((m){final mine=m['mine']==true;final date=DateTime.tryParse('${m['createdAt']}')?.toLocal();return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(constraints:BoxConstraints(maxWidth:MediaQuery.sizeOf(context).width*.8),margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:mine?AppColors.ocean900:Colors.white,borderRadius:BorderRadius.circular(20),border:mine?null:Border.all(color:AppColors.stroke)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(mine?'Você':m['senderRole']=='CUSTOMER'?'Cliente':'Motoboy',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:mine?Colors.white70:AppColors.muted)),const SizedBox(height:6),SelectableText('${m['text']}',style:TextStyle(color:mine?Colors.white:AppColors.ink,height:1.5)),if(date!=null)Text('${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}',style:TextStyle(fontSize:10,color:mine?Colors.white70:AppColors.muted))])));}),
   ])),
   if(canSend)SizedBox(height:48,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16),children:suggestions.map((s)=>Padding(padding:const EdgeInsets.only(right:8),child:ActionChip(label:Text(s),onPressed:_busy?null:(){_draft.text=s;_draft.selection=TextSelection.collapsed(offset:s.length);}))).toList())),
   if(canSend)Padding(padding:const EdgeInsets.fromLTRB(16,8,16,8),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:TextField(controller:_draft,enabled:!_busy,minLines:1,maxLines:4,maxLength:4000,decoration:const InputDecoration(hintText:'Escreva sua mensagem',counterText:''))),const SizedBox(width:10),IconButton.filled(tooltip:'Enviar mensagem',onPressed:_busy?null:_send,icon:_busy?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(AppIcons.arrowRight))])),
   if(_data!=null&&!canSend&&_data?['available']==true)const Padding(padding:EdgeInsets.all(12),child:Text('Entrega encerrada. O histórico continua disponível.')),
   TextButton.icon(onPressed:_escalating?null:_help,icon:const Icon(AppIcons.help,size:18),label:const Text('Não resolveu? Pedir ajuda à distribuidora')),
  ])));
 }
}
