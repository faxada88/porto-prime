import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Single brand artwork, fully visible at its original 2:3 aspect ratio.
class PrimeBrandBanner extends StatelessWidget {
 const PrimeBrandBanner({super.key,required this.onExplore});
 final VoidCallback onExplore;
 static const asset='assets/reference_home/porto-prime-gold.webp';
 @override
 Widget build(BuildContext context)=>Center(child:ConstrainedBox(
  constraints:const BoxConstraints(maxWidth:560),
  child:DecoratedBox(
   decoration:BoxDecoration(color:AppColors.ocean900,borderRadius:BorderRadius.circular(20),
    border:Border.all(color:AppColors.sun500.withValues(alpha:.6)),
    boxShadow:const [BoxShadow(color:Color(0x18000000),blurRadius:24,offset:Offset(0,8))]),
   child:ClipRRect(borderRadius:BorderRadius.circular(19),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    AspectRatio(aspectRatio:2/3,child:Image.asset(asset,fit:BoxFit.contain,
     semanticLabel:'Porto Prime Distribuidora. Gela no ponto, vibe no topo.',
     filterQuality:FilterQuality.high)),
    Material(color:AppColors.sun500,child:InkWell(onTap:onExplore,child:Padding(
     padding:const EdgeInsets.symmetric(horizontal:18,vertical:17),
     child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      const Icon(AppIcons.cart,color:AppColors.ocean900,size:20),
      const SizedBox(width:10),
      Flexible(child:Text('Explorar catálogo',textAlign:TextAlign.center,
       style:Theme.of(context).textTheme.labelLarge?.copyWith(color:AppColors.ocean900,fontWeight:FontWeight.w800))),
      const SizedBox(width:10),
      const Icon(AppIcons.arrowRight,color:AppColors.ocean900,size:18),
     ])))),
   ])),
  ),
 ));
}
