import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_theme.dart';

class _CategoryLook {
  const _CategoryLook(this.icon, this.bg, this.accent);
  final IconData icon;
  final Color bg;
  final Color accent;
}

_CategoryLook _look(String name) {
  final n = name.toLowerCase();
  if (n == 'todos') return const _CategoryLook(Symbols.grid_view_rounded, Color(0xFFF1ECFF), Color(0xFF7967B8));
  if (n.contains('cervej')) return const _CategoryLook(Symbols.sports_bar_rounded, Color(0xFFFFF0C9), Color(0xFFE5A52A));
  if (n.contains('vinh')) return const _CategoryLook(Symbols.wine_bar_rounded, Color(0xFFF7E5EC), Color(0xFFA95D78));
  if (n.contains('whisk') || n.contains('destil') || n.contains('vodk') || n.contains('gin')) return const _CategoryLook(Symbols.liquor_rounded, Color(0xFFFFE7D0), Color(0xFFC77B36));
  if (n.contains('energ')) return const _CategoryLook(Symbols.bolt_rounded, Color(0xFFECE8FF), Color(0xFF7664C8));
  if (n.contains('refriger') || n.contains('suco')) return const _CategoryLook(Symbols.local_drink_rounded, Color(0xFFFFE7DF), Color(0xFFE27D62));
  if (n.contains('água') || n.contains('agua')) return const _CategoryLook(Symbols.water_drop_rounded, Color(0xFFE3F5FA), Color(0xFF4BA8C2));
  if (n.contains('gelo')) return const _CategoryLook(Symbols.ac_unit_rounded, Color(0xFFEAF7FA), Color(0xFF63ABC0));
  if (n.contains('conveni')) return const _CategoryLook(Symbols.shopping_basket_rounded, Color(0xFFE8F5E9), Color(0xFF64A46D));
  if (n.contains('combo') || n.contains('kit')) return const _CategoryLook(Symbols.inventory_2_rounded, Color(0xFFFFEBD7), Color(0xFFD78A45));
  return const _CategoryLook(Symbols.local_mall_rounded, Color(0xFFF1EFEA), Color(0xFF827C71));
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
    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'Categoria ${widget.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) {
          setState(() => pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: pressed ? .96 : 1,
          duration: const Duration(milliseconds: 110),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: widget.selected ? look.bg.withValues(alpha: .75) : look.bg,
                    borderRadius: BorderRadius.circular(widget.compact ? 19 : 23),
                    border: Border.all(
                      color: widget.selected ? look.accent.withValues(alpha: .42) : Colors.transparent,
                      width: 1.3,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .68),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Icon(
                        look.icon,
                        size: widget.compact ? 39 : 48,
                        color: look.accent,
                        fill: 1,
                        weight: 560,
                        grade: 100,
                      ),
                      if (widget.selected)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(color: look.accent, shape: BoxShape.circle),
                            child: const Icon(Symbols.check_rounded, size: 13, color: Colors.white, weight: 800),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: widget.compact ? 10 : 11.5,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
