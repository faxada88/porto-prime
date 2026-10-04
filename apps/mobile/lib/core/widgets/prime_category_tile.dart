import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_theme.dart';

class _CategoryLook {
  const _CategoryLook(this.icon, this.from, this.to);
  final IconData icon;
  final Color from;
  final Color to;
}

_CategoryLook _look(String name) {
  final n = name.toLowerCase();
  if (n == 'todos') return const _CategoryLook(Symbols.grid_view_rounded, Color(0xFFFFE4D7), Color(0xFFFFF5EA));
  if (n.contains('cervej')) return const _CategoryLook(Symbols.sports_bar_rounded, Color(0xFFFFD974), Color(0xFFFFF1C9));
  if (n.contains('vinh')) return const _CategoryLook(Symbols.wine_bar_rounded, Color(0xFFFFC9C1), Color(0xFFFFE9DE));
  if (n.contains('whisk') || n.contains('destil') || n.contains('vodk') || n.contains('gin')) return const _CategoryLook(Symbols.liquor_rounded, Color(0xFFFFC46B), Color(0xFFFFE5B3));
  if (n.contains('energ')) return const _CategoryLook(Symbols.bolt_rounded, Color(0xFFFFD8B5), Color(0xFFFFEEE0));
  if (n.contains('refriger') || n.contains('suco')) return const _CategoryLook(Symbols.local_drink_rounded, Color(0xFFFFC4BA), Color(0xFFFFE9E2));
  if (n.contains('água') || n.contains('agua')) return const _CategoryLook(Symbols.water_drop_rounded, Color(0xFFD8F1F3), Color(0xFFF1FAF7));
  if (n.contains('gelo')) return const _CategoryLook(Symbols.ac_unit_rounded, Color(0xFFDFF3F4), Color(0xFFF5FBF8));
  if (n.contains('conveni')) return const _CategoryLook(Symbols.shopping_basket_rounded, Color(0xFFFFD0A8), Color(0xFFFFE9CF));
  if (n.contains('combo') || n.contains('kit')) return const _CategoryLook(Symbols.inventory_2_rounded, Color(0xFFFFC884), Color(0xFFFFE6B9));
  return const _CategoryLook(Symbols.local_drink_rounded, Color(0xFFFFD8C2), Color(0xFFFFF0E5));
}

class PrimeCategoryTile extends StatefulWidget {
  const PrimeCategoryTile({
    super.key,
    required this.name,
    required this.onTap,
    this.selected = false,
    this.compact = false,
    this.imageUrls = const [],
  });

  final String name;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;
  final List<String> imageUrls;

  @override
  State<PrimeCategoryTile> createState() => _PrimeCategoryTileState();
}

class _PrimeCategoryTileState extends State<PrimeCategoryTile> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final look = _look(widget.name);
    final selected = widget.selected;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Categoria ${widget.name}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) {
          setState(() => pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: pressed ? .95 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: selected
                          ? [AppColors.mintStrong, AppColors.mint]
                          : [look.from, look.to],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(widget.compact ? 20 : 24),
                    border: Border.all(color: selected ? AppColors.oceanDeep : Colors.white, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: (selected ? AppColors.oceanDeep : look.from).withValues(alpha: .28),
                        blurRadius: 15,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.compact ? 19 : 23),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          right: -12,
                          top: -15,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: .34),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -8,
                          bottom: -15,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: .22),
                            ),
                          ),
                        ),
                        if (widget.imageUrls.isNotEmpty)
                          _ProductComposition(urls: widget.imageUrls)
                        else
                          Icon(
                            look.icon,
                            size: widget.compact ? 42 : 50,
                            color: selected ? AppColors.oceanDeep : AppColors.oceanDeep,
                            fill: 1,
                            weight: 650,
                            shadows: const [
                              Shadow(color: Color(0x24000000), blurRadius: 7, offset: Offset(0, 4)),
                            ],
                          ),
                        if (selected)
                          Positioned(
                            right: 5,
                            top: 5,
                            child: Container(
                              width: 19,
                              height: 19,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Symbols.check_rounded, size: 14, color: AppColors.oceanDeep, weight: 800),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: widget.compact ? 10.2 : 11.5,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductComposition extends StatelessWidget {
  const _ProductComposition({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final shown = urls.where((e) => e.isNotEmpty).take(3).toList();
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 6,
          child: Container(
            width: 52,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        for (var i = 0; i < shown.length; i++)
          Positioned(
            left: shown.length == 1 ? 13 : 3.0 + (i * 15),
            top: i == 1 ? 3 : 8,
            bottom: 5,
            child: Transform.rotate(
              angle: shown.length == 1 ? 0 : (i - 1) * .09,
              child: Image.network(
                shown[i],
                width: shown.length == 1 ? 54 : 43,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
      ],
    );
  }
}
