import 'package:flutter/material.dart';
import '../../../../core/widgets/prime_reference_home.dart';
import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_product_card.dart';
import '../../../../core/widgets/prime_ui.dart';

/// One catalogue and one visual rhythm. Existing state and actions are retained.
class HomePage extends StatelessWidget {
 const HomePage({super.key});
 Widget _section(Widget child,{double top=16,double bottom=0})=>SliverToBoxAdapter(
  child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:AppControl.maxContentWidth),
   child:Padding(padding:EdgeInsets.fromLTRB(18,top,18,bottom),child:child))));

 @override Widget build(BuildContext context)=>ColoredBox(
  color:ReferenceHomeTokens.canvas,
  child:SafeArea(bottom:false,child:AnimatedBuilder(
   animation:AppState.instance,
   builder:(context,_){
    final state=AppState.instance;
    final products=state.products;
    final categories=state.catalogCategories.where((item)=>(item['name']??'').toString().trim().isNotEmpty).toList();
    String address='Porto Seguro',region='Bahia';
    if(state.isCustomer&&state.addresses.isNotEmpty){
     final selected=state.addresses.firstWhere((a)=>a['isDefault']==true,orElse:()=>state.addresses.first);
     final street=(selected['street']??'').toString(),number=(selected['number']??'').toString();
     if(street.isNotEmpty)address=number.isEmpty?street:'$street, $number';
     region=[if((selected['neighborhood']??'').toString().isNotEmpty)selected['neighborhood'].toString(),(selected['city']??'Porto Seguro').toString()].join(' • ');
    }
    return RefreshIndicator(onRefresh:state.loadProducts,child:CustomScrollView(
     physics:const AlwaysScrollableScrollPhysics(),slivers:[
      if(state.storeStatusKnown&&!state.storeOpen)_section(
       Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.sand100,borderRadius:BorderRadius.circular(16)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
         const Text('Loja fechada no momento',style:TextStyle(fontWeight:FontWeight.w800,color:AppColors.warning)),
         const SizedBox(height:6),Text(state.storeMessage.replaceAll('Sua sacola','Seu carrinho').replaceAll('sua sacola','seu carrinho'),style:const TextStyle(color:AppColors.warning,height:1.5)),
        ]))),
      _section(ReferenceHomeHeader(address:address,region:region,cartCount:state.cartCount,
       onAddress:()=>AppNav.instance.go(3),onCart:()=>AppNav.instance.go(2),onProfile:()=>AppNav.instance.go(3)),top:12),
      _section(ReferenceHomeSearch(onTap:()=>AppNav.instance.go(1))),
      if(categories.isNotEmpty)_section(_HomeCategories(categories:categories),top:12),
      _section(ReferenceCoastHero(onTap:()=>AppNav.instance.go(1)),top:14),
      _section(PrimeSectionHeader(title:'Escolha seus favoritos',actionLabel:'Ver tudo',onAction:()=>AppNav.instance.go(1)),top:24,bottom:12),
      SliverLayoutBuilder(builder:(context,viewport){
       final width=viewport.crossAxisExtent;
       final content=width.clamp(0.0,AppControl.maxContentWidth).toDouble();
       final horizontal=(width-content)/2+18;
       final columns=content>=950?4:content>=620?3:2;
       final cardWidth=(content-36-(columns-1)*12)/columns;
       final extra=(MediaQuery.textScalerOf(context).scale(14)-14).clamp(0,32).toDouble();
       return SliverPadding(padding:EdgeInsets.symmetric(horizontal:horizontal),sliver:SliverGrid(
        gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,crossAxisSpacing:12,mainAxisSpacing:14,mainAxisExtent:cardWidth+112+extra*10),
        delegate:SliverChildBuilderDelegate((context,index)=>products.isEmpty
         ? const PrimeSkeleton(height:260,radius:22)
         : PrimeProductCard(product:products[index],referenceStyle:true),
         childCount:products.isEmpty?4:products.length),
       ));
      }),
      const SliverToBoxAdapter(child:SizedBox(height:130)),
     ]));
   })));
}

class _HomeCategories extends StatelessWidget {
 const _HomeCategories({required this.categories});
 final List<dynamic> categories;
 @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[

  SizedBox(height:64+MediaQuery.textScalerOf(context).scale(10.5)*2.4,child:ListView.separated(
   scrollDirection:Axis.horizontal,itemCount:categories.length,
   separatorBuilder:(_,__)=>const SizedBox(width:10),
   itemBuilder:(context,index){
    final category=categories[index],name=(category['name']??'').toString().trim();
    return SizedBox(width:82,child:ReferenceCategoryTile(name:name,iconKey:category['iconKey']?.toString(),
     selected:AppState.instance.catalogCategory==name,onTap:(){
      AppState.instance.selectCatalogCategory(name);AppNav.instance.go(1);
     }));
   })),
 ]);
}
