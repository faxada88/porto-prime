import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/widgets/prime_safe_viewport.dart';

void main() {
  for (final size in [const Size(320,568), const Size(375,667),
    const Size(390,844), const Size(430,932), const Size(360,800),
    const Size(412,915), const Size(844,390), const Size(1024,1366)]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('Safe viewport $size scale $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        late MediaQueryData inner;
        await tester.pumpWidget(MaterialApp(home: MediaQuery(
          data: MediaQueryData(size: size, padding: const EdgeInsets.fromLTRB(20,59,20,34),
            viewPadding: const EdgeInsets.fromLTRB(20,59,20,34),
            viewInsets: const EdgeInsets.only(bottom: 150), textScaler: TextScaler.linear(scale)),
          child: PrimeSafeViewport(child: Builder(builder: (context) {
            inner = MediaQuery.of(context);
            return const SizedBox.expand(key: ValueKey('safe-content'));
          })),
        )));
        final rect = tester.getRect(find.byKey(const ValueKey('safe-content')));
        expect(rect.left, 20);
        expect(rect.top, 59);
        expect(rect.right, size.width - 20);
        expect(rect.bottom, size.height - 34);
        expect(inner.padding, EdgeInsets.zero);
        expect(inner.viewInsets.bottom, 150);
        expect(inner.textScaler.scale(14), 14 * scale);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
