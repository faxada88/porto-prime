import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/tracking/courier_route_tracker.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

class LiveDeliveryMap extends StatefulWidget {
 const LiveDeliveryMap({super.key,required this.orderId});
 final String orderId;
 @override State<LiveDeliveryMap> createState()=>_LiveDeliveryMapState();
}
class _LiveDeliveryMapState extends State<LiveDeliveryMap> with SingleTickerProviderStateMixin {
 final _map=MapController();
 late final AnimationController _motion;
 Timer? _timer;
 StreamSubscription<Map<String,dynamic>>? _events;
 Map<String,dynamic> _data={};
 LatLng? _from,_to;
 DateTime? _lastSample;
 bool _loading=false,_mapReady=false,_follow=true;
 String? _error;
 @override void initState(){super.initState();_motion=AnimationController(vsync:this,duration:const Duration(milliseconds:900));_refresh();_timer=Timer.periodic(const Duration(seconds:8),(_)=>_refresh());_events=DeliveryLocationFeed.instance.stream.listen((event){if(event['orderId']==widget.orderId)_apply(event);});}
 @override void dispose(){_timer?.cancel();_events?.cancel();_motion.dispose();_map.dispose();super.dispose();}
 LatLng? _point(dynamic value){if(value is! Map)return null;final lat=value['latitude'],lng=value['longitude'];return lat is num&&lng is num&&lat.isFinite&&lng.isFinite&&lat.abs()<=90&&lng.abs()<=180?LatLng(lat.toDouble(),lng.toDouble()):null;}
 void _apply(Map<String,dynamic> value){
  if(!mounted)return;
  final sample=value['point'];final captured=sample is Map?DateTime.tryParse('${sample['capturedAt']}'):null;
  final received=sample is Map?DateTime.tryParse('${sample['receivedAt']}'):null;
  final previous=_data['point'];final lastReceived=previous is Map?DateTime.tryParse('${previous['receivedAt']}'):null;
  if(received!=null&&lastReceived!=null&&received.isBefore(lastReceived))return;
  setState((){
   _data={..._data,...value};_error=null;
   if(value['active']==false){_from=null;_to=null;}
   final next=_point(sample);
   if(next!=null&&captured!=null&&(_lastSample==null||captured.isAfter(_lastSample!))){
    final current=_animatedPoint;
    _from=current??next;_to=next;_lastSample=captured;
    if(MediaQuery.disableAnimationsOf(context))_motion.value=1;else _motion.forward(from:0);
    if(_mapReady&&_follow)_map.move(next,_map.camera.zoom);
   }
  });
 }
 LatLng? get _animatedPoint {if(_to==null)return null;final from=_from??_to!;final t=Curves.easeInOut.transform(_motion.value);return LatLng(from.latitude+(_to!.latitude-from.latitude)*t,from.longitude+(_to!.longitude-from.longitude)*t);}
 Future<void> _refresh()async{
  if(_loading)return;_loading=true;
  try{final result=await ApiClient.instance.request('GET','/orders/${widget.orderId}/tracking',timeout:const Duration(seconds:12));if(mounted)_apply(Map<String,dynamic>.from(result));}
  catch(_){if(mounted)setState(()=>_error='Conexão com o mapa indisponível. Tentando novamente…');}
  finally{_loading=false;}
 }
 @override Widget build(BuildContext context){
  if(_data['active']==false)return const SizedBox.shrink();
  final target=_point(_data['target']),origin=_point(_data['origin']);
  final center=_to??target??origin??const LatLng(-16.4386,-39.0808);
  final sample=_data['point'];final received=sample is Map?DateTime.tryParse('${sample['receivedAt']}'):null;
  final age=received==null?null:DateTime.now().difference(received).inSeconds.clamp(0,9999);
  final stale=age==null||age>20;
  final returning=_data['mode']=='RETURN';
  final route=_data['route'];
  final seconds=route is Map?route['durationSeconds']:null;
  final eta=seconds is num&&seconds.isFinite&&seconds>0?(seconds/60).ceil():null;
  final line=<LatLng>[];
  if(route is Map&&route['coordinates'] is List){for(final p in route['coordinates']){if(p is List&&p.length>=2&&p[0] is num&&p[1] is num)line.add(LatLng((p[1] as num).toDouble(),(p[0] as num).toDouble()));}}
  return Container(margin:const EdgeInsets.symmetric(vertical:16),clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.stroke)),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   Padding(padding:const EdgeInsets.all(18),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(14)),child:const Icon(AppIcons.route,color:AppColors.ocean700)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(returning?'Retorno à distribuidora':'Seu pedido está a caminho',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(_error??(stale?'Aguardando atualização do motoboy':'Localização ao vivo • atualizado agora'),style:const TextStyle(fontSize:12,height:1.5,color:AppColors.muted))])),])),
   SizedBox(height:300,child:AnimatedBuilder(animation:_motion,builder:(context,_){
    final position=_animatedPoint;
    return Stack(children:[FlutterMap(mapController:_map,options:MapOptions(initialCenter:center,initialZoom:14,onMapReady:(){_mapReady=true;if(_to!=null)_map.move(_to!,14);},onPositionChanged:(_,hasGesture){if(hasGesture&&_follow)setState(()=>_follow=false);}),children:[
     TileLayer(urlTemplate:const String.fromEnvironment('MAP_TILE_URL',defaultValue:'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),userAgentPackageName:'com.portoprime.porto_prime'),
     if(line.length>1)PolylineLayer(polylines:[Polyline(points:line,color:AppColors.ocean700,strokeWidth:5)]),
     MarkerLayer(markers:[
      if(origin!=null)Marker(point:origin,width:36,height:36,child:const _MapPin(icon:AppIcons.store,label:'Distribuidora')),
      if(target!=null)Marker(point:target,width:40,height:40,child:const _MapPin(icon:AppIcons.mapPin,label:'Destino da rota')),
      if(position!=null)Marker(point:position,width:64,height:64,child:Semantics(label:stale?'Última posição conhecida do motoboy':'Posição do motoboy',child:Opacity(opacity:stale ? 0.5 : 1.0,child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:AppColors.ocean800,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:3),boxShadow:const [BoxShadow(color:Color(0x33000000),blurRadius:12,offset:Offset(0,4))]),child:Transform.rotate(angle:(((sample?['heading'] as num?)?.toDouble()??90)-90)*math.pi/180,child:const CustomPaint(painter:_MotoPainter())))))),
     ]),
     RichAttributionWidget(attributions:[TextSourceAttribution('OpenStreetMap contributors',onTap:()=>launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')))]),
    ]),Positioned(top:12,right:12,child:Material(color:AppColors.surface,shape:const CircleBorder(),elevation:2,child:IconButton(tooltip:'Acompanhar motoboy',onPressed:_to==null?null:(){setState(()=>_follow=true);_map.move(_to!,15);},icon:const Icon(AppIcons.mapPin,color:AppColors.ocean700))))]);
   })),
   Padding(padding:const EdgeInsets.all(16),child:Text(_error??(received==null?'O mapa será atualizado assim que recebermos o primeiro sinal GPS.':stale?'Última localização há $age segundos. O sinal pode estar indisponível.':eta!=null?'Chegada estimada em aproximadamente $eta min • pode variar durante o trajeto':'Acompanhe a moto no mapa durante a rota.'),style:const TextStyle(fontSize:12,height:1.6,color:AppColors.muted))),
  ]));
 }
}
class _MapPin extends StatelessWidget {
 const _MapPin({required this.icon,required this.label});final IconData icon;final String label;
 @override Widget build(BuildContext context)=>Semantics(label:label,child:Container(decoration:BoxDecoration(color:AppColors.surface,shape:BoxShape.circle,border:Border.all(color:AppColors.ocean700,width:2)),child:Icon(icon,size:18,color:AppColors.ocean700)));
}
/// A single vector motorcycle silhouette, independent from font glyphs or emojis.
class _MotoPainter extends CustomPainter {
 const _MotoPainter();
 @override void paint(Canvas canvas,Size size){
  canvas.save();canvas.scale(size.width/32,size.height/32);
  final p=Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=2.2..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
  canvas.drawCircle(const Offset(7,23),5,p);canvas.drawCircle(const Offset(25,23),5,p);
  canvas.drawPath(Path()..moveTo(7,23)..lineTo(13,15)..lineTo(20,23)..lineTo(7,23)..moveTo(20,23)..lineTo(25,23)..lineTo(21,10)..lineTo(17,10)..moveTo(10,14)..lineTo(15,14)..moveTo(22,13)..lineTo(27,13),p);
  canvas.drawCircle(const Offset(14,6),2.6,Paint()..color=Colors.white);
  canvas.drawPath(Path()..moveTo(14,10)..lineTo(12,14)..lineTo(18,17)..lineTo(17,21)..moveTo(14,10)..lineTo(18,13)..lineTo(22,13),p);
  canvas.restore();
 }
 @override bool shouldRepaint(covariant _MotoPainter oldDelegate)=>false;
}
