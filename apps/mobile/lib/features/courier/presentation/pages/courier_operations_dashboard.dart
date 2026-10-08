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

class CourierOperationsNav extends StatelessWidget{
  const CourierOperationsNav({super.key,required this.online,required this.active,required this.busy,required this.onHome,required this.onWallet,required this.onAction,required this.onHistory,required this.onProfile});
  final bool online,active,busy;
  final VoidCallback onHome,onWallet,onAction,onHistory,onProfile;
  Widget item(IconData icon,String label,VoidCallback tap,{bool selected=false})=>Expanded(child:TextButton(onPressed:tap,style:TextButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:8,horizontal:2),foregroundColor:selected?AppColors.ocean700:AppColors.muted,minimumSize:const Size(44,52)),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:20),const SizedBox(height:5),Text(label,style:TextStyle(fontSize:10,fontWeight:selected?FontWeight.w800:FontWeight.w600))])));
  @override Widget build(BuildContext context)=>SafeArea(top:false,minimum:const EdgeInsets.fromLTRB(12,8,12,10),child:Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:5),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.stroke),boxShadow:AppShadows.floating),child:Row(children:[item(AppIcons.home,'Início',onHome,selected:true),item(AppIcons.wallet,'Carteira',onWallet),Expanded(child:Column(mainAxisSize:MainAxisSize.min,children:[Semantics(button:true,label:active?'Abrir entrega atual':online?'Atualizar entregas':'Ficar online',child:InkWell(onTap:busy?null:onAction,borderRadius:BorderRadius.circular(19),child:AnimatedContainer(duration:Duration(milliseconds:MediaQuery.disableAnimationsOf(context)?0:180),width:52,height:48,decoration:BoxDecoration(gradient:LinearGradient(colors:online?[AppColors.ocean600,AppColors.ocean800]:[AppColors.inkSoft,AppColors.ink]),borderRadius:BorderRadius.circular(18),boxShadow:AppShadows.soft),child:busy?const Padding(padding:EdgeInsets.all(15),child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):Icon(active?AppIcons.route:AppIcons.radar,color:Colors.white,size:24)))),const SizedBox(height:4),Text(active?'Rota':online?'Entregas':'Conectar',style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:AppColors.ocean700))])),item(AppIcons.history,'Histórico',onHistory),item(AppIcons.user,'Perfil',onProfile)])));
}
