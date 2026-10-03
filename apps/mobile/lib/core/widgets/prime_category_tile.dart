import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_theme.dart';

class _CategoryVisual {
  const _CategoryVisual(this.icon, this.a, this.b, this.glow);
  final IconData icon;
  final Color a;
  final Color b;
  final Color glow;
}

_CategoryVisual _visual(String name) {
  final n = name.toLowerCase();
  if (n == 'todos') return const _CategoryVisual(Symbols.grid_view_rounded, Color(0xFF148D82), Color(0xFF075B54), Color(0xFF74E0D1));
  if (n.contains('cervej')) return const _CategoryVisual(Symbols.sports_bar_rounded, Color(0xFFFFC44D), Color(0xFFE48A19), Color(0xFFFFE39B));
  if (n.contains('vinh')) return const _CategoryVisual(Symbols.wine_bar_rounded, Color(0xFFB9476A), Color(0xFF70243D), Color(0xFFF0A8BD));
  if (n.contains('whisk')) return const _CategoryVisual(Symbols.liquor_rounded, Color(0xFFD99445), Color(0xFF75451E), Color(0xFFF6C67D));
  if (n.contains('vodk')) return const _CategoryVisual(Symbols.liquor_rounded, Color(0xFF7EB9DD), Color(0xFF326B91), Color(0xFFBEE7FF));
  if (n.contains('destil')) return const _CategoryVisual(Symbols.liquor_rounded, Color(0xFFE39B45), Color(0xFF8C4E1C), Color(0xFFFFD08D));
  if (n.contains('gin') || n.contains('drink')) return const _CategoryVisual(Symbols.local_bar_rounded, Color(0xFF72B997), Color(0xFF33745A), Color(0xFFB7E5CF));
  if (n.contains('energ')) return const _CategoryVisual(Symbols.bolt_rounded, Color(0xFF826AE6), Color(0xFF4832A4), Color(0xFFC5B9FF));
  if (n.contains('refriger') || n.contains('suco')) return const _CategoryVisual(Symbols.local_drink_rounded, Color(0xFFFF705C), Color(0xFFC9362C), Color(0xFFFFB2A6));
  if (n.contains('água') || n.contains('agua')) return const _CategoryVisual(Symbols.water_drop_rounded, Color(0xFF51BCEB), Color(0xFF1776A5), Color(0xFFAEE7FF));
  if (n.contains('gelo')) return const _CategoryVisual(Symbols.ac_unit_rounded, Color(0xFF8ED9EF), Color(0xFF3B91AF), Color(0xFFD7F6FF));
  if (n.contains('conveni') || n.contains('snack')) return const _CategoryVisual(Symbols.local_convenience_store_rounded, Color(0xFFFF8D55), Color(0xFFC95025), Color(0xFFFFC5A8));
  if (n.contains('combo') || n.contains('kit')) return const _CategoryVisual(Symbols.inventory_2_rounded, Color(0xFFF2B34C), Color(0xFFB36A19), Color(0xFFFFD996));
  return const _CategoryVisual(Symbols.local_drink_rounded, Color(0xFF37AFA1), Color(0xFF087166), Color(0xFF9CE6DC));
}

IconData categoryIcon(String name) => _visual(name).icon;

class PrimeCategoryTile extends StatefulWidget {
  const PrimeCategoryTile({
    super.key,
    required this.name,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });

  final String name;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;

  @override
  State<PrimeCategoryTile> createState() => _PrimeCategoryTileState();
}

class _PrimeCategoryTileState extends State<PrimeCategoryTile> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final visual = _visual(widget.name);
    final iconSize = widget.compact ? 47.0 : 56.0;

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
          scale: pressed ? .94 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(
              widget.compact ? 5 : 8,
              widget.compact ? 6 : 9,
              widget.compact ? 5 : 8,
              widget.compact ? 7 : 10,
            ),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [Color(0xFF0B7168), Color(0xFF064B46)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Colors.white, Color(0xFFF9FBF9)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              borderRadius: BorderRadius.circular(widget.compact ? 19 : 23),
              border: Border.all(
                color: selected ? const Color(0xFF0B7168) : const Color(0xFFE5EBE7),
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? AppColors.oceanDeep.withValues(alpha: .20)
                      : const Color(0xFF17362F).withValues(alpha: .065),
                  blurRadius: selected ? 20 : 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 1,
                        child: Container(
                          width: iconSize * .72,
                          height: iconSize * .22,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: selected ? .16 : .10),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [visual.a, visual.b],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white.withValues(alpha: .75), width: 1.4),
                          boxShadow: [
                            BoxShadow(
                              color: visual.glow.withValues(alpha: .38),
                              blurRadius: 12,
                              offset: const Offset(-2, -2),
                            ),
                            BoxShadow(
                              color: visual.b.withValues(alpha: .34),
                              blurRadius: 9,
                              offset: const Offset(2, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 8,
                              top: 6,
                              child: Container(
                                width: iconSize * .28,
                                height: iconSize * .13,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .32),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                            Center(
                              child: Icon(
                                visual.icon,
                                size: widget.compact ? 27 : 31,
                                color: Colors.white,
                                fill: 1,
                                weight: 650,
                                grade: 80,
                                shadows: const [
                                  Shadow(color: Color(0x42000000), blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: widget.compact ? 7 : 9),
                Text(
                  widget.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontSize: widget.compact ? 9.7 : 11,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
