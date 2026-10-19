import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import 'prime_category_3d.dart';

class PrimeHomeCarousel extends StatefulWidget {
 const PrimeHomeCarousel({super.key,required this.onExplore});final VoidCallback onExplore;
 @override State<PrimeHomeCarousel> createState()=>_PrimeHomeCarouselState();
}
class _PrimeHomeCarouselState extends State<PrimeHomeCarousel> with SingleTickerProviderStateMixin,WidgetsBindingObserver {
 late final AnimationController _progress;
 final _pages=PageController(initialPage:300);
 int _page=300;
 bool _reduced=false,_visible=true,_touching=false,_paused=false,_foreground=true;
 static const _slides=[
  (title:'Seu momento,\nna sua porta.',subtitle:'Bebidas e conveniência\nem Porto Seguro.',key:'beer',background:Color(0xFF003B3E),foreground:Colors.white,accent:Color(0xFFF5C866)),
  (title:'Escolha seus\npróximos favoritos.',subtitle:'Encontre produtos para\ncada ocasião.',key:'convenience',background:Color(0xFFFFE9AE),foreground:Color(0xFF163B37),accent:Color(0xFF00564F)),
  (title:'Mais cor para\no seu dia.',subtitle:'Explore as categorias\ne monte seu pedido.',key:'fruit',background:Color(0xFF633E9E),foreground:Colors.white,accent:Color(0xFFFFD677)),
 ];
 int get _index=>_page%_slides.length;
 bool get _playing=>!_paused&&!_touching&&!_reduced&&_visible&&_foreground;
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);_progress=AnimationController(vsync:this,duration:const Duration(seconds:5))..addStatusListener((status){if(status==AnimationStatus.completed&&mounted&&_playing)_go(_page+1);});}
 @override void didChangeDependencies(){super.didChangeDependencies();_reduced=MediaQuery.disableAnimationsOf(context)||MediaQuery.of(context).accessibleNavigation;_visible=TickerMode.of(context);_sync();}
 @override void didChangeAppLifecycleState(AppLifecycleState state){_foreground=state==AppLifecycleState.resumed;_sync();}
 void _sync(){if(_playing)_progress.forward();else _progress.stop();}
 void _go(int page){if(!_pages.hasClients)return;if(_reduced)_pages.jumpToPage(page);else _pages.animateToPage(page,duration:const Duration(milliseconds:450),curve:Curves.easeInOutCubic);}
 void _pointer(bool touching){_touching=touching;if(!touching)_progress.reset();_sync();}
 @override void dispose(){WidgetsBinding.instance.removeObserver(this);_progress.dispose();_pages.dispose();super.dispose();}
 @override Widget build(BuildContext context){
  final scaler=MediaQuery.textScalerOf(context);
  final large=scaler.scale(14)>19;
  return LayoutBuilder(builder:(context,constraints){
  final innerWidth=(constraints.maxWidth-36).clamp(1.0,double.infinity).toDouble();
  final textWidth=large?innerWidth:(innerWidth*.68-8).clamp(1.0,double.infinity).toDouble();
  double measure(String text,TextStyle style){
   final painter=TextPainter(text:TextSpan(text:text,style:style),textDirection:Directionality.of(context),textScaler:scaler)..layout(maxWidth:textWidth);
   final height=painter.height;
   painter.dispose();
   return height;
  }
  // Measure every slide so wrapping and accessibility text keep a stable height.
  var contentHeight=124.0;
  for(final data in _slides){
   final title=measure(data.title,const TextStyle(fontSize:23,fontWeight:FontWeight.w800,height:1.12,letterSpacing:-.6));
   final subtitle=measure(data.subtitle,const TextStyle(fontSize:12,height:1.4));
   final action=measure('Explorar catálogo',const TextStyle(fontSize:12,fontWeight:FontWeight.w800,height:1.5));
   final required=title+10+subtitle+12+(action+24).clamp(48.0,double.infinity);
   if(required>contentHeight)contentHeight=required;
  }
  final bannerHeight=contentHeight+32+44+24;
  final slide=_slides[_index];
  return ClipRRect(borderRadius:BorderRadius.circular(24),child:Listener(onPointerDown:(_)=>_pointer(true),onPointerUp:(_)=>_pointer(false),onPointerCancel:(_)=>_pointer(false),child:SizedBox(height:bannerHeight,child:AnimatedContainer(duration:_reduced?Duration.zero:const Duration(milliseconds:450),color:slide.background,child:Column(children:[
   Expanded(child:Stack(children:[
    PageView.builder(controller:_pages,onPageChanged:(page){setState(()=>_page=page);_progress.reset();_sync();},itemBuilder:(context,page){final data=_slides[page%_slides.length];final visual=AppIcons.categoryVisual('',iconKey:data.key);return ColoredBox(color:data.background,child:Padding(padding:const EdgeInsets.fromLTRB(20,24,16,8),child:LayoutBuilder(builder:(context,box){final large=MediaQuery.textScalerOf(context).scale(14)>19;return Row(children:[Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(data.title,style:TextStyle(fontSize:23,fontWeight:FontWeight.w800,height:1.12,letterSpacing:-.6,color:data.foreground)),const SizedBox(height:10),Text(data.subtitle,style:TextStyle(fontSize:12,height:1.4,color:data.foreground.withValues(alpha:.85))),const SizedBox(height:12),TextButton(onPressed:widget.onExplore,style:TextButton.styleFrom(foregroundColor:data.accent,padding:const EdgeInsets.symmetric(vertical:8),minimumSize:const Size(0,44)),child:const Row(mainAxisSize:MainAxisSize.min,children:[Flexible(child:Text('Explorar catálogo',style:TextStyle(fontSize:12,fontWeight:FontWeight.w800))),SizedBox(width:8),Icon(AppIcons.arrowRight,size:17)]))])),if(!large)...[const SizedBox(width:8),SizedBox(width:box.maxWidth*.32,height:124,child:PrimeCategory3D(iconKey:data.key,fallback:Icon(visual.icon,size:66,color:data.accent)))]]);})));}),
    Positioned(top:2,right:4,child:IconButton(tooltip:_paused?'Retomar banners':'Pausar banners',onPressed:(){setState(()=>_paused=!_paused);_sync();},icon:Icon(_paused?Icons.play_arrow_rounded:Icons.pause_rounded,size:19,color:slide.foreground.withValues(alpha:.8)))),
   ])),
   Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:AnimatedBuilder(animation:_progress,builder:(context,_)=>Row(children:[for(var i=0;i<_slides.length;i++)Expanded(child:Semantics(button:true,selected:i==_index,label:'Banner ${i+1} de ${_slides.length}',child:InkWell(onTap:()=>_go(_page-_index+i),child:SizedBox(height:44,child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:Center(child:ClipRRect(borderRadius:BorderRadius.circular(3),child:LinearProgressIndicator(value:i<_index?1:i==_index?(_reduced||_paused?1:_progress.value):0,minHeight:4,backgroundColor:slide.foreground.withValues(alpha:.3),color:slide.foreground))))))))]))),
  ])))));
  });
 }
}
