import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';

class CourierOperationsHero extends StatefulWidget {
  const CourierOperationsHero({super.key,required this.name,required this.online,required this.active,required this.onChanged});
  final String name;
  final bool online,active;
  final Future<void> Function(bool)? onChanged;
  @override State<CourierOperationsHero> createState()=>_CourierOperationsHeroState();
}
class _CourierOperationsHeroState extends State<CourierOperationsHero>{
  bool busy=false;
  Future<void> toggle() async {if(busy||widget.onChanged==null)return;setState(()=>busy=true);try{await widget.onChanged!(!widget.online);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(PrimeMessages.friendly(e))));}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context){
    final reduced=MediaQuery.disableAnimationsOf(context);
    final hour=DateTime.now().hour;
    final greeting=hour<12?'Bom dia':hour<18?'Boa tarde':'Boa noite';
    return AnimatedContainer(duration:Duration(milliseconds:reduced?0:220),padding:const EdgeInsets.all(24),decoration:BoxDecoration(borderRadius:BorderRadius.circular(28),gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:widget.online?[AppColors.ocean900,AppColors.ocean700]:[AppColors.ink,AppColors.inkSoft]),boxShadow:AppShadows.elevated),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Expanded(child:Text('PORTO PRIME / NA RUA',style:TextStyle(color:AppColors.ocean300,fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1.6))),AnimatedContainer(duration:Duration(milliseconds:reduced?0:200),padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.12),borderRadius:BorderRadius.circular(30)),child:Row(mainAxisSize:MainAxisSize.min,children:[AnimatedContainer(duration:Duration(milliseconds:reduced?0:200),width:7,height:7,decoration:BoxDecoration(color:widget.online?AppColors.ocean300:Colors.white54,shape:BoxShape.circle)),const SizedBox(width:7),Text(widget.online?'ONLINE':'OFFLINE',style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w800))]))]),
      const SizedBox(height:20),Text('$greeting, ${widget.name}.',style:const TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w800,letterSpacing:-.8)),const SizedBox(height:8),AnimatedSwitcher(duration:Duration(milliseconds:reduced?0:180),child:Text(widget.active?'Sua próxima conquista está nesta rota.':widget.online?'Seu radar está ativo. Pronto para a próxima entrega.':'Sua cidade espera por você. Entre online quando estiver pronto.',key:ValueKey('${widget.online}:${widget.active}'),style:const TextStyle(color:Colors.white70,fontSize:13,height:1.5))),
      const SizedBox(height:22),ClipRRect(borderRadius:BorderRadius.circular(18),child:TweenAnimationBuilder<double>(tween:Tween(end:widget.online?8:3),duration:Duration(milliseconds:reduced?0:220),builder:(context,blur,child)=>BackdropFilter(filter:ImageFilter.blur(sigmaX:blur,sigmaY:blur),child:child),child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.10),border:Border.all(color:Colors.white.withValues(alpha:.16)),borderRadius:BorderRadius.circular(18)),child:Row(children:[Icon(widget.active?AppIcons.route:AppIcons.radar,color:AppColors.ocean300,size:25),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.active?'Entrega em andamento':widget.online?'Disponível para chamadas':'Disponibilidade pausada',style:const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.w700)),const SizedBox(height:4),const Text('Você controla seu status',style:TextStyle(color:Colors.white60,fontSize:11))])),if(!widget.active)Switch.adaptive(value:widget.online,onChanged:busy?null:(v)=>toggle(),activeThumbColor:Colors.white,activeTrackColor:AppColors.ocean500)])))),
    ]));
  }
}

class CourierDemandPanel extends StatelessWidget{
  const CourierDemandPanel({super.key,required this.data,required this.error,required this.refresh});
  final Map<String,dynamic> data;
  final String? error;
  final Future<void> Function() refresh;
  @override Widget build(BuildContext context){
    final zones=List<dynamic>.from(data['zones']??[]).map((z)=>Map<String,dynamic>.from(z)).toList();
    final mapped=zones.where((z)=>z['latitude']!=null&&z['longitude']!=null).toList();
    final rate=data['completionRate'];
    final stamp=DateTime.tryParse(data['updatedAt']?.toString()??'')?.toLocal();
    return Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.stroke),boxShadow:AppShadows.soft),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(AppIcons.radar,color:AppColors.ocean600,size:20),const SizedBox(width:9),const Expanded(child:Text('Pulso da operação',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,letterSpacing:-.4))),IconButton(tooltip:'Atualizar demanda',onPressed:refresh,icon:const Icon(AppIcons.refresh_rounded,size:19))]),
      Text(error??(stamp==null?'Preparando visão operacional…':'Atualizado às ${stamp.hour.toString().padLeft(2,'0')}:${stamp.minute.toString().padLeft(2,'0')} · atualização a cada 15 s'),style:TextStyle(fontSize:11,color:error==null?AppColors.muted:AppColors.danger)),const SizedBox(height:16),
      if(data.isEmpty&&error==null)Container(height:190,decoration:BoxDecoration(color:AppColors.surfaceMuted,borderRadius:BorderRadius.circular(18)))
      else if(mapped.isNotEmpty)Semantics(label:'Mapa por zonas aproximadas de demanda. ${mapped.length} zonas com coordenadas.',child:ClipRRect(borderRadius:BorderRadius.circular(18),child:SizedBox(height:210,child:Stack(children:[Positioned.fill(child:InteractiveViewer(minScale:1,maxScale:4,child:CustomPaint(painter:_DemandMapPainter(mapped),child:const SizedBox.expand()))),const Positioned(top:12,left:12,child:Text('MAPA OPERACIONAL',style:TextStyle(fontSize:9,color:AppColors.ocean700,fontWeight:FontWeight.w800,letterSpacing:1.1))),const Positioned(top:12,right:12,child:Text('N ↑',style:TextStyle(fontSize:11,color:AppColors.ocean700,fontWeight:FontWeight.w800))),Positioned(bottom:12,left:12,child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.9),borderRadius:BorderRadius.circular(20)),child:const Text('Arraste e amplie · zonas aproximadas',style:TextStyle(fontSize:10,color:AppColors.ocean800))))]))))
      else Container(width:double.infinity,padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(18)),child:Column(children:[const Icon(AppIcons.route,color:AppColors.ocean600,size:29),const SizedBox(height:10),Text(zones.isEmpty?'Nenhuma demanda aguardando agora':'Coordenadas ainda não disponíveis',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700)),const SizedBox(height:6),const Text('Os dados de bairros aparecem assim que há pedidos pagos na operação.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:AppColors.muted,height:1.5))])),
      if(data.isNotEmpty) ...[const SizedBox(height:14),Text('${data['pendingOrders']??0} pedidos pagos aguardando motoboy',style:const TextStyle(fontSize:12,color:AppColors.ocean700,fontWeight:FontWeight.w700))],
      const SizedBox(height:14),Wrap(spacing:8,runSpacing:8,children:zones.take(6).map((z)=>Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:8),decoration:BoxDecoration(color:z['level']=='HIGH'?AppColors.sand100:AppColors.ocean50,borderRadius:BorderRadius.circular(12)),child:Text('${z['name']} · ${z['count']}${z['level']=='HIGH'?' / alta demanda':''}',style:const TextStyle(fontSize:11,color:AppColors.ocean800,fontWeight:FontWeight.w700)))).toList()),
      const SizedBox(height:12),const Text('Intensidade = pedidos pagos ainda sem motoboy. Mapa por zonas, sem endereços individuais ou rotas de navegação.',style:TextStyle(fontSize:10,color:AppColors.muted,height:1.5)),const SizedBox(height:18),
      Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:AppColors.surfaceSoft,borderRadius:BorderRadius.circular(16),border:Border.all(color:AppColors.stroke)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Expanded(child:Text('Conclusão operacional',style:TextStyle(fontSize:12,fontWeight:FontWeight.w800))),Text(rate==null?'Sem amostra':'$rate%',style:const TextStyle(fontSize:17,color:AppColors.ocean700,fontWeight:FontWeight.w800))]),const SizedBox(height:10),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:rate==null?0:(rate as num).toDouble()/100,color:AppColors.ocean500,backgroundColor:AppColors.stroke,minHeight:5)),const SizedBox(height:8),Text('${data['completedToday']??0} concluídas hoje · ${data['activeDeliveries']??0} em andamento',style:const TextStyle(fontSize:11,color:AppColors.muted)),const SizedBox(height:5),const Text('Concluídas hoje ÷ (concluídas hoje + ativas).',style:TextStyle(fontSize:10,color:AppColors.muted))])),
    ]));
  }
}
class _DemandMapPainter extends CustomPainter{
  _DemandMapPainter(this.zones);
  final List<Map<String,dynamic>> zones;
  @override void paint(Canvas canvas,Size size){
    canvas.drawRect(Offset.zero&size,Paint()..color=AppColors.ocean50);
    final grid=Paint()..color=AppColors.ocean700.withValues(alpha:.07)..strokeWidth=1;
    for(double x=0;x<size.width;x+=28){canvas.drawLine(Offset(x,0),Offset(x,size.height),grid);}
    for(double y=0;y<size.height;y+=28){canvas.drawLine(Offset(0,y),Offset(size.width,y),grid);}
    final lats=zones.map((z)=>(z['latitude'] as num).toDouble()).toList();final lngs=zones.map((z)=>(z['longitude'] as num).toDouble()).toList();
    final minLat=lats.reduce(math.min),maxLat=lats.reduce(math.max),minLng=lngs.reduce(math.min),maxLng=lngs.reduce(math.max);
    final centerLat=(minLat+maxLat)/2,centerLng=(minLng+maxLng)/2;
    final latRange=math.max(.03,maxLat-minLat+.02),lngRange=math.max(.03,maxLng-minLng+.02);
    for(final z in zones){final lat=(z['latitude'] as num).toDouble(),lng=(z['longitude'] as num).toDouble();final p=Offset(size.width/2+(lng-centerLng)/lngRange*(size.width-60),size.height/2-(lat-centerLat)/latRange*(size.height-70));final count=(z['count'] as num).toDouble();final radius=math.min(48.0,22+count*5);final color=z['level']=='HIGH'?AppColors.sun500:AppColors.ocean500;
      canvas.drawCircle(p,radius,Paint()..shader=RadialGradient(colors:[color.withValues(alpha:.55),color.withValues(alpha:0)]).createShader(Rect.fromCircle(center:p,radius:radius)));
      canvas.drawCircle(p,9,Paint()..color=Colors.white);canvas.drawCircle(p,6,Paint()..color=color);
      final text=TextPainter(text:TextSpan(text:'${z['count']}',style:const TextStyle(color:AppColors.ocean900,fontSize:10,fontWeight:FontWeight.w800)),textDirection:TextDirection.ltr)..layout();text.paint(canvas,p+Offset(11,-7));
    }
  }
  @override bool shouldRepaint(covariant _DemandMapPainter old)=>old.zones!=zones;
}

class CourierOperationsNav extends StatelessWidget{
  const CourierOperationsNav({super.key,required this.online,required this.active,required this.busy,required this.onHome,required this.onWallet,required this.onAction,required this.onHistory,required this.onProfile});
  final bool online,active,busy;
  final VoidCallback onHome,onWallet,onAction,onHistory,onProfile;
  Widget item(IconData icon,String label,VoidCallback tap,{bool selected=false})=>Expanded(child:TextButton(onPressed:tap,style:TextButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:8,horizontal:2),foregroundColor:selected?AppColors.ocean700:AppColors.muted,minimumSize:const Size(44,52)),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:20),const SizedBox(height:5),Text(label,style:TextStyle(fontSize:10,fontWeight:selected?FontWeight.w800:FontWeight.w600))])));
  @override Widget build(BuildContext context)=>SafeArea(top:false,minimum:const EdgeInsets.fromLTRB(12,8,12,10),child:Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:5),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.stroke),boxShadow:AppShadows.floating),child:Row(children:[item(AppIcons.home,'Início',onHome,selected:true),item(AppIcons.wallet,'Carteira',onWallet),Expanded(child:Column(mainAxisSize:MainAxisSize.min,children:[Semantics(button:true,label:active?'Abrir entrega atual':online?'Atualizar radar':'Ficar online',child:InkWell(onTap:busy?null:onAction,borderRadius:BorderRadius.circular(19),child:AnimatedContainer(duration:Duration(milliseconds:MediaQuery.disableAnimationsOf(context)?0:180),width:52,height:48,decoration:BoxDecoration(gradient:LinearGradient(colors:online?[AppColors.ocean600,AppColors.ocean800]:[AppColors.inkSoft,AppColors.ink]),borderRadius:BorderRadius.circular(18),boxShadow:AppShadows.soft),child:busy?const Padding(padding:EdgeInsets.all(15),child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):Icon(active?AppIcons.route:AppIcons.radar,color:Colors.white,size:24)))),const SizedBox(height:4),Text(active?'Rota':online?'Radar':'Conectar',style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:AppColors.ocean700))])),item(AppIcons.history,'Histórico',onHistory),item(AppIcons.user,'Perfil',onProfile)])));
}
