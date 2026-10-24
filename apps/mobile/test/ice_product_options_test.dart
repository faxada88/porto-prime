import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/state/app_state.dart';
import 'package:porto_prime/core/widgets/ice_product_option.dart';
import 'package:porto_prime/core/widgets/ice_selector_sheet.dart';
import 'package:porto_prime/features/categories/presentation/pages/categories_page.dart';

Map<String, dynamic> product(String id, String name, {String category = 'Gelos', int stock = 2}) =>
 {'id': id, 'name': name, 'price': 12, 'stock': stock, 'active': true, 'category': {'name': category}};

void main() {
 test('Each offered type and weight maps to the actual catalogue product', () {
  for (final weight in [3, 6, 10, 20]) {
   for (final type in IceType.values) {
    final item = product(type.name + weight.toString(), 'Gelo ' + type.label + ' ' + weight.toString() + ' kg');
    final option = IceProductOption.fromProduct(item)!;
    expect(option.product, same(item));
    expect(option.id, item['id']);
    expect(option.kilograms, weight);
    expect(option.type, type);
   }
  }
 });
 test('Descriptions and ambiguous product names never fabricate a purchasable variant', () {
  final generic = product('generic', 'Saco de gelo')..['description'] = 'Cubos ou moído: 3 kg, 6 kg, 15 kg e 20 kg';
  expect(IceProductOption.fromProduct(generic), isNull);
  expect(IceProductOption.fromProduct(product('mixed', 'Gelo cubos ou moído 3 kg')), isNull);
  expect(IceProductOption.fromProduct(product('weights', 'Gelo cubos 3 kg e 6 kg')), isNull);
  expect(iceOptionsFor([
   product('other', 'Gelo cubos 3 kg', category: 'Bebidas'),
   product('archived', 'Gelo cubos 6 kg')..['archived'] = true,
  ], 'Gelos'), isEmpty);
 });
 testWidgets('Selecting ice preserves product identity and enforces remaining stock', (tester) async {
  final state = AppState.instance;
  final oldProducts = state.products, oldCart = Map<String, int>.from(state.cart);
  final oldKnown = state.storeStatusKnown, oldOpen = state.storeOpen;
  state.products = [
   product('cube3', 'Gelo cubos 3 kg'),
   product('crushed6', 'Gelo moído 6 kg'),
  ];
  state.cart.clear(); state.storeStatusKnown = true; state.storeOpen = true;
  addTearDown(() {
   state.products = oldProducts;
   state.cart..clear()..addAll(oldCart);
   state.storeStatusKnown = oldKnown; state.storeOpen = oldOpen;
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) =>
   TextButton(onPressed: () => showIceSelector(context, categoryName: 'Gelos'),
    child: const Text('Abrir gelo'))))));
  await tester.tap(find.text('Abrir gelo')); await tester.pumpAndSettle();
  await tester.tap(find.text('Moído')); await tester.pumpAndSettle();
  expect(find.text('Gelo moído 6 kg'), findsOneWidget);
  expect(state.cart, isEmpty);
  await tester.tap(find.byTooltip('Aumentar quantidade')); await tester.pump();
  final plus = tester.widget<IconButton>(find.byTooltip('Aumentar quantidade'));
  expect(plus.onPressed, isNull);
  await tester.tap(find.text('Adicionar ao carrinho')); await tester.pumpAndSettle();
  expect(state.cart, {'crushed6': 2});
  expect(tester.takeException(), isNull);
 });
 testWidgets('Ice category has one total and buys a legacy product without a duplicate list', (tester) async {
  final state = AppState.instance;
  final oldProducts = state.products, oldCategories = state.catalogCategories;
  final oldCart = Map<String, int>.from(state.cart);
  final oldKnown = state.storeStatusKnown, oldOpen = state.storeOpen;
  state.products = [product('legacy-ice', 'Gelo')..['price'] = 19,
   product('other', 'Cerveja', category: 'Cervejas')];
  state.catalogCategories = [{'name': 'Gelos', 'iconKey': 'ice'}];
  state.cart.clear(); state.storeStatusKnown = true; state.storeOpen = true;
  addTearDown(() {
   state.products = oldProducts; state.catalogCategories = oldCategories;
   state.cart..clear()..addAll(oldCart);
   state.storeStatusKnown = oldKnown; state.storeOpen = oldOpen;
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CategoriesPage(categoryName: 'Gelos'))));
  await tester.pump();
  expect(find.text(r'R$ 19,00'), findsOneWidget);
  expect(find.text('Gelo'), findsOneWidget);
  expect(find.text('Cerveja'), findsNothing);
  expect(find.text('Escolher meu gelo'), findsNothing);
  expect(find.text('Opções disponíveis'), findsNothing);
  expect(find.byType(TextField), findsNothing);
  await tester.tap(find.text('Adicionar ao carrinho')); await tester.pumpAndSettle();
  expect(state.cart, {'legacy-ice': 1});
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
 });

 test('Weight-only Admin names expose real pack sizes without guessing their ice type', () {
  for (final weight in [3, 6, 10, 20]) {
   final item = product('ice' + weight.toString(), 'Gelo ' + weight.toString() + 'KG');
   expect(icePackageKilograms(item), weight);
   expect(IceProductOption.fromProduct(item), isNull);
  }
  expect(icePackageKilograms(product('generic', 'Gelo')..['description'] = '3 kg ou 20 kg'), isNull);
  expect(icePackageKilograms(product('mixed', 'Gelo 3 kg e 6 kg')), isNull);
 });
 testWidgets('Ice weight dropdown changes the actual product and price before adding', (tester) async {
  final state = AppState.instance;
  final oldProducts = state.products, oldCart = Map<String, int>.from(state.cart);
  final oldKnown = state.storeStatusKnown, oldOpen = state.storeOpen;
  state.products = [
   product('ice3', 'Gelo 3KG')..['price'] = 7,
   product('ice6', 'Gelo 6KG')..['price'] = 12,
   product('ice10', 'Gelo 10KG')..['price'] = 19,
   product('ice20', 'Gelo 20KG')..['price'] = 30,
  ];
  state.cart.clear(); state.storeStatusKnown = true; state.storeOpen = true;
  addTearDown(() {
   state.products = oldProducts; state.cart..clear()..addAll(oldCart);
   state.storeStatusKnown = oldKnown; state.storeOpen = oldOpen;
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(
   child: Padding(padding: EdgeInsets.all(16), child: IceOrderPanel(categoryName: 'Gelos'))))));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('ice-weight-dropdown'))); await tester.pumpAndSettle();
  await tester.tap(find.text('10 kg').last); await tester.pumpAndSettle();
  expect(find.text('Gelo 10KG'), findsOneWidget);
  expect(find.text(r'R$ 19,00'), findsOneWidget);
  expect(state.cart, isEmpty);
  await tester.tap(find.text('Adicionar ao carrinho')); await tester.pumpAndSettle();
  expect(state.cart, {'ice10': 1});
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
 });

}
