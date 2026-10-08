import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';

String _money(dynamic value) => 'R\$ ${(double.tryParse(value.toString()) ?? 0).toStringAsFixed(2).replaceAll('.', ',')}';

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key, this.selectForCheckout = false});
  final bool selectForCheckout;
  @override
  State<AddressBookPage> createState() => _AddressBookState();
}
class _AddressBookState extends State<AddressBookPage> {
  final app = AppState.instance;
  String? selected, error;
  Map<String,dynamic> quote = {};
  bool loading = false, managing = false;
  int generation = 0, epoch = 0;
  @override
  void initState() {
    super.initState();
    epoch = app.deliveryPricingEpoch;
    if(app.addresses.isNotEmpty) selected = (app.addresses.firstWhere((a)=>a['isDefault']==true,orElse:()=>app.addresses.first)['id']).toString();
    app.addListener(_changed);
    if(widget.selectForCheckout && selected!=null) Future.microtask(_calculate);
  }
  void _changed() {
    if(!mounted) return;
    if(epoch != app.deliveryPricingEpoch) { epoch=app.deliveryPricingEpoch; if(widget.selectForCheckout && selected!=null) _calculate(); }
    setState((){});
  }
  @override
  void dispose(){app.removeListener(_changed);generation++;super.dispose();}
  Future<void> _calculate() async {
    final id=selected; if(id==null)return;
    final n=++generation;
    setState((){loading=true;error=null;quote={};});
    try { final result=await app.quoteDelivery(id); if(mounted && generation==n && selected==id) setState((){quote=result;loading=false;}); }
    catch(e){if(mounted && generation==n)setState((){loading=false;error=PrimeMessages.friendly(e);});}
  }
  Future<void> _edit([Map<String,dynamic>? address]) async {
    final saved=await Navigator.of(context).push<String>(MaterialPageRoute(builder:(_)=>AddressEditorPage(address:address)));
    if(!mounted || saved==null)return;
    setState(()=>selected=saved);
    if(widget.selectForCheckout) await _calculate();
  }
  Future<void> _manage(Map<String,dynamic> address, String action) async {
    if(managing)return;
    if(action=='edit'){await _edit(address);return;}
    if(action=='remove') {
      final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Excluir endereço?'),content:const Text('Você pode cadastrar este local novamente quando precisar.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Excluir'))]));
      if(yes!=true || !mounted)return;
    }
    setState(()=>managing=true);
    try {
      if(action=='default') await app.updateAddress(address['id'].toString(),{...{for(final k in ['label','street','number','complement','neighborhood','city','state','postalCode']) if(address[k]!=null) k:address[k]},'isDefault':true});
      else await app.removeAddress(address['id'].toString());
      if(selected==address['id'] && action=='remove'){selected=app.addresses.isEmpty?null:app.addresses.first['id'].toString();generation++;quote={};if(widget.selectForCheckout && selected!=null)await _calculate();}
    } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(PrimeMessages.friendly(e))));}
    finally{if(mounted)setState(()=>managing=false);}
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:Text(widget.selectForCheckout?'Onde vamos entregar?':'Seus endereços')),
    body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:680),child:ListView(padding:const EdgeInsets.all(20),children:[
      Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:AppColors.oceanDeep,borderRadius:BorderRadius.circular(24)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(AppIcons.mapPin,color:AppColors.mint,size:28),SizedBox(height:14),Text('Seu pedido, no lugar certo.',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:24)),SizedBox(height:8),Text('Organize seus locais e confirme a entrada no mapa para uma entrega tranquila.',style:TextStyle(color:Color(0xFFD2E6E3),height:1.5))])),
      const SizedBox(height:24),
      Row(children:[Expanded(child:Text('${app.addresses.length} locais salvos',style:const TextStyle(fontWeight:FontWeight.w700))),TextButton.icon(onPressed:managing?null:()=>_edit(),icon:const Icon(AppIcons.plus),label:const Text('Novo endereço'))]),
      if(app.addresses.isEmpty) Padding(padding:const EdgeInsets.symmetric(vertical:40),child:Column(children:[const Icon(AppIcons.home,size:44,color:AppColors.oceanDeep),const SizedBox(height:14),const Text('Sua primeira entrega começa aqui.',style:TextStyle(fontWeight:FontWeight.w700,fontSize:18)),const SizedBox(height:8),const Text('Cadastre sua casa, trabalho ou outro local.'),const SizedBox(height:20),FilledButton(onPressed:()=>_edit(),child:const Text('Cadastrar endereço'))])),
      ...app.addresses.map((raw){final a=Map<String,dynamic>.from(raw);final chosen=widget.selectForCheckout&&a['id']==selected;return Container(margin:const EdgeInsets.only(bottom:12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:chosen?AppColors.oceanDeep:AppColors.stroke,width:chosen?2:1)),child:InkWell(borderRadius:BorderRadius.circular(20),onTap:widget.selectForCheckout?(){setState(()=>selected=a['id'].toString());_calculate();}:()=>_edit(a),child:Padding(padding:const EdgeInsets.all(18),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(14)),child:Icon(chosen?AppIcons.check:AppIcons.home,color:AppColors.oceanDeep,size:22)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((a['label']??'Endereço de entrega').toString(),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:6),Text('${a['street']}, ${a['number']}',style:const TextStyle(fontWeight:FontWeight.w600)),if((a['complement']??'').toString().isNotEmpty)Text(a['complement'].toString()),const SizedBox(height:4),Text('${a['neighborhood']} · ${a['city']}/${a['state']}',style:const TextStyle(color:AppColors.muted,height:1.5)),Text('CEP ${a['postalCode']}',style:const TextStyle(color:AppColors.muted,fontSize:12)),if(a['isDefault']==true)const Padding(padding:EdgeInsets.only(top:10),child:Text('ENDEREÇO PRINCIPAL',style:TextStyle(color:AppColors.oceanDeep,fontWeight:FontWeight.w800,fontSize:10,letterSpacing:1))),if(a['locationConfirmed']!=true)TextButton(onPressed:()=>_edit(a),child:const Text('Confirmar localização no mapa'))])),PopupMenuButton<String>(tooltip:'Gerenciar endereço',enabled:!managing,onSelected:(v)=>_manage(a,v),itemBuilder:(_)=>[const PopupMenuItem(value:'edit',child:Text('Editar endereço')),if(a['isDefault']!=true)const PopupMenuItem(value:'default',child:Text('Usar como principal')),const PopupMenuItem(value:'remove',child:Text('Excluir'))])]))));}),
      if(widget.selectForCheckout && selected!=null)Container(margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(20)),child:loading?const Row(children:[SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2)),SizedBox(width:12),Expanded(child:Text('Calculando sua entrega pela rota…'))]):error!=null?Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(error!,style:const TextStyle(color:AppColors.coralStrong)),TextButton.icon(onPressed:_calculate,icon:const Icon(AppIcons.refresh),label:const Text('Tentar novamente'))]):Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Expanded(child:Text('Sua entrega',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18))),Text(_money(quote['deliveryFee']),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:23,color:AppColors.oceanDeep))]),const SizedBox(height:8),Text('${quote['distanceKm']??'—'} km por rota · aproximadamente ${quote['durationMinutes']??'—'} min'),const SizedBox(height:8),Text('Até ${quote['includedKm']} km: ${_money(quote['baseFee'])}. Depois, ${_money(quote['pricePerAdditionalKm'])}/km proporcional.',style:const TextStyle(fontSize:12,color:AppColors.muted,height:1.5))])),
      const SizedBox(height:20),
      if(widget.selectForCheckout)SizedBox(height:56,child:FilledButton(onPressed:loading||managing||error!=null||quote.isEmpty?null:()=>Navigator.pop(context,<String,dynamic>{'addressId':selected,'quote':quote}),child:const Text('Continuar para pagamento'))),
    ])))),
  );
}

class AddressEditorPage extends StatefulWidget {
  const AddressEditorPage({super.key,this.address});
  final Map<String,dynamic>? address;
  @override
  State<AddressEditorPage> createState()=>_AddressEditorState();
}
class _AddressEditorState extends State<AddressEditorPage> {
  final formKey=GlobalKey<FormState>();
  late final Map<String,TextEditingController> fields;
  final mapController=MapController();
  LatLng? point;
  bool searching=false;
  bool saving=false, principal=false;
  String? error;
  @override
  void initState(){super.initState();fields={for(final k in ['label','street','number','complement','neighborhood','city','state','postalCode'])k:TextEditingController(text:(widget.address?[k]??(k=='city'?'Porto Seguro':k=='state'?'BA':'')).toString())};principal=widget.address?['isDefault']==true;if(widget.address?['locationConfirmed']==true){final lat=double.tryParse(widget.address?['latitude'].toString()??''),lng=double.tryParse(widget.address?['longitude'].toString()??'');if(lat!=null&&lng!=null)point=LatLng(lat,lng);}}
  @override
  void dispose(){mapController.dispose();for(final f in fields.values){f.dispose();}super.dispose();}
  Widget field(String key,String label,{bool optional=false,bool numeric=false})=>Padding(padding:const EdgeInsets.only(bottom:14),child:TextFormField(controller:fields[key],enabled:!saving,keyboardType:numeric?TextInputType.number:TextInputType.streetAddress,textCapitalization:TextCapitalization.words,decoration:InputDecoration(labelText:label),validator:(v){if(!optional&&(v??'').trim().isEmpty)return 'Preencha este campo';if(key=='postalCode'&&(v??'').replaceAll(RegExp(r'\D'),'').length!=8)return 'Informe os 8 dígitos do CEP';if(key=='state'&&(v??'').trim().length!=2)return 'Use a sigla do estado';return null;},onChanged:(_){if(!['label','complement'].contains(key))setState(()=>point=null);}));
  Future<void> locate() async {
    if(searching || saving)return;
    setState((){searching=true;error=null;});
    try {
      final response=await AppState.instance.api.request('POST','/delivery/locate',body:{'street':fields['street']!.text,'number':fields['number']!.text,'city':fields['city']!.text});
      final rows=List<dynamic>.from(response['results']??[]);
      if(!mounted)return;
      if(rows.isEmpty){setState(()=>error='Rua não encontrada nos dados locais. Localize a entrada diretamente no mapa.');return;}
      final chosen=await showModalBottomSheet<Map<String,dynamic>>(context:context,isScrollControlled:true,builder:(ctx)=>SafeArea(child:ListView(shrinkWrap:true,padding:const EdgeInsets.all(22),children:[const Text('Encontramos estes locais',style:TextStyle(fontWeight:FontWeight.w800,fontSize:20)),const SizedBox(height:10),const Text('Escolha a rua e depois confirme a entrada no mapa.'),...rows.map((r)=>ListTile(leading:const Icon(AppIcons.mapPin),title:Text(r['street'].toString()),subtitle:Text((r['number']??'Trecho de rua').toString()),onTap:()=>Navigator.pop(ctx,Map<String,dynamic>.from(r))))])));
      if(!mounted||chosen==null)return;
      setState(()=>point=null);
      mapController.move(LatLng((chosen['latitude'] as num).toDouble(),(chosen['longitude'] as num).toDouble()),17);
    }catch(e){if(mounted)setState(()=>error=PrimeMessages.friendly(e));}finally{if(mounted)setState(()=>searching=false);}
  }
  Future<void> save()async {
    if(saving||!formKey.currentState!.validate())return;
    if(point==null){setState(()=>error='Confirme a entrada do endereço no mapa.');return;}
    setState((){saving=true;error=null;});
    try {final data=<String,dynamic>{for(final e in fields.entries)e.key:e.value.text.trim(),'isDefault':principal,'latitude':point!.latitude,'longitude':point!.longitude};final app=AppState.instance;final result=await app.api.request(widget.address==null?'POST':'PATCH',widget.address==null?'/addresses':'/addresses/${widget.address!['id']}',body:data);await app.loadAddresses();if(mounted)Navigator.pop(context,result['id'].toString());}
    catch(e){if(mounted)setState(()=>error=PrimeMessages.friendly(e));}finally{if(mounted)setState(()=>saving=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.address==null?'Novo endereço':'Editar endereço')),body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:680),child:Form(key:formKey,child:ListView(padding:const EdgeInsets.all(22),children:[
    const Text('Onde você quer receber?',style:TextStyle(fontSize:26,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('Preencha o endereço e confirme a entrada no mapa.',style:TextStyle(color:AppColors.muted,height:1.5)),const SizedBox(height:26),
    field('label','Nome do local · Casa, trabalho…',optional:true),field('postalCode','CEP',numeric:true),field('street','Rua / avenida'),field('number','Número'),field('complement','Complemento / referência',optional:true),field('neighborhood','Bairro'),Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:3,child:field('city','Cidade')),const SizedBox(width:12),Expanded(child:field('state','UF'))]),
    const SizedBox(height:12),const Text('Confirme o ponto de entrega',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('Toque na entrada da casa ou prédio. O ponto confirmado será usado para calcular a rota e a taxa.',style:TextStyle(color:AppColors.muted,height:1.5)),const SizedBox(height:14),
    OutlinedButton.icon(onPressed:saving||searching?null:locate,icon:const Icon(AppIcons.search),label:Text(searching?'Buscando rua…':'Localizar rua no mapa')),const SizedBox(height:12),
    ClipRRect(borderRadius:BorderRadius.circular(20),child:SizedBox(height:330,child:FlutterMap(mapController:mapController,options:MapOptions(initialCenter:point??const LatLng(-16.449,-39.064),initialZoom:16,minZoom:10,maxZoom:19,onTap:(_,p){if(!saving)setState((){point=p;error=null;});}),children:[TileLayer(urlTemplate:const String.fromEnvironment('MAP_TILE_URL',defaultValue:'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),userAgentPackageName:'PortoPrimeDelivery'),if(point!=null)MarkerLayer(markers:[Marker(point:point!,width:48,height:48,alignment:Alignment.topCenter,child:const Icon(AppIcons.mapPin,color:AppColors.oceanDeep,size:44))]),RichAttributionWidget(attributions:[TextSourceAttribution('OpenStreetMap contributors',onTap:()=>launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')))])]))),
    Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Row(children:[Icon(point==null?AppIcons.mapPin:AppIcons.checkCircle,color:AppColors.oceanDeep,size:20),const SizedBox(width:8),Expanded(child:Text(point==null?'Selecione o ponto no mapa':'Ponto de entrega confirmado',style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.oceanDeep)))])),
    SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,title:const Text('Usar como endereço principal'),subtitle:const Text('Selecionado primeiro nas próximas entregas'),value:principal,onChanged:saving?null:(v)=>setState(()=>principal=v)),
    if(error!=null)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(error!,style:const TextStyle(color:AppColors.coralStrong))),const SizedBox(height:18),SizedBox(height:56,child:FilledButton(onPressed:saving?null:save,child:saving?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('Salvar endereço'))),const SizedBox(height:30),
  ]))))));
}
