import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/state/app_state.dart';
import 'package:porto_prime/core/widgets/ice_product_option.dart';
import 'package:porto_prime/core/widgets/ice_selector_sheet.dart';

Map<String, dynamic> product(String id, String name, {String category = 'Gelos', int stock = 2}) =>
 {'id': id, 'name': name, 'price': 12, 'stock': stock, 'active': true, 'category': {'name': category}};

void main() {
 test('Each offered type and weight maps to the actual catalogue product', () {
  for (final weight in [3, 6, 15, 20]) {
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
}
