import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_icons.dart';
import 'prime_category_artwork.dart';
import '../theme/app_theme.dart';

class PrimeCategoryTile extends StatefulWidget {
  const PrimeCategoryTile({
    super.key,
    required this.name,
    required this.onTap,
    this.selected = false,
    this.compact = false,
    this.imageUrls = const [],
    this.iconKey,
  });

  final String name;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;
  final List<String> imageUrls;
  final String? iconKey;

  @override
  State<PrimeCategoryTile> createState() => _PrimeCategoryTileState();
}

class _PrimeCategoryTileState extends State<PrimeCategoryTile> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final visual = AppIcons.categoryVisual(widget.name, iconKey: widget.iconKey);
    final selected = widget.selected;
    final compact = widget.compact;
    final iconBox = compact ? 56.0 : 64.0;

    final initials = widget.name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty)
        .take(2).map((part) => String.fromCharCode(part.runes.first)).join().toUpperCase();
    Widget artwork() => visual.key == null
      ? SizedBox(width: 42, height: 42, child: Center(child: PrimeText(initials,
          textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: visual.foreground))))
      : widget.iconKey != null && widget.iconKey!.isNotEmpty
        ? SizedBox.square(dimension: compact ? 37 : 42, child: Icon(visual.icon,
            size: compact ? 29 : 32, color: visual.foreground))
        : PrimeCategoryArtwork(icon: visual.icon, size: compact ? 37 : 42, color: visual.foreground);
    return Semantics(
      button: true,
      selected: selected,
      label: translateLabel( 'Categoria ${widget.name}'),
      onTap: widget.onTap,
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            child: AnimatedScale(
              scale: _pressed ? .96 : (_hovered ? 1.015 : 1),
              duration: AppMotion.resolve(context, AppMotion.fast),
              curve: AppMotion.curve,
              child: AnimatedContainer(
                duration: AppMotion.resolve(context, AppMotion.standard),
                curve: AppMotion.curve,
                padding: EdgeInsets.fromLTRB(
                  compact ? 1 : 4,
                  compact ? 6 : 8,
                  compact ? 1 : 4,
                  compact ? 7 : 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.ocean50
                      : _hovered
                      ? AppColors.surfaceSoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: _focused
                        ? AppColors.ocean700
                        : selected
                        ? AppColors.ocean300
                        : _hovered
                        ? AppColors.stroke
                        : Colors.transparent,
                  ),
                  boxShadow: selected
                      ? AppShadows.soft
                      : _hovered
                      ? [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: .035),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.resolve(context, AppMotion.standard),
                      curve: AppMotion.curve,
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [visual.background, selected ? AppColors.ocean100 : AppColors.surface]),
                        boxShadow: [BoxShadow(color: visual.foreground.withValues(alpha: .045), blurRadius: 10, offset: const Offset(0, 4))],
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected
                              ? visual.foreground.withValues(alpha: .13)
                              : Colors.white.withValues(alpha: .7),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              width: 39,
                              height: 39,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .32),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: visual.offset,
                            child: (widget.iconKey == null || widget.iconKey!.isEmpty) && widget.imageUrls.isNotEmpty && widget.imageUrls.first.isNotEmpty
                              ? SizedBox.square(dimension: compact ? 37 : 42, child: Image.network(widget.imageUrls.first,
                                  fit: BoxFit.contain, errorBuilder: (_, __, ___) => artwork()))
                              : artwork(),
                          ),
                          if (selected)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: AppColors.ocean800,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surface,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  AppIcons.check,
                                  size: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 7 : 8),
                    PrimeText(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected
                            ? AppColors.ocean800
                            : AppColors.inkSoft,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w700,
                        fontSize: compact
                            ? AppFontSize.caption
                            : AppFontSize.label,
                        height: 1.2,
                        letterSpacing: -.08,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

