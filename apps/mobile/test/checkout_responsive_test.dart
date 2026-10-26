import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/features/checkout/presentation/widgets/checkout_progress.dart';

void main() {
  for (final width in [280.0,320.0,360.0,375.0,390.0,430.0,768.0]) {
    for (final scale in [1.0,1.5,2.0,3.0]) {
      testWidgets('Checkout labels fit $width / $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 700);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(home: MediaQuery(
          data: MediaQueryData(size: Size(width,700), textScaler: TextScaler.linear(scale)),
          child: const Scaffold(body: SingleChildScrollView(child: Padding(
            padding: EdgeInsets.all(16), child: Column(children: [
              CheckoutProgress(step: 1),
              CheckoutPriceLine(label: 'Total a pagar', value: 'R\$ 12.345,67', strong: true),
              CheckoutPriceLine(label: 'Entrega', value: 'Selecione um endereço'),
            ])))),
        )));
        expect(tester.takeException(), isNull);
        expect(find.text('Carrinho'), findsOneWidget);
        expect(find.text('Entrega'), findsNWidgets(2));
        expect(find.text('Pagamento'), findsOneWidget);
      });
    }
  }
}
