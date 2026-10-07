import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

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
  bool _pressed = false;

  void _release() {
    if (_pressed && mounted) setState(() => _pressed = false);
  }

  Color get _soft {
    final n = widget.name.toLowerCase();
    if (n.contains('cervej')) return const Color(0xFFFFF2D2);
    if (n.contains('vinh')) return const Color(0xFFFBE8EE);
    if (n.contains('destil') ||
        n.contains('whisk') ||
        n.contains('vodk') ||
        n.contains('gin')) {
      return const Color(0xFFFFEBDD);
    }
    if (n.contains('energ')) return const Color(0xFFEDE9FF);
    if (n.contains('refriger') || n.contains('suco')) {
      return const Color(0xFFFFEBE4);
    }
    if (n.contains('agua') || n.contains('água')) {
      return const Color(0xFFE5F5FA);
    }
    if (n.contains('gelo')) return const Color(0xFFE8F4FA);
    if (n.contains('conveni')) return const Color(0xFFE7F5EC);
    if (n.contains('combo') || n.contains('kit')) {
      return const Color(0xFFFFEFDA);
    }
    if (n.contains('oferta') || n.contains('promo')) {
      return const Color(0xFFFFE8E2);
    }
    return AppColors.ocean50;
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.compact ? 25.0 : 29.0;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'Categoria ' + widget.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: _release,
        onTapUp: (_) {
          _release();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? .96 : 1,
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          child: AnimatedContainer(
            duration: AppMotion.standard,
            curve: AppMotion.curve,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 7 : 9,
              vertical: widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: widget.selected ? AppColors.ocean50 : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: widget.selected
                    ? AppColors.ocean300
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppMotion.standard,
                  width: widget.compact ? 50 : 58,
                  height: widget.compact ? 50 : 58,
                  decoration: BoxDecoration(
                    color: _soft,
                    borderRadius: BorderRadius.circular(
                      widget.compact ? AppRadius.md : AppRadius.lg,
                    ),
                    boxShadow: widget.selected ? AppShadows.soft : null,
                  ),
                  child: Icon(
                    AppIcons.category(widget.name),
                    size: iconSize,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: widget.compact ? 7 : 9),
                Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: widget.selected
                            ? AppColors.ocean800
                            : AppColors.ink,
                        fontWeight: widget.selected
                            ? FontWeight.w800
                            : FontWeight.w700,
                        fontSize: widget.compact ? 9.8 : 10.5,
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
