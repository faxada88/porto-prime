import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

/// A manual notice from the distributor, never a price or assignment instruction.
class CourierDemandNotice extends StatelessWidget {
 const CourierDemandNotice({super.key,required this.online});
 final bool online;
 @override
 Widget build(BuildContext context)=>Semantics(liveRegion:true,child:Container(
  padding:const EdgeInsets.all(20),
  decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFFFF6DF),Color(0xFFFFFCF5)]),borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFECD49C)),boxShadow:AppShadows.soft),
  child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Container(width:42,height:42,decoration:BoxDecoration(color:AppColors.sun500,borderRadius:BorderRadius.circular(14)),child:const Icon(AppIcons.energy,color:AppColors.midnight,size:23)),
   const SizedBox(width:13),
   Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('AVISO DA OPERAÇÃO',style:TextStyle(color:Color(0xFF79540E),fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1)),
    const SizedBox(height:6),
    const Text('Alta demanda',style:TextStyle(color:AppColors.midnight,fontSize:20,fontWeight:FontWeight.w800,letterSpacing:-.4)),
    const SizedBox(height:8),
    Text(online?'A distribuidora está chamando a equipe. Confira suas ofertas de entrega.':'A distribuidora está chamando a equipe. Fique online quando estiver disponível para receber entregas.',style:const TextStyle(color:Color(0xFF725B2D),fontSize:13,height:1.5)),
   ])),
  ]),
 ));
}
