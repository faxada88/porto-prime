import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

/// The server defines the bonus; the accepted offer retains its own snapshot.
class CourierDemandNotice extends StatelessWidget {
 const CourierDemandNotice({super.key,required this.online,required this.bonusAmount});
 final bool online;
 final double bonusAmount;
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
    const Text('Alta demanda ativa',style:TextStyle(color:AppColors.midnight,fontSize:20,fontWeight:FontWeight.w800,letterSpacing:-.4)),
    const SizedBox(height:8),
    Text('Ganhe +R\$ ${bonusAmount.toStringAsFixed(2).replaceAll(".",",")} por entrega enquanto durar a alta demanda.${online?"":" Fique online quando estiver disponível."}',style:const TextStyle(color:Color(0xFF725B2D),fontSize:13,height:1.5)),
   ])),
  ]),
 ));
}
