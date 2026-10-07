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
  bool _hovered = false;

  void _release() {
    if (_pressed && mounted) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final visual = AppIcons.categoryVisual(widget.name);
    final selected = widget.selected;
    final compact = widget.compact;
    final containerSize = compact ? 50.0 : 58.0;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Categoria ' + widget.name,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: _release,
          onTapUp: (_) {
            _release();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _pressed ? .965 : (_hovered ? 1.018 : 1),
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            child: AnimatedContainer(
              duration: AppMotion.standard,
              curve: AppMotion.curve,
              padding: EdgeInsets.fromLTRB(
                compact ? 5 : 7,
                compact ? 7 : 9,
                compact ? 5 : 7,
                compact ? 7 : 9,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.surface
                    : _hovered
                        ? AppColors.surface.withValues(alpha: .72)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: selected
                      ? AppColors.ocean300
                      : _hovered
                          ? AppColors.stroke
                          : Colors.transparent,
                ),
                boxShadow: selected || _hovered ? AppShadows.soft : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.standard,
                    curve: AppMotion.curve,
                    width: containerSize,
                    height: containerSize,
                    decoration: BoxDecoration(
                      color: selected
                          ? Color.lerp(
                              visual.background,
                              AppColors.surface,
                              .12,
                            )
                          : visual.background,
                      borderRadius: BorderRadius.circular(
                        compact ? AppRadius.md : AppRadius.lg,
                      ),
                      border: Border.all(
                        color: selected
                            ? visual.foreground.withValues(alpha: .14)
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Transform.translate(
                        offset: _opticalOffset(widget.name),
                        child: Icon(
                          visual.icon,
                          size: visual.size - (compact ? 2 : 0),
                          color: visual.foreground,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 7 : 9),
                  Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color:
                              selected ? AppColors.ocean800 : AppColors.ink,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w700,
                          fontSize: compact ? 9.4 : 10.2,
                          letterSpacing: -.05,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset _opticalOffset(String name) {
    final value = name.toLowerCase();
    if (value.contains('vinh')) return const Offset(0, -.5);
    if (value.contains('cervej')) return const Offset(.4, .2);
    if (value.contains('gelo')) return const Offset(0, -.3);
    if (value.contains('energ')) return const Offset(.2, 0);
    return Offset.zero;
  }
}
