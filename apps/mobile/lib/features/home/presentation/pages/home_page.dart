import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const categories = [
    ('Cervejas', Icons.sports_bar_rounded),
    ('Whiskies', Icons.liquor_rounded),
    ('Gin & Vodka', Icons.local_bar_rounded),
    ('Vinhos', Icons.wine_bar_rounded),
    ('Refrigerantes', Icons.local_drink_rounded),
    ('Gelo & mais', Icons.ac_unit_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            sliver: SliverToBoxAdapter(child: _Header()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(child: _Search()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(child: _Hero()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
            sliver: SliverToBoxAdapter(child: _SectionTitle(title: 'Categorias', action: 'Ver todas')),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 106,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final item = categories[index];
                  return SizedBox(
                    width: 78,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                          child: Icon(item.$2, color: AppColors.primaryDark, size: 29),
                        ),
                        const SizedBox(height: 8),
                        Text(item.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            sliver: SliverToBoxAdapter(child: _SectionTitle(title: 'Mais pedidos', action: 'Ver mais')),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList.separated(
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _ProductCard(index: index),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 46, height: 46,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: const Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PORTO PRIME', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -.4)),
        SizedBox(height: 2),
        Row(children: [Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary), SizedBox(width: 3), Flexible(child: Text('Entregar em Porto Seguro', style: TextStyle(fontSize: 12, color: AppColors.muted), overflow: TextOverflow.ellipsis))]),
      ])),
      _RoundButton(icon: Icons.notifications_none_rounded),
      const SizedBox(width: 8),
      _RoundButton(icon: Icons.person_outline_rounded),
    ],
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 42, height: 42,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Icon(icon, color: AppColors.ink, size: 22),
  );
}

class _Search extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    readOnly: true,
    decoration: InputDecoration(
      hintText: 'O que você quer gelado hoje?',
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.ink),
      suffixIcon: Container(
        margin: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.tune_rounded, size: 19),
      ),
    ),
  );
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(colors: [Color(0xFF087A61), Color(0xFF16A77F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(20)),
          child: const Text('PORTO SEGURO • ENTREGA RÁPIDA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5)),
        ),
        const SizedBox(height: 16),
        const Text('Sua bebida,\nno clima certo.', style: TextStyle(color: Colors.white, fontSize: 27, height: 1.05, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('Gelada, rápida e sem complicação.', style: TextStyle(color: Color(0xFFE1FFF5), fontSize: 13)),
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13)),
          onPressed: () {},
          child: const Text('Pedir agora', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ])),
      const SizedBox(width: 8),
      Container(
        width: 94, height: 128,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(26)),
        child: const Icon(Icons.local_drink_rounded, size: 66, color: Colors.white),
      ),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});
  final String title;
  final String action;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
    Text(action, style: const TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.w800)),
  ]);
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    const products = [
      ('Heineken Long Neck', '330 ml • bem gelada', 'R\$ 8,99', Icons.sports_bar_rounded),
      ('Coca-Cola Original', '2 L • gelada', 'R\$ 12,90', Icons.local_drink_rounded),
      ('Johnnie Walker Red', '750 ml', 'R\$ 89,90', Icons.liquor_rounded),
    ];
    final p = products[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        Container(width: 78, height: 78, decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(18)), child: Icon(p.$4, color: AppColors.primaryDark, size: 36)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          Text(p.$2, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 10),
          Text(p.$3, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16)),
        ])),
        Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.add_rounded, color: Colors.white)),
      ]),
    );
  }
}
