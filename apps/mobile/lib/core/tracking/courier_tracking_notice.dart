import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'courier_route_tracker.dart';
class CourierTrackingNotice extends StatelessWidget {
 const CourierTrackingNotice({super.key,this.hideWhenSharing=false});
 final bool hideWhenSharing;
 @override Widget build(BuildContext context)=>ListenableBuilder(listenable:CourierRouteTracker.instance,builder:(context,_) {
  final gps=CourierRouteTracker.instance;
  if(hideWhenSharing&&gps.sharing)return const SizedBox.shrink();
  return Container(margin:const EdgeInsets.only(bottom:14),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(20),border:Border.all(color:AppColors.ocean100)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(AppIcons.route,color:AppColors.ocean700),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const PrimeText('Rota ao vivo',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),PrimeText(gps.message,style:const TextStyle(fontSize:12,height:1.5))]))]),
   if(!gps.sharing)Wrap(spacing:8,children:[TextButton(onPressed:gps.retry,child:const PrimeText('Ativar localização')),TextButton(onPressed:()=>Geolocator.openLocationSettings(),child:const PrimeText('GPS')),TextButton(onPressed:()=>Geolocator.openAppSettings(),child:const PrimeText('Permissões'))]),
  ]));
 });
}
