import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/widgets/prime_animated_navigation.dart';
import 'package:porto_prime/core/widgets/prime_bottom_navigation.dart';
import 'package:porto_prime/features/courier/presentation/pages/courier_operations_dashboard.dart';

Widget frame(Widget bar, {double scale = 1, bool reduceMotion = false,
  TextDirection direction = TextDirection.ltr}) => MaterialApp(theme: AppTheme.light,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale), disableAnimations: reduceMotion,
      padding: const EdgeInsets.only(bottom: 24), viewPadding: const EdgeInsets.only(bottom: 24)),
      child: Directionality(textDirection: direction, child: child!)),
    home: Scaffold(bottomNavigationBar: bar));

Rect capsule(WidgetTester tester) => tester.getRect(find.byKey(PrimeAnimatedNavigation.capsuleKey));
Rect target(WidgetTester tester, int value) =>
  tester.getRect(find.byKey(PrimeAnimatedNavigation.destinationKey(value)));

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final role in ['guest', 'customer', 'partner', 'courier']) {
        testWidgets('$role navigation fits $width px / text $scale with every callback intact', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 950);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final calls = <int>[];
          final values = role == 'guest' ? [0, 2, 4, 3] : role == 'courier' ? [0, 1, 2, 3, 4] : [0, 1, 2, 4, 3];
          final bar = role == 'courier' ? CourierOperationsNav(online: true, active: false, busy: false,
            onHome: () => calls.add(0), onAction: () => calls.add(1), onWallet: () => calls.add(2),
            onHistory: () => calls.add(3), onProfile: () => calls.add(4))
            : PrimeBottomNavigation(index: 0, showOrders: role != 'guest',
                cartCount: 3, orderCount: 1, onSelect: calls.add);
          await tester.pumpWidget(frame(bar, scale: scale));
          await tester.pump();
          for (final value in values) {
            final rect = target(tester, value);
            expect(rect.width, greaterThanOrEqualTo(44));
            expect(rect.height, greaterThanOrEqualTo(44));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(width));
            await tester.tap(find.byKey(PrimeAnimatedNavigation.destinationKey(value)));
            await tester.pumpAndSettle();
          }
          expect(calls, values);
          expect(find.byKey(PrimeAnimatedNavigation.capsuleKey), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }

  test('Physical navigation spring has mild overshoot and settles at 300 ms', () {
    const spring = PrimeNavigationSpring();
    expect(PrimeNavigationSpring.duration.inMilliseconds, 300);
    expect(spring.transform(0), 0);
    expect(spring.transform(1), 1);
    final samples = [for (var i = 0; i <= 300; i++) spring.transform(i / 300)];
    expect(samples.reduce((a, b) => a > b ? a : b), allOf(greaterThan(1), lessThan(1.03)));
    expect(samples[299], closeTo(1, .002));
  });

  testWidgets('Capsule slides, keeps its element and retargets continuously from external selection', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final selected = ValueNotifier(0);
    final calls = <int>[];
    await tester.pumpWidget(frame(ValueListenableBuilder<int>(valueListenable: selected,
      builder: (_, index, child) => PrimeBottomNavigation(index: index, showOrders: true, onSelect: calls.add))));
    await tester.pump();
    final element = tester.element(find.byKey(PrimeAnimatedNavigation.capsuleKey));
    final initial = capsule(tester).center.dx;
    selected.value = 3;
    await tester.pump();
    expect(capsule(tester).center.dx, closeTo(initial, .1));
    await tester.pump(const Duration(milliseconds: 75));
    final middle = capsule(tester).center.dx;
    expect(middle, greaterThan(initial));
    expect(middle, lessThan(target(tester, 3).center.dx));
    selected.value = 2;
    await tester.pump();
    expect(capsule(tester).center.dx, closeTo(middle, .1));
    await tester.pumpAndSettle();
    expect(capsule(tester).center.dx, closeTo(target(tester, 2).center.dx, .5));
    expect(tester.element(find.byKey(PrimeAnimatedNavigation.capsuleKey)), same(element));
    expect(calls, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    selected.dispose();
  });

  testWidgets('Rapid taps retain every callback, finish at the controlled destination and emit one haptic each', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final selected = ValueNotifier(0);
    final calls = <int>[];
    var haptics = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics++;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(frame(ValueListenableBuilder<int>(valueListenable: selected,
      builder: (_, index, child) => PrimeBottomNavigation(index: index, showOrders: true,
        onSelect: (value) { calls.add(value); selected.value = value; }))));
    await tester.pump();
    for (final value in [2, 3, 0, 4, 1]) {
      await tester.tap(find.byKey(PrimeAnimatedNavigation.destinationKey(value)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 25));
      final rect = capsule(tester);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(tester.view.physicalSize.width));
    }
    await tester.pumpAndSettle();
    expect(calls, [2, 3, 0, 4, 1]);
    expect(haptics, 5);
    expect(capsule(tester).center.dx, closeTo(target(tester, 1).center.dx, .5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    selected.dispose();
  });

  testWidgets('Reduced motion snaps to selection and keeps accessible selected semantics', (tester) async {
    final selected = ValueNotifier(0);
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await tester.pumpWidget(frame(ValueListenableBuilder<int>(valueListenable: selected,
      builder: (_, index, child) => PrimeBottomNavigation(index: index, showOrders: true,
        onSelect: (value) => selected.value = value)), reduceMotion: true));
    await tester.tap(find.byKey(PrimeAnimatedNavigation.destinationKey(2)));
    await tester.pump();
    expect(capsule(tester).center.dx, closeTo(target(tester, 2).center.dx, .5));
    expect(tester.getSemantics(find.byKey(PrimeAnimatedNavigation.destinationKey(2)))
      .flagsCollection.isSelected, Tristate.isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    selected.dispose();
  });

  testWidgets('Guest transition preserves destination IDs, hides Orders and aligns Account', (tester) async {
    final loggedIn = ValueNotifier(true);
    await tester.pumpWidget(frame(ValueListenableBuilder<bool>(valueListenable: loggedIn,
      builder: (_, value, child) => PrimeBottomNavigation(index: 3, showOrders: value,
        orderCount: 8, cartCount: 12, onSelect: (_) {}))));
    await tester.pump();
    loggedIn.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Pedidos'), findsNothing);
    expect(find.text('8'), findsNothing);
    expect(find.text('12'), findsOneWidget);
    expect(capsule(tester).center.dx, closeTo(target(tester, 3).center.dx, .5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    loggedIn.dispose();
  });

  testWidgets('A cancelled press restores the selected tab without invoking its callback', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final calls = <int>[];
    await tester.pumpWidget(frame(PrimeBottomNavigation(index: 0, showOrders: true, onSelect: calls.add)));
    await tester.pump();
    final initial = capsule(tester).center.dx;
    final gesture = await tester.startGesture(target(tester, 2).center);
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 60));
    expect(capsule(tester).center.dx, greaterThan(initial));
    await gesture.moveTo(const Offset(1, 1));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(capsule(tester).center.dx, closeTo(target(tester, 0).center.dx, .5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Opening and returning from a page reconciles touch preview with the owner', (tester) async {
    final calls = <int>[];
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: Builder(builder: (context) => Scaffold(bottomNavigationBar: PrimeBottomNavigation(
        index: 0, showOrders: true, onSelect: (value) {
          calls.add(value);
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (pageContext) => Scaffold(
            body: Center(child: TextButton(onPressed: () => Navigator.of(pageContext).pop(),
              child: const Text('Retornar'))))));
        })))));
    await tester.tap(find.byKey(PrimeAnimatedNavigation.destinationKey(4)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retornar'));
    await tester.pumpAndSettle();
    expect(calls, [4]);
    expect(capsule(tester).center.dx, closeTo(target(tester, 0).center.dx, .5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('A selection update with TickerMode disabled snaps without a stale animation', (tester) async {
    final selected = ValueNotifier<int>(0);
    final ticker = ValueNotifier<bool>(true);
    await tester.pumpWidget(frame(ValueListenableBuilder<bool>(valueListenable: ticker,
      builder: (_, enabled, child) => TickerMode(enabled: enabled,
        child: ValueListenableBuilder<int>(valueListenable: selected,
          builder: (_, index, child) => PrimeBottomNavigation(index: index, showOrders: true, onSelect: (_) {}))))));
    await tester.pump();
    ticker.value = false;
    await tester.pump();
    selected.value = 3;
    await tester.pump();
    expect(capsule(tester).center.dx, closeTo(target(tester, 3).center.dx, .5));
    ticker.value = true;
    await tester.pumpAndSettle();
    expect(capsule(tester).center.dx, closeTo(target(tester, 3).center.dx, .5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    selected.dispose();
    ticker.dispose();
  });

  testWidgets('Courier busy state blocks all tabs without changing callback order', (tester) async {
    final calls = <int>[];
    await tester.pumpWidget(frame(CourierOperationsNav(index: 2, online: true, active: true, busy: true,
      onHome: () => calls.add(0), onAction: () => calls.add(1), onWallet: () => calls.add(2),
      onHistory: () => calls.add(3), onProfile: () => calls.add(4))));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(PrimeAnimatedNavigation.destinationKey(i)));
    }
    await tester.pump();
    expect(calls, isEmpty);
    expect(capsule(tester).center.dx, closeTo(target(tester, 2).center.dx, .5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('RTL and rotation preserve the actual destination and selected white icon', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget bar() => frame(PrimeBottomNavigation(index: 2, showOrders: true, onSelect: (_) {}), direction: TextDirection.rtl);
    await tester.pumpWidget(bar());
    await tester.pump();
    expect(capsule(tester).center.dx, closeTo(target(tester, 2).center.dx, .5));
    final icon = tester.widget<Icon>(find.descendant(
      of: find.byKey(PrimeAnimatedNavigation.destinationKey(2)), matching: find.byType(Icon)).first);
    expect(icon.color, Colors.white);
    tester.view.physicalSize = const Size(768, 800);
    await tester.pumpWidget(bar());
    await tester.pumpAndSettle();
    expect(capsule(tester).center.dx, closeTo(target(tester, 2).center.dx, .5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
