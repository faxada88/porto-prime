import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_category_tile.dart';
import '../../../../core/widgets/prime_product_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppState.instance,
    builder: (_, __) {
      final s = AppState.instance;
      final categories = s.products
          .map((p) => (p['category']?['name'] ?? 'Outros').toString())
          .toSet()
          .toList()
        ..sort();

      return SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: s.bootstrap,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverToBoxAdapter(child: _Header(logged: s.loggedIn)),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(child: _Search()),
              ),
              if (s.activeOrder != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(child: _Active(order: s.activeOrder!)),
                ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverToBoxAdapter(child: _Hero()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _Section(
                    title: 'Categorias',
                    subtitle: 'Tudo organizado para você encontrar rápido',
                    onTap: () => AppNav.instance.go(1),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: categories.isEmpty
                      ? const _CategorySkeleton()
                      : LayoutBuilder(
                          builder: (context, box) {
                            final columns = box.maxWidth >= 700 ? 6 : box.maxWidth >= 390 ? 5 : 4;
                            final visible = categories.take(columns * 2).toList();
                            final gap = box.maxWidth < 350 ? 7.0 : 9.0;
                            final width = (box.maxWidth - gap * (columns - 1)) / columns;
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: visible.map((name) {
                                return SizedBox(
                                  width: width,
                                  height: width * 1.24,
                                  child: PrimeCategoryTile(
                                    name: name,
                                    compact: true,
                                    imageUrls: _categoryImages(s.products, name),
                                    onTap: () {
                                      s.selectCatalogCategory(name);
                                      AppNav.instance.go(1);
                                    },
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 26, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _Section(title: 'Para o seu momento', subtitle: 'Escolhas rápidas para cada ocasião'),
                ),
              ),
              const SliverToBoxAdapter(child: _Moments()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _Section(
                    title: 'Gelou, chegou',
                    subtitle: 'Destaques do catálogo Porto Prime',
                    onTap: () => AppNav.instance.go(1),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 270,
                  child: s.products.isEmpty
                      ? const _ProductSkeleton()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: s.products.length > 8 ? 8 : s.products.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => SizedBox(
                            width: 172,
                            child: PrimeProductCard(
                              product: s.products[i],
                              onOpen: () {
                                final cat = (s.products[i]['category']?['name'] ?? 'Todos').toString();
                                s.selectCatalogCategory(cat);
                                AppNav.instance.go(1);
                              },
                            ),
                          ),
                        ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 25, 20, 125),
                sliver: SliverToBoxAdapter(child: _Promise()),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.logged});
  final bool logged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.oceanDeep, AppColors.turquoise]),
          borderRadius: BorderRadius.circular(17),
          boxShadow: AppShadows.soft,
        ),
        alignment: Alignment.center,
        child: const Text('P', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
      ),
      const SizedBox(width: 11),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PORTO PRIME', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -.4)),
            SizedBox(height: 3),
            Row(
              children: [
                Icon(Symbols.location_on_rounded, size: 14, color: AppColors.coral, fill: 1),
                SizedBox(width: 4),
                Flexible(child: Text('Porto Seguro • BA', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700))),
                SizedBox(width: 3),
                Icon(Symbols.keyboard_arrow_down_rounded, size: 15, color: AppColors.muted),
              ],
            ),
          ],
        ),
      ),
      InkWell(
        onTap: () => AppNav.instance.go(3),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.stroke), boxShadow: AppShadows.soft),
          child: Icon(logged ? Symbols.person_rounded : Symbols.person_rounded, color: AppColors.coral, fill: logged ? 1 : 0),
        ),
      ),
    ],
  );
}

class _Search extends StatelessWidget {
  const _Search();
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => AppNav.instance.go(1),
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.stroke), boxShadow: AppShadows.soft),
      child: const Row(
        children: [
          Icon(Symbols.search_rounded, size: 23, color: AppColors.ink),
          SizedBox(width: 10),
          Expanded(child: Text('O que vai gelado hoje?', style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600))),
          Icon(Symbols.tune_rounded, size: 20, color: AppColors.coral),
        ],
      ),
    ),
  );
}

class _Active extends StatelessWidget {
  const _Active({required this.order});
  final Map<String, dynamic> order;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => AppNav.instance.go(3),
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: const Icon(Symbols.delivery_dining_rounded, color: AppColors.oceanDeep)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Pedido em andamento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)), Text(_status(order['status'].toString()), style: const TextStyle(fontSize: 9.5, color: AppColors.muted, fontWeight: FontWeight.w700))])),
          const Icon(Symbols.arrow_forward_rounded, size: 18),
        ],
      ),
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => AppNav.instance.go(1),
    borderRadius: BorderRadius.circular(30),
    child: Container(
      height: 244,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(colors: [Color(0xFFFF354B), Color(0xFFFF7A3D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: AppShadows.elevated,
      ),
      child: Stack(
        children: [
          Positioned(right: -60, top: -84, child: Container(width: 220, height: 220, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.sun))),
          Positioned(right: 15, bottom: -15, child: Transform.rotate(angle: -.10, child: const Icon(Symbols.sports_bar_rounded, size: 132, color: Colors.white, fill: 1, weight: 600))),
          Padding(
            padding: const EdgeInsets.all(22),
            child: SizedBox(
              width: 225,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Symbols.bolt_rounded, size: 14, color: Color(0xFF8CFFE4), fill: 1), SizedBox(width: 5), Text('ENTREGA RÁPIDA • PORTO SEGURO', style: TextStyle(color: Color(0xFFD9FFF6), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .7))]),
                  const SizedBox(height: 15),
                  const Text('Seu momento\ncontinua.', style: TextStyle(color: Colors.white, fontSize: 32, height: .98, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
                  const SizedBox(height: 9),
                  const Text('Bebidas, gelo e conveniência sem interromper o seu momento.', style: TextStyle(color: Color(0xFFD5F4EE), fontSize: 11.5, height: 1.35, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Explorar agora', style: TextStyle(color: AppColors.oceanDeep, fontSize: 12, fontWeight: FontWeight.w900)), SizedBox(width: 7), Icon(Symbols.arrow_forward_rounded, size: 16, color: AppColors.oceanDeep)]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.subtitle, this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600))])),
      if (onTap != null)
        InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: const Padding(padding: EdgeInsets.all(6), child: Row(children: [Text('Ver tudo', style: TextStyle(color: AppColors.oceanDeep, fontSize: 10, fontWeight: FontWeight.w900)), SizedBox(width: 2), Icon(Symbols.arrow_forward_rounded, size: 14, color: AppColors.oceanDeep)]))),
    ],
  );
}

class _Moments extends StatelessWidget {
  const _Moments();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 106,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _moment('Praia', 'Pé na areia', Symbols.beach_access_rounded, AppColors.sand),
        const SizedBox(width: 10),
        _moment('Churrasco', 'Sem faltar nada', Symbols.outdoor_grill_rounded, const Color(0xFFFFDED1)),
        const SizedBox(width: 10),
        _moment('Noite', 'Drinks & amigos', Symbols.nightlife_rounded, AppColors.mint),
      ],
    ),
  );

  Widget _moment(String title, String subtitle, IconData icon, Color color) => InkWell(
    onTap: () => AppNav.instance.go(1),
    borderRadius: BorderRadius.circular(22),
    child: Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .78), borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 24, color: AppColors.ink, weight: 500)),
          const SizedBox(width: 10),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.w700))])),
        ],
      ),
    ),
  );
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) {
      final columns = box.maxWidth >= 390 ? 5 : 4;
      final gap = 9.0;
      final width = (box.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: List.generate(columns * 2, (_) => Container(width: width, height: width * 1.24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.stroke)))),
      );
    },
  );
}

class _ProductSkeleton extends StatelessWidget {
  const _ProductSkeleton();
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    scrollDirection: Axis.horizontal,
    itemCount: 3,
    separatorBuilder: (_, __) => const SizedBox(width: 12),
    itemBuilder: (_, __) => Container(width: 172, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.stroke))),
  );
}

class _Promise extends StatelessWidget {
  const _Promise();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: const Color(0xFF17231F), borderRadius: BorderRadius.circular(26)),
    child: const Row(
      children: [
        DecoratedBox(decoration: BoxDecoration(color: Color(0xFF263A34), borderRadius: BorderRadius.all(Radius.circular(17))), child: SizedBox(width: 53, height: 53, child: Icon(Symbols.bolt_rounded, color: AppColors.sun, size: 29, fill: 1))),
        SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Gelada. Rápida. Sem complicação.', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('Da escolha ao acompanhamento, tudo em poucos toques.', style: TextStyle(color: Colors.white60, fontSize: 10, height: 1.35, fontWeight: FontWeight.w600))])),
      ],
    ),
  );
}

String _status(String s) => switch (s) {
  'PENDING' => 'Pedido recebido',
  'CONFIRMED' => 'Pagamento confirmado',
  'PREPARING' => 'Separando seu pedido',
  'READY_FOR_PICKUP' => 'Pronto para coleta',
  'COURIER_ASSIGNED' => 'Motoboy a caminho da coleta',
  'PICKED_UP' => 'Pedido coletado',
  'OUT_FOR_DELIVERY' => 'A caminho de você',
  'DELIVERED' => 'Entregue',
  _ => s,
};


List<String> _categoryImages(List<dynamic> products, String category) {
  return products
      .where((p) => (p['category']?['name'] ?? '').toString() == category)
      .map((p) => (p['imageUrl'] ?? '').toString())
      .where((url) => url.isNotEmpty)
      .take(3)
      .toList();
}
