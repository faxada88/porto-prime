import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});
  @override Widget build(BuildContext context)=>SafeArea(bottom:false,child:ListView(
    physics:const BouncingScrollPhysics(),padding:const EdgeInsets.fromLTRB(20,22,20,120),children:[
      Row(children:[Expanded(child:Text('Sua sacola',style:Theme.of(context).textTheme.headlineLarge)),Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:7),decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(20)),child:const Text('3 itens',style:TextStyle(color:AppColors.oceanDeep,fontSize:11,fontWeight:FontWeight.w900)))]),
      const SizedBox(height:6),const Text('Já já seu brinde chega.',style:TextStyle(color:AppColors.muted,fontWeight:FontWeight.w600)),
      const SizedBox(height:22),
      const _Delivery(),
      const SizedBox(height:14),
      const _Item('Heineken','Long Neck • 330 ml','R\$ 8,99',Icons.sports_bar_rounded,Color(0xFFE0F4E7),2),
      const SizedBox(height:10),
      const _Item('Coca-Cola','Original • 2 L','R\$ 12,90',Icons.local_drink_rounded,Color(0xFFFFE2DE),1),
      const SizedBox(height:20),
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:const Color(0xFFE8EBE6))),child:const Column(children:[
        _Price('Subtotal','R\$ 30,88'),SizedBox(height:10),_Price('Entrega','R\$ 5,90'),Padding(padding:EdgeInsets.symmetric(vertical:14),child:Divider(height:1)),_Price('Total','R\$ 36,78',strong:true),
      ])),
      const SizedBox(height:14),
      Container(height:58,alignment:Alignment.center,decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppColors.oceanDeep,AppColors.turquoise]),borderRadius:BorderRadius.circular(19),boxShadow:[BoxShadow(color:Color(0x33007F73),blurRadius:22,offset:Offset(0,10))]),child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[Text('Continuar para entrega',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),SizedBox(width:8),Icon(Icons.arrow_forward_rounded,color:Colors.white,size:19)])),
    ],
  ));
}

class _Delivery extends StatelessWidget{const _Delivery();@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.sand,borderRadius:BorderRadius.circular(22)),child:const Row(children:[DecoratedBox(decoration:BoxDecoration(color:Colors.white,shape:BoxShape.circle),child:SizedBox(width:44,height:44,child:Icon(Icons.bolt_rounded,color:AppColors.coral))),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Entrega Prime',style:TextStyle(fontWeight:FontWeight.w900)),SizedBox(height:2),Text('Estimativa visual • 25–40 min',style:TextStyle(fontSize:11,color:AppColors.muted,fontWeight:FontWeight.w600))])),Icon(Icons.chevron_right_rounded)]));}
class _Item extends StatelessWidget{const _Item(this.name,this.detail,this.price,this.icon,this.color,this.qty);final String name,detail,price;final IconData icon;final Color color;final int qty;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(23)),child:Row(children:[Container(width:76,height:76,decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(18)),child:Icon(icon,size:38)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:14)),Text(detail,style:const TextStyle(color:AppColors.muted,fontSize:10)),const SizedBox(height:8),Text(price,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:14))])),Container(padding:const EdgeInsets.all(5),decoration:BoxDecoration(color:AppColors.canvas,borderRadius:BorderRadius.circular(13)),child:Row(children:[const Icon(Icons.remove_rounded,size:17),Padding(padding:const EdgeInsets.symmetric(horizontal:8),child:Text('$qty',style:const TextStyle(fontWeight:FontWeight.w900))),const Icon(Icons.add_rounded,size:17)]))]));}
class _Price extends StatelessWidget{const _Price(this.a,this.b,{this.strong=false});final String a,b;final bool strong;@override Widget build(BuildContext context)=>Row(children:[Expanded(child:Text(a,style:TextStyle(color:strong?AppColors.ink:AppColors.muted,fontWeight:strong?FontWeight.w900:FontWeight.w600))),Text(b,style:TextStyle(fontSize:strong?18:13,fontWeight:FontWeight.w900))]);}
