import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
class CustomerDemandNotice extends StatelessWidget {
 const CustomerDemandNotice({super.key});
 @override
 Widget build(BuildContext context)=>Semantics(liveRegion:true,child:Container(
  color:AppColors.sand100,
  child:SafeArea(bottom:false,child:Padding(padding:const EdgeInsets.symmetric(horizontal:18,vertical:12),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Icon(AppIcons.energy,size:20,color:AppColors.warning),
   const SizedBox(width:10),
   Expanded(child:PrimeText('Estamos com alta demanda no momento. Nossa equipe está trabalhando para atender todos os pedidos o mais rápido possível.',style:const TextStyle(color:AppColors.midnight,fontSize:12,fontWeight:FontWeight.w600,height:1.5))),
  ]))),
 ));
}

