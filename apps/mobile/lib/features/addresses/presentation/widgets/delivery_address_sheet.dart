import '../../../../core/localization/prime_localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';
import '../pages/address_book_page.dart';

bool _showingAddresses=false;
Future<void> showDeliveryAddressSheet(BuildContext context) async {
 if(_showingAddresses||!AppState.instance.isCustomer)return;
 _showingAddresses=true;
 try{await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,backgroundColor:Colors.transparent,builder:(_)=>const DeliveryAddressSheet());}
 finally{_showingAddresses=false;}
}
class DeliveryAddressSheet extends StatefulWidget {
 const DeliveryAddressSheet({super.key});
 @override State<DeliveryAddressSheet> createState()=>_DeliveryAddressSheetState();
}
class _DeliveryAddressSheetState extends State<DeliveryAddressSheet> {
 final _app=AppState.instance;
 final _query=TextEditingController();
 Timer? _debounce;
 final List<Map<String,dynamic>> _places=[];
 Object? _owner;
 int _generation=0;
 bool _loading=false,_searching=false,_busy=false,_editing=false;
 String? _error;
 bool get _authorized=>_app.isCustomer&&_app.user?['id']==_owner;
 @override void initState(){super.initState();_owner=_app.user?['id'];unawaited(_refresh());}
 @override void dispose(){_debounce?.cancel();_generation++;_query.dispose();super.dispose();}
 Future<void> _refresh() async {
  setState(()=>_loading=true);
  try{await _app.loadAddresses();}catch(error){if(mounted&&_authorized)setState(()=>_error=PrimeMessages.friendly(error));}
  finally{if(mounted)setState(()=>_loading=false);}
 }
 void _search(String value){
  _debounce?.cancel();final generation=++_generation;
  setState((){_places.clear();_error=null;_searching=value.trim().length>=3;});
  if(value.trim().length<3)return;
  _debounce=Timer(const Duration(milliseconds:400),()async{
   try{
    final query=Uri(queryParameters:{'q':value.trim()}).query;
    final result=await _app.api.request('GET','/delivery/places?$query');
    if(!mounted||!_authorized||generation!=_generation)return;
    setState(()=>_places.addAll(List<dynamic>.from(result['results']??[]).take(6).map((item)=>Map<String,dynamic>.from(item as Map))));
   }catch(error){if(mounted&&generation==_generation)setState(()=>_error=PrimeMessages.friendly(error));}
   finally{if(mounted&&generation==_generation)setState(()=>_searching=false);}
  });
 }
 Future<void> _edit({Map<String,dynamic>? address,Map<String,dynamic>? place}) async {
  if(_busy||_editing||!_authorized)return;
  FocusManager.instance.primaryFocus?.unfocus();
  setState(()=>_editing=true);
  try{
   final saved=await Navigator.of(context).push<String>(MaterialPageRoute(builder:(_)=>AddressEditorPage(address:address,initialPlace:place)));
   if(!mounted||!_authorized||saved==null)return;
   if(address==null){
    final matches=_app.addresses.where((item)=>item['id'].toString()==saved);
    if(matches.isNotEmpty)await _select(Map<String,dynamic>.from(matches.first as Map));
   }
  }finally{if(mounted)setState(()=>_editing=false);}
 }
 Future<void> _select(Map<String,dynamic> address) async {
  if(_busy||!_authorized)return;
  FocusManager.instance.primaryFocus?.unfocus();
  if(address['isDefault']==true){Navigator.pop(context);return;}
  setState((){_busy=true;_error=null;});
  try{
   await _app.updateAddress(address['id'].toString(),{
    for(final key in ['label','street','number','complement','neighborhood','city','state','postalCode','locationRef'])if(address[key]!=null)key:address[key],
    'isDefault':true,
   });
   if(mounted&&_authorized)Navigator.pop(context);
  }catch(error){if(mounted)setState(()=>_error=PrimeMessages.friendly(error));}
  finally{if(mounted)setState(()=>_busy=false);}
 }
 Future<void> _manage(Map<String,dynamic> address,String action) async {
  if(_busy||_editing||!_authorized)return;
  if(action=='edit'){await _edit(address:address);return;}
  if(action=='select'){await _select(address);return;}
  final confirmed=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
   shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22)),
   icon:const Icon(AppIcons.trash,color:AppColors.coral600),title:const PrimeText('Remover endereço?'),
   content:PrimeText('O endereço ${address['label']??address['street']??''} será removido da sua lista.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const PrimeText('Manter endereço')),FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:const PrimeText('Remover'))],
  ));
  if(confirmed!=true||!mounted||!_authorized)return;
  setState((){_busy=true;_error=null;});
  try{await _app.removeAddress(address['id'].toString());}
  catch(error){if(mounted)setState(()=>_error=PrimeMessages.friendly(error));}
  finally{if(mounted)setState(()=>_busy=false);}
 }
 @override Widget build(BuildContext context)=>AnimatedBuilder(animation:_app,builder:(context,_){
  final query=_query.text.trim().toLowerCase();
  final current=_authorized&&_app.addresses.isNotEmpty?_app.addresses.firstWhere((item)=>item['isDefault']==true,orElse:()=>_app.addresses.first)['id']:null;
  final addresses=_authorized?_app.addresses.where((item)=>query.isEmpty||['label','street','number','neighborhood','city','complement'].map((key)=>item[key]??'').join(' ').toLowerCase().contains(query)).map((item)=>Map<String,dynamic>.from(item as Map)).toList():<Map<String,dynamic>>[];
  return Padding(padding:EdgeInsets.only(bottom:MediaQuery.viewInsetsOf(context).bottom),child:PopScope(canPop:!_busy,child:Container(
   height:(MediaQuery.sizeOf(context).height-MediaQuery.viewInsetsOf(context).bottom)*.90,
   decoration:const BoxDecoration(color:Color(0xFFF6F7F8),borderRadius:BorderRadius.vertical(top:Radius.circular(26))),
   child:SafeArea(top:false,child:Column(children:[
    Container(padding:const EdgeInsets.fromLTRB(14,10,14,16),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(26))),child:Column(children:[
     Container(width:36,height:4,decoration:BoxDecoration(color:AppColors.stroke,borderRadius:BorderRadius.circular(4))),const SizedBox(height:10),
     Row(children:[IconButton(tooltip: translateLabel('Fechar endereços'),onPressed:_busy?null:()=>Navigator.pop(context),icon:const Icon(AppIcons.chevronDown)),const Expanded(child:PrimeText('Endereço de entrega',textAlign:TextAlign.center,style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:AppColors.ink))),const SizedBox(width:48)]),
     const SizedBox(height:8),
     TextField(scrollPadding: const EdgeInsets.all(80), controller:_query,enabled:!_busy&&_authorized,onChanged:_search,textInputAction:TextInputAction.search,onSubmitted:(_)=>_edit(),decoration:PrimeInputDecoration(hintText:'Buscar rua, hotel ou endereço',hintStyle:const TextStyle(fontSize:13),filled:true,fillColor:const Color(0xFFF3F4F5),prefixIcon:const Icon(AppIcons.search,size:21),suffixIcon:query.isEmpty?null:IconButton(tooltip: translateLabel('Limpar busca'),onPressed:(){_query.clear();_search('');},icon:const Icon(AppIcons.close,size:18)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none))),
    ])),
    if(_busy||_loading||_searching)const LinearProgressIndicator(minHeight:2),
    Expanded(child:ListView(keyboardDismissBehavior:ScrollViewKeyboardDismissBehavior.onDrag,padding:const EdgeInsets.fromLTRB(18,18,18,10),children:[
     if(!_authorized)const PrimeText('Entre na sua conta para gerenciar seus endereços.'),
     if(_error!=null)Padding(padding:const EdgeInsets.only(bottom:14),child:PrimeText(_error!,style:const TextStyle(color:AppColors.coral600,fontSize:12,height:1.4))),
     if(_authorized)...[
      const PrimeText('Seus endereços',style:TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:AppColors.muted)),const SizedBox(height:12),
      if(addresses.isEmpty&&!_loading)Padding(padding:const EdgeInsets.symmetric(vertical:20),child:PrimeText(query.isEmpty?'Adicione seu primeiro endereço de entrega.':'Nenhum endereço salvo corresponde à busca.',style:const TextStyle(fontSize:14,color:AppColors.muted,height:1.5))),
      for(final address in addresses)DeliveryAddressCard(address:address,selected:address['id']==current,busy:_busy||_editing,onSelect:()=>_select(address),onAction:(action)=>_manage(address,action)),
      if(_places.isNotEmpty)...[
       const Padding(padding:EdgeInsets.symmetric(vertical:12),child:PrimeText('Locais encontrados',style:TextStyle(fontWeight:FontWeight.w700,color:AppColors.muted,fontSize:12))),
       for(final place in _places)Card(elevation:0,color:Colors.white,child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:8),leading:const Icon(AppIcons.mapPin,color:AppColors.ocean700),title:PrimeText((place['name']??'Local encontrado').toString(),style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700)),subtitle:PrimeText([place['street'],place['number'],place['neighborhood']].where((part)=>part!=null&&part.toString().isNotEmpty).join(' · '),style:const TextStyle(fontSize:12)),trailing:const Icon(AppIcons.chevronRight,size:18),onTap:_busy||_editing?null:()=>_edit(place:place))),
      ],
     ],
    ])),
    if(MediaQuery.viewInsetsOf(context).bottom==0)Container(padding:const EdgeInsets.fromLTRB(18,12,18,14),color:Colors.white,child:SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_busy||_editing||!_authorized?null:()=>_edit(),style:FilledButton.styleFrom(backgroundColor:AppColors.ocean900,padding:const EdgeInsets.symmetric(vertical:16),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),icon:const Icon(AppIcons.plus,size:19),label:const PrimeText('Adicionar novo endereço',style:TextStyle(fontWeight:FontWeight.w700))))),
   ])),
  )));
 });
}

class DeliveryAddressCard extends StatelessWidget {
 const DeliveryAddressCard({super.key,required this.address,required this.onSelect,required this.onAction,this.busy=false,this.selected});
 final Map<String,dynamic> address;final VoidCallback onSelect;final ValueChanged<String> onAction;final bool busy;final bool? selected;
 @override Widget build(BuildContext context){
  final selected=this.selected??(address['isDefault']==true);
  final label=(address['label']??'').toString().trim();
  final street=[address['street'],address['number']].where((part)=>part!=null&&part.toString().isNotEmpty).join(', ');
  return Padding(padding:const EdgeInsets.only(bottom:12),child:Material(color:Colors.white,borderRadius:BorderRadius.circular(18),child:InkWell(onTap:busy?null:onSelect,borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.fromLTRB(14,16,8,16),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),border:Border.all(color:selected?AppColors.ocean700:const Color(0xFFE8ECEA),width:selected?1.5:1)),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Padding(padding:const EdgeInsets.only(top:5),child:Icon(label.toLowerCase()=='casa'?AppIcons.home:AppIcons.mapPin,size:24,color:selected?AppColors.ocean700:AppColors.muted)),const SizedBox(width:12),
   Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    PrimeText(label.isEmpty?(street.isEmpty?'Endereço de entrega':street):label,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w800,color:AppColors.ink)),const SizedBox(height:5),
    if(label.isNotEmpty)PrimeText(street,style:const TextStyle(fontSize:13,height:1.45,color:AppColors.muted)),
    PrimeText([address['neighborhood'],[address['city'],address['state']].where((part)=>part!=null&&part.toString().isNotEmpty).join('/')].where((part)=>part!=null&&part.toString().isNotEmpty).join(' · '),style:const TextStyle(fontSize:12,height:1.45,color:AppColors.muted)),
    if((address['complement']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:6),child:PrimeText(address['complement'].toString(),style:const TextStyle(fontSize:11,height:1.4,color:AppColors.muted))),
    if(selected)const Padding(padding:EdgeInsets.only(top:9),child:PrimeText('EM USO',style:TextStyle(fontSize:9,fontWeight:FontWeight.w800,letterSpacing:1,color:AppColors.ocean700))),
   ])),
   Column(children:[if(selected)const Padding(padding:EdgeInsets.only(bottom:3),child:Icon(AppIcons.checkCircle,size:18,color:AppColors.ocean700)),PopupMenuButton<String>(tooltip: translateLabel('Opções do endereço'),enabled:!busy,onSelected:onAction,itemBuilder:(_)=>[const PopupMenuItem(value:'edit',child:PrimeText('Editar endereço')),if(!selected)const PopupMenuItem(value:'select',child:PrimeText('Usar para entrega')),const PopupMenuItem(value:'remove',child:PrimeText('Remover endereço'))])]),
  ])))));
 }
}
