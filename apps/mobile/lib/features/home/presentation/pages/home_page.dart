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
   child:Padding(padding:EdgeInsets.fromLTRB(18,top,18,bottom),child:child))));

 @override Widget build(BuildContext context)=>ColoredBox(
  color:ReferenceHomeTokens.canvas,
  child:SafeArea(bottom:false,child:AnimatedBuilder(
   animation:AppState.instance,
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
       _section(ProductShowcase(products:products),top:24),
      ],
      const SliverToBoxAdapter(child:SizedBox(height:28)),
     ]));
   })));
}

class _HomeCategories extends StatelessWidget {
 const _HomeCategories({required this.categories});
 final List<dynamic> categories;
 @override Widget build(BuildContext context){
  final visible=categories.take(8).toList();
  final height=68+MediaQuery.textScalerOf(context).scale(10.5)*2.4;
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[
    const Expanded(child:PrimeText('Categorias',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:AppColors.ink))),
    TextButton(onPressed:(){
     Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const AllCategoriesPage()));
    },child:const PrimeText('Ver todas')),
   ]),
   const SizedBox(height:4),
   GridView.builder(
    padding:EdgeInsets.zero,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
    itemCount:visible.length,
    gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
     crossAxisCount:4,crossAxisSpacing:6,mainAxisSpacing:10,mainAxisExtent:height),
    itemBuilder:(context,index){
     final category=visible[index],name=(category['name']??'').toString().trim();
     return ReferenceCategoryTile(name:name,iconKey:category['iconKey']?.toString(),
      selected:AppState.instance.catalogCategory==name,onTap:(){
       openProductCatalogue(context,category:name);
      });
    }),
  ]);
 }
}
