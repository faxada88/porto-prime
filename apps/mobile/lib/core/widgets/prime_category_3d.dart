import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Shared transparent atlas; the Admin icon key remains the source of truth.
class PrimeCategory3D extends StatefulWidget {
 const PrimeCategory3D({super.key,required this.iconKey,required this.fallback});
 final String? iconKey;final Widget fallback;
 static const asset='assets/reference_home/category-3d.webp';
 static const keys=['beer','softDrink','ice','barbecue','fruit','fitness','spirits','wine','convenience'];
 @override State<PrimeCategory3D> createState()=>_PrimeCategory3DState();
}
class _PrimeCategory3DState extends State<PrimeCategory3D> {
 ImageStream? _stream;ImageStreamListener? _listener;ImageInfo? _info;
 @override void didChangeDependencies(){super.didChangeDependencies();if(_stream!=null)return;_stream=const AssetImage(PrimeCategory3D.asset).resolve(createLocalImageConfiguration(context));_listener=ImageStreamListener((image,_){if(mounted)setState((){_info?.dispose();_info=image;});},onError:(Object _,StackTrace? __){});_stream!.addListener(_listener!);}
 @override void dispose(){if(_listener!=null)_stream?.removeListener(_listener!);_info?.dispose();super.dispose();}
 @override Widget build(BuildContext context){final index=PrimeCategory3D.keys.indexOf(widget.iconKey??'');return _info==null||index<0?widget.fallback:ExcludeSemantics(child:CustomPaint(painter:_AtlasIcon(_info!.image,index),size:const Size(80,80)));}
}
class _AtlasIcon extends CustomPainter {
 const _AtlasIcon(this.image,this.index);final ui.Image image;final int index;
 @override void paint(Canvas canvas,Size size){final cell=Size(image.width/3,image.height/3);final src=Rect.fromLTWH((index%3)*cell.width,(index~/3)*cell.height,cell.width,cell.height);final fit=applyBoxFit(BoxFit.contain,src.size,size);canvas.drawImageRect(image,src,Alignment.center.inscribe(fit.destination,Offset.zero&size),Paint()..filterQuality=FilterQuality.medium);}
 @override bool shouldRepaint(covariant _AtlasIcon old)=>old.image!=image||old.index!=index;
}
