import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override Widget build(BuildContext context)=>SafeArea(bottom:false,child:ListView(
    physics:const BouncingScrollPhysics(),padding:const EdgeInsets.fromLTRB(20,22,20,120),children:[
      Text('Seu espaço',style:Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height:18),
      Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF15211F),Color(0xFF29403B)]),borderRadius:BorderRadius.circular(28)),child:const Row(children:[
        CircleAvatar(radius:31,backgroundColor:AppColors.mint,child:Icon(Icons.person_rounded,color:AppColors.oceanDeep,size:31)),SizedBox(width:14),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Olá, seja bem-vindo',style:TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w900)),SizedBox(height:4),Text('Entre para viver a experiência completa',style:TextStyle(color:Colors.white70,fontSize:11,fontWeight:FontWeight.w600))])),
        Icon(Icons.arrow_forward_rounded,color:Colors.white),
      ])),
      const SizedBox(height:14),
      Row(children:[Expanded(child:_quick('Pedidos',Icons.receipt_long_rounded)),const SizedBox(width:10),Expanded(child:_quick('Endereços',Icons.near_me_rounded)),const SizedBox(width:10),Expanded(child:_quick('Favoritos',Icons.favorite_rounded))]),
      const SizedBox(height:24),const Text('Sua conta',style:TextStyle(fontSize:13,fontWeight:FontWeight.w900,color:AppColors.muted)),
      const SizedBox(height:8),
      const _Menu('Pagamentos',Icons.credit_card_rounded,'Carteiras e cartões'),
      const _Menu('Notificações',Icons.notifications_none_rounded,'Escolha o que receber'),
      const _Menu('Ajuda',Icons.support_agent_rounded,'Fale com a Porto Prime'),
      const _Menu('Privacidade',Icons.shield_outlined,'Seus dados e segurança'),
      const SizedBox(height:16),
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:AppColors.sand,borderRadius:BorderRadius.circular(23)),child:const Row(children:[Icon(Icons.wb_sunny_rounded,color:AppColors.sun),SizedBox(width:12),Expanded(child:Text('Feito para dias de sol, noites longas e brindes em Porto Seguro.',style:TextStyle(fontSize:12,height:1.35,fontWeight:FontWeight.w700)))])),
    ],
  ));

  static Widget _quick(String s,IconData i)=>Container(height:88,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(21),border:Border.all(color:const Color(0xFFE9ECE7))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(i,color:AppColors.oceanDeep,size:24),const SizedBox(height:7),Text(s,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800))]));
}
class _Menu extends StatelessWidget{const _Menu(this.title,this.icon,this.sub);final String title,sub;final IconData icon;@override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:14,vertical:12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(19)),child:Row(children:[Container(width:42,height:42,decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:AppColors.oceanDeep,size:21)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w900)),Text(sub,style:const TextStyle(fontSize:10,color:AppColors.muted,fontWeight:FontWeight.w600))])),const Icon(Icons.chevron_right_rounded,color:AppColors.muted)]));}
