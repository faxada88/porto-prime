import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:porto_prime/core/theme/app_icons.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/widgets/prime_category_tile.dart';

void main() {
  test('Category names resolve to meaningful, accent-insensitive icons', () {
    expect(AppIcons.category('Churrasco'), LucideIcons.beef);
    expect(AppIcons.category('Açougue'), LucideIcons.beef);
    expect(AppIcons.category('Fitness'), LucideIcons.dumbbell);
    expect(AppIcons.category('Out frutas'), LucideIcons.apple);
    expect(AppIcons.category('Verduras'), LucideIcons.carrot);
    expect(AppIcons.category('Café'), LucideIcons.coffee);
    expect(AppIcons.category('Peixes'), LucideIcons.fish);
    expect(AppIcons.categoryVisual('Nome novo', iconKey: 'pizza').icon, LucideIcons.pizza);
    expect(AppIcons.categoryVisual('Categoria exclusiva').key, isNull);
    expect(AppIcons.category('Categoria exclusiva'), isNot(AppIcons.package));
  });
  testWidgets('Unknown category uses a typographic mark and preserves its action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(body:
      SizedBox(width: 140, height: 160, child: PrimeCategoryTile(name: 'Categoria exclusiva', onTap: () => taps++)))));
    expect(find.text('CE'), findsOneWidget);
    await tester.tap(find.text('Categoria exclusiva'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Explicit Admin icon wins over category name and legacy image', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(body:
      SizedBox(width: 150, height: 160, child: PrimeCategoryTile(name: 'Nome definido no Admin',
        iconKey: 'spirits', imageUrls: const ['https://example.com/old-image.png'], onTap: () {})))));
    expect(find.byIcon(LucideIcons.martini), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Nome definido no Admin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
