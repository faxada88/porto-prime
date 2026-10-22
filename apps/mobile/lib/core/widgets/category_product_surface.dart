import '../state/app_state.dart';
import 'package:flutter/material.dart';
import '../localization/prime_localization.dart';
import '../theme/app_theme.dart';
import 'product_showcase.dart';

/// Category presentation only; cart callbacks and prices come from PrimeProductCard.
class CategoryProductSurface extends StatelessWidget {
 const CategoryProductSurface({super.key,required this.product,required this.name,
  required this.description,required this.price,required this.image,required this.control,
  required this.available,required this.fullWidthControl,this.oldPrice,this.discount,this.onOpen});
 final dynamic product;
 final String name,description,price;
 final String? oldPrice;
 final int? discount;
 final Widget image,control;
 final bool available,fullWidthControl;
 final VoidCallback? onOpen;
 @override Widget build(BuildContext context){
  final brand=(product['brand']??'').toString().trim();
  final rating=double.tryParse('${product['rating']}');
  final reviews=int.tryParse('${product['reviewCount']}')??0;
  return Material(color:const Color(0xFFF8FCFC),borderRadius:BorderRadius.circular(16),
   clipBehavior:Clip.antiAlias,child:InkWell(onTap:onOpen,child:Container(
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFDCE8EA))),
    child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     AspectRatio(aspectRatio:1.35,child:Stack(fit:StackFit.expand,children:[
      ColoredBox(color:AppColors.ocean50,child:image),
      Positioned(top:7,right:7,child:ProductFavoriteButton(productId:product['id'].toString(),owner:'${AppState.instance.user?['id']??'guest'}')),
      if(discount!=null)Positioned(top:8,left:8,child:Container(
       padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),
       decoration:BoxDecoration(color:const Color(0xFFFC4C60),borderRadius:BorderRadius.circular(18)),
       child:PrimeText('${AppLanguage.instance.translate('Oferta')} −$discount%',
        textScaler:TextScaler.noScaling,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:Colors.white)))),
      if(!available)const Center(child:Chip(label:PrimeText('Indisponível'))),
     ])),
     Expanded(child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(brand.isNotEmpty)...[PrimeText(brand,maxLines:1,overflow:TextOverflow.ellipsis,
       style:const TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:Color(0xFF153E46))),const SizedBox(height:4)],
      PrimeText(name,maxLines:2,overflow:TextOverflow.ellipsis,
       style:const TextStyle(fontSize:13,height:1.22,fontWeight:FontWeight.w700,color:Color(0xFF123540))),
      if(description.isNotEmpty)...[const SizedBox(height:5),PrimeText(description,maxLines:2,
       overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10.5,height:1.3,color:Color(0xFF7C929D)))],
      if(rating!=null&&rating>=0&&rating<=5&&reviews>0)...[
       const SizedBox(height:6),Row(children:[
        const Icon(Icons.star_rounded,color:Color(0xFFFFC957),size:16),const SizedBox(width:4),
        Expanded(child:PrimeText('${rating.toStringAsFixed(1)} ($reviews ${AppLanguage.instance.translate('avaliações')})',
         maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:Color(0xFF718A96)))),
       ]),
      ],
      const Spacer(),
      if(oldPrice!=null)PrimeText(oldPrice!,style:const TextStyle(fontSize:10,color:AppColors.muted,decoration:TextDecoration.lineThrough)),
      if(fullWidthControl)...[
       PrimeText(price,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(
        fontSize:18,fontWeight:FontWeight.w800,color:Color(0xFF003D47))),
       const SizedBox(height:5),SizedBox(width:double.infinity,child:control),
      ]else Row(children:[
       Expanded(child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,
        child:PrimeText(price,maxLines:1,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:Color(0xFF003D47))))),
       const SizedBox(width:5),SizedBox(width:44,height:44,child:control),
      ]),
     ]))),
    ]))));
 }
}
