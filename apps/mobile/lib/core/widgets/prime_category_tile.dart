import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class _CategoryLook {
  const _CategoryLook(this.icon, this.bg, this.accent);
  final IconData icon;
  final Color bg;
  final Color accent;
}

_CategoryLook _look(String name) {
  final n = name.toLowerCase();
  if (n == 'todos') return const _CategoryLook(CupertinoIcons.square_grid_2x2_fill, Color(0xFFF1EDFF), Color(0xFF7867B7));
  if (n.contains('cervej')) return const _CategoryLook(CupertinoIcons.cart_fill, Color(0xFFFFF1C9), Color(0xFFD99A22));
  if (n.contains('vinh')) return const _CategoryLook(CupertinoIcons.drop_fill, Color(0xFFF9E8EF), Color(0xFFA95F7A));
  if (n.contains('whisk') || n.contains('destil') || n.contains('vodk') || n.contains('gin')) return const _CategoryLook(CupertinoIcons.flame_fill, Color(0xFFFFE8D1), Color(0xFFB97535));
  if (n.contains('energ')) return const _CategoryLook(CupertinoIcons.bolt_fill, Color(0xFFECE9FF), Color(0xFF7364BE));
  if (n.contains('refriger') || n.contains('suco')) return const _CategoryLook(CupertinoIcons.cube_box_fill, Color(0xFFFFE8E0), Color(0xFFD87860));
  if (n.contains('água') || n.contains('agua')) return const _CategoryLook(CupertinoIcons.drop_fill, Color(0xFFE4F5FA), Color(0xFF449CB6));
  if (n.contains('gelo')) return const _CategoryLook(CupertinoIcons.snow, Color(0xFFEAF7FA), Color(0xFF5DA7BC));
  if (n.contains('conveni')) return const _CategoryLook(CupertinoIcons.bag_fill, Color(0xFFE9F6EB), Color(0xFF609968));
  if (n.contains('combo') || n.contains('kit')) return const _CategoryLook(CupertinoIcons.gift_fill, Color(0xFFFFECD8), Color(0xFFC98242));
  return const _CategoryLook(CupertinoIcons.bag_fill, Color(0xFFF3F0EA), Color(0xFF80796E));
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
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? .965 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: look.bg,
                    borderRadius: BorderRadius.circular(widget.compact ? 20 : 24),
                    border: Border.all(
                      color: widget.selected
                          ? look.accent.withValues(alpha: .34)
                          : Colors.white.withValues(alpha: .9),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: widget.compact ? 48 : 60,
                      height: widget.compact ? 48 : 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .74),
                        borderRadius: BorderRadius.circular(widget.compact ? 16 : 19),
                      ),
                      child: Icon(
                        look.icon,
                        size: widget.compact ? 27 : 33,
                        color: look.accent,
                      ),
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
