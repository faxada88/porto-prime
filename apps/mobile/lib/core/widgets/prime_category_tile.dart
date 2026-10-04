import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

class _CategoryLook {
  const _CategoryLook(this.asset, this.bg);
  final String asset;
  final Color bg;
}

_CategoryLook _look(String name) {
  final n = name.toLowerCase();
  if (n == 'todos') return const _CategoryLook('assets/category_icons/all.svg', Color(0xFFF2EEFF));
  if (n.contains('cervej')) return const _CategoryLook('assets/category_icons/beer.svg', Color(0xFFFFF3D2));
  if (n.contains('vinh')) return const _CategoryLook('assets/category_icons/wine.svg', Color(0xFFF9EAF0));
  if (n.contains('whisk') || n.contains('destil') || n.contains('vodk') || n.contains('gin')) return const _CategoryLook('assets/category_icons/spirits.svg', Color(0xFFFFEBD6));
  if (n.contains('energ')) return const _CategoryLook('assets/category_icons/energy.svg', Color(0xFFEFECFF));
  if (n.contains('refriger') || n.contains('suco')) return const _CategoryLook('assets/category_icons/softdrink.svg', Color(0xFFFFECE5));
  if (n.contains('água') || n.contains('agua')) return const _CategoryLook('assets/category_icons/water.svg', Color(0xFFE8F7FB));
  if (n.contains('gelo')) return const _CategoryLook('assets/category_icons/ice.svg', Color(0xFFEBF8FB));
  if (n.contains('conveni')) return const _CategoryLook('assets/category_icons/convenience.svg', Color(0xFFECF7EE));
  if (n.contains('combo') || n.contains('kit')) return const _CategoryLook('assets/category_icons/combo.svg', Color(0xFFFFEEDC));
  return const _CategoryLook('assets/category_icons/all.svg', Color(0xFFF4F1EC));
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
  bool _pressed = false;

  void _release() {
    if (_pressed && mounted) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final look = _look(widget.name);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'Categoria ${widget.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: _release,
        onTapUp: (_) {
          _release();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? .97 : 1,
          duration: const Duration(milliseconds: 85),
          curve: Curves.easeOutCubic,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: look.bg,
                    borderRadius: BorderRadius.circular(widget.compact ? 20 : 24),
                    border: Border.all(
                      color: widget.selected
                          ? AppColors.ink.withValues(alpha: .12)
                          : Colors.white.withValues(alpha: .92),
                    ),
                  ),
                  padding: EdgeInsets.all(widget.compact ? 10 : 13),
                  child: SvgPicture.asset(
                    look.asset,
                    fit: BoxFit.contain,
                    semanticsLabel: widget.name,
                    placeholderBuilder: (_) => Icon(
                      Icons.category_rounded,
                      size: widget.compact ? 32 : 40,
                      color: AppColors.oceanDeep,
                    ),
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
                  fontSize: widget.compact ? 10.1 : 11.5,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
