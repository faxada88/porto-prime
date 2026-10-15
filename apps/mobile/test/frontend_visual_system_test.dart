import 'package:flutter/material.dart';
import 'package:porto_prime/core/widgets/prime_cart_widgets.dart';
import 'package:porto_prime/core/widgets/prime_bottom_navigation.dart';
import 'package:porto_prime/core/widgets/prime_moment_card.dart';
import 'package:porto_prime/core/widgets/prime_category_artwork.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_icons.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/widgets/prime_brand.dart';
import 'package:porto_prime/core/widgets/prime_category_tile.dart';
import 'package:porto_prime/features/checkout/presentation/widgets/checkout_progress.dart';
import 'package:porto_prime/features/partners/presentation/pages/partner_premium_hero.dart';

void main() {
 for (final width in [320.0, 390.0, 768.0, 1280.0]) {
  for (final scale in [1.0, 1.5, 2.0]) {
   testWidgets('Prime components fit width=$width text=$scale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 1024);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true), child: child!), home: Scaffold(bottomNavigationBar: PrimeBottomNavigation(index: 2, cartCount: 12, onSelect: (_) {}), body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
     const PrimeEditorialHeader(title: 'Seu espaço Prime', subtitle: 'Pedidos, saldo e sua conta. Tudo organizado para você.', icon: AppIcons.user),
     const SizedBox(height: 16), const CheckoutProgress(step: 1),
     const SizedBox(height: 16), const PrimePaymentCard(name: 'Cliente Porto Prime', code: 'PRIME-1234-5678', balance: 'R\$ 1.250,00'),
     const SizedBox(height: 16), PartnerPremiumHero(name: 'Parceiro', businessName: 'Parceiro Porto Seguro', balance: 'R\$ 150,00', onWallet: () {}, onShare: () {}),
     const SizedBox(height: 16), PrimeMomentCard(title: 'Pé na areia', subtitle: 'Bebidas e conveniência para curtir a praia.', scene: 0, onTap: () {}),
     const SizedBox(height: 16), PrimeMomentCard(title: 'Churrasco', subtitle: 'Bebidas e acompanhamentos.', scene: 1, onTap: () {}),
     const SizedBox(height: 16), PrimeMomentCard(title: 'Fim de tarde', subtitle: 'Explore vinhos e destilados.', scene: 2, onTap: () {}),
     const SizedBox(height: 16), PrimeCartEmpty(onExplore: () {}),
     const SizedBox(height: 16), PrimeCartSummary(subtotal: 'R\$ 1.250,00', working: false, storeKnown: true, storeOpen: true, storeMessage: '', onContinue: () {}),
     const SizedBox(height: 16), LayoutBuilder(builder: (context, box) => SizedBox(height: AppResponsive.categoryHeight(context), child: Row(children: [Expanded(child: PrimeCategoryTile(name: 'Conveniência', onTap: () {})), Expanded(child: PrimeCategoryTile(name: 'Cervejas', selected: true, onTap: () {}))]))),
    ]))))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
   });
  }
 }
 testWidgets('Category tap delegates once to existing handler', (tester) async {
  var taps = 0;
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(body: Center(child: SizedBox(width: 130, height: 150, child: PrimeCategoryTile(name: 'Cervejas', onTap: () => taps++))))));
  await tester.tap(find.text('Cervejas'));
  await tester.pump();
  expect(taps, 1);
 });
 testWidgets('Original category vectors paint on the shared optical grid', (tester) async {
  final icons = [AppIcons.beer, AppIcons.wine, AppIcons.spirits,
   AppIcons.softDrink, AppIcons.energy, AppIcons.water, AppIcons.ice,
   AppIcons.convenience, AppIcons.combo, AppIcons.offers, AppIcons.all];
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Wrap(children: [
   for (final icon in icons) Padding(padding: const EdgeInsets.all(8),
    child: PrimeCategoryArtwork(icon: icon, color: AppColors.ocean700)),
  ]))));
  await tester.pump();
  expect(find.byType(PrimeCategoryArtwork), findsNWidgets(11));
  expect(tester.takeException(), isNull);
 });

 testWidgets('Bottom navigation delegates the four original destinations', (tester) async {
  final destinations = <int>[];
  await tester.pumpWidget(MaterialApp(home: Scaffold(
   bottomNavigationBar: PrimeBottomNavigation(index: 0, cartCount: 3,
    onSelect: destinations.add), body: const SizedBox.shrink())));
  for (final label in ['Início', 'Buscar', 'Carrinho', 'Conta']) {
   await tester.tap(find.text(label));
   await tester.pump();
  }
  expect(destinations, [0, 1, 2, 3]);
  expect(tester.takeException(), isNull);
 });
 testWidgets('Moment card preserves its supplied action', (tester) async {
  var taps = 0;
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: PrimeMomentCard(
   title: 'Pé na areia', subtitle: 'Explorar bebidas.', scene: 0,
   onTap: () => taps++))));
  await tester.tap(find.text('Explorar'));
  await tester.pump();
  expect(taps, 1);
  expect(tester.takeException(), isNull);
 });

 testWidgets('Empty cart and summary delegate their existing actions', (tester) async {
  var explored = 0;
  var continued = 0;
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(
   body: SingleChildScrollView(child: Column(children: [
    PrimeCartEmpty(onExplore: () => explored++),
    PrimeCartSummary(subtotal: 'R\$ 150,00', working: false, storeKnown: true,
     storeOpen: true, storeMessage: '', onContinue: () => continued++),
   ])))));
  await tester.ensureVisible(find.text('Explorar produtos'));
  await tester.tap(find.text('Explorar produtos'));
  await tester.ensureVisible(find.text('Continuar para entrega'));
  await tester.tap(find.text('Continuar para entrega'));
  expect(explored, 1);
  expect(continued, 1);
  expect(tester.takeException(), isNull);
 });
 testWidgets('Cart summary keeps store and loading checkout guards', (tester) async {
  var continued = 0;
  for (final flags in [[false, false, true], [false, true, false], [true, true, true]]) {
   await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(
    body: PrimeCartSummary(subtotal: 'R\$ 50,00', working: flags[0], storeKnown: flags[1],
     storeOpen: flags[2], storeMessage: 'Voltamos em breve.', onContinue: () => continued++))));
   expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
   expect(tester.takeException(), isNull);
  }
  expect(continued, 0);
  await tester.pumpWidget(const SizedBox.shrink());
 });

}
