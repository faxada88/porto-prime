import '../../../../core/localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import 'categories_page.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_reference_home.dart';
class AllCategoriesPage extends StatefulWidget{
 const AllCategoriesPage({super.key});
 @override State<AllCategoriesPage> createState()=>_AllCategoriesState();
}
class _AllCategoriesState extends State<AllCategoriesPage>{
 String query='';
 @override Widget build(BuildContext context)=>AnimatedBuilder(animation:AppState.instance,builder:(context,_){
  final categories=AppState.instance.catalogCategories.where((e)=>'${e['name']??''}'.trim().isNotEmpty&&'${e['name']}'.toLowerCase().contains(query.toLowerCase())).toList();
  return Scaffold(backgroundColor:AppColors.canvas,appBar:AppBar(title:const PrimeText('Todas as categorias')),
   body:CustomScrollView(slivers:[
    SliverPadding(padding:const EdgeInsets.all(20),sliver:SliverToBoxAdapter(child:TextField(
     onChanged:(value)=>setState(()=>query=value),decoration:const PrimeInputDecoration(hintText:'Encontrar categoria',prefixIcon:Icon(Icons.search_rounded))))),
    if(categories.isEmpty)const SliverToBoxAdapter(child:Padding(padding:EdgeInsets.all(24),child:PrimeText('Nenhuma categoria encontrada.',textAlign:TextAlign.center))),
    SliverPadding(padding:const EdgeInsets.fromLTRB(20,0,20,28),sliver:SliverLayoutBuilder(builder:(context,box){
     final columns=box.crossAxisExtent>=700?6:box.crossAxisExtent>=480?4:3;
     return SliverGrid(gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,crossAxisSpacing:10,mainAxisSpacing:14,
      mainAxisExtent:80+MediaQuery.textScalerOf(context).scale(12)*3),
      delegate:SliverChildBuilderDelegate((context,i){final c=categories[i];return ReferenceCategoryTile(
       name:'${c['name']}',iconKey:c['iconKey']?.toString(),selected:false,onTap:(){
        openProductCatalogue(context,category:'${c['name']}');
       });},childCount:categories.length));
    })),
   ]));
 });
}
