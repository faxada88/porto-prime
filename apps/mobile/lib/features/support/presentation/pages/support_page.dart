import '../../../../core/widgets/prime_brand.dart';
import '../../../../core/widgets/prime_ui.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

String _requestId() => '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
String _short(String id) => id.substring(id.length > 8 ? id.length - 8 : 0).toUpperCase();
String _status(dynamic status) => switch (status) {
  'IN_PROGRESS' => 'Em atendimento', 'RESOLVED' => 'Resolvido', _ => 'Aguardando atendimento',
};
String _time(dynamic date) {
  final d = DateTime.tryParse('$date')?.toLocal();
  return d == null ? '' : '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')} · ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

class SupportPage extends StatefulWidget {
  const SupportPage({super.key, this.orderId});
  final String? orderId;
  @override
  State<SupportPage> createState() => _SupportPageState();
}
class _SupportPageState extends State<SupportPage> with WidgetsBindingObserver {
  List<Map<String,dynamic>> _rows = [];
  List<String> _categories = [];
  bool _loading = true, _fetching = false, _openedOrder = false, _reloadQueued = false;
  String? _error;
  int _epoch = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _epoch = AppState.instance.supportEpoch;
    AppState.instance.addListener(_updated);
    _timer = Timer.periodic(const Duration(seconds:15), (_) => _load());
    _load();
  }
  void _updated() {
    if (!AppState.instance.loggedIn) { Navigator.of(context).popUntil((r)=>r.isFirst); return; }
    if (_epoch != AppState.instance.supportEpoch) {
      _epoch = AppState.instance.supportEpoch;
      _load();
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }
  @override
  void dispose() {
    _timer?.cancel();
    AppState.instance.removeListener(_updated);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  Future<void> _load() async {
    if (_fetching) { _reloadQueued = true; return; }
    _fetching = true;
    try {
      final results = await Future.wait([
        AppState.instance.api.request('GET','/support/me${widget.orderId == null ? '' : '?orderId=${Uri.encodeComponent(widget.orderId!)}'}'),
        AppState.instance.api.request('GET','/support/options'),
      ]);
      if (!mounted) return;
      setState(() {
        _rows = (results[0]['rows'] as List).map((x) => Map<String,dynamic>.from(x as Map)).toList();
        _categories = List<String>.from(results[1]['categories'] as List);
        _error = null;
        _loading = false;
      });
      if (widget.orderId != null && !_openedOrder) {
        _openedOrder = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_rows.isNotEmpty) {
            _open(_rows.first['id'].toString());
          } else {
            _new();
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Não conseguimos atualizar seus atendimentos. Tente novamente.'; });
    } finally { _fetching = false; if(_reloadQueued && mounted) { _reloadQueued = false; _load(); } }
  }
  Future<void> _open(String id) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SupportConversationPage(threadId:id)));
    if (mounted) _load();
  }
  Future<void> _new() async {
    if (_categories.isEmpty) return;
    final id = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => _NewSupportPage(categories:_categories,orderId:widget.orderId)));
    if (!mounted) return;
    if (id != null) await _open(id);
    if (mounted) _load();
  }
  @override
  Widget build(BuildContext context) {
    final partner = AppState.instance.isPartner;
    return Scaffold(
      backgroundColor:AppColors.canvas,
      appBar:AppBar(title:const Text('Ajuda e suporte')),
      body:SafeArea(child:RefreshIndicator(onRefresh:_load,child:ListView(
        physics:const AlwaysScrollableScrollPhysics(), padding:const EdgeInsets.all(20),
        children:[
          _SupportHero(title:partner ? 'Seu parceiro, em cada etapa.' : 'Conte com a Porto Prime.', subtitle:partner ? 'Abra um ticket sobre comissões, saques, indicações ou cadastro. Acompanhe cada resposta aqui.' : widget.orderId != null ? 'Fale com a distribuidora sobre o pedido #${_short(widget.orderId!)}. Nossa equipe recebe sua mensagem nesta conversa.' : 'Pedidos, entregas e sua conta. Um canal direto com a nossa equipe.'),
          const SizedBox(height:20),
          FilledButton.icon(onPressed:_categories.isEmpty ? null : _new,icon:const Icon(AppIcons.plus,size:19),label:Text(partner ? 'Abrir ticket' : 'Iniciar conversa')),
          const SizedBox(height:24),
          Text(widget.orderId != null ? 'Atendimento do pedido' : 'Seus atendimentos',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:AppColors.ink)),
          const SizedBox(height:12),
          if (_error != null) _SupportError(message:_error!,onRetry:_load),
          if (_loading) ...List.generate(3, (_) => const _SupportSkeleton()),
          if (!_loading && _rows.isEmpty && _error == null) const _SupportEmpty(),
          ..._rows.map((t) => Padding(padding:const EdgeInsets.only(bottom:12),child:Material(color:Colors.white,borderRadius:BorderRadius.circular(20),child:InkWell(borderRadius:BorderRadius.circular(20),onTap:() => _open(t['id'].toString()),child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:AppColors.ocean100,borderRadius:BorderRadius.circular(12)),child:const Icon(AppIcons.mail,size:21,color:AppColors.ocean700)),const SizedBox(width:12),Expanded(child:Text(t['subject'].toString(),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14,color:AppColors.ink))),const Icon(AppIcons.chevronRight,size:18,color:AppColors.muted)]),
            const SizedBox(height:12),Text((t['messages'] as List).isEmpty ? t['category'].toString() : t['messages'][0]['text'].toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,color:AppColors.muted,height:1.6)),
            const SizedBox(height:14),Wrap(spacing:12,runSpacing:8,children:[_StatusPill(status:t['status'].toString()),Text('#${_short(t['id'].toString())} · ${_time(t['updatedAt'])}',style:const TextStyle(fontSize:10,color:AppColors.muted))]),
          ])))))),
          const SizedBox(height:20),
          const Text('Suas mensagens ficam registradas. Você pode sair e voltar para acompanhar as respostas.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:AppColors.muted,height:1.7)),
        ],
      ))),
    );
  }
}

class _NewSupportPage extends StatefulWidget {
  const _NewSupportPage({required this.categories,this.orderId});
  final List<String> categories;
  final String? orderId;
  @override
  State<_NewSupportPage> createState() => _NewSupportPageState();
}
class _NewSupportPageState extends State<_NewSupportPage> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController(), _message = TextEditingController();
  String? _category, _error;
  String? _pendingId, _pendingBody;
  bool _sending = false;
  @override
  void initState() { super.initState(); _category = widget.categories.first; if(widget.orderId != null) _subject.text = 'Pedido #${_short(widget.orderId!)}'; }
  @override
  void dispose() { _subject.dispose(); _message.dispose(); super.dispose(); }
  Future<void> _send() async {
    if (_sending || !_form.currentState!.validate()) return;
    final signature = '$_category|${_subject.text.trim()}|${_message.text.trim()}';
    if (_pendingBody != signature) { _pendingBody = signature; _pendingId = _requestId(); }
    setState(() { _sending = true; _error = null; });
    try {
      final result = await AppState.instance.api.request('POST','/support/threads',body:{'category':_category,'subject':_subject.text.trim(),'text':_message.text.trim(),'requestId':_pendingId,if(widget.orderId != null) 'orderId':widget.orderId});
      if (mounted) Navigator.of(context).pop(result['id'].toString());
    } catch (_) {
      if(mounted) setState(() { _sending = false; _error = 'Não foi possível abrir o atendimento. Seu texto foi preservado; tente novamente.'; });
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor:AppColors.canvas,appBar:AppBar(title:Text(AppState.instance.isPartner ? 'Novo ticket' : 'Falar com a equipe')),body:SafeArea(child:Form(key:_form,child:ListView(padding:const EdgeInsets.all(20),children:[
    const _SupportHero(title:'Vamos resolver juntos.',subtitle:'Selecione o assunto e conte o que aconteceu. Quanto mais claro, melhor podemos ajudar.'),
    const SizedBox(height:24),
    DropdownButtonFormField<String>(value:_category,isExpanded:true,decoration:const InputDecoration(labelText:'Como podemos ajudar?'),items:widget.categories.map((c) => DropdownMenuItem(value:c,child:Text(c))).toList(),onChanged:_sending ? null : (v) => setState(() => _category = v)),
    const SizedBox(height:18),
    TextFormField(controller:_subject,enabled:!_sending,maxLength:120,decoration:const InputDecoration(labelText:'Título',hintText:'Um resumo do que você precisa'),validator:(v) => v == null || v.trim().isEmpty ? 'Informe o título do atendimento' : null),
    const SizedBox(height:8),
    TextFormField(controller:_message,enabled:!_sending,maxLength:4000,minLines:5,maxLines:10,keyboardType:TextInputType.multiline,decoration:const InputDecoration(labelText:'Sua mensagem',alignLabelWithHint:true,hintText:'Descreva sua dúvida ou o que aconteceu…'),validator:(v) => v == null || v.trim().isEmpty ? 'Escreva sua mensagem' : null),
    if(_error != null) Padding(padding:const EdgeInsets.symmetric(vertical:12),child:_SupportError(message:_error!,onRetry:_send)),
    const SizedBox(height:18),
    FilledButton.icon(onPressed:_sending ? null : _send,icon:_sending ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(AppIcons.arrowRight,size:18),label:Text(_sending ? 'Enviando…' : 'Enviar para Porto Prime')),
    const SizedBox(height:18),
    const Text('Não envie senhas, códigos de acesso ou dados completos do cartão.',style:TextStyle(fontSize:11,color:AppColors.muted,height:1.6)),
  ]))));
}

class SupportConversationPage extends StatefulWidget {
  const SupportConversationPage({super.key,required this.threadId});
  final String threadId;
  @override
  State<SupportConversationPage> createState() => _SupportConversationPageState();
}
class _SupportConversationPageState extends State<SupportConversationPage> with WidgetsBindingObserver {
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  Map<String,dynamic>? _thread;
  List<Map<String,dynamic>> _messages = [];
  String? _olderCursor, _error, _pendingText, _pendingId;
  bool _sending = false, _fetching = false, _olderBusy = false, _first = true, _reloadQueued = false;
  int _epoch = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this);
    _epoch = AppState.instance.supportEpoch;
    AppState.instance.addListener(_updated);
    _timer = Timer.periodic(const Duration(seconds:15), (_) => _load());
    _load();
  }
  void _updated() { if(!AppState.instance.loggedIn) { Navigator.of(context).popUntil((r)=>r.isFirst); return; } if (_epoch != AppState.instance.supportEpoch) { _epoch = AppState.instance.supportEpoch; _load(); } }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if(state == AppLifecycleState.resumed) _load(); }
  @override
  void dispose() { _timer?.cancel(); AppState.instance.removeListener(_updated); WidgetsBinding.instance.removeObserver(this); _draft.dispose(); _scroll.dispose(); super.dispose(); }
  Future<void> _load() async {
    if (_fetching) { _reloadQueued = true; return; }
    _fetching = true;
    try {
      final result = Map<String,dynamic>.from(await AppState.instance.api.request('GET','/support/threads/${widget.threadId}') as Map);
      if(!mounted) return;
      final latest = (result['messages'] as List).map((x) => Map<String,dynamic>.from(x as Map)).toList();
      final previousLast = _messages.isEmpty ? null : _messages.last['id'];
      final autoScroll = !_scroll.hasClients || _scroll.position.maxScrollExtent - _scroll.offset < 160;
      final byId = {for(final m in _messages) m['id'].toString():m,for(final m in latest) m['id'].toString():m};
      final merged = byId.values.toList()..sort((a,b) { final date = a['createdAt'].toString().compareTo(b['createdAt'].toString()); return date != 0 ? date : a['id'].toString().compareTo(b['id'].toString()); });
      setState(() { _thread = result; _messages = merged; if(_first) _olderCursor = result['olderCursor']?.toString(); _first = false; _error = null; });
      if(autoScroll && previousLast != (_messages.isEmpty ? null : _messages.last['id'])) _bottom();
    } catch (_) { if(mounted) setState(() => _error = 'Não foi possível atualizar a conversa. Tente novamente.'); }
    finally { _fetching = false; if(_reloadQueued && mounted) { _reloadQueued = false; _load(); } }
  }
  void _bottom() { WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted && _scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent); }); }
  Future<void> _older() async {
    if(_olderBusy || _olderCursor == null) return;
    setState(() => _olderBusy = true);
    try {
      final result = await AppState.instance.api.request('GET','/support/threads/${widget.threadId}?before=${Uri.encodeComponent(_olderCursor!)}');
      if(!mounted) return;
      final older = (result['messages'] as List).map((x) => Map<String,dynamic>.from(x as Map)).toList();
      final known = _messages.map((m) => m['id']).toSet();
      setState(() { _messages = [...older.where((m) => !known.contains(m['id'])),..._messages]; _olderCursor = result['olderCursor']?.toString(); });
    } catch (_) { if(mounted) setState(() => _error = 'Não foi possível carregar as mensagens anteriores.'); }
    finally { if(mounted) setState(() => _olderBusy = false); }
  }
  Future<void> _send() async {
    final text = _draft.text.trim();
    if(_sending || text.isEmpty) return;
    if(_pendingText != text) { _pendingText = text; _pendingId = _requestId(); }
    setState(() { _sending = true; _error = null; });
    try {
      await AppState.instance.api.request('POST','/support/threads/${widget.threadId}/messages',body:{'text':text,'requestId':_pendingId});
      if(!mounted) return;
      _draft.clear(); _pendingText = null; _pendingId = null;
      await _load(); _bottom();
    } catch (_) { if(mounted) setState(() => _error = 'Sua mensagem não foi confirmada. Tente enviar novamente.'); }
    finally { if(mounted) setState(() => _sending = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor:AppColors.canvas,appBar:AppBar(title:const Text('Equipe Porto Prime')),body:SafeArea(child:Column(children:[
    if(_thread != null) Container(width:double.infinity,color:Colors.white,padding:const EdgeInsets.fromLTRB(20,10,20,16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(_thread!['subject'].toString(),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16,color:AppColors.ink)),const SizedBox(height:9),Wrap(spacing:10,runSpacing:8,children:[_StatusPill(status:_thread!['status'].toString()),Text('#${_short(widget.threadId)}${_thread!['orderId'] == null ? '' : ' · Pedido #${_short(_thread!['orderId'].toString())}'}',style:const TextStyle(fontSize:10,color:AppColors.muted))])])),
    if(_error != null) Padding(padding:const EdgeInsets.all(12),child:_SupportError(message:_error!,onRetry:_load)),
    Expanded(child:_thread == null ? ListView(padding:const EdgeInsets.all(20),children:const [_SupportSkeleton(),_SupportSkeleton(),_SupportSkeleton()]) : ListView.builder(controller:_scroll,padding:const EdgeInsets.all(20),itemCount:_messages.length+1,itemBuilder:(context,index) {
      if(index == 0) return _olderCursor == null ? const Padding(padding:EdgeInsets.only(bottom:18),child:Text('Atendimento oficial Porto Prime',textAlign:TextAlign.center,style:TextStyle(fontSize:10,color:AppColors.muted))) : Center(child:TextButton(onPressed:_olderBusy ? null : _older,child:Text(_olderBusy ? 'Buscando…' : 'Mensagens anteriores')));
      final m = _messages[index-1], admin = m['senderRole'] == 'ADMIN';
      return Align(alignment:admin ? Alignment.centerLeft : Alignment.centerRight,child:Container(constraints:BoxConstraints(maxWidth:min(MediaQuery.sizeOf(context).width*.8,640.0)),margin:const EdgeInsets.only(bottom:14),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:admin ? Colors.white : AppColors.ocean700,border:admin ? Border.all(color:AppColors.stroke) : null,borderRadius:BorderRadius.only(topLeft:const Radius.circular(18),topRight:const Radius.circular(18),bottomLeft:Radius.circular(admin ? 4 : 18),bottomRight:Radius.circular(admin ? 18 : 4))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(admin ? 'Equipe Porto Prime' : 'Você',style:TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:admin ? AppColors.ocean700 : Colors.white70)),const SizedBox(height:7),SelectableText(m['text'].toString(),style:TextStyle(fontSize:14,height:1.55,color:admin ? AppColors.ink : Colors.white)),const SizedBox(height:8),Text(_time(m['createdAt']),style:TextStyle(fontSize:9,color:admin ? AppColors.muted : Colors.white70))])));
    })),
    Container(padding:const EdgeInsets.fromLTRB(16,12,16,16),decoration:const BoxDecoration(color:Colors.white,border:Border(top:BorderSide(color:AppColors.stroke))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(_thread?['status'] == 'RESOLVED') const Padding(padding:EdgeInsets.only(bottom:8),child:Text('Precisa de mais ajuda? Sua mensagem reabre o atendimento.',style:TextStyle(fontSize:11,color:AppColors.muted))),
      Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:TextField(controller:_draft,enabled:!_sending,minLines:1,maxLines:4,maxLength:4000,keyboardType:TextInputType.multiline,decoration:const InputDecoration(hintText:'Escreva sua mensagem…',counterText:''))),const SizedBox(width:10),SizedBox(height:48,child:FilledButton(onPressed:_sending || _thread == null ? null : _send,style:FilledButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:15)),child:_sending ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(AppIcons.arrowRight,semanticLabel:'Enviar mensagem')))]),
    ])),
  ])));
}

class _SupportHero extends StatelessWidget {
 const _SupportHero({required this.title,required this.subtitle});
 final String title,subtitle;
 @override Widget build(BuildContext context)=>PrimeEditorialHeader(title:title,subtitle:subtitle,icon:AppIcons.help,eyebrow:'AJUDA / PORTO PRIME');
}
class _StatusPill extends StatelessWidget {
 const _StatusPill({required this.status});
 final String status;
 @override
 Widget build(BuildContext context) => Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:status == 'RESOLVED' ? AppColors.ocean100 : status == 'IN_PROGRESS' ? AppColors.sky100 : AppColors.sun200,borderRadius:BorderRadius.circular(8)),child:Text(_status(status),style:TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:status == 'OPEN' ? const Color(0xFF73501B) : AppColors.ocean700)));
}
class _SupportSkeleton extends StatelessWidget {
 const _SupportSkeleton();
 @override
 Widget build(BuildContext context) => Semantics(label:'Carregando atendimento',child:Container(height:110,margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(height:14,width:160,color:AppColors.surfaceMuted),const SizedBox(height:12),Container(height:10,width:double.infinity,color:AppColors.surfaceMuted),const SizedBox(height:12),Container(height:10,width:110,color:AppColors.surfaceMuted)])));
}
class _SupportEmpty extends StatelessWidget {
 const _SupportEmpty();
 @override Widget build(BuildContext context)=>const PrimeEmptyState(icon:AppIcons.mail,title:'Estamos aqui para ajudar.',message:'Abra um atendimento. Suas conversas e respostas ficam organizadas aqui.');
}
class _SupportError extends StatelessWidget {
 const _SupportError({required this.message,required this.onRetry});
 final String message;
 final VoidCallback onRetry;
 @override
 Widget build(BuildContext context) => Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:AppColors.coral100,borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(message,style:const TextStyle(color:AppColors.coral600,fontSize:12,height:1.6)),TextButton(onPressed:onRetry,child:const Text('Tentar novamente'))]));
}

