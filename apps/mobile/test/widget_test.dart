import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/state/app_state.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/theme/app_icons.dart';
import 'package:porto_prime/core/widgets/prime_category_tile.dart';
import 'package:porto_prime/core/widgets/prime_product_card.dart';
import 'package:porto_prime/core/widgets/prime_ui.dart';
import 'package:porto_prime/features/home/presentation/pages/home_page.dart';

const categories = [
  'Cervejas',
  'Destilados',
  'Vinhos',
  'Refrigerantes',
  'Energéticos',
  'Águas',
  'Gelo',
  'Conveniência',
  'Combos',
  'Ofertas',
];
Widget host(Widget child, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: child),
  ),
);
void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Indicadores financeiros: viewport $width / texto $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) => Center(
                child: SizedBox(
                  width: 134,
                  height: AppResponsive.metricHeight(context),
                  child: const PrimeMetricCard(
                    icon: AppIcons.wallet,
                    label: 'Saldo disponível',
                    value: 'R\$ 125,90',
                  ),
                ),
              ),
            ),
            textScale: scale,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
      testWidgets('Home completa: viewport $width / texto $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final state = AppState.instance;
        state.products = [
          for (var i = 0; i < categories.length; i++)
            {
              'id': 'home-$i',
              'name': 'Produto de demonstração 350 ml',
              'price': '15.90',
              'stock': 10,
              'category': {'name': categories[i]},
            },
        ];
        state.user = {'role': 'CUSTOMER'};
        state.addresses = [
          {
            'street': 'Rua de demonstração com endereço muito comprido',
            'number': '123',
            'isDefault': true,
          },
        ];
        addTearDown(() {
          state.products = [];
          state.user = null;
          state.addresses = [];
        });
        await tester.pumpWidget(host(const HomePage(), textScale: scale));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -700),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Categorias e produto: viewport $width / texto $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) => ListView(
                children: [
                  LayoutBuilder(
                    builder: (_, box) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: AppResponsive.categoryColumns(
                          box.maxWidth,
                        ),
                        mainAxisExtent: AppResponsive.categoryHeight(context),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (_, i) => PrimeCategoryTile(
                        name: categories[i],
                        compact: box.maxWidth < 390,
                        onTap: () {},
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: 134,
                      height: AppResponsive.productHeight(context, 134),
                      child: const PrimeProductCard(
                        product: {
                          'id': 'visual-product',
                          'name': 'Produto com nome longo 350 ml',
                          'price': '15.90',
                          'oldPrice': '19.90',
                          'description': 'Descrição curta do produto',
                          'category': {'name': 'Conveniência'},
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            textScale: scale,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Categoria preserva callback no toque e no teclado', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        SizedBox(
          height: 160,
          width: 120,
          child: PrimeCategoryTile(
            name: 'Águas',
            selected: true,
            onTap: () => calls++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Águas'));
    await tester.pump();
    expect(calls, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls, 2);
  });
  testWidgets('Adicionar e quantidade preservam o carrinho existente', (
    tester,
  ) async {
    final state = AppState.instance;
    state.cart.clear();
    addTearDown(state.cart.clear);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        host(
          AnimatedBuilder(
            animation: state,
            builder: (_, __) => SizedBox(
              width: 184,
              height: 360,
              child: PrimeProductCard(
                product: {
                  'id': 'visual-product',
                  'name': 'Produto',
                  'price': '15.90',
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();
      expect(state.cart['visual-product'], 1);
      expect(
        tester.getSize(find.bySemanticsLabel('Aumentar quantidade')).width,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.bySemanticsLabel('Aumentar quantidade'));
      await tester.pumpAndSettle();
      expect(state.cart['visual-product'], 2);
      await tester.tap(find.bySemanticsLabel('Diminuir quantidade'));
      await tester.pumpAndSettle();
      expect(state.cart['visual-product'], 1);
    } finally {
      semantics.dispose();
    }
  });
  test('Erro técnico é traduzido somente na apresentação', () {
    expect(
      PrimeMessages.friendly('SocketException: Connection refused'),
      contains('conexão'),
    );
    expect(
      PrimeMessages.friendly('500 Internal Server Error'),
      contains('temporariamente'),
    );
    expect(
      PrimeMessages.friendly('Exception: CPF já cadastrado'),
      'CPF já cadastrado',
    );
    expect(PrimeMessages.friendly('undefined'), isNot(contains('undefined')));
  });
}
