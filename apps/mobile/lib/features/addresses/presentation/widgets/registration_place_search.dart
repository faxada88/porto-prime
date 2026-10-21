import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
class RegistrationPlaceSearch extends StatefulWidget{
 const RegistrationPlaceSearch({super.key,required this.onSelected});
 final ValueChanged<Map<String,dynamic>> onSelected;
 @override State<RegistrationPlaceSearch> createState()=>_RegistrationPlaceSearchState();
}
class _RegistrationPlaceSearchState extends State<RegistrationPlaceSearch>{
 final controller=TextEditingController();Timer? timer;int generation=0;bool loading=false;
 List<Map<String,dynamic>> results=[];String? error;
 @override void dispose(){timer?.cancel();generation++;controller.dispose();super.dispose();}
 void search(String value){
  timer?.cancel();final ticket=++generation;
  setState((){results=[];error=null;loading=value.trim().length>=3;});
  if(value.trim().length<3)return;
  timer=Timer(const Duration(milliseconds:400),()async{
   try{
    final query=Uri(queryParameters:{'q':value.trim()}).query;
    final response=await AppState.instance.api.request('GET','/delivery/address-suggestions?$query');
    if(!mounted||ticket!=generation)return;
    setState((){results=(response['results'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();loading=false;if(results.isEmpty)error='Tente o nome completo do local ou preencha o endereço abaixo.';});
   }catch(_){if(mounted&&ticket==generation)setState((){loading=false;error='Busca indisponível agora. Você pode preencher o endereço abaixo.';});}
  });
 }
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:20),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  TextField(controller:controller,onChanged:search,decoration:InputDecoration(
   labelText:'Onde vamos entregar?',hintText:'Hotel, pousada, rua ou estabelecimento',prefixIcon:const Icon(Icons.search_rounded),
   suffixIcon:loading?const Padding(padding:EdgeInsets.all(16),child:SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))):null)),
  const SizedBox(height:8),const Text('Digite a rua, hotel ou estabelecimento e escolha seu endereço nas sugestões.',style:TextStyle(fontSize:12,height:1.5,color:AppColors.inkSoft)),
  if(error!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text(error!,style:const TextStyle(fontSize:12,color:AppColors.muted))),
  for(final place in results)ListTile(contentPadding:EdgeInsets.zero,
   leading:Icon(place['kind']=='HOTEL'?Icons.hotel_outlined:place['kind']=='STREET'?Icons.place_outlined:Icons.storefront_outlined,color:AppColors.ocean700),
   title:Text('${place['name']}',style:const TextStyle(fontWeight:FontWeight.w700)),
   subtitle:Text([place['street'],place['number'],place['neighborhood']].where((v)=>v!=null&&'$v'.isNotEmpty).join(' · ')),
   onTap:(){timer?.cancel();generation++;setState((){controller.text='${place['name']}';results=[];loading=false;error=null;});widget.onSelected(place);}),
  const SizedBox(height:6),const Text('© OpenStreetMap contributors',style:TextStyle(fontSize:10,color:AppColors.muted)),
 ]));
}
