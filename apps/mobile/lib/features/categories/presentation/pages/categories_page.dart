import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/catalogue_cart_shortcut.dart';
import '../../../../core/widgets/home_reference_artwork.dart';
import '../../../../core/widgets/prime_product_card.dart';

Future<void> openProductCatalogue(BuildContext context,{required String category})async{
 AppState.instance.selectCatalogCategory(category);
 await Navigator.of(context).push<void>(MaterialPageRoute(builder:(_)=>Scaffold(
  backgroundColor:const Color(0xFFF5F9FA),body:CategoriesPage(categoryName:category))));
}

String _fold(String value){
 var text=value.toLowerCase();
 const accents={'á':'a','à':'a','â':'a','ã':'a','ä':'a','é':'e','ê':'e','è':'e',
  'í':'i','î':'i','ó':'o','ô':'o','õ':'o','ö':'o','ú':'u','ü':'u','ç':'c','ñ':'n'};
 for(final entry in accents.entries){text=text.replaceAll(entry.key,entry.value);}
 return text;
}
String _searchable(dynamic p)=>_fold('${p['name']??''} ${p['description']??''} ${p['brand']??''}');
double _price(dynamic p)=>double.tryParse('${p['price']}')??0;
bool _sale(dynamic p)=>(double.tryParse('${p['oldPrice']??p['compareAtPrice']}')??0)>_price(p);

class _Facet{
 const _Facet(this.label,this.terms);
 final String label;final List<String> terms;
 bool matches(dynamic p)=>terms.any((term)=>_searchable(p).contains(_fold(term)));
}
const _facets=<String,List<_Facet>>{
 'beer':[_Facet('Long Neck',['long neck','longneck']),_Facet('Lata',['lata','latinha']),
  _Facet('Garrafa',['garrafa','600 ml','600ml','1 litro']),_Facet('Artesanais',['artesanal','artesanais','craft']),
  _Facet('Sem álcool',['sem alcool','zero alcool','0.0'])],
 'barbecue':[_Facet('Bovina',['picanha','bovina','alcatra','fraldinha','contrafile','costela']),
  _Facet('Frango',['frango','galinha','ave']),_Facet('Suína',['suina','suino','porco','linguica']),_Facet('Kits',['kit','combo'])],
 'fitness':[_Facet('Proteínas',['whey','proteina']),_Facet('Creatina',['creatina']),_Facet('Pré-treino',['pre treino','pre-treino']),_Facet('Barras',['barra'])],
 'wine':[_Facet('Tintos',['tinto','cabernet','malbec','merlot']),_Facet('Brancos',['branco','chardonnay','sauvignon']),
  _Facet('Rosés',['rose']),_Facet('Espumantes',['espumante','champagne','prosecco'])],
 'energy':[_Facet('Lata',['lata','250ml','250 ml','473ml','473 ml']),_Facet('Sem açúcar',['sem acucar','zero','sugarfree'])],
 'ice':[_Facet('Cubos',['cubo']),_Facet('Escamas',['escama'])],
 'spirits':[_Facet('Whisky',['whisky','whiskey']),_Facet('Vodka',['vodka']),_Facet('Gin',['gin']),
  _Facet('Rum',['rum']),_Facet('Tequila',['tequila'])],
 'snacks':[_Facet('Hambúrgueres',['hamburguer','burger']),_Facet('Sanduíches',['sanduiche']),_Facet('Combos',['combo'])],
};
const _sortLabels={'recommended':'Recomendados','priceAsc':'Menor preço','priceDesc':'Maior preço','name':'Nome: A–Z'};
const _headlines=<String,String>{
 'beer':'Nossas cervejas','barbecue':'Cortes para o seu churrasco','fitness':'Sua rotina, seu ritmo',
 'wine':'Nossa seleção de vinhos','energy':'Energia para acompanhar você','ice':'Gelo no ponto',
 'spirits':'Nossa seleção de destilados','offers':'Ofertas para aproveitar','snacks':'Hora de matar a fome',
};
class CategoriesPage extends StatefulWidget{
 const CategoriesPage({super.key,required this.categoryName});
 final String categoryName;
 @override State<CategoriesPage> createState()=>_CategoriesPageState();
}
class _CategoriesPageState extends State<CategoriesPage>{
 final search=TextEditingController();
 String? facet;String sort='recommended';
 bool stockOnly=false,saleOnly=false;
 @override void dispose(){search.dispose();super.dispose();}
 Future<void> filters()async{
  var available=stockOnly,offers=saleOnly;
  final result=await showModalBottomSheet<Map<String,bool>>(context:context,isScrollControlled:true,
   backgroundColor:Colors.white,shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(28))),
   builder:(context)=>StatefulBuilder(builder:(context,update)=>SafeArea(child:SingleChildScrollView(
    padding:const EdgeInsets.all(22),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     const PrimeText('Filtrar produtos',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:Color(0xFF003D47))),
     const SizedBox(height:16),
     CheckboxListTile(contentPadding:EdgeInsets.zero,title:const PrimeText('Em estoque'),value:available,
      onChanged:(value)=>update(()=>available=value??false)),
     CheckboxListTile(contentPadding:EdgeInsets.zero,title:const PrimeText('Somente ofertas'),value:offers,
      onChanged:(value)=>update(()=>offers=value??false)),
     const SizedBox(height:16),
     FilledButton(style:FilledButton.styleFrom(backgroundColor:const Color(0xFF003E48),minimumSize:const Size(0,48)),
      onPressed:()=>Navigator.pop(context,{'stock':available,'sale':offers}),child:const PrimeText('Aplicar filtros')),
    ])))));
  if(!mounted||result==null)return;
  setState((){stockOnly=result['stock']??false;saleOnly=result['sale']??false;});
 }
 @override Widget build(BuildContext context)=>AnnotatedRegion<SystemUiOverlayStyle>(
  value:SystemUiOverlayStyle.light,
  child:ColoredBox(color:const Color(0xFFF5F9FA),child:AnimatedBuilder(
   animation:Listenable.merge([AppState.instance,AppLanguage.instance]),builder:(context,_){
    final state=AppState.instance;
    final category=widget.categoryName;
    final matches=state.catalogCategories.where((c)=>c['name']==category);
    final dynamic metadata=matches.isEmpty?<String,dynamic>{}:matches.first;
    final visual=AppIcons.categoryVisual(category,iconKey:metadata['iconKey']?.toString());
    // Every control filters only this category, even if the Home selection changes.
    final scoped=state.products.where((p)=>p['category']?['name']==category&&p['archived']!=true).toList();
    final query=_fold(search.text.trim());
    final options=_facets[visual.key]??const <_Facet>[];
    final selected=options.where((f)=>f.label==facet);
    final products=scoped.where((p)=>(query.isEmpty||_searchable(p).contains(query))&&
     (selected.isEmpty||selected.first.matches(p))&&(!stockOnly||(p['active']!=false&&(int.tryParse('${p['stock']}')??0)>0))&&
     (!saleOnly||_sale(p))).toList();
    final positions=<String,int>{for(var i=0;i<scoped.length;i++)'${scoped[i]['id']}':i};
    products.sort((a,b){
     if(sort=='priceAsc')return _price(a).compareTo(_price(b));
     if(sort=='priceDesc')return _price(b).compareTo(_price(a));
     if(sort=='name')return _fold('${a['name']}').compareTo(_fold('${b['name']}'));
     final recommended=(b['featuredHome']==true?1:0)-(a['featuredHome']==true?1:0);
     return recommended!=0?recommended:(positions['${a['id']}']??0).compareTo(positions['${b['id']}']??0);
    });
    final heroUrl=(metadata['imageUrl']??'').toString().trim();
    final firstPhoto=scoped.where((p)=>(p['imageUrl']??'').toString().trim().isNotEmpty);
    final photo=heroUrl.isNotEmpty?heroUrl:visual.key=='beer'?'':firstPhoto.isEmpty?'':'${firstPhoto.first['imageUrl']}';
    return Column(children:[
     Expanded(child:RefreshIndicator(onRefresh:state.loadProducts,child:CustomScrollView(
      physics:const AlwaysScrollableScrollPhysics(),keyboardDismissBehavior:ScrollViewKeyboardDismissBehavior.onDrag,
      slivers:[
       SliverToBoxAdapter(child:_CategoryHero(name:category,iconKey:visual.key,photo:photo,count:state.cartCount)),
       SliverPadding(padding:const EdgeInsets.fromLTRB(16,16,16,0),sliver:SliverToBoxAdapter(child:Row(children:[
        Expanded(child:TextField(controller:search,onChanged:(_)=>setState((){}),textInputAction:TextInputAction.search,
         onSubmitted:(_)=>FocusScope.of(context).unfocus(),
         decoration:PrimeInputDecoration(hintText:'Buscar em ${AppLanguage.instance.translate(category)}',
          prefixIcon:const Icon(AppIcons.search,size:23,color:Color(0xFF003E48)),
          suffixIcon:query.isEmpty?null:IconButton(tooltip:translateLabel('Limpar busca'),
           onPressed:(){search.clear();setState((){});},icon:const Icon(Icons.close_rounded,size:19)),
          filled:true,fillColor:const Color(0xFFEFF5F7),
          contentPadding:const EdgeInsets.symmetric(horizontal:15,vertical:15),
          border:OutlineInputBorder(borderRadius:BorderRadius.circular(17),borderSide:const BorderSide(color:Color(0xFFDCE8EB))),
          enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(17),borderSide:const BorderSide(color:Color(0xFFDCE8EB)))))),
        const SizedBox(width:9),
        SizedBox(width:48,height:52,child:IconButton.filledTonal(
         tooltip:translateLabel('Filtrar produtos'),onPressed:filters,
         style:IconButton.styleFrom(backgroundColor:stockOnly||saleOnly?const Color(0xFFD6EEEF):const Color(0xFFEFF5F7),
          foregroundColor:const Color(0xFF003E48),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17),
           side:const BorderSide(color:Color(0xFFDCE8EB)))),
         icon:const Icon(AppIcons.filter,size:22))),
       ]))),
       if(options.isNotEmpty)SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(16,14,0,0),
        child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
         for(final option in <_Facet?>[null,...options])Padding(padding:const EdgeInsets.only(right:8),
          child:ChoiceChip(showCheckmark:false,selected:facet==option?.label,
           onSelected:(_)=>setState(()=>facet=option?.label),
           selectedColor:const Color(0xFF003E48),backgroundColor:const Color(0xFFF5F9FA),
           side:BorderSide(color:facet==option?.label?const Color(0xFF003E48):const Color(0xFFDFEAED)),
           shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17)),
           padding:const EdgeInsets.symmetric(horizontal:9,vertical:10),
           label:PrimeText(option?.label??(visual.key=='beer'?'Todas':'Todos'),
            style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:facet==option?.label?Colors.white:const Color(0xFF123F49))))),
        ])))),
       SliverPadding(padding:const EdgeInsets.fromLTRB(16,22,16,14),sliver:SliverToBoxAdapter(child:Row(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
         Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          PrimeText(_headlines[visual.key]??'Produtos selecionados',style:const TextStyle(
           fontSize:18,fontWeight:FontWeight.w800,color:Color(0xFF123F49),height:1.2)),
          const SizedBox(height:4),
          const PrimeText('Escolha sua favorita e aproveite!',style:TextStyle(fontSize:11,color:Color(0xFF839BA5),height:1.35)),
         ])),
         const SizedBox(width:8),
         PopupMenuButton<String>(tooltip:translateLabel('Ordenar produtos'),initialValue:sort,
          onSelected:(value)=>setState(()=>sort=value),
          itemBuilder:(_)=>[
           for(final entry in _sortLabels.entries)
            PopupMenuItem(value:entry.key,child:PrimeText(entry.value)),
          ],
          child:Container(constraints:const BoxConstraints(maxWidth:132),padding:const EdgeInsets.symmetric(horizontal:10,vertical:11),
           decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFDFEAED))),
           child:Row(mainAxisSize:MainAxisSize.min,children:[
            Flexible(child:PrimeText(_sortLabels[sort]!,
             maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:Color(0xFF123F49)))),
            const SizedBox(width:6),const Icon(Icons.keyboard_arrow_down_rounded,size:18,color:Color(0xFF123F49)),
           ]))),
        ]))),
       if(products.isEmpty)SliverFillRemaining(hasScrollBody:false,child:Padding(padding:const EdgeInsets.all(28),
        child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
         Icon(visual.icon,size:36,color:const Color(0xFF406E76)),const SizedBox(height:16),
         const PrimeText('Nada por aqui',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700,color:Color(0xFF123F49))),
         const SizedBox(height:8),const PrimeText('Tente outro termo ou ajuste os filtros.',textAlign:TextAlign.center,
          style:TextStyle(color:AppColors.muted,height:1.4)),
         TextButton(onPressed:(){search.clear();setState((){facet=null;stockOnly=false;saleOnly=false;});},child:const PrimeText('Limpar busca')),
        ])))
       else SliverPadding(padding:const EdgeInsets.fromLTRB(16,0,16,22),sliver:SliverLayoutBuilder(builder:(context,box){
        final scale=MediaQuery.textScalerOf(context).scale(14)/14;
        final columns=scale>1.6&&box.crossAxisExtent<600?1:box.crossAxisExtent>=900?4:box.crossAxisExtent>=600?3:2;
        final width=(box.crossAxisExtent-(columns-1)*12)/columns;
        final brandSpace=products.any((p)=>'${p['brand']??''}'.trim().isNotEmpty)?16:0;
        final ratingSpace=products.any((p)=>(int.tryParse('${p['reviewCount']}')??0)>0)?22:0;
        final oldPriceSpace=products.any(_sale)?14:0;
        final quantitySpace=products.any((p)=>(state.cart['${p['id']}']??0)>0)?32:0;
        final detailsHeight=(146+brandSpace+ratingSpace+oldPriceSpace+quantitySpace)*scale;
        return SliverGrid(gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,
         crossAxisSpacing:12,mainAxisSpacing:14,mainAxisExtent:width/1.35+detailsHeight),
         delegate:SliverChildBuilderDelegate((_,i)=>PrimeProductCard(product:products[i],categoryStyle:true),childCount:products.length));
       })),
      ]))),
     const CatalogueCartShortcut(compact:true),
    ]);
   })));
}

class _CategoryHero extends StatelessWidget{
 const _CategoryHero({required this.name,required this.iconKey,required this.photo,required this.count});
 final String name,iconKey,photo;final int count;
 @override Widget build(BuildContext context){
  final inset=MediaQuery.paddingOf(context).top;
  final scale=MediaQuery.textScalerOf(context).scale(14)/14;
  final source=HomeReferenceArtwork.categories[iconKey];
  return ClipRRect(borderRadius:const BorderRadius.vertical(bottom:Radius.circular(22)),
   child:SizedBox(height:180+inset+(scale-1)*120,child:Stack(fit:StackFit.expand,children:[
    const ColoredBox(color:Color(0xFF003039)),
    if(photo.isNotEmpty)Image.network(photo,fit:BoxFit.cover,cacheWidth:1200,errorBuilder:(_,__,___)=>const SizedBox.shrink())
    else if(iconKey=='beer')Image.asset('assets/reference_home/coast-banner.webp',fit:BoxFit.cover,
     errorBuilder:(_,__,___)=>const SizedBox.shrink())
    else Align(alignment:Alignment.centerRight,child:SizedBox(width:150,height:140,child:source==null?
     Icon(AppIcons.categoryVisual(name,iconKey:iconKey).icon,size:95,color:const Color(0xFF91BCB8)):
     HomeReferenceArtwork(source:source,fallback:const SizedBox.shrink()))),
    const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(
     colors:[Color(0xEF001A20),Color(0xD900252B),Color(0x2200252B)],stops:[0,.48,1]))),
    Padding(padding:EdgeInsets.fromLTRB(16,inset+9,16,16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Row(children:[
      _HeroButton(icon:Icons.arrow_back_rounded,label:'Voltar',onTap:()=>Navigator.of(context).maybePop()),
      const Spacer(),
      Stack(clipBehavior:Clip.none,children:[
       _HeroButton(icon:AppIcons.cart,label:'Ver carrinho',onTap:()=>openCatalogueCart(context)),
       if(count>0)Positioned(top:-3,right:-3,child:Container(padding:const EdgeInsets.all(4),
        constraints:const BoxConstraints(minWidth:18,minHeight:18),alignment:Alignment.center,
        decoration:const BoxDecoration(color:Color(0xFFFC445B),shape:BoxShape.circle),
        child:Text(count>99?'99+':'$count',textScaler:TextScaler.noScaling,style:const TextStyle(
         fontSize:10,fontWeight:FontWeight.w800,color:Colors.white)))),
      ]),
     ]),
     const Spacer(),
     const PrimeText('PORTO PRIME DELIVERY',style:TextStyle(fontSize:8,letterSpacing:1.9,color:Color(0xFFE1E1CD),fontWeight:FontWeight.w600)),
     const SizedBox(height:7),
     PrimeText(name,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(
      fontSize:27,height:1.05,fontWeight:FontWeight.w800,letterSpacing:-.7,color:Colors.white)),
     const SizedBox(height:7),
     SizedBox(width:245,child:PrimeText(iconKey=='beer'?'As melhores marcas, sempre geladas para o seu momento.':'Boas escolhas para o seu momento.',
      maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11.5,height:1.35,color:Colors.white))),
    ])),
   ])));
 }
}
class _HeroButton extends StatelessWidget{
 const _HeroButton({required this.icon,required this.label,required this.onTap});
 final IconData icon;final String label;final VoidCallback onTap;
 @override Widget build(BuildContext context)=>SizedBox(width:40,height:40,child:IconButton(
  tooltip:translateLabel(label),onPressed:onTap,
  style:IconButton.styleFrom(backgroundColor:const Color(0x55FFFFFF),foregroundColor:Colors.white),
  icon:Icon(icon,size:22)));
}
