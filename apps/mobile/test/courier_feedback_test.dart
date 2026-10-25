import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/courier/presentation/pages/courier_operations_dashboard.dart';
import 'package:porto_prime/features/courier/presentation/widgets/courier_dashboard_header.dart';
import 'package:porto_prime/features/courier/presentation/widgets/courier_withdrawal_feedback.dart';

Widget host(Widget child, {bool reduceMotion = false, double scale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, widget) => MediaQuery(data: MediaQuery.of(context).copyWith(
    disableAnimations: reduceMotion, textScaler: TextScaler.linear(scale)), child: widget!),
  home: Scaffold(body: child));

void main() {
  testWidgets('Searching radar runs online and stops offline', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final online = ValueNotifier(true);
    await tester.pumpWidget(host(ValueListenableBuilder<bool>(valueListenable: online,
      builder: (_, value, child) => CourierSearchingRadar(online: value, size: 280))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue);
    online.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
  });

  testWidgets('Reduced motion leaves the online radar still', (tester) async {
    await tester.pumpWidget(host(const CourierSearchingRadar(online: true, size: 280), reduceMotion: true));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Waiting header has no repeated status text and aligns the pill with the name', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 850);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(CourierDashboardHeader(name: 'Victor', photo: null,
      online: true, active: false, waiting: true, unreadCount: 0,
      onNotifications: () {}, onProfile: () {}, onLogout: () {}, onRoute: () {}, onChanged: (_) async {})));
    await tester.pump();
    expect(find.text('Você está online e pronto para receber entregas.'), findsNothing);
    expect(find.text('Recebendo entregas'), findsNothing);
    final name = tester.getCenter(find.text('Victor 👋'));
    final control = tester.getCenter(find.byType(CourierReferenceAvailability));
    expect(control.dy, closeTo(name.dy, .5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final entry in const {
    'PENDING': 'Boa! Saque solicitado',
    'PROCESSING': 'Seu saque está em processamento',
    'PAID': 'Saque pago!',
  }.entries) {
    testWidgets('Withdrawal receipt reflects ${entry.key} at 320px with large text', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 750);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(host(Builder(builder: (context) => TextButton(
        onPressed: () => showDialog<void>(context: context,
          builder: (_) => CourierWithdrawalFeedback(status: entry.key, amount: 19)),
        child: const Text('Abrir comprovante'))), reduceMotion: true, scale: 2));
      await tester.tap(find.text('Abrir comprovante'));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      if (entry.key != 'PAID') {
        expect(find.text('Saque pago!'), findsNothing);
        expect(find.text('Pagamento confirmado'), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Voltar à carteira'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voltar à carteira'));
      await tester.pumpAndSettle();
      expect(find.byType(CourierWithdrawalFeedback), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Celebration finishes once and does not restart on rebuild', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    Widget receipt() => host(const CourierWithdrawalFeedback(status: 'PENDING', amount: 19));
    await tester.pumpWidget(receipt());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(receipt());
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
