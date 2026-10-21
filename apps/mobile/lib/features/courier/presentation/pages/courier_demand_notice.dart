import '../../../../core/localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

/// Operational status only. Values remain controlled by the backend.
class CourierDemandNotice extends StatelessWidget {
 const CourierDemandNotice({super.key,required this.online,required this.bonusAmount});
 final bool online;
 final double bonusAmount;
 @override
 Widget build(BuildContext context) => Semantics(liveRegion:true,container:true,child:Container(
  padding:const EdgeInsets.all(20),
  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:AppColors.stroke),boxShadow:const [BoxShadow(color:Color(0x080F3B2E),blurRadius:16,offset:Offset(0,4))]),
  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(width:38,height:38,decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(12)),child:const Icon(AppIcons.energy,color:AppColors.ocean700,size:20)),
    const SizedBox(width:11),
    const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     PrimeText('Alta demanda',style:TextStyle(color:AppColors.midnight,fontSize:16,fontWeight:FontWeight.w800,letterSpacing:-.3)),
     SizedBox(height:3),
     PrimeText('Adicional operacional ativo',style:TextStyle(color:AppColors.muted,fontSize:11,height:1.4)),
    ])),
    Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(20)),child:const PrimeText('ATIVA',style:TextStyle(color:AppColors.ocean700,fontSize:9,fontWeight:FontWeight.w800,letterSpacing:.6))),
   ]),
   const SizedBox(height:13),
   Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:13,vertical:11),decoration:BoxDecoration(color:AppColors.surfaceMuted,borderRadius:BorderRadius.circular(12)),child:Wrap(spacing:12,runSpacing:5,crossAxisAlignment:WrapCrossAlignment.center,children:[
    PrimeText('+R\$ ${bonusAmount.toStringAsFixed(2).replaceAll('.',',')}',style:const TextStyle(color:AppColors.ocean700,fontSize:26,fontWeight:FontWeight.w800,letterSpacing:-.5)),
    const PrimeText('por entrega elegível · repasse integral',style:TextStyle(color:AppColors.inkSoft,fontSize:11,fontWeight:FontWeight.w600)),
   ])),
   const SizedBox(height:10),
   PrimeText(online?'Confira o adicional incluído em cada oferta. O valor do pedido fica garantido até a entrega.':'Fique online quando estiver disponível. Confira o adicional incluído em cada oferta.',style:const TextStyle(color:AppColors.muted,fontSize:11,height:1.5)),
  ]),
 ));
}

