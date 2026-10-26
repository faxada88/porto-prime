import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/courier/presentation/pages/courier_operations_dashboard.dart';
import 'package:porto_prime/features/courier/presentation/widgets/courier_dashboard_header.dart';

Widget host(Widget child, {double scale = 1, bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.light, builder: (context, widget) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale),
      disableAnimations: reduceMotion), child: widget!), home: Scaffold(body: child));

Widget header({required bool online, required Future<void> Function(bool) onChanged}) =>
  CourierDashboardHeader(name: 'VICTOR', photo: null, online: online, active: false,
    waiting: true, unreadCount: 0, onNotifications: () {}, onProfile: () {},
    onLogout: () {}, onRoute: () {}, onChanged: onChanged);

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Courier status header fits $width / $scale with a single compact caption', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(host(SingleChildScrollView(child:
          header(online: true, onChanged: (_) async {})), scale: scale));
        await tester.pump();
        expect(find.text('Victor 👋'), findsOneWidget);
        expect(find.text('ONLINE'), findsOneWidget);
        expect(find.text('Recebendo entregas'), findsOneWidget);
        final track = tester.getRect(find.byKey(CourierReferenceAvailability.trackKey));
        expect(track.height, greaterThanOrEqualTo(48));
        expect(track.left, greaterThanOrEqualTo(0));
        expect(track.right, lessThanOrEqualTo(width));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('Thumb moves with confirmed status and honours reduced motion', (tester) async {
    final online = ValueNotifier(false);
    Widget view({bool reduceMotion = false}) => host(Center(child: SizedBox(width: 180,
      child: ValueListenableBuilder<bool>(valueListenable: online,
        builder: (_, value, child) => CourierReferenceAvailability(online: value,
          active: false, changing: false, onTap: () {})))), reduceMotion: reduceMotion);
    await tester.pumpWidget(view());
    await tester.pump();
    final left = tester.getCenter(find.byKey(CourierReferenceAvailability.thumbKey)).dx;
    online.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final moving = tester.getCenter(find.byKey(CourierReferenceAvailability.thumbKey)).dx;
    expect(moving, greaterThan(left));
    await tester.pumpAndSettle();
    final right = tester.getCenter(find.byKey(CourierReferenceAvailability.thumbKey)).dx;
    expect(right, greaterThan(moving));
    await tester.pumpWidget(view(reduceMotion: true));
    online.value = false;
    await tester.pump();
    expect(tester.getCenter(find.byKey(CourierReferenceAvailability.thumbKey)).dx, closeTo(left, .5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
  });

  testWidgets('Availability sends one request and keeps the real status while the server is pending', (tester) async {
    final pending = Completer<void>();
    final requests = <bool>[];
    await tester.pumpWidget(host(header(online: false, onChanged: (value) {
      requests.add(value);
      return pending.future;
    })));
    await tester.tap(find.byKey(CourierReferenceAvailability.trackKey));
    await tester.pump();
    await tester.tap(find.byKey(CourierReferenceAvailability.trackKey));
    await tester.pump();
    expect(requests, [true]);
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('A failed status request restores the button without pretending to be online', (tester) async {
    var requests = 0;
    await tester.pumpWidget(host(header(online: false,
      onChanged: (_) async { requests++; throw Exception('Sem conexão'); })));
    await tester.tap(find.byKey(CourierReferenceAvailability.trackKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(requests, 1);
    await tester.tap(find.byKey(CourierReferenceAvailability.trackKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(requests, 2);
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Waiting summary follows the message without a large forced gap', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1050);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(SingleChildScrollView(child: CourierWaitingPanel(online: true,
      summary: const {'earningsToday': 96, 'deliveriesToday': 5}, onlineTime: const Duration(hours: 4, minutes: 20),
      minimumHeight: 900, onEarnings: () {}, onDeliveries: () {})), reduceMotion: true));
    await tester.pump();
    final title = tester.getRect(find.text('Buscando entregas'));
    final summary = tester.getRect(find.byKey(const ValueKey('courier_waiting_summary')));
    expect(summary.top - title.bottom, lessThan(100));
    expect(find.text('4h 20min'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
