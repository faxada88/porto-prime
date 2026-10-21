import '../../../../core/localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';
import '../../../../core/widgets/prime_brand.dart';

class CourierOperationsHero extends StatefulWidget {
  const CourierOperationsHero({super.key,required this.name,required this.online,required this.active,required this.onChanged});
  final String name;
  final bool online,active;
  final Future<void> Function(bool)? onChanged;
  @override State<CourierOperationsHero> createState()=>_CourierOperationsHeroState();
}
class _CourierOperationsHeroState extends State<CourierOperationsHero>{
  bool busy=false;
  Future<void> toggle() async {if(busy||widget.onChanged==null)return;setState(()=>busy=true);try{await widget.onChanged!(!widget.online);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:PrimeText(PrimeMessages.friendly(e))));}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context){
    final reduced=MediaQuery.disableAnimationsOf(context),hour=DateTime.now().hour;
    final greeting=hour<12?'Bom dia':hour<18?'Boa tarde':'Boa noite';
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     ClipRRect(borderRadius:BorderRadius.circular(AppRadius.xl),child:AnimatedContainer(duration:Duration(milliseconds:reduced?0:180),decoration:BoxDecoration(color:widget.online?AppColors.ocean900:AppColors.inkSoft),child:Stack(children:[const Positioned.fill(child:PrimeCoastArtwork()),Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const PrimeBrandMark(size:34),const SizedBox(width:10),const Expanded(child:PrimeText('PORTO PRIME / NA RUA',style:TextStyle(color:Colors.white70,fontSize:9,fontWeight:FontWeight.w800,letterSpacing:1.1))),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.12),borderRadius:BorderRadius.circular(20)),child:PrimeText(widget.online?'ONLINE':'OFFLINE',style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w800)))]),
      const SizedBox(height:24),PrimeText('$greeting,',style:const TextStyle(color:Colors.white70,fontSize:14)),const SizedBox(height:3),PrimeText(widget.name,style:const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.w800,letterSpacing:-1)),const SizedBox(height:14),
      PrimeText(widget.active?'Você tem uma entrega em andamento.':widget.online?'Disponível para sua próxima entrega.':'Seu próximo trajeto começa quando você estiver pronto.',style:const TextStyle(color:Color(0xFFD8ECE6),fontSize:12,height:1.6)),
     ]))]))),const SizedBox(height:12),
     Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(21),border:Border.all(color:AppColors.stroke)),child:Row(children:[Container(width:42,height:42,decoration:BoxDecoration(color:widget.online?AppColors.ocean50:AppColors.surfaceMuted,borderRadius:BorderRadius.circular(14)),child:Icon(widget.active?AppIcons.route:AppIcons.bike,color:AppColors.ocean700,size:22)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[PrimeText(widget.active?'Entrega em andamento':widget.online?'Pronto para receber entregas':'Você está offline',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800)),const SizedBox(height:4),const PrimeText('Você controla sua disponibilidade',style:TextStyle(fontSize:10,color:AppColors.muted))])),if(!widget.active)Switch.adaptive(value:widget.online,onChanged:busy?null:(v)=>toggle(),activeThumbColor:Colors.white,activeTrackColor:AppColors.ocean700)])),
    ]);
  }
}


class CourierOperationsNav extends StatelessWidget{
  const CourierOperationsNav({super.key,required this.online,required this.active,required this.busy,required this.onHome,required this.onWallet,required this.onAction,required this.onHistory,required this.onProfile});
  final bool online,active,busy;
  final VoidCallback onHome,onWallet,onAction,onHistory,onProfile;
  Widget item(IconData icon,String label,VoidCallback tap,{bool selected=false})=>Expanded(child:TextButton(onPressed:tap,style:TextButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:8,horizontal:2),foregroundColor:selected?AppColors.ocean700:AppColors.muted,minimumSize:const Size(44,52)),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:20),const SizedBox(height:5),PrimeText(label,style:TextStyle(fontSize:10,fontWeight:selected?FontWeight.w800:FontWeight.w600))])));
  @override Widget build(BuildContext context)=>SafeArea(top:false,minimum:const EdgeInsets.fromLTRB(12,8,12,10),child:Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:5),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.stroke),boxShadow:AppShadows.floating),child:Row(children:[item(AppIcons.home,'Início',onHome,selected:true),item(AppIcons.wallet,'Carteira',onWallet),Expanded(child:Column(mainAxisSize:MainAxisSize.min,children:[Semantics(button:true,label: translateLabel(active?'Abrir entrega atual':online?'Atualizar entregas':'Ficar online'),child:InkWell(onTap:busy?null:onAction,borderRadius:BorderRadius.circular(19),child:AnimatedContainer(duration:Duration(milliseconds:MediaQuery.disableAnimationsOf(context)?0:180),width:52,height:48,decoration:BoxDecoration(gradient:LinearGradient(colors:online?[AppColors.ocean700,AppColors.ocean900]:[AppColors.inkSoft,AppColors.ink]),borderRadius:BorderRadius.circular(AppRadius.md),boxShadow:AppShadows.soft),child:busy?const Padding(padding:EdgeInsets.all(15),child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):Icon(active?AppIcons.route:AppIcons.radar,color:Colors.white,size:24)))),const SizedBox(height:4),PrimeText(active?'Rota':online?'Entregas':'Conectar',style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:AppColors.ocean700))])),item(AppIcons.history,'Histórico',onHistory),item(AppIcons.user,'Perfil',onProfile)])));
}

