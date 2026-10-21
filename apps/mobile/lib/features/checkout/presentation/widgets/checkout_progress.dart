import '../../../../core/localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

class CheckoutProgress extends StatelessWidget {
 const CheckoutProgress({super.key,required this.step});
 final int step;
 @override
 Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(AppRadius.md),border:Border.all(color:AppColors.stroke)),child:Row(children:List.generate(3,(index)=>Expanded(child:Row(children:[Container(width:24,height:24,decoration:BoxDecoration(color:index<=step?AppColors.ocean700:AppColors.surfaceMuted,shape:BoxShape.circle),child:Icon(index<step?AppIcons.check:index==0?AppIcons.cart:index==1?AppIcons.mapPin:AppIcons.lock,size:12,color:index<=step?Colors.white:AppColors.muted)),const SizedBox(width:6),Flexible(child:PrimeText(['Carrinho','Entrega','Pagamento'][index],maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:10,fontWeight:index==step?FontWeight.w800:FontWeight.w500,color:index<=step?AppColors.ocean900:AppColors.muted)))])))));

}
class CheckoutPriceLine extends StatelessWidget {
 const CheckoutPriceLine({super.key,required this.label,required this.value,this.strong=false});
 final String label,value;final bool strong;
 @override
 Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:PrimeText(label,style:TextStyle(color:strong?AppColors.ink:AppColors.muted,fontWeight:strong?FontWeight.w800:FontWeight.w500))),PrimeText(value,style:TextStyle(fontSize:strong?23:14,fontWeight:FontWeight.w800,color:strong?AppColors.ocean900:AppColors.ink))]));
}
String checkoutMoney(dynamic value)=>'R\$ ${(double.tryParse(value.toString())??0).toStringAsFixed(2).replaceAll('.',',')}';

