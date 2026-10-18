import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/widgets/prime_reference_home.dart';
import 'package:porto_prime/core/widgets/prime_bottom_navigation.dart';
import 'package:porto_prime/core/widgets/prime_product_card.dart';
import 'package:porto_prime/core/state/app_state.dart';
import 'package:porto_prime/features/home/presentation/pages/home_page.dart';

// Locate the configured action widget rather than a merged accessibility node.
Finder action(String label) => find.byWidgetPredicate(
 (widget) => widget is Semantics && widget.properties.label == label,
);

void main() {
 for(final width in [320.0,390.0,768.0]) {
  for(final scale in [1.0,1.5,2.0]) {
   testWidgets('Reference Home fits $width / $scale', (tester) async {
    tester.view.devicePixelRatio=1;
    tester.view.physicalSize=Size(width,1100);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme:AppTheme.light,builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale),disableAnimations:true),child:child!),home:Scaffold(
     bottomNavigationBar:PrimeBottomNavigation(index:0,cartCount:12,onSelect:(_){}),
     body:SingleChildScrollView(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      ReferenceHomeHeader(address:'Avenida dos Navegantes, 123',region:'Centro • Porto Seguro, BA',cartCount:12,onAddress:(){},onCart:(){},onProfile:(){}),
      const SizedBox(height:16),ReferenceHomeSearch(onTap:(){}),
      const SizedBox(height:16),SizedBox(height:100+scale*26,child:Row(children:[for(final name in ['Cervejas','Refrigerantes','Conveniência'])Expanded(child:ReferenceCategoryTile(name:name,onTap:(){}))])),
      const SizedBox(height:16),ReferenceCoastHero(onTap:(){}),
      const SizedBox(height:16),SizedBox(height:300+scale*120,child:Row(children:[for(var i=0;i<2;i++)Expanded(child:ReferenceProductSurface(name:'Produto do catálogo',description:'Descrição original',price:r'R$ 42,00',available:true,image:const Icon(Icons.local_drink),control:IconButton(onPressed:(){},icon:const Icon(Icons.shopping_cart))))])),
     ]))))));
    await tester.pump();
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
   });
  }
 }
 testWidgets('Header and search keep their existing destinations', (tester) async {
  final calls=<String>[];
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:Column(children:[
   ReferenceHomeHeader(address:'Porto Seguro',region:'BA',cartCount:0,onAddress:()=>calls.add('address'),onCart:()=>calls.add('cart'),onProfile:()=>calls.add('profile')),
   ReferenceHomeSearch(onTap:()=>calls.add('search')),
  ]))));
  await tester.tap(find.text('ENTREGAR EM'));
  await tester.tap(action('Abrir carrinho'));
  await tester.tap(action('Abrir perfil'));
  await tester.tap(find.text('O que você quer pedir hoje?'));
  expect(calls,['address','cart','profile','search']);
 });
 testWidgets('Reference product keeps original cart quantity handlers', (tester) async {
  final state=AppState.instance;
  final known=state.storeStatusKnown,open=state.storeOpen;
  final cart=Map<String,int>.from(state.cart);
  state.storeStatusKnown=true;state.storeOpen=true;state.cart.clear();
  addTearDown((){state.storeStatusKnown=known;state.storeOpen=open;state.cart..clear()..addAll(cart);});
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:Scaffold(body:Center(child:SizedBox(width:160,height:340,child:AnimatedBuilder(animation:state,builder:(context,_)=>PrimeProductCard(referenceStyle:true,product:{'id':'reference-test','name':'Produto de teste','price':'42.00','active':true,'stock':10,'category':{'name':'Cervejas','iconKey':'beer'}})))))));
  await tester.tap(action('Adicionar Produto de teste'));
  await tester.pump();
  expect(state.cart['reference-test'],1);
  await tester.tap(action('Aumentar quantidade'));
  await tester.pump();
  expect(state.cart['reference-test'],2);
  await tester.tap(action('Diminuir quantidade'));
  await tester.pump();
  expect(state.cart['reference-test'],1);
 });

 testWidgets('Compact Home banner has no overlapping photo and opens catalogue', (tester) async {
  var opened=0;
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:Padding(padding:const EdgeInsets.all(18),child:ReferenceCoastHero(onTap:()=>opened++)))));
  expect(find.descendant(of:find.byType(ReferenceCoastHero),matching:find.byType(Image)),findsNothing);
  await tester.tap(find.text('Explorar catálogo').hitTestable().first);
  expect(opened,1);
  expect(tester.takeException(),isNull);
 });

 testWidgets('Home has a single catalogue without repeated editorial sections', (tester) async {
  tester.view.devicePixelRatio=1;
  tester.view.physicalSize=const Size(320,1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:const Scaffold(body:HomePage())));
  expect(find.text('Escolha seus favoritos'),findsOneWidget);
  expect(find.text('Para o seu momento'),findsNothing);
  expect(find.text('Continue explorando'),findsNothing);
  expect(find.byType(SliverGrid),findsOneWidget);
  expect(tester.takeException(),isNull);
  await tester.pumpWidget(const SizedBox.shrink());
 });

}
