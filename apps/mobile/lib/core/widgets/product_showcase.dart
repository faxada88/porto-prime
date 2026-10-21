import 'dart:async';
import 'package:flutter/material.dart';
import '../navigation/app_nav.dart';
import '../theme/app_theme.dart';
import 'prime_product_card.dart';
import 'prime_ui.dart';

/// Uses the catalogue's real products and existing cart handlers.
class ProductShowcase extends StatefulWidget{
 const ProductShowcase({super.key,required this.products});
 final List<dynamic> products;
 @override State<ProductShowcase> createState()=>_ShowcaseState();
}
class _ShowcaseState extends State<ProductShowcase> with WidgetsBindingObserver{
 final controller=PageController(viewportFraction:.76);
 Timer? timer;int page=0;bool foreground=true,dragging=false;
 DateTime touched=DateTime.fromMillisecondsSinceEpoch(0);
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);
  timer=Timer.periodic(const Duration(seconds:6),(_){
   if(!mounted||!foreground||dragging||widget.products.length<2||!controller.hasClients||AppNav.instance.index.value!=0||ModalRoute.of(context)?.isCurrent==false||MediaQuery.disableAnimationsOf(context)||DateTime.now().difference(touched).inSeconds<10)return;
   if(controller.position.isScrollingNotifier.value)return;
   final next=(page+1)%widget.products.take(8).length;
   controller.animateToPage(next,duration:const Duration(milliseconds:550),curve:Curves.easeInOutCubic);
  });
 }
 @override void didChangeAppLifecycleState(AppLifecycleState state){foreground=state==AppLifecycleState.resumed;}
 @override void dispose(){timer?.cancel();controller.dispose();WidgetsBinding.instance.removeObserver(this);super.dispose();}
 @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,box){
  final count=widget.products.take(8).length;
  final cardWidth=box.maxWidth*.76-12;
  final extra=(MediaQuery.textScalerOf(context).scale(14)-14).clamp(0,32).toDouble();
  return Column(children:[
   SizedBox(height:cardWidth+122+extra*10,child:Listener(
    onPointerDown:(_){dragging=true;touched=DateTime.now();},
    onPointerUp:(_){dragging=false;touched=DateTime.now();},onPointerCancel:(_){dragging=false;},
    child:PageView.builder(controller:controller,padEnds:false,itemCount:count==0?2:count,
     onPageChanged:(value)=>setState(()=>page=value),itemBuilder:(context,index)=>Padding(
      padding:const EdgeInsets.only(right:12,bottom:4),child:count==0?const PrimeSkeleton(height:300,radius:22):PrimeProductCard(product:widget.products[index],referenceStyle:true))),
   )),
   if(count>1)Padding(padding:const EdgeInsets.only(top:14),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
    for(var i=0;i<count;i++)AnimatedContainer(duration:const Duration(milliseconds:220),margin:const EdgeInsets.symmetric(horizontal:3),
     height:5,width:i==page?20:5,decoration:BoxDecoration(color:i==page?AppColors.ocean700:AppColors.strokeStrong,borderRadius:BorderRadius.circular(8))),
   ])),
  ]);
 });
}
