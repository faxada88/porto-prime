import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

class CourierSearchNotice extends StatefulWidget {
  const CourierSearchNotice({super.key});
  @override
  State<CourierSearchNotice> createState()=>_CourierSearchNoticeState();
}
class _CourierSearchNoticeState extends State<CourierSearchNotice> with SingleTickerProviderStateMixin {
  late final AnimationController _motion=AnimationController(vsync:this,duration:const Duration(milliseconds:2200));
  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    if(MediaQuery.of(context).disableAnimations){_motion.stop();_motion.value=.35;}else if(!_motion.isAnimating){_motion.repeat();}
  }
  @override
  void dispose(){_motion.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>Semantics(liveRegion:true,label:'Procurando entregador. Seu pedido está liberado e aguardando aceite.',child:Container(
    padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.ocean100)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        RepaintBoundary(child:SizedBox(width:82,height:82,child:CustomPaint(painter:_SearchRings(_motion),child:Center(child:Container(width:44,height:44,decoration:const BoxDecoration(color:AppColors.ocean800,shape:BoxShape.circle),child:const Icon(AppIcons.bike,color:Colors.white,size:23)))))),
        const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Conectando sua entrega',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:AppColors.ocean900,letterSpacing:-.4)),SizedBox(height:7),Text('Buscando um entregador disponível.',style:TextStyle(color:AppColors.ocean700,fontSize:12,height:1.5))])),
      ]),const SizedBox(height:15),
      const Text('Seu pedido já foi liberado. Assim que alguém aceitar, os dados do entregador aparecem aqui.',style:TextStyle(color:AppColors.muted,fontSize:12,height:1.6)),
      const SizedBox(height:16),
      Row(children:[_point(AppIcons.store,'Retirada'),const Expanded(child:Padding(padding:EdgeInsets.symmetric(horizontal:10),child:Divider(color:AppColors.ocean300))),_point(AppIcons.bike,'Entregador'),const Expanded(child:Padding(padding:EdgeInsets.symmetric(horizontal:10),child:Divider(color:AppColors.ocean300))),_point(AppIcons.home,'Você')]),
    ]),
  ));
  Widget _point(IconData icon,String label)=>Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:18,color:AppColors.ocean700),const SizedBox(height:5),Text(label,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:AppColors.ocean700))]);
}
class _SearchRings extends CustomPainter {
  _SearchRings(this.motion):super(repaint:motion);
  final Animation<double> motion;
  @override
  void paint(Canvas canvas,Size size){
    final center=Offset(size.width/2,size.height/2);
    for(var i=0;i<2;i++){
      final phase=(motion.value+i*.5)%1;
      final radius=23+phase*17;
      canvas.drawCircle(center,radius,Paint()..style=PaintingStyle.stroke..strokeWidth=1.5..color=AppColors.ocean600.withValues(alpha:(1-phase)*.3));
    }
  }
  @override
  bool shouldRepaint(covariant _SearchRings oldDelegate)=>oldDelegate.motion!=motion;
}
