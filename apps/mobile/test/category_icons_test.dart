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
}
