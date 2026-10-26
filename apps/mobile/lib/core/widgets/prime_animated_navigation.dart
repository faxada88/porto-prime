import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:flutter/services.dart';
import '../localization/prime_localization.dart';
import '../theme/app_theme.dart';

/// The value is the existing destination ID, never its visible row position.
@immutable
class PrimeNavigationDestination {
  const PrimeNavigationDestination({required this.value, required this.label,
    required this.icon, this.selectedIcon, this.badgeCount = 0, this.semanticLabel});
  final int value, badgeCount;
  final String label;
  final String? semanticLabel;
  final IconData icon;
  final IconData? selectedIcon;
}

/// Samples a lightly underdamped physical spring over the 300 ms transition.
/// Both the positioned capsule and the icon colors share the same trajectory.
class PrimeNavigationSpring extends Curve {
  const PrimeNavigationSpring();
  static const duration = Duration(milliseconds: 300);
  static final _spring = SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 900, damping: 48), 0, 1, 0);
  @override double transformInternal(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return _spring.x(t * .3);
  }
}

/// Touch previews are visual only. The owner keeps routes and selectedValue.
class PrimeAnimatedNavigation extends StatefulWidget {
  const PrimeAnimatedNavigation({super.key, required this.destinations,
    required this.selectedValue, required this.onSelect, this.enabled = true, this.maxWidth = 600})
    : assert(destinations.length > 1);
  final List<PrimeNavigationDestination> destinations;
  final int selectedValue;
  final ValueChanged<int> onSelect;
  final bool enabled;
  final double maxWidth;
  static const petrol = Color(0xFF073E43);
  static const inactive = Color(0xFF657E7B);
  static const capsuleKey = ValueKey('prime_navigation_capsule');
  static Key destinationKey(int value) => ValueKey('prime_navigation_destination_$value');
  @override State<PrimeAnimatedNavigation> createState() => _PrimeAnimatedNavigationState();
}

class _PrimeAnimatedNavigationState extends State<PrimeAnimatedNavigation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _selection;
  late double _from, _to;
  bool _reduceMotion = false, _tickerEnabled = true, _foreground = true, _snapLayout = true;
  bool _routeCurrent = true;
  int? _previewValue;
  double? _lastWidth;
  TextDirection? _lastDirection;
  static const _spring = PrimeNavigationSpring();

  double _slot([int? value]) {
    final index = widget.destinations.indexWhere((item) => item.value == (value ?? widget.selectedValue));
    return (index < 0 ? 0 : index).toDouble();
  }
  double get _visualSlot => _selection.value == 1 ? _to
    : _from + (_to - _from) * _spring.transform(_selection.value);
  bool get _canAnimate => !_reduceMotion && _tickerEnabled && _foreground && _routeCurrent;
  void _moveTo(double target) {
    if (!_canAnimate) {
      _to = target;
      _snap();
    } else if (target != _to) {
      _from = _visualSlot;
      _to = target;
      _selection.forward(from: 0);
    }
  }
  void _preview(int value) {
    if (!widget.enabled) return;
    final preview = value == widget.selectedValue ? null : value;
    if (_previewValue == preview && _to == _slot(value)) return;
    setState(() {
      _previewValue = preview;
      _snapLayout = !_canAnimate;
      _moveTo(_slot(value));
    });
  }
  void _cancelPreview() {
    if (_previewValue == null) return;
    setState(() { _previewValue = null; _moveTo(_slot()); });
  }
  void _snap() {
    _selection.stop();
    _from = _to;
    _selection.value = 1;
    _snapLayout = true;
  }
  @override void initState() {
    super.initState();
    _from = _to = _slot();
    _selection = AnimationController(vsync: this, duration: PrimeNavigationSpring.duration, value: 1);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }
  @override void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _routeCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (!_routeCurrent) {
      _previewValue = null;
      _to = _slot();
    }
    if (!_canAnimate) _snap();
  }
  @override void didUpdateWidget(covariant PrimeAnimatedNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final topologyChanged = !listEquals(oldWidget.destinations.map((item) => item.value).toList(),
      widget.destinations.map((item) => item.value).toList());
    if (topologyChanged || oldWidget.selectedValue != widget.selectedValue) _previewValue = null;
    final target = _slot(_previewValue);
    _snapLayout = topologyChanged || !_canAnimate;
    if (topologyChanged || !_canAnimate) {
      _to = target;
      _snap();
    } else { _moveTo(target); }
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) { _previewValue = null; _to = _slot(); _snap(); }
    if (mounted) setState(() {});
  }
  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selection.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) => SafeArea(top: false,
    minimum: const EdgeInsets.fromLTRB(8, 8, 8, 9),
    child: Center(heightFactor: 1, child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: LayoutBuilder(builder: (context, constraints) {
        final direction = Directionality.of(context);
        final locale = Localizations.maybeLocaleOf(context);
        final scaler = MediaQuery.textScalerOf(context);
        // A horizontal fallback retains 44 px targets in unusually tiny viewports.
        final width = math.max(constraints.maxWidth, widget.destinations.length * 44.0 + 12).toDouble();
        final slotWidth = (width - 12) / widget.destinations.length;
        final capsuleWidth = math.min(64.0, slotWidth - 8).toDouble();
        var labelHeight = 0.0;
        final labelStyle = DefaultTextStyle.of(context).style.merge(
          const TextStyle(fontSize: 11, height: 1.25, fontWeight: FontWeight.w700));
        for (final item in widget.destinations) {
          final painter = TextPainter(text: TextSpan(text: translateLabel(item.label), style: labelStyle),
            textDirection: direction, textScaler: scaler, locale: locale)
            ..layout(maxWidth: slotWidth - 8);
          labelHeight = math.max(labelHeight, painter.height.ceilToDouble() + 2).toDouble();
          painter.dispose();
        }
        final height = 44.0 + 4 + labelHeight;
        final geometryChanged = _lastWidth != width || _lastDirection != direction;
        if (geometryChanged) {
          _selection.stop();
          _from = _to;
        }
        _lastWidth = width;
        _lastDirection = direction;
        final duration = _canAnimate && !_snapLayout && !geometryChanged
          ? PrimeNavigationSpring.duration : Duration.zero;
        double centerFor(double slot) => (direction == TextDirection.rtl
          ? widget.destinations.length - 1 - slot : slot) * slotWidth + slotWidth / 2;
        final body = SizedBox(width: width, height: height + 14,
          child: Padding(padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
            child: RepaintBoundary(child: AnimatedBuilder(animation: _selection, builder: (context, _) {
              final center = centerFor(_visualSlot);
              return Stack(clipBehavior: Clip.none, children: [
                AnimatedPositioned(duration: duration, curve: _spring,
                  left: centerFor(_to) - capsuleWidth / 2, top: 0, width: capsuleWidth, height: 44,
                  child: IgnorePointer(child: ExcludeSemantics(child: DecoratedBox(
                    key: PrimeAnimatedNavigation.capsuleKey,
                    decoration: BoxDecoration(color: PrimeAnimatedNavigation.petrol,
                      borderRadius: BorderRadius.circular(24)))))),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var i = 0; i < widget.destinations.length; i++)
                    Expanded(child: _PrimeNavigationButton(
                      key: ValueKey(widget.destinations[i].value), item: widget.destinations[i],
                      selected: i.toDouble() == _to, enabled: widget.enabled,
                      reduceMotion: _reduceMotion, labelHeight: labelHeight, ordinal: i,
                      tint: _iconTint(centerFor(i.toDouble()), center, capsuleWidth),
                      onPreview: () => _preview(widget.destinations[i].value),
                      onCancelPreview: _cancelPreview,
                      onTap: () => widget.onSelect(widget.destinations[i].value))),
                ]),
              ]);
            }))),
        );
        return DecoratedBox(decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(29),
          boxShadow: const [BoxShadow(color: Color(0x07073E43), blurRadius: 18, offset: Offset(0, 4))]),
          child: Material(color: Colors.white, clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29),
            side: const BorderSide(color: Color(0xFFE0E9E8))),
          child: width > constraints.maxWidth
            ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: body) : body));
      })),
    ));

  Color _iconTint(double iconCenter, double capsuleCenter, double capsuleWidth) {
    final overlap = math.max(0.0, math.min(iconCenter + 12, capsuleCenter + capsuleWidth / 2)
      - math.max(iconCenter - 12, capsuleCenter - capsuleWidth / 2)).toDouble();
    final weight = (overlap / 24).clamp(0.0, 1.0).toDouble();
    return Color.lerp(PrimeAnimatedNavigation.inactive, Colors.white, weight)!;
  }
}

class _PrimeNavigationButton extends StatefulWidget {
  const _PrimeNavigationButton({super.key, required this.item, required this.selected,
    required this.enabled, required this.reduceMotion, required this.labelHeight,
    required this.ordinal, required this.tint, required this.onTap,
    required this.onPreview, required this.onCancelPreview});
  final PrimeNavigationDestination item;
  final bool selected, enabled, reduceMotion;
  final double labelHeight;
  final int ordinal;
  final Color tint;
  final VoidCallback onTap, onPreview, onCancelPreview;
  @override State<_PrimeNavigationButton> createState() => _PrimeNavigationButtonState();
}
class _PrimeNavigationButtonState extends State<_PrimeNavigationButton> {
  bool _pressed = false;
  @override void didUpdateWidget(covariant _PrimeNavigationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _pressed = false;
  }
  void _press(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }
  void _activate() {
    if (!widget.enabled) return;
    _press(false);
    widget.onPreview();
    if (!widget.reduceMotion) unawaited(HapticFeedback.selectionClick().catchError((Object _) {}));
    widget.onTap();
  }
  @override Widget build(BuildContext context) {
    final item = widget.item;
    final duration = widget.reduceMotion ? Duration.zero : const Duration(milliseconds: 160);
    return Semantics(key: PrimeAnimatedNavigation.destinationKey(item.value),
      button: true, selected: widget.selected, enabled: widget.enabled,
      sortKey: OrdinalSortKey(widget.ordinal.toDouble()), excludeSemantics: true,
      label: translateLabel(item.semanticLabel ?? item.label), onTap: widget.enabled ? _activate : null,
      child: Tooltip(message: translateLabel(item.semanticLabel ?? item.label),
        child: InkWell(onTap: widget.enabled ? _activate : null,
          onTapDown: widget.enabled ? (_) { _press(true); widget.onPreview(); } : null,
          onTapCancel: widget.enabled ? () { _press(false); widget.onCancelPreview(); } : null,
          borderRadius: BorderRadius.circular(22),
          enableFeedback: false, splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent, highlightColor: Colors.transparent,
          focusColor: const Color(0x18073E43), hoverColor: const Color(0x08073E43),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: 44, child: Center(child: SizedBox(width: 44, height: 44,
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                AnimatedScale(scale: _pressed ? .9 : widget.selected ? 1.04 : 1,
                  duration: duration, curve: Curves.easeOutBack,
                  child: Icon(widget.selected ? item.selectedIcon ?? item.icon : item.icon,
                    size: 24, color: widget.tint)),
                if (item.badgeCount > 0) Positioned(top: 0, right: -1,
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(color: AppColors.coral600,
                      borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white, width: 1.5)),
                    alignment: Alignment.center,
                    child: Text(item.badgeCount > 99 ? '99+' : item.badgeCount.toString(),
                      textScaler: TextScaler.linear(math.min(MediaQuery.textScalerOf(context).scale(10) / 10, 1.4).toDouble()),
                      style: const TextStyle(fontSize: 10, height: 1.2,
                        fontWeight: FontWeight.w800, color: Colors.white)))),
              ])))),
            const SizedBox(height: 4),
            SizedBox(height: widget.labelHeight, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: PrimeText(item.label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, height: 1.25, fontWeight: FontWeight.w700,
                  color: widget.selected ? PrimeAnimatedNavigation.petrol : PrimeAnimatedNavigation.inactive)))),
          ]))));
  }
}
