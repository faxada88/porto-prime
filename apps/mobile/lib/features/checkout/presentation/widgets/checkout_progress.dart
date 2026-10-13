import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

class CheckoutProgress extends StatelessWidget {
 const CheckoutProgress({super.key,required this.step});
 final int step;
 @override
 Widget build(BuildContext context)=>Row(children:List.generate(3,(index)=>Expanded(child:Padding(padding:EdgeInsets.only(right:index==2?0:8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(height:3,decoration:BoxDecoration(color:index<=step?AppColors.ocean600:AppColors.stroke,borderRadius:BorderRadius.circular(8))),const SizedBox(height:9),Row(children:[Icon(index<step?AppIcons.check:index==0?AppIcons.cart:index==1?AppIcons.mapPin:AppIcons.lock,size:14,color:index<=step?AppColors.ocean700:AppColors.muted),const SizedBox(width:5),Flexible(child:Text(['Carrinho','Entrega','Pagamento'][index],maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:11,fontWeight:index==step?FontWeight.w800:FontWeight.w500,color:index<=step?AppColors.ocean900:AppColors.muted)))]),])))));
}
class CheckoutPriceLine extends StatelessWidget {
 const CheckoutPriceLine({super.key,required this.label,required this.value,this.strong=false});
 final String label,value;final bool strong;
 @override
 Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:Text(label,style:TextStyle(color:strong?AppColors.ink:AppColors.muted,fontWeight:strong?FontWeight.w800:FontWeight.w500))),Text(value,style:TextStyle(fontSize:strong?23:14,fontWeight:FontWeight.w800,color:strong?AppColors.ocean900:AppColors.ink))]));
}
String checkoutMoney(dynamic value)=>'R\$ ${(double.tryParse(value.toString())??0).toStringAsFixed(2).replaceAll('.',',')}';
