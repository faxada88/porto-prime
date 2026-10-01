import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  static const data = [
    ('Cervejas','Geladas, packs e especiais',Icons.sports_bar_rounded,Color(0xFFFFE3A3)),
    ('Whiskies','Clássicos & premium',Icons.liquor_rounded,Color(0xFFFFD8C5)),
    ('Gin & Vodka','Para drinks perfeitos',Icons.local_bar_rounded,Color(0xFFD9F3ED)),
    ('Vinhos','Brancos, tintos & rosés',Icons.wine_bar_rounded,Color(0xFFFFDEE5)),
    ('Sem álcool','Refresque sem álcool',Icons.local_drink_rounded,Color(0xFFDDEEFF)),
    ('Gelo & extras','Tudo para não parar',Icons.ac_unit_rounded,Color(0xFFE9E4FF)),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(bottom:false, child: CustomScrollView(
    physics: const BouncingScrollPhysics(),
    slivers:[
      SliverPadding(padding:const EdgeInsets.fromLTRB(20,22,20,8),sliver:SliverToBoxAdapter(child:Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Descobrir',style:Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height:5),const Text('Seu clima, sua bebida.',style:TextStyle(color:AppColors.muted,fontWeight:FontWeight.w600)),
        ])),
        Container(width:46,height:46,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.search_rounded)),
      ]))),
      const SliverPadding(padding:EdgeInsets.fromLTRB(20,14,20,18),sliver:SliverToBoxAdapter(child:_Occasions())),
      SliverPadding(padding:const EdgeInsets.symmetric(horizontal:20),sliver:SliverGrid(
        delegate:SliverChildBuilderDelegate((_,i)=>_Category(data:data[i]),childCount:data.length),
        gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:.94),
      )),
      const SliverToBoxAdapter(child:SizedBox(height:120)),
    ],
  ));
}

class _Occasions extends StatelessWidget {
  const _Occasions();
  @override Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(20),
    decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF007C70),Color(0xFF12B5A3)]),borderRadius:BorderRadius.circular(28)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('COMBINA COM HOJE',style:TextStyle(color:Color(0xFFCFF8F0),fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1)),
      const SizedBox(height:8),const Text('Qual é o seu rolê?',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900,letterSpacing:-.6)),
      const SizedBox(height:16),Wrap(spacing:8,runSpacing:8,children:[
        _chip('Praia',Icons.beach_access_rounded),_chip('Churrasco',Icons.outdoor_grill_rounded),_chip('Festa',Icons.celebration_rounded),_chip('Relax',Icons.nights_stay_rounded),
      ]),
    ]),
  );
  Widget _chip(String s,IconData i)=>Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.14),borderRadius:BorderRadius.circular(14)),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(i,color:Colors.white,size:16),const SizedBox(width:6),Text(s,style:const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.w800))]));
}

class _Category extends StatelessWidget {
  const _Category({required this.data}); final (String,String,IconData,Color) data;
  @override Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(15),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(25),border:Border.all(color:const Color(0xFFE9ECE7))),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Expanded(child:Container(width:double.infinity,decoration:BoxDecoration(color:data.$4,borderRadius:BorderRadius.circular(20)),child:Icon(data.$3,size:48,color:AppColors.ink))),
      const SizedBox(height:12),Text(data.$1,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w900)),
      const SizedBox(height:2),Text(data.$2,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:AppColors.muted,fontWeight:FontWeight.w600)),
    ]),
  );
}
