import '../../../../core/localization/prime_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_product_card.dart';
import '../../../../core/widgets/prime_ui.dart';

Future<void> openProductCatalogue(BuildContext context,{String category='Todos'})async{
 AppState.instance.selectCatalogCategory(category);
 await Navigator.of(context).push<void>(MaterialPageRoute(builder:(_)=>Scaffold(
  backgroundColor:AppColors.canvas,
  appBar:AppBar(title:PrimeText(category=='Todos'?'Produtos':category)),
  body:CategoriesPage(categoryName:category=='Todos'?null:category),
 )));
}

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key,this.categoryName});
  final String? categoryName;

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: AnimatedBuilder(
      animation: AppState.instance,
      builder: (_, __) {
        final state = AppState.instance;
        final products = state.products;
        final categories = _categories(state.catalogCategories);
        final query = search.text.trim().toLowerCase();
        final selected = widget.categoryName??state.catalogCategory;
        final scoped=widget.categoryName!=null;

        final filtered = products.where((product) {
          final name = (product['name'] ?? '').toString().toLowerCase();
          final description = (product['description'] ?? '')
              .toString()
              .toLowerCase();
          final category = (product['category']?['name'] ?? '').toString();
          final categoryMatches = selected == 'Todos' || category == selected;
          final searchMatches =
              query.isEmpty ||
              name.contains(query) ||
              description.contains(query) ||
              category.toLowerCase().contains(query);
          return categoryMatches && searchMatches;
        }).toList();

        return RefreshIndicator(
          onRefresh: state.loadProducts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                        PrimeText(scoped?'Explore $selected':'Buscar',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800,letterSpacing:-.8,color:AppColors.ink)),
                        SizedBox(height:7),PrimeText(scoped?'Escolha seus produtos e adicione ao carrinho.':'Encontre o que você precisa.',style:TextStyle(fontSize:13,height:1.5,color:AppColors.muted)),
                      ]),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: TextField(
                        controller:search,onChanged:(_)=>setState((){}),
                        textInputAction:TextInputAction.search,
                        onSubmitted:(_)=>FocusScope.of(context).unfocus(),
                        decoration:PrimeInputDecoration(
                          hintText:scoped?'Buscar em $selected':'Produto ou categoria',prefixIcon:const Icon(AppIcons.search,size:21),
                          suffixIcon:search.text.isEmpty?null:IconButton(tooltip: translateLabel('Limpar busca'),
                            icon:const Icon(Icons.close_rounded,size:20),onPressed:(){search.clear();setState((){});}),
                          filled:true,fillColor:AppColors.surface,
                          contentPadding:const EdgeInsets.symmetric(horizontal:18,vertical:18),
                          border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:const BorderSide(color:AppColors.stroke)),
                          enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:const BorderSide(color:AppColors.stroke)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if(!scoped)
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20,16,20,0),
                      child: _CategoryGrid(
                        categories: categories,
                        selected: selected,
                        onSelect: state.selectCatalogCategory,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppControl.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                          PrimeText(query.isEmpty?(scoped||selected=='Todos'?'Produtos':selected):'Resultados da busca',
                            style:const TextStyle(fontSize:20,height:1.3,fontWeight:FontWeight.w800,color:AppColors.ink)),
                          const SizedBox(height:5),
                          PrimeText('${filtered.length} ${filtered.length==1?'produto':'produtos'}',
                            style:const TextStyle(fontSize:12,color:AppColors.muted)),
                        ])),
                        if(query.isNotEmpty||(!scoped&&selected!='Todos'))TextButton(onPressed:(){
                          search.clear();if(!scoped)state.selectCatalogCategory('Todos');setState((){});
                        },child:PrimeText(scoped?'Limpar busca':'Limpar filtros')),
                      ]),
                    ),
                  ),
                ),
              ),
              if (state.products.isEmpty&&!scoped)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _CatalogSkeleton(),
                  ),
                )
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: PrimeEmptyState(
                          icon: AppIcons.search,
                          title: 'Nada por aqui',
                          message:
                              scoped?'Nenhum produto encontrado nesta categoria. Tente outro termo ou volte para explorar outras categorias.':'Tente outro termo ou escolha uma categoria diferente.',
                          actionLabel: scoped?'Limpar busca':'Limpar filtros',
                          onAction: () {
                            search.clear();
                            if(!scoped)state.selectCatalogCategory('Todos');
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverLayoutBuilder(
                    builder: (_, constraints) {
                      final width = constraints.crossAxisExtent;
                      final columns = AppResponsive.productColumns(width);
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => PrimeProductCard(product: filtered[i],referenceStyle:true),
                          childCount: filtered.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: (width-(columns-1)*12)/columns+112+(MediaQuery.textScalerOf(context).scale(14)-14).clamp(0,32)*10,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );

  List<String> _categories(List<dynamic> categories) {
    final names = <String>['Todos'];
    for (final category in categories) {
      final value = (category['name'] ?? '').toString().trim();
      if (value.isNotEmpty && !names.contains(value)) names.add(value);
    }
    return names;
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context)=>SingleChildScrollView(
    scrollDirection:Axis.horizontal,
    child:Row(children:[for(final category in categories)Padding(
      padding:const EdgeInsets.only(right:8),
      child:ChoiceChip(
        label:PrimeText(category),selected:selected==category,
        onSelected:(_)=>onSelect(category),
        showCheckmark:false,
        selectedColor:AppColors.ocean100,backgroundColor:AppColors.surface,
        labelStyle:TextStyle(fontSize:13,fontWeight:selected==category?FontWeight.w700:FontWeight.w500,
          color:selected==category?AppColors.ocean700:AppColors.inkSoft),
        side:BorderSide(color:selected==category?AppColors.ocean300:AppColors.stroke),
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),
        padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),
      ),
    )]),
  );
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final columns = constraints.maxWidth >= 520 ? 3 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: AppResponsive.productHeight(
            context,
            (constraints.maxWidth - (columns - 1) * 12) / columns,
          ),
        ),
        itemBuilder: (_, __) =>
            const PrimeSkeleton(height: 260, radius: AppRadius.lg),
      );
    },
  );
}

