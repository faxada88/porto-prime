import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/widgets/prime_identity_widgets.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Identity sheets fit width=$width text=$scale with keyboard', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Widget app(Widget child, {double keyboard = 0}) => MaterialApp(key: UniqueKey(),
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale), disableAnimations: true,
            viewInsets: EdgeInsets.only(bottom: keyboard)), child: child!),
          home: Scaffold(resizeToAvoidBottomInset: false, body: Align(
            alignment: Alignment.bottomCenter, child: child)));
        await tester.pumpWidget(app(PrimeIdentitySheet(children: [
          PrimeLoginIntro(onClose: () {}),
          const SizedBox(height: 20),
          const TextField(decoration: InputDecoration(labelText: 'E-mail')),
          const SizedBox(height: 16),
          const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Senha')),
        ]), keyboard: 300));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(app(PrimePhotoSource(onCamera: () {}, onGallery: () {}, onClose: () {})));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(app(PrimePhotoReview(photo: '', onRetake: () {}, onUse: () {})));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets('Photo choices delegate the original camera and gallery actions', (tester) async {
    final choices = <String>[];
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(body:
      PrimePhotoSource(onCamera: () => choices.add('camera'),
        onGallery: () => choices.add('gallery'), onClose: () => choices.add('close')))));
    for (final label in ['Tirar uma selfie', 'Escolher da galeria']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
    }
    await tester.ensureVisible(find.byTooltip('Fechar opções de foto'));
    await tester.tap(find.byTooltip('Fechar opções de foto'));
    expect(choices, ['camera', 'gallery', 'close']);
    expect(tester.takeException(), isNull);
  });
}
