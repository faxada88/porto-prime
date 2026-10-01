import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const categories = [
    ('Cervejas', Icons.sports_bar_rounded, Color(0xFFFFE7A8)),
    ('Whiskies', Icons.liquor_rounded, Color(0xFFFFDCC8)),
    ('Gin & Vodka', Icons.local_bar_rounded, Color(0xFFDDF4EF)),
    ('Vinhos', Icons.wine_bar_rounded, Color(0xFFFFE0E5)),
    ('Sem álcool', Icons.local_drink_rounded, Color(0xFFDDEFFF)),
    ('Gelo & mais', Icons.ac_unit_rounded, Color(0xFFE9E6FF)),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverPadding(padding: EdgeInsets.fromLTRB(20, 14, 20, 0), sliver: SliverToBoxAdapter(child: _TopBar())),
        const SliverPadding(padding: EdgeInsets.fromLTRB(20, 18, 20, 0), sliver: SliverToBoxAdapter(child: _Search())),
        const SliverPadding(padding: EdgeInsets.fromLTRB(20, 18, 20, 0), sliver: SliverToBoxAdapter(child: _Hero())),
        const SliverPadding(padding: EdgeInsets.fromLTRB(20, 25, 20, 13), sliver: SliverToBoxAdapter(child: _Title('Escolha seu clima', 'Ver todas'))),
        SliverToBoxAdapter(child: SizedBox(
          height: 112,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = categories[i];
              return SizedBox(width: 78, child: Column(children: [
                Container(width: 68, height: 68, decoration: BoxDecoration(color: c.$3, borderRadius: BorderRadius.circular(24)), child: Icon(c.$2, size: 31, color: AppColors.ink)),
                const SizedBox(height: 8),
                Text(c.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ]));
            },
          ),
        )),
        const SliverPadding(padding: EdgeInsets.fromLTRB(20, 17, 20, 13), sliver: SliverToBoxAdapter(child: _Title('Chegam voando', 'Ver mais'))),
        SliverToBoxAdapter(child: SizedBox(
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ProductCard(index: i),
          ),
        )),
        const SliverPadding(padding: EdgeInsets.fromLTRB(20, 25, 20, 120), sliver: SliverToBoxAdapter(child: _ExperienceCard())),
      ],
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.ocean, AppColors.turquoise]), borderRadius: BorderRadius.circular(17)), alignment: Alignment.center, child: const Text('P', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900))),
    const SizedBox(width: 11),
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PORTO PRIME', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -.4)),
      SizedBox(height: 3),
      Row(children: [Icon(Icons.near_me_rounded, size: 13, color: AppColors.coral), SizedBox(width: 4), Flexible(child: Text('Porto Seguro • BA', style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)))]),
    ])),
    _Circle(icon: Icons.notifications_none_rounded),
  ]);
}

class _Circle extends StatelessWidget {
  const _Circle({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFECEDE8))), child: Icon(icon, size: 22, color: AppColors.ink));
}

class _Search extends StatelessWidget {
  const _Search();
  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFFE8EBE6))),
    child: const Row(children: [
      SizedBox(width: 17), Icon(Icons.search_rounded, size: 23), SizedBox(width: 11),
      Expanded(child: Text('O que vai gelado hoje?', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600))),
      Padding(padding: EdgeInsets.all(7), child: DecoratedBox(decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.all(Radius.circular(13))), child: SizedBox(width: 40, height: 40, child: Icon(Icons.tune_rounded, size: 19)))),
    ]),
  );
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 235),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(colors: [Color(0xFF006D64), Color(0xFF00A996)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      boxShadow: [BoxShadow(color: AppColors.ocean.withValues(alpha: .18), blurRadius: 28, offset: const Offset(0, 14))],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(children: [
      Positioned(right: -35, top: -45, child: Container(width: 165, height: 165, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.sun.withValues(alpha: .95)))),
      Positioned(right: 22, bottom: -13, child: Transform.rotate(angle: -.12, child: const Icon(Icons.sports_bar_rounded, color: Colors.white, size: 116))),
      Padding(padding: const EdgeInsets.all(23), child: SizedBox(width: 225, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(30)), child: const Text('VERÃO O ANO INTEIRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .7))),
        const SizedBox(height: 15),
        const Text('O brinde começa\naqui.', style: TextStyle(color: Colors.white, fontSize: 30, height: 1.02, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 9),
        const Text('Bebidas geladas chegando no seu ritmo.', style: TextStyle(color: Color(0xFFDDFBF5), fontSize: 13, height: 1.3, fontWeight: FontWeight.w600)),
        const SizedBox(height: 17),
        Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: const Text('Explorar bebidas  →', style: TextStyle(color: AppColors.oceanDeep, fontSize: 12, fontWeight: FontWeight.w900))),
      ]))),
    ]),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.title, this.action);
  final String title, action;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
    Text(action, style: const TextStyle(color: AppColors.ocean, fontSize: 12, fontWeight: FontWeight.w900)),
  ]);
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    const data = [
      ('Heineken', 'Long Neck • 330 ml', 'R\$ 8,99', Icons.sports_bar_rounded, Color(0xFFE1F4E8)),
      ('Coca-Cola', 'Original • 2 L', 'R\$ 12,90', Icons.local_drink_rounded, Color(0xFFFFE4E1)),
      ('Red Label', 'Whisky • 750 ml', 'R\$ 89,90', Icons.liquor_rounded, Color(0xFFFFE9D5)),
    ];
    final p = data[index];
    return Container(
      width: 158, padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFEBEDE8))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Container(height: 105, decoration: BoxDecoration(color: p.$5, borderRadius: BorderRadius.circular(19)), alignment: Alignment.center, child: Icon(p.$4, size: 55, color: AppColors.ink)),
          Positioned(right: 7, top: 7, child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.favorite_border_rounded, size: 16))),
        ]),
        const SizedBox(height: 10), Text(p.$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        Text(p.$2, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600)),
        const Spacer(),
        Row(children: [Expanded(child: Text(p.$3, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))), Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.ocean, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_rounded, color: Colors.white, size: 20))]),
      ]),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(27)),
    child: const Row(children: [
      DecoratedBox(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(18))), child: SizedBox(width: 58, height: 58, child: Icon(Icons.bolt_rounded, color: AppColors.coral, size: 31))),
      SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Gelou? A gente resolve.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        SizedBox(height: 4),
        Text('Uma experiência rápida, simples e com a energia da Bahia.', style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.muted, fontWeight: FontWeight.w600)),
      ])),
    ]),
  );
}
