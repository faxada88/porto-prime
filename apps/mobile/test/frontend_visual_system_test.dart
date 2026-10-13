import 'package:flutter/material.dart';
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
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true), child: child!), home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
     const PrimeEditorialHeader(title: 'Seu espaço Prime', subtitle: 'Pedidos, saldo e sua conta. Tudo organizado para você.', icon: AppIcons.user),
     const SizedBox(height: 16), const CheckoutProgress(step: 1),
     const SizedBox(height: 16), const PrimePaymentCard(name: 'Cliente Porto Prime', code: 'PRIME-1234-5678', balance: 'R\$ 1.250,00'),
     const SizedBox(height: 16), PartnerPremiumHero(name: 'Parceiro', businessName: 'Parceiro Porto Seguro', balance: 'R\$ 150,00', onWallet: () {}, onShare: () {}),
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

}
