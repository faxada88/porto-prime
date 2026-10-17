import 'package:flutter/material.dart';
import '../../../../core/widgets/prime_reference_home.dart';
import '../../../../core/widgets/prime_moment_card.dart';
import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_product_card.dart';
import '../../../../core/widgets/prime_ui.dart';

class HomePage extends StatelessWidget {
 const HomePage({super.key});
 Widget _section(Widget child,{EdgeInsets padding=const EdgeInsets.symmetric(horizontal:18)})=>SliverToBoxAdapter(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:AppControl.maxContentWidth),child:Padding(padding:padding,child:child))));
 @override Widget build(BuildContext context)=>ColoredBox(color:ReferenceHomeTokens.canvas,child:SafeArea(bottom:false,child:AnimatedBuilder(animation:AppState.instance,builder:(context,_){
  final state=AppState.instance;
  final products=state.products;
  final categories=state.catalogCategories.map((category)=>(category['name']??'').toString().trim()).where((name)=>name.isNotEmpty).take(10).toList();
  final featured=products.take(8).toList();
  final recommended=products.length>4?products.skip(4).take(8).toList():products;
  String address='Porto Seguro',region='Porto Seguro, BA';
  if(state.isCustomer&&state.addresses.isNotEmpty){
   final selected=state.addresses.firstWhere((a)=>a['isDefault']==true,orElse:()=>state.addresses.first);
   final street=(selected['street']??'').toString(),number=(selected['number']??'').toString();
   if(street.isNotEmpty)address=number.isEmpty?street:'$street, $number';
   region=[if((selected['neighborhood']??'').toString().isNotEmpty)selected['neighborhood'].toString(),(selected['city']??'Porto Seguro').toString(),(selected['state']??'BA').toString()].join(' • ');
  }
  return RefreshIndicator(onRefresh:state.loadProducts,child:CustomScrollView(physics:const AlwaysScrollableScrollPhysics(parent:BouncingScrollPhysics()),slivers:[
   if(state.storeStatusKnown&&!state.storeOpen)_section(Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.sand100,borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Loja fechada no momento',style:TextStyle(fontWeight:FontWeight.w800,color:AppColors.warning)),const SizedBox(height:6),Text(state.storeMessage.replaceAll('Sua sacola','Seu carrinho').replaceAll('sua sacola','seu carrinho'),style:const TextStyle(color:AppColors.warning,height:1.5))])),padding:const EdgeInsets.fromLTRB(18,12,18,0)),
   _section(ReferenceHomeHeader(address:address,region:region,cartCount:state.cartCount,onAddress:()=>AppNav.instance.go(3),onCart:()=>AppNav.instance.go(2),onProfile:()=>AppNav.instance.go(3)),padding:const EdgeInsets.fromLTRB(18,12,18,0)),
   _section(ReferenceHomeSearch(onTap:()=>AppNav.instance.go(1)),padding:const EdgeInsets.fromLTRB(18,16,18,0)),
   _section(_ReferenceCategories(categories:categories),padding:const EdgeInsets.fromLTRB(18,12,18,0)),
   _section(ReferenceCoastHero(onTap:()=>AppNav.instance.go(1)),padding:const EdgeInsets.fromLTRB(18,14,18,0)),
   _section(PrimeSectionHeader(title:'Em destaque',actionLabel:'Ver tudo',onAction:()=>AppNav.instance.go(1)),padding:const EdgeInsets.fromLTRB(18,22,18,10)),
   SliverToBoxAdapter(child:_HorizontalProducts(products:featured,loading:products.isEmpty)),
   _section(const PrimeSectionHeader(title:'Para o seu momento',subtitle:'Encontre a combinação para o seu dia.'),padding:const EdgeInsets.fromLTRB(18,26,18,10)),
   const SliverToBoxAdapter(child:_Moments()),
   if(products.length>8) _section(const PrimeSectionHeader(title:'Continue explorando'),padding:const EdgeInsets.fromLTRB(18,26,18,10)),
   if(products.length>8) SliverToBoxAdapter(child:_HorizontalProducts(products:recommended,loading:products.isEmpty)),
   _section(_PrimePromise(onTap:()=>AppNav.instance.go(1)),padding:const EdgeInsets.fromLTRB(18,26,18,140)),
  ]));
 })));
}
class _ReferenceCategories extends StatelessWidget {
 const _ReferenceCategories({required this.categories});final List<String> categories;
 @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,box){
  final labelHeight=MediaQuery.textScalerOf(context).scale(10.5)*2.4;
  final height=66+labelHeight;
  Widget tile(int index){final name=categories[index];final category=AppState.instance.catalogCategories.firstWhere((item)=>item['name']==name,orElse:()=> <String,dynamic>{});return ReferenceCategoryTile(name:name,iconKey:category['iconKey']?.toString(),selected:AppState.instance.catalogCategory==name,onTap:(){AppState.instance.selectCatalogCategory(name);AppNav.instance.go(1);});}
  if(categories.isEmpty)return const SizedBox.shrink();
  if(box.maxWidth>=700)return GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),padding:EdgeInsets.zero,itemCount:categories.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:5,mainAxisExtent:height,crossAxisSpacing:10,mainAxisSpacing:10),itemBuilder:(_,i)=>tile(i));
  return SizedBox(height:height,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:categories.length,padding:const EdgeInsets.symmetric(vertical:3),separatorBuilder:(_,__)=>const SizedBox(width:7),itemBuilder:(_,i)=>SizedBox(width:box.maxWidth<340?76:82,child:tile(i))));
 });
}

class _HorizontalProducts extends StatefulWidget {
  const _HorizontalProducts({required this.products, required this.loading});
  final List<dynamic> products;
  final bool loading;
  @override
  State<_HorizontalProducts> createState() => _HorizontalProductsState();
}

class _HorizontalProductsState extends State<_HorizontalProducts> {
  final _scroll = ScrollController();
  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  void _move(double amount) {
    if (!_scroll.hasClients) return;
    final destination = (_scroll.offset + amount).clamp(0.0, _scroll.position.maxScrollExtent).toDouble();
    final duration = AppMotion.resolve(context, AppMotion.standard);
    if (duration == Duration.zero) { _scroll.jumpTo(destination); }
    else { _scroll.animateTo(destination, duration: duration, curve: AppMotion.curve); }
  }

  @override
  Widget build(BuildContext context) => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: AppControl.maxContentWidth),
    child: LayoutBuilder(builder: (context, box) {
      final cardWidth = ((box.maxWidth - 48) / 2).clamp(148.0, 210.0).toDouble();
      final height = cardWidth + 100 + (MediaQuery.textScalerOf(context).scale(14)-14).clamp(0,32).toDouble()*10;
      final count = widget.loading ? 4 : widget.products.length;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(height: height, child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
          scrollDirection: Axis.horizontal,
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(width: cardWidth,
            child: widget.loading ? const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              PrimeSkeleton(height: 170, radius: AppRadius.lg), SizedBox(height: 10),
              PrimeSkeleton(height: 16), SizedBox(height: 7), PrimeSkeleton(height: 14, width: 110),
            ]) : PrimeProductCard(product: widget.products[i], referenceStyle:true)),
        )),
        if (!widget.loading && count > 0)
          AnimatedBuilder(animation: _scroll, builder: (context, _) {
            final attached = _scroll.hasClients && _scroll.position.hasContentDimensions;
            final extent = attached ? _scroll.position.maxScrollExtent : 0.0;
            final offset = attached ? _scroll.offset.clamp(0.0, extent).toDouble() : 0.0;
            // Also works before the first layout, when ScrollPosition has no metrics.
            final estimatedExtent = (count * (cardWidth + 12) + 28 - box.maxWidth).clamp(0.0, double.infinity);
            final canNext = attached ? offset < extent - 1 : estimatedExtent > 0;
            return Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$count opções para explorar', style: const TextStyle(fontSize: 11,
                    color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 7),
                  SizedBox(width: 100, child: LinearProgressIndicator(
                    value: extent > 0 ? ((offset + box.maxWidth) / (extent + box.maxWidth)).clamp(0.0, 1.0).toDouble() : canNext ? .25 : 1,
                    minHeight: 3, borderRadius: BorderRadius.circular(8),
                    backgroundColor: AppColors.stroke, color: AppColors.ocean700)),
                ])),
                IconButton(tooltip: 'Produtos anteriores',
                  onPressed: offset > 1 ? () => _move(-(cardWidth + 12)) : null,
                  style: IconButton.styleFrom(backgroundColor: AppColors.surface, foregroundColor: AppColors.ocean900),
                  icon: const Icon(AppIcons.arrowLeft, size: 19)),
                const SizedBox(width: 6),
                IconButton(tooltip: 'Próximos produtos',
                  onPressed: canNext ? () => _move(cardWidth + 12) : null,
                  style: IconButton.styleFrom(backgroundColor: AppColors.ocean900, foregroundColor: AppColors.sun500),
                  icon: const Icon(AppIcons.arrowRight, size: 19)),
              ]));
          }),
      ]);
    }),
  ));
}

class _Moments extends StatelessWidget {
  const _Moments();
  @override
  Widget build(BuildContext context) => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: AppControl.maxContentWidth),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth >= 850;
        Widget card(int scene, String title, String subtitle) => PrimeMomentCard(
          scene: scene, title: title, subtitle: subtitle,
          onTap: () => AppNav.instance.go(1));
        final cards = [card(0, 'Pé na areia', 'Bebidas e conveniência para curtir a praia.'),
          card(1, 'Churrasco', 'Encontre bebidas e acompanhamentos.'),
          card(2, 'Fim de tarde', 'Explore vinhos e destilados sem pressa.')];
        if (wide) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12), Expanded(child: cards[i]),
          ],
        ]);
        return Column(children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 10), cards[i],
          ],
        ]);
      })),
  ));
}

class _PrimePromise extends StatelessWidget {
  const _PrimePromise({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Ink(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.ocean50,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(
                AppIcons.sparkles,
                color: AppColors.ocean700,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Porto Prime, do seu jeito.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Catálogo simples, pagamento seguro e acompanhamento do pedido em tempo real.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              AppIcons.chevronRight,
              color: AppColors.ocean700,
              size: 19,
            ),
          ],
        ),
      ),
    ),
  );
}

