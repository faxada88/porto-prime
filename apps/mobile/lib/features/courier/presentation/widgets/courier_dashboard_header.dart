import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/courier_portrait.dart';
import '../../../../core/widgets/prime_ui.dart';
import '../../../../core/widgets/prime_animated_navigation.dart' show PrimeNavigationSpring;
import 'courier_dashboard_map.dart' show courierGreen, courierInk;

/// Availability is one action. The avatar also exposes the existing logout.
class CourierDashboardHeader extends StatefulWidget {
  const CourierDashboardHeader({super.key, required this.name, required this.photo,
    required this.online, required this.active, required this.unreadCount,
    required this.onNotifications, required this.onProfile, required this.onLogout,
    required this.onRoute, required this.onChanged, this.waiting = false, this.receivingOffer = false});
  final String name;
  final String? photo;
  final bool online, active, waiting, receivingOffer;
  final int unreadCount;
  final VoidCallback onNotifications, onProfile, onRoute;
  final VoidCallback? onLogout;
  final Future<void> Function(bool)? onChanged;
  @override State<CourierDashboardHeader> createState() => _CourierDashboardHeaderState();
}

class _CourierDashboardHeaderState extends State<CourierDashboardHeader> {
  bool _changing = false;
  Future<void> _toggle() async {
    if (_changing || widget.onChanged == null) return;
    setState(() => _changing = true);
    try { await widget.onChanged!(!widget.online); }
    catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: PrimeText(PrimeMessages.friendly(error))));
      }
    } finally { if (mounted) setState(() => _changing = false); }
  }

  @override Widget build(BuildContext context) {
    final names = widget.name.trim().split(RegExp(r'\s+'));
    final firstName = names.first;
    final name = firstName.isEmpty ? 'Motoboy' : '${firstName[0].toUpperCase()}${firstName.substring(1).toLowerCase()}';
    return SafeArea(bottom: false, child: Padding(
      padding: EdgeInsets.fromLTRB(18, 10, 18, widget.active ? 8 : 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(child: _CourierBrand()),
          const SizedBox(width: 12),
          Badge(isLabelVisible: widget.unreadCount > 0,
            label: Text(widget.unreadCount > 9 ? '9+' : widget.unreadCount.toString()),
            child: IconButton.filledTonal(onPressed: widget.onNotifications,
              tooltip: translateLabel('Atualizações'),
              style: IconButton.styleFrom(backgroundColor: const Color(0xFFEDF3F5),
                foregroundColor: courierGreen, minimumSize: const Size(44, 44)),
              icon: const Icon(AppIcons.bell, size: 23))),
          const SizedBox(width: 12),
          PopupMenuButton<String>(tooltip: translateLabel('Minha conta'),
            enabled: widget.onLogout != null,
            onSelected: (value) {
              if (value == 'profile') { widget.onProfile(); }
              if (value == 'logout') { widget.onLogout?.call(); }
              if (value == 'availability') { _toggle(); }
            },
            itemBuilder: (_) => [
              if (widget.receivingOffer && widget.onChanged != null)
                PopupMenuItem(value: 'availability', enabled: !_changing, child: Row(children: [
                  const Icon(AppIcons.power, size: 19), const SizedBox(width: 10),
                  Flexible(child: PrimeText(widget.online ? 'Ficar offline' : 'Ficar online'))])),
              PopupMenuItem(value: 'profile', child: Row(children: [
                const Icon(AppIcons.user, size: 19), const SizedBox(width: 10),
                Flexible(child: PrimeText('Meu perfil'))])),
              PopupMenuItem(value: 'logout', child: Row(children: [
                const Icon(AppIcons.logout, size: 19), const SizedBox(width: 10),
                Flexible(child: PrimeText('Sair da conta'))])),
            ],
            child: SizedBox(width: 46, height: 46, child: Stack(children: [
              CourierPortrait(photo: widget.photo, size: 46),
              Positioned(right: 0, bottom: 0, child: Container(width: 14, height: 14,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: widget.online ? const Color(0xFF159447) : const Color(0xFF83939B),
                  border: Border.all(color: Colors.white, width: 2.5)))),
            ]))),
        ]),
        if (widget.active) ...[
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, box) {
            const title = PrimeText('Sua entrega', style: TextStyle(fontSize: 21,
              height: 1.3, fontWeight: FontWeight.w800, letterSpacing: -.5, color: courierInk));
            final details = TextButton(onPressed: widget.onRoute,
              style: TextButton.styleFrom(foregroundColor: courierGreen,
                minimumSize: const Size(44, 44), padding: const EdgeInsets.symmetric(horizontal: 10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const PrimeText('Detalhes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 5), const Icon(AppIcons.chevronRight, size: 17),
              ]));
            return box.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(13) > 19
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, details])
              : Row(children: [const Expanded(child: title), details]);
          }),
        ] else if (!widget.receivingOffer) ...[
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, box) {
            final scaler = MediaQuery.textScalerOf(context);
            final direction = Directionality.of(context);
            final locale = Localizations.maybeLocaleOf(context);
            final baseStyle = DefaultTextStyle.of(context).style;
            final nameStyle = baseStyle.merge(TextStyle(fontSize: box.maxWidth < 330 ? 28 : 30,
              height: 1.18, fontWeight: FontWeight.w800, letterSpacing: -.8, color: courierInk));
            const statusStyle = TextStyle(fontSize: 12.5, height: 1.1,
              fontWeight: FontWeight.w800, letterSpacing: .4);
            var widest = 0.0;
            for (final label in ['ONLINE', 'OFFLINE']) {
              final painter = TextPainter(text: TextSpan(text: translateLabel(label),
                style: baseStyle.merge(statusStyle)), textDirection: direction,
                textScaler: scaler, locale: locale)..layout();
              widest = math.max(widest, painter.width).toDouble();
              painter.dispose();
            }
            final preferred = (box.maxWidth * .40).clamp(128.0, 142.0).toDouble();
            final controlWidth = math.max(preferred, widest + 58).clamp(0.0, box.maxWidth).toDouble();
            // Measure the name; the decorative wave can wrap inside its column.
            final namePainter = TextPainter(text: TextSpan(text: name, style: nameStyle),
              textDirection: direction, textScaler: scaler, locale: locale)..layout();
            final nameWidth = namePainter.width;
            namePainter.dispose();
            final stacked = nameWidth + controlWidth + 12 > box.maxWidth;
            const hello = PrimeText('Olá,', style: TextStyle(fontSize: 13, height: 1.3,
              color: Color(0xFF56707D)));
            final nameLine = Text('$name 👋', softWrap: true, style: nameStyle);
            Widget control({bool caption = false}) => CourierReferenceAvailability(
              online: widget.online, active: false, changing: _changing, showCaption: caption,
              onTap: widget.onChanged == null ? null : _toggle);
            if (stacked) {
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                hello, const SizedBox(height: 2), nameLine, const SizedBox(height: 10),
                Align(alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(width: controlWidth, child: control(caption: true))),
              ]);
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              hello, const SizedBox(height: 2),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: nameLine), const SizedBox(width: 12),
                SizedBox(width: controlWidth, child: control()),
              ]),
              const SizedBox(height: 5),
              Row(children: [
                const Expanded(child: SizedBox.shrink()), const SizedBox(width: 12),
                SizedBox(width: controlWidth, child: CourierAvailabilityCaption(online: widget.online, active: false)),
              ]),
            ]);
          }),
        ],
      ])));
  }
}

class CourierReferenceAvailability extends StatefulWidget {
  const CourierReferenceAvailability({super.key, required this.online,
    required this.active, required this.changing, required this.onTap, this.showCaption = true});
  final bool online, active, changing, showCaption;
  final VoidCallback? onTap;
  static const trackKey = ValueKey('courier_availability_track');
  static const thumbKey = ValueKey('courier_availability_thumb');
  @override State<CourierReferenceAvailability> createState() => _CourierReferenceAvailabilityState();
}

class _CourierReferenceAvailabilityState extends State<CourierReferenceAvailability> {
  bool _pressed = false;
  bool get _enabled => !widget.changing && widget.onTap != null;
  void _press(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }
  void _activate() {
    if (!_enabled) return;
    _press(false);
    if (!MediaQuery.disableAnimationsOf(context)) {
      unawaited(HapticFeedback.selectionClick().catchError((Object _) {}));
    }
    widget.onTap!();
  }
  @override void didUpdateWidget(covariant CourierReferenceAvailability oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _pressed = false;
  }
  @override Widget build(BuildContext context) {
    final on = widget.online || widget.active;
    final action = widget.active ? 'Ver detalhes da rota' : widget.online ? 'Ficar offline' : 'Ficar online';
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 280);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Semantics(button: true, enabled: _enabled, toggled: widget.active ? null : widget.online,
        label: translateLabel(action), onTap: _enabled ? _activate : null, excludeSemantics: true,
        child: Tooltip(message: translateLabel(action), child: AnimatedScale(
          scale: _pressed ? .97 : 1, duration: reduce ? Duration.zero : const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: Material(color: Colors.transparent, child: InkWell(
            onTap: _enabled ? _activate : null,
            onTapDown: _enabled ? (_) => _press(true) : null,
            onTapCancel: _enabled ? () => _press(false) : null,
            enableFeedback: false, splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent, focusColor: const Color(0x18073E43),
            hoverColor: const Color(0x08073E43),
            borderRadius: BorderRadius.circular(40),
            child: LayoutBuilder(builder: (context, box) {
              final label = on ? 'ONLINE' : 'OFFLINE';
              final style = DefaultTextStyle.of(context).style.merge(
                const TextStyle(fontSize: 12.5, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: .4));
              final painter = TextPainter(text: TextSpan(text: translateLabel(label), style: style),
                textDirection: Directionality.of(context), locale: Localizations.maybeLocaleOf(context),
                textScaler: MediaQuery.textScalerOf(context))
                ..layout(maxWidth: math.max(32.0, box.maxWidth - 56).toDouble());
              final height = math.max(48.0, painter.height + 14).toDouble();
              painter.dispose();
              return AnimatedContainer(key: CourierReferenceAvailability.trackKey,
                duration: duration, height: height,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: on ? const [Color(0xFF00968A), Color(0xFF00636C)]
                      : const [Color(0xFFE5EEF0), Color(0xFFD8E4E7)]),
                  border: Border.all(color: on ? const Color(0xFF6AC7BF) : const Color(0xFFCADCDE), width: .8),
                  boxShadow: [BoxShadow(color: on ? const Color(0x26077778) : const Color(0x0A305D64),
                    blurRadius: on ? 16 : 10, offset: const Offset(0, 4))]),
                child: Stack(children: [
                  AnimatedPositionedDirectional(duration: duration, curve: Curves.easeOutCubic,
                    start: on ? 12 : 44, end: on ? 44 : 12, top: 0, bottom: 0,
                    child: Center(child: AnimatedDefaultTextStyle(duration: duration,
                      style: style.copyWith(color: on ? Colors.white : const Color(0xFF496770)),
                      child: PrimeText(label, textAlign: TextAlign.center)))),
                  Positioned.fill(child: Padding(padding: const EdgeInsets.all(6),
                    child: AnimatedAlign(duration: duration, curve: const PrimeNavigationSpring(),
                      alignment: on ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      child: Container(key: CourierReferenceAvailability.thumbKey, width: 34, height: 34,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                          border: Border.all(color: on ? const Color(0xFFCEF1E8) : const Color(0xFFEEF4F5)),
                          boxShadow: const [BoxShadow(color: Color(0x18344950), blurRadius: 8, offset: Offset(0, 2))]),
                        child: Center(child: AnimatedSwitcher(duration: reduce ? Duration.zero : const Duration(milliseconds: 140),
                          child: widget.changing ? const SizedBox(key: ValueKey('pending'), width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: courierGreen))
                            : on ? const SizedBox(key: ValueKey('on'), width: 16, height: 16)
                              : const Icon(AppIcons.power, key: ValueKey('off'), size: 17, color: Color(0xFF64828A)))))))),
                ]));
            })))))),
      if (widget.showCaption) ...[const SizedBox(height: 5),
        CourierAvailabilityCaption(online: widget.online, active: widget.active)],
    ]);
  }
}

/// Caption height never participates in the horizontal alignment of the pill.
class CourierAvailabilityCaption extends StatelessWidget {
  const CourierAvailabilityCaption({super.key, required this.online, required this.active});
  final bool online, active;
  @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle,
          color: online || active ? const Color(0xFF00B184) : const Color(0xFF8CA1AA))),
        const SizedBox(width: 5),
        Flexible(child: PrimeText(active ? 'Em entrega' : online ? 'Recebendo entregas' : 'Toque para ficar online',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, height: 1.4, color: Color(0xFF456E73)))),
      ]);
}

class _CourierBrand extends StatelessWidget {
  const _CourierBrand();
  @override Widget build(BuildContext context) => Row(children: [
    const SizedBox(width: 33, height: 36, child: CustomPaint(painter: _CrownPainter())),
    const SizedBox(width: 8),
    const Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'PORTO ', style: TextStyle(color: courierGreen)),
          TextSpan(text: 'PRIME', style: TextStyle(color: Color(0xFFDDA839))),
        ]), style: TextStyle(fontSize: 17, height: 1.2, fontWeight: FontWeight.w800)),
        SizedBox(height: 3),
        Text('D E L I V E R Y', style: TextStyle(fontSize: 7,
          letterSpacing: 1.5, fontWeight: FontWeight.w600, color: courierGreen)),
      ]))),
  ]);
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();
  @override void paint(Canvas canvas, Size size) {
    canvas.save(); canvas.scale(size.width / 30, size.height / 32);
    final crown = Path()..moveTo(2, 10)..lineTo(8, 15)..lineTo(15, 2)
      ..lineTo(22, 15)..lineTo(28, 10)..lineTo(25, 24)..lineTo(5, 24)..close();
    canvas.drawPath(crown, Paint()..shader = const LinearGradient(
      colors: [Color(0xFFFFDA75), Color(0xFFD99622)])
      .createShader(const Rect.fromLTWH(0, 0, 30, 28)));
    canvas.drawPath(Path()..moveTo(8, 15)..lineTo(15, 2)..lineTo(15, 24)..lineTo(5, 24)..close(),
      Paint()..color = const Color(0xFFFFE5A2).withValues(alpha: .35));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 26, 20, 3),
      const Radius.circular(1.5)), Paint()..color = const Color(0xFFE5AC37));
    canvas.restore();
  }
  @override bool shouldRepaint(covariant _CrownPainter oldDelegate) => false;
}
