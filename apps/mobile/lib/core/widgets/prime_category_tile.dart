import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_theme.dart';

IconData categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('cervej')) return Symbols.sports_bar_rounded;
  if (n.contains('vinh')) return Symbols.wine_bar_rounded;
  if (n.contains('whisk') || n.contains('destil') || n.contains('vodk')) return Symbols.liquor_rounded;
  if (n.contains('gin') || n.contains('drink')) return Symbols.local_bar_rounded;
  if (n.contains('energ')) return Symbols.bolt_rounded;
  if (n.contains('refriger') || n.contains('suco')) return Symbols.local_drink_rounded;
  if (n.contains('água') || n.contains('agua')) return Symbols.water_drop_rounded;
  if (n.contains('gelo')) return Symbols.ac_unit_rounded;
  if (n.contains('conveni') || n.contains('snack')) return Symbols.local_convenience_store_rounded;
  if (n.contains('combo') || n.contains('kit')) return Symbols.inventory_2_rounded;
  return Symbols.local_drink_rounded;
}

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
          scale: pressed ? .96 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 6 : 8,
              vertical: widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.oceanDeep : Colors.white,
              borderRadius: BorderRadius.circular(widget.compact ? 18 : 22),
              border: Border.all(
                color: selected ? AppColors.oceanDeep : AppColors.stroke,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.oceanDeep.withValues(alpha: .18),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : AppShadows.soft,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: widget.compact ? 42 : 48,
                  height: widget.compact ? 42 : 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: .14)
                        : AppColors.mint,
                    borderRadius: BorderRadius.circular(widget.compact ? 14 : 16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    categoryIcon(widget.name),
                    size: widget.compact ? 23 : 26,
                    color: selected ? Colors.white : AppColors.oceanDeep,
                    fill: selected ? 1 : 0,
                    weight: 520,
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
                    fontSize: widget.compact ? 10 : 11,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.15,
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
