import '../../../../core/localization/prime_localization.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_brand.dart';
import '../../../../core/widgets/prime_ui.dart';

const publicSupportTopics=<String,String>{'ACCESS':'Não consigo entrar','ACCOUNT':'Minha conta ou cadastro','GENERAL':'Dúvidas e problemas gerais','PARTNERSHIP':'Quero fazer uma parceria','SPONSORSHIP':'Patrocínios e ações comerciais'};
const _personas=<String,String>{'CUSTOMER':'Cliente','COURIER':'Motoboy','PARTNER':'Parceiro','OTHER':'Ainda não tenho cadastro / outro'};
String _randomKey(){final r=Random.secure();return base64UrlEncode(List.generate(30,(_)=>r.nextInt(256))).replaceAll('=','');}
String _status(dynamic value)=>switch(value){'IN_PROGRESS'=>'Em atendimento','RESOLVED'=>'Resolvido',_=>'Aguardando atendimento'};

class PublicSupportPage extends StatefulWidget {
  const PublicSupportPage({super.key,this.initialTopic='GENERAL',this.client});
  final String initialTopic;
  final http.Client? client;
  @override State<PublicSupportPage> createState()=>_PublicSupportPageState();
}
class _PublicSupportPageState extends State<PublicSupportPage> {
  late final http.Client _http;
  final _form=GlobalKey<FormState>();
  final _name=TextEditingController(),_email=TextEditingController(),_phone=TextEditingController(),_company=TextEditingController(),_text=TextEditingController(),_reply=TextEditingController(),_protocolInput=TextEditingController(),_keyInput=TextEditingController();
  String _topic='GENERAL',_persona='OTHER';
  bool _working=false,_tracking=false,_polling=false;
  String? _error;
  List<Map<String,dynamic>> _saved=[];
  Map<String,dynamic>? _ticket,_credentials,_pendingCreate,_pendingReply;
  Timer? _timer;
  int _epoch=0;
  static const _storage='pp_public_support_v1';
  @override void initState(){super.initState();_http=widget.client??http.Client();_topic=publicSupportTopics.containsKey(widget.initialTopic)?widget.initialTopic:'GENERAL';_restore();_timer=Timer.periodic(const Duration(seconds:8),(_){if(_ticket!=null&&!_working)_refresh();});}
  @override void dispose(){_timer?.cancel();_epoch++;_http.close();for(final c in [_name,_email,_phone,_company,_text,_reply,_protocolInput,_keyInput]){c.dispose();}super.dispose();}
  Future<void> _restore() async {try{final p=await SharedPreferences.getInstance();final rows=jsonDecode(p.getString(_storage)??'[]') as List;if(mounted)setState(()=>_saved=rows.whereType<Map>().map((row)=>Map<String,dynamic>.from(row)).take(10).toList());}catch(_){}}
  Future<void> _remember(Map<String,dynamic> credentials) async {
    final rows=[credentials,..._saved.where((c)=>c['requestId']!=credentials['requestId']&&((credentials['protocol']??'').toString().isEmpty||c['protocol']!=credentials['protocol']))].take(10).toList();
    if(mounted)setState(()=>_saved=rows);
    try{final p=await SharedPreferences.getInstance();await p.setString(_storage,jsonEncode(rows));}catch(_){/* The access code remains available to copy on screen. */}
  }
  Future<Map<String,dynamic>> _request(String path,Map<String,dynamic> body) async {
    final response=await _http.post(Uri.parse('${AppState.instance.api.baseUrl}/support/public/$path'),headers:{'Content-Type':'application/json','Accept':'application/json'},body:jsonEncode(body)).timeout(const Duration(seconds:25));
    if(response.statusCode>=500)throw Exception('Não foi possível conectar ao atendimento agora. Seu texto foi preservado.');
    dynamic data;try{data=jsonDecode(response.body);}catch(_){throw Exception('Não foi possível concluir. Tente novamente.');}
    if(response.statusCode<200||response.statusCode>=300)throw Exception(data is Map?(data['message']??'Não foi possível concluir.').toString():'Não foi possível concluir.');
    return Map<String,dynamic>.from(data as Map);
  }
  String _friendly(Object error)=>error is http.ClientException?'Não foi possível conectar ao atendimento. Verifique a conexão e tente novamente.':error is TimeoutException?'A conexão demorou mais que o esperado. Tente novamente; seu texto está salvo nesta tela.':error.toString().replaceFirst('Exception: ','');
  void _apply(Map<String,dynamic> data,{bool reset=false}){
    if(!mounted)return;
    setState((){
      if(!reset&&_ticket?['id']==data['id']&&'${_ticket!['updatedAt']}'.compareTo('${data['updatedAt']}')>0)return;
      if(reset||_ticket?['id']!=data['id']){_ticket=data;}else{
        final messages=<String,dynamic>{};for(final message in [...(_ticket?['messages']??[]),...(data['messages']??[])]){messages[message['id'].toString()]=message;}
        final ordered=messages.values.toList()..sort((a,b)=>'${a['createdAt']}'.compareTo('${b['createdAt']}'));
        _ticket={...data,'messages':ordered,'olderCursor':_ticket?['olderCursor']??data['olderCursor']};
      }
      _error=null;
    });
  }
  Future<void> _create() async {
    if(_working||!_form.currentState!.validate())return;
    final data=<String,dynamic>{'name':_name.text.trim(),'email':_email.text.trim(),'phone':_phone.text.trim(),'company':_company.text.trim(),'persona':_persona,'topic':_topic,'text':_text.text.trim()};
    final fingerprint=jsonEncode(data);
    if(_pendingCreate?['fingerprint']!=fingerprint)_pendingCreate={'fingerprint':fingerprint,'requestId':_randomKey(),'accessKey':_randomKey()};
    final credentials=<String,dynamic>{'protocol':'','requestId':_pendingCreate!['requestId'],'accessKey':_pendingCreate!['accessKey']};
    setState((){_working=true;_error=null;});
    try{
      await _remember(credentials);
      final result=await _request('contacts',{...data,'requestId':credentials['requestId'],'accessKey':credentials['accessKey']});
      credentials['protocol']=result['protocol'];
      if(!mounted)return;_credentials=credentials;_pendingCreate=null;_text.clear();_apply(result,reset:true);await _remember(credentials);
    }catch(e){if(mounted)setState(()=>_error=_friendly(e));}finally{if(mounted)setState(()=>_working=false);}
  }
  Future<void> _open(Map<String,dynamic> credentials) async {
    if(_working)return;final epoch=++_epoch;setState((){_working=true;_error=null;});
    try{final result=await _request('lookup',credentials);if(!mounted||epoch!=_epoch)return;_credentials={...credentials,'protocol':result['protocol']};_reply.clear();_pendingReply=null;_apply(result,reset:true);await _remember(_credentials!);}catch(e){if(mounted&&epoch==_epoch)setState(()=>_error=_friendly(e));}finally{if(mounted&&epoch==_epoch)setState(()=>_working=false);}
  }
  Future<void> _refresh() async {
    if(_polling||_credentials==null)return;_polling=true;final epoch=_epoch,id=_ticket?['id'];
    try{final data=await _request('lookup',_credentials!);if(mounted&&epoch==_epoch&&_ticket?['id']==id)_apply(data);}catch(_){/* Manual refresh displays errors without losing the conversation. */}finally{_polling=false;}
  }
  Future<void> _send() async {
    if(_working||_reply.text.trim().isEmpty||_credentials==null)return;
    final text=_reply.text.trim();if(_pendingReply?['text']!=text)_pendingReply={'text':text,'requestId':_randomKey()};
    setState((){_working=true;_error=null;});
    try{await _request('contacts/${Uri.encodeComponent(_credentials!['protocol'])}/messages',{'accessKey':_credentials!['accessKey'],..._pendingReply!});if(!mounted)return;_reply.clear();_pendingReply=null;final updated=await _request('lookup',_credentials!);if(mounted)_apply(updated);}catch(e){if(mounted)setState(()=>_error=_friendly(e));}finally{if(mounted)setState(()=>_working=false);}
  }
  Future<void> _older() async {
    if(_working||_ticket?['olderCursor']==null||_credentials==null)return;
    setState(()=>_working=true);
    try{final data=await _request('lookup',{..._credentials!,'before':_ticket!['olderCursor']});if(mounted){_apply(data);setState(()=>_ticket!['olderCursor']=data['olderCursor']);}}catch(e){if(mounted)setState(()=>_error=_friendly(e));}finally{if(mounted)setState(()=>_working=false);}
  }
  Widget _field(TextEditingController controller,String label,{int max=160,bool required=true,TextInputType? keyboard,int lines=1})=>Padding(padding:const EdgeInsets.only(bottom:16),child:TextFormField(controller:controller,keyboardType:keyboard,maxLength:max,maxLines:lines,decoration:PrimeInputDecoration(labelText:label,counterText:'',filled:true,fillColor:AppColors.surfaceSoft),validator: localizeValidator((value){final text=value?.trim()??'';if(required&&text.isEmpty)return 'Preencha este campo';if(controller==_email&&!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text))return 'Informe um e-mail válido';return null;})));
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const PrimeText('Conte com a Porto Prime',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),leading:_ticket==null?null:IconButton(tooltip: translateLabel('Voltar à central'),icon:const Icon(AppIcons.arrowLeft),onPressed:_working?null:(){_epoch++;setState((){_ticket=null;_credentials=null;_error=null;});})),
    body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:720),child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,16,20,32),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      if(_error!=null)Padding(padding:const EdgeInsets.only(bottom:16),child:PrimeText(_error!,style:const TextStyle(color:AppColors.coral600,height:1.5))),
      if(_ticket!=null)..._conversation() else ...[
        const PrimeEditorialHeader(title:'Vamos conversar?',subtitle:'Ajuda com acesso, conta ou uma nova oportunidade. Você não precisa estar logado.',icon:AppIcons.help,eyebrow:'PORTAS ABERTAS'),
        const SizedBox(height:20),
        Wrap(spacing:10,runSpacing:8,children:[ChoiceChip(label:const PrimeText('Enviar um contato'),selected:!_tracking,onSelected:_working?null:(_)=>setState(()=>_tracking=false)),ChoiceChip(label:const PrimeText('Acompanhar protocolo'),selected:_tracking,onSelected:_working?null:(_)=>setState(()=>_tracking=true))]),
        const SizedBox(height:22),
        if(_tracking)...[
          TextField(controller:_protocolInput,textCapitalization:TextCapitalization.characters,decoration:const PrimeInputDecoration(labelText:'Protocolo',hintText:'PP-…')),const SizedBox(height:16),
          TextField(controller:_keyInput,obscureText:true,decoration:const PrimeInputDecoration(labelText:'Código de acesso')),const SizedBox(height:18),
          FilledButton(onPressed:_working?null:()=>_open({'protocol':_protocolInput.text.trim(),'accessKey':_keyInput.text.trim()}),child:PrimeText(_working?'Consultando…':'Abrir atendimento')),
        ]else Form(key:_form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          DropdownButtonFormField<String>(initialValue:_topic,isExpanded:true,itemHeight:null,menuMaxHeight:400,decoration:const PrimeInputDecoration(labelText:'Como podemos ajudar?'),items:publicSupportTopics.entries.map((e)=>DropdownMenuItem(value:e.key,child:PrimeText(e.value,maxLines:2,overflow:TextOverflow.ellipsis))).toList(),onChanged:_working?null:(value)=>setState(()=>_topic=value!)),
          const SizedBox(height:18),
          DropdownButtonFormField<String>(initialValue:_persona,isExpanded:true,itemHeight:null,menuMaxHeight:400,decoration:const PrimeInputDecoration(labelText:'Você fala como'),items:_personas.entries.map((e)=>DropdownMenuItem(value:e.key,child:PrimeText(e.value,maxLines:2,overflow:TextOverflow.ellipsis))).toList(),onChanged:_working?null:(value)=>setState(()=>_persona=value!)),
          const SizedBox(height:22),_field(_name,'Seu nome',max:120),_field(_email,'E-mail de contato',max:254,keyboard:TextInputType.emailAddress),_field(_phone,'WhatsApp com DDD (opcional)',required:false,max:30,keyboard:TextInputType.phone),
          if(_topic=='PARTNERSHIP'||_topic=='SPONSORSHIP')_field(_company,'Empresa, marca ou atividade (opcional)',required:false,max:160),
          _field(_text,'Conte como podemos ajudar',max:4000,lines:5),
          const PrimeText('Não envie senhas, códigos de cartão ou de autenticação. As respostas ficam disponíveis no acompanhamento do protocolo.',style:TextStyle(fontSize:11,height:1.6,color:AppColors.muted)),const SizedBox(height:18),
          FilledButton(onPressed:_working?null:_create,style:FilledButton.styleFrom(padding:const EdgeInsets.all(18)),child:PrimeText(_working?'Enviando…':'Enviar para a Porto Prime',textAlign:TextAlign.center)),
        ])),
        if(_saved.isNotEmpty)...[const SizedBox(height:28),const PrimeText('Seus contatos neste dispositivo',style:TextStyle(fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:12),for(final credentials in _saved)Card(child:ListTile(title:PrimeText((credentials['protocol']??'').toString().isEmpty?'Recuperar envio em andamento':credentials['protocol'].toString()),subtitle:const PrimeText('Abrir com o acesso salvo neste dispositivo'),trailing:const Icon(AppIcons.chevronRight),onTap:_working?null:()=>_open(credentials)))],
      ],
    ]))))),
  );
  List<Widget> _conversation()=>[
    PrimeEditorialHeader(title:'Estamos com você.',subtitle:'${_ticket!['protocol']} · ${_status(_ticket!['status'])}',icon:AppIcons.help,eyebrow:'SEU ATENDIMENTO'),const SizedBox(height:16),
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:AppColors.sand100,borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const PrimeText('Guarde seu acesso',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:8),const PrimeText('O protocolo e o código permitem acompanhar este contato em outro dispositivo. Mantenha o código privado.',style:TextStyle(fontSize:12,height:1.5)),const SizedBox(height:10),TextButton.icon(onPressed:()async{await Clipboard.setData(ClipboardData(text:'Protocolo: ${_credentials!['protocol']}\nCódigo de acesso: ${_credentials!['accessKey']}'));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:PrimeText('Protocolo e código copiados.')));},icon:const Icon(AppIcons.copy,size:16),label:const PrimeText('Copiar protocolo e código'))])),
    const SizedBox(height:20),if(_ticket!['olderCursor']!=null)TextButton(onPressed:_working?null:_older,child:const PrimeText('Mensagens anteriores')),
    for(final message in (_ticket!['messages'] as List))Align(alignment:message['senderRole']=='ADMIN'?Alignment.centerLeft:Alignment.centerRight,child:Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(16),constraints:const BoxConstraints(maxWidth:540),decoration:BoxDecoration(color:message['senderRole']=='ADMIN'?AppColors.ocean100:AppColors.surface,borderRadius:BorderRadius.circular(18),border:Border.all(color:AppColors.stroke)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[PrimeText(message['senderRole']=='ADMIN'?'Equipe Porto Prime':'Você',style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:AppColors.ocean700)),const SizedBox(height:7),SelectableText(message['text'].toString(),style:const TextStyle(fontSize:14,height:1.6))]))),
    const SizedBox(height:12),TextField(controller:_reply,onChanged:(_)=>setState((){}),maxLength:4000,minLines:2,maxLines:5,decoration:const PrimeInputDecoration(labelText:'Sua mensagem',hintText:'Responda por aqui…')),
    const SizedBox(height:10),FilledButton(onPressed:_working||_reply.text.trim().isEmpty?null:_send,style:FilledButton.styleFrom(padding:const EdgeInsets.all(16)),child:PrimeText(_working?'Enviando…':_ticket!['status']=='RESOLVED'?'Enviar e reabrir atendimento':'Enviar mensagem',textAlign:TextAlign.center)),
    TextButton(onPressed:_working?null:()=>_open(_credentials!),child:const PrimeText('Atualizar conversa')),
  ];
}
