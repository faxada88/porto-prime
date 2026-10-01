import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  static const cats=[
    ('Cerveja',Icons.sports_bar_rounded,Color(0xFFFFE4A8)),
    ('Whisky',Icons.liquor_rounded,Color(0xFFFFD9C6)),
    ('Drinks',Icons.local_bar_rounded,Color(0xFFDDF5EF)),
    ('Vinhos',Icons.wine_bar_rounded,Color(0xFFFFDFE6)),
    ('Sem álcool',Icons.local_drink_rounded,Color(0xFFDDEFFF)),
  ];
  @override Widget build(BuildContext context)=>SafeArea(bottom:false,child:CustomScrollView(
    physics:const BouncingScrollPhysics(),slivers:[
      const SliverPadding(padding:EdgeInsets.fromLTRB(20,13,20,0),sliver:SliverToBoxAdapter(child:_Header())),
      const SliverPadding(padding:EdgeInsets.fromLTRB(20,17,20,0),sliver:SliverToBoxAdapter(child:_Search())),
      const SliverPadding(padding:EdgeInsets.fromLTRB(20,14,20,0),sliver:SliverToBoxAdapter(child:_Hero())),
      const SliverPadding(padding:EdgeInsets.fromLTRB(20,22,20,11),sliver:SliverToBoxAdapter(child:_Title('Seu momento','Ver tudo'))),
      SliverToBoxAdapter(child:SizedBox(height:96,child:ListView.separated(padding:const EdgeInsets.symmetric(horizontal:20),scrollDirection:Axis.horizontal,itemCount:cats.length,separatorBuilder:(_,__)=>const SizedBox(width:10),itemBuilder:(_,i)=>_Cat(cats[i])))),
      const SliverPadding(padding:EdgeInsets.fromLTRB(20,20,20,11),sliver:SliverToBoxAdapter(child:_Title('Gelou, chegou','Ver mais'))),
      SliverToBoxAdapter(child:SizedBox(height:239,child:ListView.separated(padding:const EdgeInsets.symmetric(horizontal:20),scrollDirection:Axis.horizontal,itemCount:3,separatorBuilder:(_,__)=>const SizedBox(width:12),itemBuilder:(_,i)=>_Product(i)))),
      const SliverPadding(padding:EdgeInsets.fromLTRB(20,23,20,11),sliver:SliverToBoxAdapter(child:_Title('Escolha pelo rolê',''))),
      const SliverToBoxAdapter(child:_Moments()),
      const SliverPadding(padding:EdgeInsets.fromLTRB(20,22,20,125),sliver:SliverToBoxAdapter(child:_PrimeCard())),
    ],
  ));
}

class _Header extends StatelessWidget{const _Header();@override Widget build(BuildContext context)=>Row(children:[
  Container(width:46,height:46,decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppColors.oceanDeep,AppColors.turquoise]),borderRadius:BorderRadius.circular(16)),alignment:Alignment.center,child:const Text('P',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900))),
  const SizedBox(width:11),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('PORTO PRIME',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900,letterSpacing:-.4)),SizedBox(height:2),Row(children:[Icon(Icons.near_me_rounded,size:12,color:AppColors.coral),SizedBox(width:4),Text('Entregar em Porto Seguro',style:TextStyle(fontSize:11,color:AppColors.muted,fontWeight:FontWeight.w600)),Icon(Icons.keyboard_arrow_down_rounded,size:15)])])),
  _Btn(Icons.notifications_none_rounded),
]);}
class _Btn extends StatelessWidget{const _Btn(this.i);final IconData i;@override Widget build(BuildContext context)=>Container(width:43,height:43,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:const Color(0xFFE9ECE7))),child:Icon(i,size:21));}

class _Search extends StatelessWidget{const _Search();@override Widget build(BuildContext context)=>Container(height:53,padding:const EdgeInsets.symmetric(horizontal:15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFE8EBE6))),child:const Row(children:[Icon(Icons.search_rounded,size:22),SizedBox(width:10),Expanded(child:Text('Busque sua bebida, marca ou combo',style:TextStyle(fontSize:12,color:AppColors.muted,fontWeight:FontWeight.w600))),Icon(Icons.tune_rounded,size:19,color:AppColors.oceanDeep)]));}

class _Hero extends StatelessWidget{const _Hero();@override Widget build(BuildContext context)=>Container(
  height:252,clipBehavior:Clip.antiAlias,
  decoration:BoxDecoration(borderRadius:BorderRadius.circular(30),gradient:const LinearGradient(colors:[Color(0xFF063F3A),Color(0xFF008D7F)],begin:Alignment.topLeft,end:Alignment.bottomRight),boxShadow:[BoxShadow(color:AppColors.ocean.withValues(alpha:.2),blurRadius:28,offset:const Offset(0,13))]),
  child:Stack(children:[
    Positioned(right:-70,top:-75,child:Container(width:220,height:220,decoration:BoxDecoration(shape:BoxShape.circle,color:AppColors.sun.withValues(alpha:.98)))),
    Positioned(right:16,bottom:-15,child:Transform.rotate(angle:-.10,child:const Icon(Icons.sports_bar_rounded,size:135,color:Colors.white))),
    Positioned(right:88,bottom:18,child:Container(width:15,height:15,decoration:BoxDecoration(color:AppColors.coral,borderRadius:BorderRadius.circular(5)))),
    Padding(padding:const EdgeInsets.all(22),child:SizedBox(width:220,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Container(width:7,height:7,decoration:const BoxDecoration(color:Color(0xFF7FF2D8),shape:BoxShape.circle)),const SizedBox(width:6),const Text('PORTO SEGURO • ONLINE',style:TextStyle(color:Color(0xFFD9FFF6),fontSize:9,fontWeight:FontWeight.w900,letterSpacing:.8))]),
      const SizedBox(height:15),const Text('Seu brinde.\nNo seu tempo.',style:TextStyle(color:Colors.white,fontSize:31,height:1.0,fontWeight:FontWeight.w900,letterSpacing:-1.1)),
      const SizedBox(height:9),const Text('Gelada do jeito certo, sem tirar você do momento.',style:TextStyle(color:Color(0xFFD5F4EE),fontSize:12,height:1.35,fontWeight:FontWeight.w600)),
      const Spacer(),Container(padding:const EdgeInsets.symmetric(horizontal:15,vertical:11),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14)),child:const Row(mainAxisSize:MainAxisSize.min,children:[Text('Pedir agora',style:TextStyle(color:AppColors.oceanDeep,fontSize:12,fontWeight:FontWeight.w900)),SizedBox(width:7),Icon(Icons.arrow_forward_rounded,size:16,color:AppColors.oceanDeep)])),
    ]))),
  ]),
);}

class _Title extends StatelessWidget{const _Title(this.a,this.b);final String a,b;@override Widget build(BuildContext context)=>Row(children:[Expanded(child:Text(a,style:Theme.of(context).textTheme.titleLarge)),if(b.isNotEmpty)Text(b,style:const TextStyle(color:AppColors.oceanDeep,fontSize:11,fontWeight:FontWeight.w900))]);}
class _Cat extends StatelessWidget{const _Cat(this.d);final (String,IconData,Color)d;@override Widget build(BuildContext context)=>SizedBox(width:70,child:Column(children:[Container(width:62,height:62,decoration:BoxDecoration(color:d.$3,borderRadius:BorderRadius.circular(21)),child:Icon(d.$2,size:28,color:AppColors.ink)),const SizedBox(height:6),Text(d.$1,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800))]));}

class _Product extends StatelessWidget{const _Product(this.i);final int i;@override Widget build(BuildContext context){const d=[
('Heineken','Long Neck • 330 ml','R\$ 8,99','+','GELADA',Icons.sports_bar_rounded,Color(0xFFDDF2E4)),
('Coca-Cola','Original • 2 L','R\$ 12,90','+','TRINCA',Icons.local_drink_rounded,Color(0xFFFFE0DC)),
('Red Label','Whisky • 750 ml','R\$ 89,90','+','PRIME',Icons.liquor_rounded,Color(0xFFFFE7D0))];final p=d[i];return Container(width:164,padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:const Color(0xFFE8EBE6))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Stack(children:[Container(height:112,decoration:BoxDecoration(color:p.$7,borderRadius:BorderRadius.circular(19)),alignment:Alignment.center,child:Icon(p.$6,size:57,color:AppColors.ink)),Positioned(left:8,top:8,child:Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(9)),child:Text(p.$5,style:const TextStyle(fontSize:8,fontWeight:FontWeight.w900,letterSpacing:.5)))),const Positioned(right:8,top:8,child:Icon(Icons.favorite_border_rounded,size:18))]),
 const SizedBox(height:9),Text(p.$1,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w900)),Text(p.$2,style:const TextStyle(fontSize:10,color:AppColors.muted,fontWeight:FontWeight.w600)),const Spacer(),Row(children:[Expanded(child:Text(p.$3,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w900))),Container(width:35,height:35,decoration:BoxDecoration(color:AppColors.ink,borderRadius:BorderRadius.circular(12)),child:Center(child:Text(p.$4,style:const TextStyle(color:Colors.white,fontSize:20))))])
]));}}

class _Moments extends StatelessWidget{const _Moments();@override Widget build(BuildContext context)=>SizedBox(height:113,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:20),children:[
 _m('Pé na areia','Praia + cerveja',Icons.beach_access_rounded,AppColors.sand),const SizedBox(width:10),
 _m('Churrasco','Combo sem erro',Icons.outdoor_grill_rounded,const Color(0xFFFFE0D2)),const SizedBox(width:10),
 _m('Noite','Drinks & destilados',Icons.nightlife_rounded,const Color(0xFFDDF3EE)),
]));static Widget _m(String a,String b,IconData i,Color c)=>Container(width:174,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:c,borderRadius:BorderRadius.circular(23)),child:Row(children:[Container(width:45,height:45,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.75),borderRadius:BorderRadius.circular(15)),child:Icon(i,size:24)),const SizedBox(width:10),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(b,style:const TextStyle(fontSize:9,color:AppColors.muted,fontWeight:FontWeight.w700))]))]));}

class _PrimeCard extends StatelessWidget{const _PrimeCard();@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xFF17231F),borderRadius:BorderRadius.circular(26)),child:const Row(children:[
 DecoratedBox(decoration:BoxDecoration(color:Color(0xFF263A34),borderRadius:BorderRadius.all(Radius.circular(17))),child:SizedBox(width:53,height:53,child:Icon(Icons.bolt_rounded,color:AppColors.sun,size:29))),SizedBox(width:13),
 Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Prime é chegar antes.',style:TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w900)),SizedBox(height:3),Text('Uma experiência desenhada para não interromper seu momento.',style:TextStyle(color:Colors.white60,fontSize:10,height:1.35,fontWeight:FontWeight.w600))])),Icon(Icons.arrow_forward_rounded,color:Colors.white),
]));}
