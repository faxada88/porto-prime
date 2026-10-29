import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/features/orders/presentation/widgets/delivery_completed_view.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Delivery confirmation fits $width / $scale and preserves actions', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 720);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var back = 0, help = 0, details = 0;
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
          home: DeliveryCompletedView(
            deliveredAt: '2026-10-28T09:56:00',
            onBack: () => back++,
            onHelp: () => help++,
            onDetails: () => details++),
        ));
        expect(tester.takeException(), isNull);
        expect(find.text('Seu pedido foi entregue'), findsOneWidget);
        expect(find.text('09:56'), findsOneWidget);
        expect(find.textContaining('antes'), findsNothing);
        await tester.tap(find.byTooltip('Voltar'));
        await tester.tap(find.text('Ajuda'));
        expect(back, 1);
        expect(help, 1);
        await tester.ensureVisible(find.text('Pedido entregue às'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pedido entregue às'));
        expect(details, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Missing delivery timestamp does not invent a time', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DeliveryCompletedView(
      deliveredAt: null, onBack: () {}, onHelp: () {}, onDetails: () {})));
    expect(find.text('Ver detalhes do pedido'), findsOneWidget);
    expect(find.text('Pedido entregue às'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
