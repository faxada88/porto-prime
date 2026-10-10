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
  padding:const EdgeInsets.all(17),
  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFCFDFD8)),boxShadow:const [BoxShadow(color:Color(0x080F3B2E),blurRadius:16,offset:Offset(0,4))]),
  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(width:38,height:38,decoration:BoxDecoration(color:const Color(0xFFE9F4EE),borderRadius:BorderRadius.circular(12)),child:const Icon(AppIcons.energy,color:Color(0xFF226D51),size:20)),
    const SizedBox(width:11),
    const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text('Alta demanda',style:TextStyle(color:AppColors.midnight,fontSize:16,fontWeight:FontWeight.w800,letterSpacing:-.3)),
     SizedBox(height:3),
     Text('Adicional operacional ativo',style:TextStyle(color:Color(0xFF567166),fontSize:11,height:1.4)),
    ])),
    Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:const Color(0xFFE9F4EE),borderRadius:BorderRadius.circular(20)),child:const Text('ATIVA',style:TextStyle(color:Color(0xFF226D51),fontSize:9,fontWeight:FontWeight.w800,letterSpacing:.6))),
   ]),
   const SizedBox(height:13),
   Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:13,vertical:11),decoration:BoxDecoration(color:const Color(0xFFF5F8F6),borderRadius:BorderRadius.circular(12)),child:Wrap(spacing:12,runSpacing:5,crossAxisAlignment:WrapCrossAlignment.center,children:[
    Text('+R\$ ${bonusAmount.toStringAsFixed(2).replaceAll('.',',')}',style:const TextStyle(color:Color(0xFF1D6349),fontSize:23,fontWeight:FontWeight.w800,letterSpacing:-.5)),
    const Text('por entrega elegível · repasse integral',style:TextStyle(color:Color(0xFF456658),fontSize:11,fontWeight:FontWeight.w600)),
   ])),
   const SizedBox(height:10),
   Text(online?'Confira o adicional incluído em cada oferta. O valor do pedido fica garantido até a entrega.':'Fique online quando estiver disponível. Confira o adicional incluído em cada oferta.',style:const TextStyle(color:Color(0xFF5A7066),fontSize:11,height:1.5)),
  ]),
 ));
}
