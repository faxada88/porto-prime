import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_icons.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/courier/presentation/pages/courier_operations_dashboard.dart';
import 'package:porto_prime/features/courier/presentation/widgets/courier_assigned_delivery.dart';
import 'package:porto_prime/features/courier/presentation/widgets/courier_dashboard_header.dart';
import 'package:porto_prime/features/courier/presentation/widgets/courier_workflow_layout.dart';
import 'package:porto_prime/features/courier/presentation/widgets/incoming_delivery_offer_sheet.dart';

Map<String, dynamic> offer() => {
  'offerId': 'offer-a', 'orderId': 'order-a',
  'expiresAt': DateTime.now().add(const Duration(minutes: 2)).toIso8601String(),
  'courierEarnings': 8.5, 'routeDistanceKm': 3.4, 'routeDurationMinutes': 12,
  'pickup': {'name': 'Porto Prime Distribuidora', 'region': 'Centro'},
  'dropoff': {'neighborhood': 'Taperapuan', 'city': 'Porto Seguro'},
};
Map<String, dynamic> assigned(String status) => {
  'id': 'order-a', 'status': status, 'deliveryFee': 8.5,
  'routeDistanceKm': 3.4, 'routeDurationMinutes': 12,
  'pickup': {'name': 'Porto Prime Distribuidora', 'latitude': -16.44, 'longitude': -39.08},
  'customer': {'name': 'Maria', 'phone': '+5573999999999'},
  'address': {'street': 'Rua de teste', 'number': '123', 'neighborhood': 'Taperapuan',
    'city': 'Porto Seguro', 'state': 'BA', 'latitude': -16.39, 'longitude': -39.04},
};

Widget workflow(String phase, double scale, {double topInset = 0}) => MaterialApp(theme: AppTheme.light,
  builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(scale), disableAnimations: true,
    padding: EdgeInsets.only(top: topInset), viewPadding: EdgeInsets.only(top: topInset)), child: child!),
  home: Scaffold(bottomNavigationBar: CourierOperationsNav(online: true,
    active: phase == 'assigned', busy: false, onHome: () {}, onWallet: () {},
    onAction: () {}, onHistory: () {}, onProfile: () {}),
    body: CourierWorkflowLayout(online: true, accountId: 'courier-a', onRefresh: () async {},
      header: CourierDashboardHeader(name: 'Victor', photo: null, online: true,
        active: phase == 'assigned', waiting: phase == 'waiting', unreadCount: 0,
        onNotifications: () {}, onProfile: () {}, onLogout: () {}, onRoute: () {}, onChanged: (_) async {}),
      waitingBuilder: (height, elapsed) => CourierWaitingPanel(online: true,
        summary: const {'earningsToday': 96, 'deliveriesToday': 5}, onlineTime: elapsed,
        minimumHeight: height, onEarnings: () {}, onDeliveries: () {}),
      delivery: phase == 'waiting' ? null : phase == 'offer'
        ? IncomingDeliveryOfferSheet(order: offer(), embedded: true,
            onAccept: () async {}, onReject: () async {})
        : CourierAssignedDelivery(order: assigned('OUT_FOR_DELIVERY'), busy: false,
            primaryLabel: 'Concluir com PIN', primaryIcon: AppIcons.check,
            onAdvance: () {}, onDetails: () {}))));

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final phase in ['waiting', 'offer', 'assigned']) {
        testWidgets('Courier workflow renders $phase at $width / $scale', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 850);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(workflow(phase, scale));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.text(phase == 'assigned' ? 'Sua entrega' : 'Victor 👋'), findsOneWidget);
          expect(find.byType(CourierWaitingPanel), phase == 'waiting' ? findsOneWidget : findsNothing);
          expect(find.byType(IncomingDeliveryOfferSheet), phase == 'offer' ? findsOneWidget : findsNothing);
          expect(find.byType(CourierAssignedDelivery), phase == 'assigned' ? findsOneWidget : findsNothing);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }

  for (final row in [
    ['COURIER_ASSIGNED', 'Confirmar coleta'],
    ['PICKED_UP', 'Iniciar rota'],
    ['OUT_FOR_DELIVERY', 'Finalizar entrega'],
  ]) {
    testWidgets('Assigned action delegates ${row[0]} without skipping a stage', (tester) async {
      var calls = 0;
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(
        body: SingleChildScrollView(child: CourierAssignedDelivery(order: assigned(row[0]),
          busy: false, primaryLabel: row[1], primaryIcon: AppIcons.check,
          onAdvance: () { calls++; }, onDetails: () {})))));
      await tester.ensureVisible(find.text(row[1]));
      await tester.tap(find.text(row[1]));
      await tester.pump();
      expect(calls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Courier scroll viewport remains below the phone status bar', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 850);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(workflow('assigned', 1, topInset: 34));
    await tester.pump();
    final scroll = find.byType(CustomScrollView);
    expect(tester.getRect(scroll).top, greaterThanOrEqualTo(34));
    expect(find.text('ONLINE'), findsNothing);
    expect(find.text('Sua entrega'), findsOneWidget);
    await tester.drag(scroll, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(tester.getRect(scroll).top, greaterThanOrEqualTo(34));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Navigation uses pickup before collection and customer after collection', () {
    expect(courierNavigationUri(assigned('COURIER_ASSIGNED'))!.queryParameters['q'], '-16.44,-39.08');
    expect(courierNavigationUri(assigned('PICKED_UP'))!.queryParameters['q'], '-16.39,-39.04');
    expect(courierNavigationUri(assigned('OUT_FOR_DELIVERY'), apple: true)!.scheme, 'maps');
    expect(courierCustomerPhone(assigned('OUT_FOR_DELIVERY'))!.path, '+5573999999999');
  });
  test('Incoming offer cannot expose customer navigation or phone', () {
    final data = assigned('READY_FOR_PICKUP');
    expect(courierNavigationUri(data), isNull);
    expect(courierCustomerPhone(data), isNull);
    final missingPickup = assigned('COURIER_ASSIGNED')..remove('pickup');
    expect(courierNavigationUri(missingPickup), isNull);
    final regionOnly = assigned('COURIER_ASSIGNED')..['pickup'] = {'region': 'Centro'};
    expect(courierNavigationUri(regionOnly), isNull);
  });
}
