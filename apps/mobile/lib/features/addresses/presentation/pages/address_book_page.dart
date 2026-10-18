import '../../../../core/widgets/prime_brand.dart';
import '../../../../core/navigation/app_nav.dart';
import '../../../checkout/presentation/widgets/checkout_progress.dart';
import '../../../../core/widgets/customer_credit_selector.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';

String _money(dynamic value) => 'R\$ ${(double.tryParse(value.toString()) ?? 0).toStringAsFixed(2).replaceAll('.', ',')}';

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key, this.selectForCheckout = false, this.onContinue});
  final bool selectForCheckout;
  final Future<void> Function(Map<String,dynamic> selection)? onContinue;
  @override
  State<AddressBookPage> createState() => _AddressBookState();
}
class _AddressBookState extends State<AddressBookPage> {
  final app = AppState.instance;
  String? selected, error;
  Map<String,dynamic> quote = {};
  bool loading = false, managing = false, preparing = false;
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
  Future<void> _continueCheckout() async {
    if(preparing||loading||managing||quote.isEmpty||error!=null||selected==null)return;
    final selection=<String,dynamic>{'addressId':selected,'quote':Map<String,dynamic>.from(quote),'storeCreditRequested':app.selectedCustomerCredit(double.tryParse(quote['storeCreditBalance'].toString())??0,app.cartSubtotal+(double.tryParse(quote['deliveryFee'].toString())??0))};
    if(widget.onContinue==null){Navigator.pop(context,selection);return;}
    setState(()=>preparing=true);
    try{await widget.onContinue!(selection);}
    catch(e){if(mounted){setState(()=>error=PrimeMessages.friendly(e));}}
    finally{if(mounted)setState(()=>preparing=false);}
  }
  Widget _checkoutView(BuildContext context){
    final balance=double.tryParse(quote['storeCreditBalance'].toString())??0;
    final credit=app.selectedCustomerCredit(balance,app.cartSubtotal+(double.tryParse(quote['deliveryFee'].toString())??0));
    final fee=double.tryParse(quote['deliveryFee'].toString())??0;
    final remaining=((app.cartSubtotal+fee-credit)*100).round()/100;
    final valid=selected!=null&&quote.isNotEmpty&&error==null&&!loading&&!managing&&!preparing&&app.cart.isNotEmpty;
    return PopScope(canPop:true,child:Scaffold(backgroundColor:AppColors.canvas,
      appBar:AppBar(title:const Text('Entrega e revisão'),leading:IconButton(tooltip:'Voltar ao carrinho',onPressed:()=>Navigator.of(context).pop(),icon:const Icon(AppIcons.arrowLeft)),actions:[IconButton(tooltip:'Voltar ao início',onPressed:AppNav.instance.home,icon:const Icon(AppIcons.home))]),
      body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:680),child:Column(children:[
       Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(22,12,22,24),children:[
        const CheckoutProgress(step:1),const SizedBox(height:28),
        const PrimePageIntro(title:'Qual é o seu destino?',subtitle:'Confirme o endereço, revise sua compra e continue com tranquilidade.',icon:AppIcons.mapPin,label:'ENTREGA / PORTO PRIME'),
        Row(children:[const Expanded(child:Text('Endereço de entrega',style:TextStyle(fontWeight:FontWeight.w800,fontSize:16))),TextButton.icon(onPressed:preparing||managing?null:()=>_edit(),icon:const Icon(AppIcons.plus,size:17),label:const Text('Adicionar'))]),
        if(app.addresses.isEmpty)PrimeEmptyState(icon:AppIcons.mapPin,title:'Seu primeiro endereço',message:'Informe a rua, hotel ou ponto de entrega para calcularmos a rota.',actionLabel:'Adicionar endereço',onAction:()=>_edit()),
        ...app.addresses.map((raw){final a=Map<String,dynamic>.from(raw as Map);final chosen=a['id']==selected;return Container(margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:chosen?AppColors.ocean50:Colors.white,borderRadius:BorderRadius.circular(AppRadius.md),border:Border.all(color:chosen?AppColors.ocean600:AppColors.stroke,width:chosen?1.5:1)),child:InkWell(borderRadius:BorderRadius.circular(AppRadius.md),onTap:preparing||managing?null:(){setState(()=>selected=a['id'].toString());_calculate();},child:Padding(padding:const EdgeInsets.all(17),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(chosen?AppIcons.check:AppIcons.mapPin,color:chosen?AppColors.ocean700:AppColors.muted,size:22),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${a['label']??'Entrega'}',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text('${a['street']}, ${a['number']}',style:const TextStyle(height:1.5)),if('${a['complement']??''}'.isNotEmpty)Text('${a['complement']}',style:const TextStyle(color:AppColors.muted,height:1.5)),Text('${a['neighborhood']} · ${a['city']}',style:const TextStyle(fontSize:12,color:AppColors.muted,height:1.5))])),IconButton(tooltip:'Editar endereço',onPressed:preparing||managing?null:()=>_edit(a),icon:const Icon(AppIcons.edit_rounded,size:17))]))));}),
        if(loading)const Padding(padding:EdgeInsets.symmetric(vertical:12),child:PrimeSkeleton(height:78,radius:18)),
        if(!loading&&quote.isNotEmpty)Container(padding:const EdgeInsets.all(17),margin:const EdgeInsets.only(top:8),decoration:BoxDecoration(color:AppColors.ocean900,borderRadius:BorderRadius.circular(AppRadius.md)),child:Row(children:[const Icon(AppIcons.route,color:AppColors.ocean300),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Entrega Prime',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text('${quote['distanceKm']??'—'} km por rota · aproximadamente ${quote['durationMinutes']??'—'} min',style:const TextStyle(color:Colors.white70,fontSize:12,height:1.5))])),Text(_money(fee),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:18))])),
        if(error!=null)Padding(padding:const EdgeInsets.only(top:14),child:Column(children:[PrimeErrorBanner(message:error!),TextButton.icon(onPressed:preparing?null:_calculate,icon:const Icon(AppIcons.refresh,size:16),label:const Text('Atualizar entrega e tentar novamente'))])),
        const SizedBox(height:24),
        Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(AppRadius.lg),border:Border.all(color:AppColors.stroke)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Icon(AppIcons.cart,size:20,color:AppColors.ocean700),const SizedBox(width:9),Expanded(child:Text('Sua compra · ${app.cartCount} itens',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)))]),const SizedBox(height:14),
         ...app.cart.entries.map((entry){final product=app.product(entry.key);return Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Text('${entry.value}×',style:const TextStyle(color:AppColors.ocean700,fontWeight:FontWeight.w800)),const SizedBox(width:10),Expanded(child:Text('${product?['name']??'Produto'}',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:13))),const SizedBox(width:10),Text(_money((double.tryParse('${product?['price']}')??0)*entry.value),style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700))]));}),
         const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Divider(height:1)),CheckoutPriceLine(label:'Produtos',value:_money(app.cartSubtotal)),CheckoutPriceLine(label:'Entrega',value:loading?'Calculando…':quote.isEmpty?'Selecione um endereço':_money(fee)),if(credit>0)CheckoutPriceLine(label:'Saldo Porto Prime escolhido',value:'−${_money(credit)}'),
        ])),
        if(quote.isNotEmpty&&!loading)AbsorbPointer(absorbing:preparing,child:CustomerCreditSelector(available:balance,total:app.cartSubtotal+fee)),
        const SizedBox(height:8),const Row(children:[Icon(AppIcons.shield,size:16,color:AppColors.ocean700),SizedBox(width:8),Expanded(child:Text('Na próxima etapa, seus dados de pagamento ficam com o Stripe.',style:TextStyle(fontSize:12,color:AppColors.muted,height:1.5)))]),
       ])),
       Container(padding:const EdgeInsets.fromLTRB(22,16,22,18),decoration:const BoxDecoration(color:Colors.white,border:Border(top:BorderSide(color:AppColors.stroke))),child:Column(mainAxisSize:MainAxisSize.min,children:[CheckoutPriceLine(label:'Total a pagar',value:quote.isEmpty||loading?'—':_money(remaining),strong:true),const SizedBox(height:10),SizedBox(width:double.infinity,height:54,child:FilledButton.icon(onPressed:valid?_continueCheckout:null,icon:preparing?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(AppIcons.arrowRight,size:18),label:Text(preparing?'Preparando pagamento…':remaining==0&&quote.isNotEmpty?'Ir para confirmação':'Ir para pagamento seguro'))),const SizedBox(height:7),const Text('Você ainda não será cobrado nesta etapa.',style:TextStyle(fontSize:11,color:AppColors.muted))])),
      ]))))));
  }
  @override
  Widget build(BuildContext context) => widget.selectForCheckout?_checkoutView(context):Scaffold(
    appBar:AppBar(title:Text(widget.selectForCheckout?'Onde vamos entregar?':'Seus endereços')),
    body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:680),child:ListView(padding:const EdgeInsets.all(20),children:[
      const PrimeEditorialHeader(title:'Seus lugares favoritos.',subtitle:'Casa, trabalho ou hotel. Organize os locais onde você quer receber seus pedidos.',icon:AppIcons.mapPin,eyebrow:'ENDEREÇOS / PORTO PRIME'),
      const SizedBox(height:24),
      Row(children:[Expanded(child:Text('${app.addresses.length} locais salvos',style:const TextStyle(fontWeight:FontWeight.w700))),TextButton.icon(onPressed:managing?null:()=>_edit(),icon:const Icon(AppIcons.plus),label:const Text('Novo endereço'))]),
      if(app.addresses.isEmpty) Padding(padding:const EdgeInsets.symmetric(vertical:40),child:Column(children:[const Icon(AppIcons.home,size:44,color:AppColors.oceanDeep),const SizedBox(height:14),const Text('Sua primeira entrega começa aqui.',style:TextStyle(fontWeight:FontWeight.w700,fontSize:18)),const SizedBox(height:8),const Text('Cadastre sua casa, trabalho ou outro local.'),const SizedBox(height:20),FilledButton(onPressed:()=>_edit(),child:const Text('Cadastrar endereço'))])),
      ...app.addresses.map((raw){final a=Map<String,dynamic>.from(raw);final chosen=widget.selectForCheckout&&a['id']==selected;return Container(margin:const EdgeInsets.only(bottom:12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:chosen?AppColors.oceanDeep:AppColors.stroke,width:chosen?2:1)),child:InkWell(borderRadius:BorderRadius.circular(20),onTap:widget.selectForCheckout?(){setState(()=>selected=a['id'].toString());_calculate();}:()=>_edit(a),child:Padding(padding:const EdgeInsets.all(18),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(14)),child:Icon(chosen?AppIcons.check:AppIcons.home,color:AppColors.oceanDeep,size:22)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((a['label']??'Endereço de entrega').toString(),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:6),Text('${a['street']}, ${a['number']}',style:const TextStyle(fontWeight:FontWeight.w600)),if((a['complement']??'').toString().isNotEmpty)Text(a['complement'].toString()),const SizedBox(height:4),Text('${a['neighborhood']} · ${a['city']}/${a['state']}',style:const TextStyle(color:AppColors.muted,height:1.5)),Text('CEP ${a['postalCode']}',style:const TextStyle(color:AppColors.muted,fontSize:12)),if(a['isDefault']==true)const Padding(padding:EdgeInsets.only(top:10),child:Text('ENDEREÇO PRINCIPAL',style:TextStyle(color:AppColors.oceanDeep,fontWeight:FontWeight.w800,fontSize:10,letterSpacing:1)))])),PopupMenuButton<String>(tooltip:'Gerenciar endereço',enabled:!managing,onSelected:(v)=>_manage(a,v),itemBuilder:(_)=>[const PopupMenuItem(value:'edit',child:Text('Editar endereço')),if(a['isDefault']!=true)const PopupMenuItem(value:'default',child:Text('Usar como principal')),const PopupMenuItem(value:'remove',child:Text('Excluir'))])]))));}),
      if(widget.selectForCheckout && selected!=null)Container(margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(20)),child:loading?const Row(children:[SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2)),SizedBox(width:12),Expanded(child:Text('Calculando sua entrega pela rota…'))]):error!=null?Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(error!,style:const TextStyle(color:AppColors.coralStrong)),TextButton.icon(onPressed:_calculate,icon:const Icon(AppIcons.refresh),label:const Text('Tentar novamente'))]):Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Expanded(child:Text('Sua entrega',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18))),Text(_money(quote['deliveryFee']),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:23,color:AppColors.oceanDeep))]),const SizedBox(height:8),Text('${quote['distanceKm']??'—'} km por rota · aproximadamente ${quote['durationMinutes']??'—'} min'),if(quote['locationAccuracy']=='STREET_ESTIMATE')const Padding(padding:EdgeInsets.only(top:8),child:Text('Distância estimada pelo trecho da rua. Número ainda não mapeado.',style:TextStyle(fontSize:12,color:AppColors.muted))),])),
      if(widget.selectForCheckout && quote.isNotEmpty && error==null && !loading)CustomerCreditSelector(available:double.tryParse(quote['storeCreditBalance'].toString())??0),
      if(widget.selectForCheckout && app.selectedCustomerCredit(double.tryParse(quote['storeCreditBalance'].toString())??0,app.cartSubtotal+(double.tryParse(quote['deliveryFee'].toString())??0))>0)Padding(padding:const EdgeInsets.only(top:12),child:Text('Voucher escolhido: −${_money(app.selectedCustomerCredit(double.tryParse(quote['storeCreditBalance'].toString())??0,app.cartSubtotal+(double.tryParse(quote['deliveryFee'].toString())??0)))}',style:const TextStyle(color:AppColors.oceanDeep,fontWeight:FontWeight.w700))),
      if(widget.selectForCheckout && quote.isNotEmpty && error==null && !loading)Padding(padding:const EdgeInsets.only(top:16),child:Row(children:[const Expanded(child:Text('Total com entrega',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18))),Text(_money(app.cartSubtotal+(double.tryParse(quote['deliveryFee'].toString())??0)-app.selectedCustomerCredit(double.tryParse(quote['storeCreditBalance'].toString())??0,app.cartSubtotal+(double.tryParse(quote['deliveryFee'].toString())??0))),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:22))])),
      const SizedBox(height:20),
      if(widget.selectForCheckout)SizedBox(height:56,child:FilledButton(onPressed:loading||managing||error!=null||quote.isEmpty?null:()=>Navigator.pop(context,<String,dynamic>{'addressId':selected,'quote':quote,'storeCreditRequested':app.selectedCustomerCredit(double.tryParse(quote['storeCreditBalance'].toString())??0,app.cartSubtotal+(double.tryParse(quote['deliveryFee'].toString())??0))}),child:const Text('Continuar para pagamento'))),
    ])))),
  );
}

class AddressEditorPage extends StatefulWidget {
  const AddressEditorPage({super.key,this.address,this.initialPlace});
  final Map<String,dynamic>? address;
  final Map<String,dynamic>? initialPlace;
  @override
  State<AddressEditorPage> createState()=>_AddressEditorState();
}
class _AddressEditorState extends State<AddressEditorPage> {
  final formKey=GlobalKey<FormState>();
  final app=AppState.instance;
  late final Map<String,TextEditingController> fields;
  Timer? debounce, searchDebounce;
  final searchController=TextEditingController();
  List<Map<String,dynamic>> suggestions=[];
  String? locationRef, searchError, selectedName, autofilledPlaceName;
  bool searching=false;
  int searchGeneration=0;
  Map<String,dynamic> quote={};
  bool calculating=false, postalLoading=false, saving=false, principal=false;
  String? error, postalHint;
  int generation=0, postalGeneration=0, epoch=0;
  @override
  void initState(){
    super.initState();
    fields={for(final k in ['label','street','number','complement','neighborhood','city','state','postalCode'])k:TextEditingController(text:(widget.address?[k]??(k=='city'?'Porto Seguro':k=='state'?'BA':'')).toString())};
    principal=widget.address?['isDefault']==true;
    locationRef=widget.address?['locationRef']?.toString();
    if(locationRef!=null){selectedName=(widget.address?['label']??widget.address?['street']??'Local salvo').toString();searchController.text=selectedName!;}
    epoch=app.deliveryPricingEpoch;
    app.addListener(_pricingChanged);
    _schedule();
    if(widget.initialPlace!=null)_selectPlace(widget.initialPlace!);
  }
  void _pricingChanged(){if(mounted && epoch!=app.deliveryPricingEpoch){epoch=app.deliveryPricingEpoch;_schedule();}}
  @override
  void dispose(){searchDebounce?.cancel();searchGeneration++;searchController.dispose();debounce?.cancel();generation++;postalGeneration++;app.removeListener(_pricingChanged);for(final f in fields.values){f.dispose();}super.dispose();}
  Map<String,dynamic> get data=>{for(final e in fields.entries)e.key:e.value.text.trim(),'isDefault':principal,if(locationRef!=null)'locationRef':locationRef};
  bool get complete=>(locationRef!=null&&fields['street']!.text.trim().isNotEmpty&&fields['city']!.text.trim().isNotEmpty&&fields['state']!.text.trim().length==2&&fields['postalCode']!.text.replaceAll(RegExp(r'\D'),'').length==8)||['street','number','neighborhood','city','state'].every((k)=>fields[k]!.text.trim().isNotEmpty)&&fields['state']!.text.trim().length==2&&fields['postalCode']!.text.replaceAll(RegExp(r'\D'),'').length==8;
  void _searchChanged(String value){
    searchDebounce?.cancel();final n=++searchGeneration;
    debounce?.cancel();generation++;
    setState((){suggestions=[];searchError=null;locationRef=null;selectedName=null;quote={};calculating=false;searching=value.trim().length>=3;});
    if(value.trim().length<3)return;
    searchDebounce=Timer(const Duration(milliseconds:400),()async{
      try{
        final query=Uri(queryParameters:{'q':value.trim()}).query;
        final result=await app.api.request('GET','/delivery/places?$query');
        if(!mounted||n!=searchGeneration)return;
        setState((){suggestions=List<dynamic>.from(result['results']??[]).map((r)=>Map<String,dynamic>.from(r as Map)).toList();searching=false;if(suggestions.isEmpty)searchError='Nenhum local encontrado. Tente o nome da rua, hotel ou estabelecimento por extenso.';});
      }catch(e){if(mounted&&n==searchGeneration)setState((){searching=false;searchError=PrimeMessages.friendly(e);});}
    });
  }
  void _selectPlace(Map<String,dynamic> place){
    searchDebounce?.cancel();searchGeneration++;postalGeneration++;
    final name=place['name'].toString(), street=(place['street']??'').toString();
    setState((){
      locationRef=place['id'].toString();selectedName=name;searchController.text=name;suggestions=[];searching=false;searchError=null;postalLoading=false;
      fields['street']!.text=street.isNotEmpty?street:name;
      fields['number']!.text=(place['number']??'').toString();
      fields['neighborhood']!.text=(place['neighborhood']??'').toString();
      fields['city']!.text='Porto Seguro';fields['state']!.text='BA';
      fields['postalCode']!.text=(place['postalCode']??'').toString().replaceAll(RegExp(r'\D'),'').length==8?place['postalCode'].toString():'45810000';
      if(place['kind']!='STREET'){fields['label']!.text=name;fields['complement']!.text=name;autofilledPlaceName=name;}else{if(autofilledPlaceName!=null){if(fields['label']!.text==autofilledPlaceName)fields['label']!.clear();if(fields['complement']!.text==autofilledPlaceName)fields['complement']!.clear();}autofilledPlaceName=null;}
      postalHint='Local selecionado. Confira o número, bairro e referência de entrega.';
    });
    _schedule();
  }
  Widget get placeSearch=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    TextField(controller:searchController,enabled:!saving,autocorrect:false,onChanged:_searchChanged,decoration:InputDecoration(labelText:'Buscar rua, hotel ou estabelecimento',hintText:'Ex.: Navegantes ou nome do hotel',prefixIcon:const Icon(AppIcons.search),suffixIcon:searching?const Padding(padding:EdgeInsets.all(16),child:SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))):searchController.text.isNotEmpty?IconButton(tooltip:'Limpar busca',onPressed:(){searchController.clear();_searchChanged('');},icon:const Icon(AppIcons.close)):null)),
    if(suggestions.isNotEmpty)Container(margin:const EdgeInsets.only(top:8,bottom:12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(AppRadius.md),border:Border.all(color:AppColors.stroke)),child:Column(children:suggestions.map((p)=>ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:6),leading:Icon(p['kind']=='STREET'?AppIcons.mapPin:AppIcons.home,color:AppColors.oceanDeep),title:Text(p['name'].toString(),style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${p['kind']=='HOTEL'?'Hotel':p['kind']=='STREET'?'Rua':'Estabelecimento'} · ${[p['street'],p['number'],p['neighborhood']].where((v)=>v!=null&&v.toString().isNotEmpty).join(' · ')}',maxLines:2,overflow:TextOverflow.ellipsis),trailing:const Icon(AppIcons.chevronRight),onTap:()=>_selectPlace(p))).toList())),
    if(searchError!=null)Padding(padding:const EdgeInsets.only(top:8,bottom:12),child:Text(searchError!,style:const TextStyle(color:AppColors.muted,fontSize:13))),
    if(locationRef!=null)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Row(children:[const Icon(AppIcons.checkCircle,color:AppColors.oceanDeep,size:20),const SizedBox(width:8),Expanded(child:Text('Local selecionado: $selectedName',style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.oceanDeep)))])),
    const Text('Selecione uma sugestão para usar o local encontrado. © OpenStreetMap contributors',style:TextStyle(fontSize:11,color:AppColors.muted)),const SizedBox(height:22),
  ]);
  void _schedule(){
    debounce?.cancel();generation++;
    if(mounted)setState((){quote={};error=null;calculating=complete;});
    if(complete)debounce=Timer(const Duration(milliseconds:650),_calculate);
  }
  Future<void> _postal() async {
    final n=++postalGeneration;
    final cep=fields['postalCode']!.text.replaceAll(RegExp(r'\D'),'');
    if(cep.length!=8){setState((){postalHint=null;postalLoading=false;});return;}
    final before={for(final k in ['street','neighborhood','city','state'])k:fields[k]!.text};
    setState((){postalLoading=true;postalHint=null;});
    try {
      final result=await app.lookupPostalCode(cep);
      if(!mounted||n!=postalGeneration)return;
      if(result['valid']==true){
        for(final k in before.keys){if(locationRef!=null)continue;final value=(result[k]??'').toString();if(value.isNotEmpty&&(fields[k]!.text.isEmpty||fields[k]!.text==before[k]))fields[k]!.text=value;}
        postalHint='Confira a rua e informe o número para calcular a entrega.';
      }else{postalHint=result['reason']=='OUTSIDE_SERVICE_AREA'?'Atendemos Porto Seguro/BA. Confira o CEP.':'Não encontramos este CEP. Preencha o endereço completo.';}
      _schedule();
    }catch(_){if(mounted&&n==postalGeneration)setState(()=>postalHint='Consulta de CEP indisponível. Você pode preencher o endereço.');}
    finally{if(mounted&&n==postalGeneration)setState(()=>postalLoading=false);}
  }
  Future<void> _calculate() async {
    if(!complete)return;
    final n=++generation;
    setState((){calculating=true;error=null;quote={};});
    try{final result=await app.api.request('POST','/delivery/preview',body:data);if(mounted&&n==generation)setState(()=>quote=Map<String,dynamic>.from(result));}
    catch(e){if(mounted&&n==generation)setState(()=>error=PrimeMessages.friendly(e));}
    finally{if(mounted&&n==generation)setState(()=>calculating=false);}
  }
  Widget field(String key,String label,{bool optional=false,bool numeric=false})=>Padding(padding:const EdgeInsets.only(bottom:14),child:TextFormField(controller:fields[key],enabled:!saving,keyboardType:numeric?TextInputType.number:TextInputType.streetAddress,textCapitalization:TextCapitalization.words,decoration:InputDecoration(labelText:label),validator:(v){if(!optional&&(v??'').trim().isEmpty)return 'Preencha este campo';if(key=='postalCode'&&(v??'').replaceAll(RegExp(r'\D'),'').length!=8)return 'Informe os 8 dígitos do CEP';if(key=='state'&&(v??'').trim().length!=2)return 'Use a sigla do estado';return null;},onChanged:(_){if(['street','city','state'].contains(key)){locationRef=null;selectedName=null;}if(!['label','complement'].contains(key))_schedule();if(key=='postalCode')_postal();}));
  Future<void> save()async {
    if(saving||!formKey.currentState!.validate())return;
    debounce?.cancel();
    // Aguarda a cotação vigente antes de salvar; o pedido recalcula no backend.
    setState(()=>saving=true);
    try {
      await _calculate();
      if(!mounted||quote.isEmpty)return;
      final result=await app.api.request(widget.address==null?'POST':'PATCH',widget.address==null?'/addresses':'/addresses/${widget.address!['id']}',body:data);
      await app.loadAddresses();
      if(mounted)Navigator.pop(context,result['id'].toString());
    }catch(e){if(mounted)setState(()=>error=PrimeMessages.friendly(e));}
    finally{if(mounted)setState(()=>saving=false);}
  }
  Widget get deliveryCard=>Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:AppColors.oceanDeep,borderRadius:BorderRadius.circular(AppRadius.lg)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('ENTREGA CALCULADA PARA VOCÊ',style:TextStyle(color:AppColors.mint,fontSize:11,fontWeight:FontWeight.w800,letterSpacing:1)),const SizedBox(height:14),
    if(calculating)const Row(children:[SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:AppColors.mint)),SizedBox(width:12),Expanded(child:Text('Calculando rota e valor…',style:TextStyle(color:Colors.white)))])
    else if(quote.isNotEmpty)...[
      Row(children:[const Expanded(child:Text('Taxa de entrega',style:TextStyle(color:Colors.white,fontSize:16))),Text(_money(quote['deliveryFee']),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:28))]),const SizedBox(height:10),
      Text('${quote['distanceKm']} km de rota · aproximadamente ${quote['durationMinutes']} min',style:const TextStyle(color:Color(0xFFD2E6E3))),
      if(quote['locationAccuracy']=='STREET_ESTIMATE')const Padding(padding:EdgeInsets.only(top:10),child:Text('Estimativa pelo trecho da rua; número ainda não mapeado.',style:TextStyle(color:Color(0xFFD2E6E3),fontSize:12))),
      if(app.cart.isNotEmpty)...[const Divider(color:Colors.white24,height:30),Row(children:[const Expanded(child:Text('Total com entrega',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w700))),Text(_money(app.cartSubtotal+(double.tryParse(quote['deliveryFee'].toString())??0)-app.selectedCustomerCredit(double.tryParse(quote['storeCreditBalance'].toString())??0,app.cartSubtotal+(double.tryParse(quote['deliveryFee'].toString())??0))),style:const TextStyle(color:AppColors.mint,fontSize:22,fontWeight:FontWeight.w800))])],
    ]else Text(error??'Preencha rua, número, bairro e CEP. O valor aparece automaticamente aqui.',style:const TextStyle(color:Colors.white,height:1.5)),
    if(error!=null)TextButton(onPressed:saving?null:_calculate,child:const Text('Calcular novamente',style:TextStyle(color:AppColors.mint))),
  ]));
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.address==null?'Novo endereço':'Editar endereço')),body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:680),child:Form(key:formKey,child:ListView(padding:const EdgeInsets.all(22),children:[
    const Text('Seu endereço. Nossa rota.',style:TextStyle(fontSize:26,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('Busque a rua, hotel ou estabelecimento e selecione uma opção. Calculamos sua entrega sem abrir mapas.',style:TextStyle(color:AppColors.muted,height:1.5)),const SizedBox(height:26),
    placeSearch,field('postalCode','CEP',numeric:true),
    if(postalLoading)const Padding(padding:EdgeInsets.only(bottom:14),child:Text('Buscando endereço do CEP…',style:TextStyle(color:AppColors.muted))),
    if(postalHint!=null)Padding(padding:const EdgeInsets.only(bottom:14),child:Text(postalHint!,style:const TextStyle(color:AppColors.muted,fontSize:12))),
    field('street','Rua / avenida'),Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:field('number','Número ou S/N')),const SizedBox(width:12),Expanded(flex:2,child:field('neighborhood','Bairro'))]),
    field('complement','Complemento / referência',optional:true),Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:3,child:field('city','Cidade')),const SizedBox(width:12),Expanded(child:field('state','UF'))]),
    deliveryCard,const SizedBox(height:22),field('label','Nome do local · Casa, trabalho…',optional:true),
    SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,title:const Text('Usar como endereço principal'),subtitle:const Text('Selecionado primeiro nas próximas entregas'),value:principal,onChanged:saving?null:(v)=>setState(()=>principal=v)),
    const SizedBox(height:18),SizedBox(height:56,child:FilledButton(onPressed:saving?null:save,child:saving?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('Salvar endereço'))),const SizedBox(height:30),
  ]))))));
}

