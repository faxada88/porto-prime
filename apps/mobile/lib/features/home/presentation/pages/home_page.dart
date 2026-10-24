import '../../../../core/localization/prime_localization.dart';
import '../../../../core/widgets/product_showcase.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../../categories/presentation/pages/all_categories_page.dart';
import '../../../../core/state/customer_activity.dart';
import '../../../../core/widgets/customer_activity_page.dart';
import '../../../addresses/presentation/widgets/delivery_address_sheet.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/prime_reference_home.dart';
import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';

/// One catalogue and one visual rhythm. Existing state and actions are retained.
class HomePage extends StatelessWidget {
 const HomePage({super.key});
 Widget _section(Widget child,{double top=16,double bottom=0})=>SliverToBoxAdapter(
  child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:AppControl.maxContentWidth),
   child:Padding(padding:EdgeInsets.fromLTRB(14,top,14,bottom),child:child))));

 @override Widget build(BuildContext context)=>ColoredBox(
  color:ReferenceHomeTokens.canvas,
  child:SafeArea(bottom:false,child:AnimatedBuilder(
   animation:Listenable.merge([AppState.instance,AppLanguage.instance]),
   builder:(context,_){
    final state=AppState.instance;
    final products=state.products.where((p)=>p['featuredHome']==true&&p['active']!=false&&p['archived']!=true&&(int.tryParse('${p["stock"]}')??0)>0).toList();
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
         const PrimeText('Loja fechada no momento',style:TextStyle(fontWeight:FontWeight.w800,color:AppColors.warning)),
         const SizedBox(height:6),PrimeText(state.storeMessage.replaceAll('Sua sacola','Seu carrinho').replaceAll('sua sacola','seu carrinho'),style:const TextStyle(color:AppColors.warning,height:1.5)),
        ]))),
      _section(AnimatedBuilder(animation:CustomerActivity.instance,builder:(context,_)=>ReferenceHomeHeader(address:address,region:region,cartCount:state.cartCount,
       greeting:'${DateTime.now().hour<12?'Bom dia':DateTime.now().hour<18?'Boa tarde':'Boa noite'}${state.user?['name']==null?'':', ${state.user!['name'].toString().trim().split(' ').first}'}',notificationCount:CustomerActivity.instance.unread,
       onAddress:(){if(state.isCustomer){showDeliveryAddressSheet(context);}else{AppNav.instance.go(3);}},onCart:()=>AppNav.instance.go(2),onProfile:(){if(!state.isCustomer){AppNav.instance.go(3);return;}Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const CustomerActivityPage()));})),top:12),
      _section(ReferenceHomeSearch(onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const AllCategoriesPage())))),
      if(categories.isNotEmpty)_section(_HomeCategories(categories:categories),top:12),
      _section(const ReferenceCoastHero(),top:14),
      if(products.isNotEmpty)...[
       _section(ProductShowcase(products:products),top:20),
      ],
      const SliverToBoxAdapter(child:SizedBox(height:28)),
     ]));
   })));
}

class _HomeCategories extends StatelessWidget {
 const _HomeCategories({required this.categories});
 final List<dynamic> categories;
 @override Widget build(BuildContext context){
  final visible=categories.take(9).toList();
  final scale=MediaQuery.textScalerOf(context);
  Widget row(List<dynamic> entries) => LayoutBuilder(builder:(context,box){
   final cellWidth=(box.maxWidth-(entries.length-1)*8)/entries.length;
   final height=cellWidth*.78+scale.scale(11)*2.5+6;
   return SizedBox(height:height,child:Row(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    for(var i=0;i<entries.length;i++)...[
     if(i>0)const SizedBox(width:8),
     Expanded(child:ReferenceCategoryTile(name:'${entries[i]['name']}',iconKey:entries[i]['iconKey']?.toString(),
      selected:AppState.instance.catalogCategory==entries[i]['name'],
      onTap:()=>openProductCatalogue(context,category:'${entries[i]['name']}'))),
    ],
   ]));
  });
  return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   row(visible.take(4).toList()),
   if(visible.length>4)...[const SizedBox(height:12),row(visible.skip(4).toList())],
   if(categories.length>9)Align(alignment:Alignment.centerRight,child:TextButton(
    onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const AllCategoriesPage())),
    child:const PrimeText('Ver todas'))),
  ]);
 }
}
