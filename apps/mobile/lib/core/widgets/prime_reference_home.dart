import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'prime_brand.dart';

abstract final class ReferenceHomeTokens {
 static const green=Color(0xFF003B3E);
 static const gold=Color(0xFFF5C866);
 static const canvas=Color(0xFFF5F8F6);
 static const shadow=[BoxShadow(color:Color(0x0E003B3E),blurRadius:22,offset:Offset(0,7))];
 static const heroAsset='assets/reference_home/coast-banner.webp';
 static const categoryAsset='assets/reference_home/category-atlas.webp';
}
class ReferenceHomeHeader extends StatelessWidget {
 const ReferenceHomeHeader({super.key,required this.address,required this.region,required this.cartCount,required this.onAddress,required this.onCart,required this.onProfile});
 final String address,region;final int cartCount;final VoidCallback onAddress,onCart,onProfile;
 @override Widget build(BuildContext context)=>Row(children:[
  Expanded(child:InkWell(onTap:onAddress,borderRadius:BorderRadius.circular(16),child:Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(children:[const PrimeBrandMark(size:43),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('ENTREGAR EM',style:TextStyle(color:AppColors.ocean700,fontSize:10,letterSpacing:.8,fontWeight:FontWeight.w800)),const SizedBox(height:4),Row(children:[const Icon(AppIcons.mapPin,size:15,color:AppColors.ink),const SizedBox(width:4),Expanded(child:Text(address,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))),const Icon(AppIcons.chevronDown,size:14)]),if(region.isNotEmpty)Padding(padding:const EdgeInsets.only(left:19,top:3),child:Text(region,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:AppColors.muted)))]))])))),
  const SizedBox(width:8),_HeaderAction(icon:AppIcons.cart,label:'Abrir carrinho',count:cartCount,onTap:onCart),const SizedBox(width:7),_HeaderAction(icon:AppIcons.user,label:'Abrir perfil',dark:true,onTap:onProfile),
 ]);
}
class _HeaderAction extends StatelessWidget {
 const _HeaderAction({required this.icon,required this.label,required this.onTap,this.count=0,this.dark=false});
 final IconData icon;final String label;final VoidCallback onTap;final int count;final bool dark;
 @override Widget build(BuildContext context)=>Semantics(button:true,label:count>0?'$label, $count itens':label,child:Stack(clipBehavior:Clip.none,children:[
  Material(color:dark?ReferenceHomeTokens.green:Colors.white,borderRadius:BorderRadius.circular(17),elevation:dark?0:1,shadowColor:const Color(0x18003B3E),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(17),child:SizedBox(width:44,height:46,child:Icon(icon,color:dark?Colors.white:AppColors.ink,size:24)))),
  if(count>0)Positioned(top:-4,right:-3,child:Container(constraints:const BoxConstraints(minWidth:18,minHeight:18),padding:const EdgeInsets.symmetric(horizontal:4),alignment:Alignment.center,decoration:BoxDecoration(color:AppColors.coral600,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:1.4)),child:Text(count>99?'99+':'$count',textScaler:TextScaler.noScaling,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:Colors.white)))),
 ]));
}
class ReferenceHomeSearch extends StatelessWidget {
 const ReferenceHomeSearch({super.key,required this.onTap});final VoidCallback onTap;
 @override Widget build(BuildContext context)=>Material(color:Colors.white,borderRadius:BorderRadius.circular(20),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(20),child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:16),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFF0F3F1)),boxShadow:ReferenceHomeTokens.shadow),child:Row(children:[const Icon(AppIcons.search,size:24,color:AppColors.ink),const SizedBox(width:12),const Expanded(child:Text('O que você quer pedir hoje?',style:TextStyle(fontSize:13,color:AppColors.muted))),const SizedBox(width:8),const Icon(AppIcons.filter,size:20,color:AppColors.ink)]))));
}
class ReferenceCoastHero extends StatelessWidget {
 const ReferenceCoastHero({super.key,required this.onTap});final VoidCallback onTap;
 @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,box){
  final wide=box.maxWidth>=600;
  final large=MediaQuery.textScalerOf(context).scale(14)>20;
  final textWidth=large?box.maxWidth-40:box.maxWidth*(wide ? 0.60 : 0.69);
  return Semantics(container:true,child:ClipRRect(borderRadius:BorderRadius.circular(24),child:Stack(children:[
   Positioned.fill(child:Image.asset(ReferenceHomeTokens.heroAsset,fit:BoxFit.cover,alignment:Alignment.centerRight,excludeFromSemantics:true,cacheWidth:1400)),
   const Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[Color(0xF000292D),Color(0xC400292D),Color(0x0500292D)],stops:[0,.54,1])))),
   Padding(padding:EdgeInsets.fromLTRB(20,wide?32:22,20,24),child:SizedBox(width:textWidth,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('BEBIDAS • SNACKS • GELO • E MUITO MAIS',style:TextStyle(fontSize:8,fontWeight:FontWeight.w700,color:ReferenceHomeTokens.gold,letterSpacing:1.5,height:1.6)),const SizedBox(height:12),
    Text.rich(const TextSpan(children:[TextSpan(text:'O melhor de Porto.\n',style:TextStyle(color:Colors.white)),TextSpan(text:'Na sua porta.',style:TextStyle(color:ReferenceHomeTokens.gold))]),style:TextStyle(fontFamily:'DMSerifDisplay',fontSize:wide?43:28,height:1.05,letterSpacing:-.5)),
    const SizedBox(height:12),const Text('Mais variedade, mais qualidade\ne conveniência em Porto Seguro.',style:TextStyle(color:Colors.white,fontSize:11,height:1.5)),const SizedBox(height:18),
    FilledButton(onPressed:onTap,style:FilledButton.styleFrom(backgroundColor:ReferenceHomeTokens.gold,foregroundColor:AppColors.ocean900,padding:const EdgeInsets.symmetric(horizontal:16,vertical:13),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(28))),child:const Row(mainAxisSize:MainAxisSize.min,children:[Flexible(child:Text('Explorar catálogo',style:TextStyle(fontSize:12,fontWeight:FontWeight.w800))),SizedBox(width:8),Icon(AppIcons.arrowRight,size:18)])),
   ]))),
  ])));
 });
}

/// Curated source rectangles preserve the alpha of one optimized photographic
/// atlas. Unknown or explicitly different keys keep the existing vector icon.
class ReferenceCategoryPicture extends StatefulWidget {
 const ReferenceCategoryPicture({super.key,required this.iconKey,required this.fallback});
 final String? iconKey;final Widget fallback;
 static const rects=<String,Rect>{
  'beer':Rect.fromLTRB(.002,.12,.192,.90),'softDrink':Rect.fromLTRB(.192,.15,.331,.89),
  'ice':Rect.fromLTRB(.331,.35,.502,.90),'convenience':Rect.fromLTRB(.502,.28,.706,.90),
  'spirits':Rect.fromLTRB(.714,.04,.862,.90),'wine':Rect.fromLTRB(.874,.01,1,.90),
 };
 @override State<ReferenceCategoryPicture> createState()=>_ReferenceCategoryPictureState();
}
class _ReferenceCategoryPictureState extends State<ReferenceCategoryPicture> {
 ImageStream? _stream;ImageInfo? _info;ImageStreamListener? _listener;
 @override void didChangeDependencies(){super.didChangeDependencies();if(_stream!=null)return;_stream=const AssetImage(ReferenceHomeTokens.categoryAsset).resolve(createLocalImageConfiguration(context));_listener=ImageStreamListener((image,synchronous){if(mounted)setState((){_info?.dispose();_info=image;});},onError:(Object error,StackTrace? stack){});_stream!.addListener(_listener!);}
 @override void dispose(){if(_listener!=null)_stream?.removeListener(_listener!);_info?.dispose();super.dispose();}
 @override Widget build(BuildContext context){final rect=ReferenceCategoryPicture.rects[widget.iconKey];return _info==null||rect==null?widget.fallback:ExcludeSemantics(child:CustomPaint(painter:_CategoryPhotoPainter(_info!.image,rect),size:const Size(72,72)));}
}
class _CategoryPhotoPainter extends CustomPainter {
 const _CategoryPhotoPainter(this.image,this.region);final ui.Image image;final Rect region;
 @override void paint(Canvas canvas,Size size){final src=Rect.fromLTRB(region.left*image.width,region.top*image.height,region.right*image.width,region.bottom*image.height);final fit=applyBoxFit(BoxFit.contain,src.size,size);final dst=Alignment.center.inscribe(fit.destination,Offset.zero&size);canvas.drawImageRect(image,src,dst,Paint()..filterQuality=FilterQuality.medium);}
 @override bool shouldRepaint(covariant _CategoryPhotoPainter old)=>old.image!=image||old.region!=region;
}
class ReferenceCategoryTile extends StatelessWidget {
 const ReferenceCategoryTile({super.key,required this.name,required this.onTap,this.iconKey,this.selected=false});
 final String name;final String? iconKey;final bool selected;final VoidCallback onTap;
 @override Widget build(BuildContext context){final visual=AppIcons.categoryVisual(name,iconKey:iconKey);return Semantics(button:true,selected:selected,label:'Categoria $name',child:Material(color:selected?const Color(0xFFFFF3D7):Colors.white,borderRadius:BorderRadius.circular(20),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(20),child:AnimatedContainer(duration:AppMotion.resolve(context,AppMotion.fast),padding:const EdgeInsets.fromLTRB(6,8,6,8),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),border:Border.all(color:selected?ReferenceHomeTokens.gold:const Color(0xFFE9EFEC),width:selected?1.5:1),boxShadow:selected?const [BoxShadow(color:Color(0x22F5C866),blurRadius:12,offset:Offset(0,4))]:null),child:Column(children:[Expanded(child:ReferenceCategoryPicture(iconKey:visual.key,fallback:Icon(visual.icon,size:34,color:visual.foreground))),const SizedBox(height:5),Text(name,maxLines:2,overflow:TextOverflow.ellipsis,textAlign:TextAlign.center,style:TextStyle(fontSize:10.5,height:1.15,fontWeight:selected?FontWeight.w800:FontWeight.w600,color:AppColors.ink))])))));}
}

class ReferenceProductSurface extends StatelessWidget {
 const ReferenceProductSurface({super.key,required this.name,required this.description,required this.price,required this.image,required this.control,required this.available,this.oldPrice,this.discount,this.onOpen,this.fullWidthControl=false});
 final String name,description,price;final String? oldPrice;final int? discount;final Widget image,control;final bool available;final bool fullWidthControl;final VoidCallback? onOpen;
 @override Widget build(BuildContext context)=>Semantics(button:onOpen!=null,label:name,child:Material(color:Colors.white,borderRadius:BorderRadius.circular(22),child:InkWell(onTap:onOpen,borderRadius:BorderRadius.circular(22),child:Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFEBF0ED)),boxShadow:ReferenceHomeTokens.shadow),padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  Expanded(child:Stack(fit:StackFit.expand,children:[ClipRRect(borderRadius:BorderRadius.circular(16),child:image),if(discount!=null)Positioned(left:0,top:0,child:Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(color:AppColors.coral600,borderRadius:BorderRadius.circular(9)),child:Text('−$discount%',textScaler:TextScaler.noScaling,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w800)))),if(!available)const Center(child:Chip(label:Text('Indisponível',style:TextStyle(fontSize:10))))])),
  const SizedBox(height:9),Text(name,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:13,height:1.18,fontWeight:FontWeight.w800,color:AppColors.ink)),
  if(description.isNotEmpty)...[const SizedBox(height:4),Text(description,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10.5,color:AppColors.muted))],
  const SizedBox(height:7),if(oldPrice!=null)Text(oldPrice!,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:AppColors.muted,decoration:TextDecoration.lineThrough)),if(fullWidthControl)...[Text(price,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:AppColors.ink)),const SizedBox(height:7),control]else Row(children:[Expanded(child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(price,maxLines:1,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:AppColors.ink)))),const SizedBox(width:4),SizedBox(width:44,child:control)]),
 ])))));
}
