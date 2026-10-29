import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/prime_localization.dart';

/// Display only: delivery confirmation is controlled by the server order status.
class DeliveryCompletedView extends StatelessWidget {
  const DeliveryCompletedView({
    super.key,
    required this.deliveredAt,
    required this.onBack,
    required this.onHelp,
    required this.onDetails,
  });

  final String? deliveredAt;
  final VoidCallback onBack;
  final VoidCallback onHelp;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(deliveredAt ?? '')?.toLocal();
    final time = date == null ? null : MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: true);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                final artWidth = math.min(width, 440.0);
                final top = MediaQuery.paddingOf(context).top;
                final height = top + artWidth * 1.06;
                return SizedBox(
                  height: height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(painter: _CelebrationPainter(top: top)),
                        ),
                      ),
                      Positioned(
                        left: (width - artWidth) / 2,
                        bottom: 0,
                        width: artWidth,
                        height: artWidth * .80,
                        child: const ExcludeSemantics(child: RepaintBoundary(
                          child: CustomPaint(painter: _DeliveryBagPainter()),
                        )),
                      ),
                      Positioned(
                        left: 20, right: 20, top: top + 18,
                        child: Row(children: [
                          Material(
                            color: Colors.white,
                            shape: const CircleBorder(side: BorderSide(color: Color(0xFFEAEAEA))),
                            elevation: 2,
                            shadowColor: const Color(0x18000000),
                            child: IconButton(
                              tooltip: translateLabel('Voltar'),
                              onPressed: onBack,
                              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                              icon: const Icon(Icons.chevron_left_rounded, size: 32, color: Color(0xFF191919)),
                            ),
                          ),
                          const Spacer(),
                          Flexible(child: FilledButton(
                            onPressed: onHelp,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF191919),
                              minimumSize: const Size(84, 48),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              side: const BorderSide(color: Color(0xFFEAEAEA)),
                              shape: const StadiumBorder(),
                            ),
                            child: const PrimeText('Ajuda',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                          )),
                        ]),
                      ),
                    ],
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: const PrimeText('Seu pedido foi entregue',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 25, height: 1.22,
                      fontWeight: FontWeight.w700, color: Color(0xFF191919))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: TextButton(
                  onPressed: onDetails,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF666666),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    minimumSize: const Size(48, 48),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      PrimeText(time == null ? 'Ver detalhes do pedido' : 'Pedido entregue às',
                        style: const TextStyle(fontSize: 18)),
                      if (time != null) Text(time, style: const TextStyle(
                        fontSize: 18, color: Color(0xFF191919), fontWeight: FontWeight.w600)),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22, color: Color(0xFF999999)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({required this.top});
  final double top;
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height * .68;
    final path = Path()..moveTo(0, 0)..lineTo(size.width, 0)
      ..lineTo(size.width, h * .73)
      ..cubicTo(size.width * .84, h * .69, size.width * .83, h * 1.15, size.width * .65, h)
      ..cubicTo(size.width * .46, h * .83, size.width * .35, h * 1.16, size.width * .20, h * .94)
      ..cubicTo(size.width * .10, h * .74, size.width * .07, h * .92, 0, h * .90)
      ..close();
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPaint(Paint()..color = const Color(0xFFF00036));
    final accent = Paint()..color = const Color(0xFFFF2454);
    canvas.drawOval(Rect.fromLTWH(-size.width * .28, -h * .10, size.width * .54, h * 1.3), accent);
    canvas.drawOval(Rect.fromLTWH(size.width * .25, -h * .65, size.width * .44, h * 1.15), accent);
    canvas.drawOval(Rect.fromLTWH(size.width * .72, -h * .15, size.width * .48, h * 1.20), accent);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) => oldDelegate.top != top;
}

/// Resolution-independent illustration: bag, friendly face, thumbs up and seal.
class _DeliveryBagPainter extends CustomPainter {
  const _DeliveryBagPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 320);
    void shape(Path path, int color) => canvas.drawPath(path, Paint()..color = Color(color));
    void line(Path path, int color, double width) => canvas.drawPath(path,
      Paint()..color = Color(color)..style = PaintingStyle.stroke
        ..strokeWidth = width..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    void star(double x, double y, double radius, int color) {
      final path = Path();
      for (var i = 0; i < 8; i++) {
        final angle = -math.pi / 2 + i * math.pi / 4;
        final r = i.isEven ? radius : radius * .30;
        final point = Offset(x + math.cos(angle) * r, y + math.sin(angle) * r);
        if (i == 0) { path.moveTo(point.dx, point.dy); }
        else { path.lineTo(point.dx, point.dy); }
      }
      shape(path..close(), color);
    }
    for (final point in const [Offset(114, 86), Offset(270, 37), Offset(185, 17), Offset(306, 113)]) {
      star(point.dx, point.dy, 10, 0xFFFFFFFF);
    }
    star(174, 115, 61, 0xFFFFFFFF);
    star(121, 263, 12, 0xFFFF2454);
    star(89, 163, 8, 0xFFFF2454);
    // Raised thumb and curled fingers, behind the bag.
    shape(Path()..moveTo(118, 237)..cubicTo(92, 221, 91, 188, 109, 172)
      ..cubicTo(128, 156, 133, 152, 126, 133)
      ..cubicTo(112, 95, 147, 95, 151, 117)
      ..lineTo(154, 157)..cubicTo(177, 166, 180, 192, 174, 212)
      ..lineTo(151, 250)..close(), 0xFFFFD566);
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(104 + i * 3, 184 + i * 17, 47, 24), const Radius.circular(13)),
        Paint()..color = const Color(0xFFF5B943));
      line(Path()..moveTo(110, 199 + i * 16)..quadraticBezierTo(129, 207 + i * 16, 146, 190 + i * 16),
        0xFFFFDB77, 4);
    }
    // Handle, side panel and warm paper facets.
    line(Path()..moveTo(215, 114)..cubicTo(230, 56, 255, 68, 260, 129), 0xFFA97140, 8);
    shape(Path()..moveTo(182, 95)..lineTo(278, 117)..lineTo(267, 256)
      ..lineTo(213, 281)..lineTo(139, 229)..close(), 0xFFD99B69);
    shape(Path()..moveTo(278, 117)..lineTo(299, 124)..lineTo(285, 247)
      ..lineTo(213, 281)..close(), 0xFFEF0038);
    shape(Path()..moveTo(139, 229)..quadraticBezierTo(164, 168, 197, 205)
      ..lineTo(267, 256)..lineTo(213, 281)..close(), 0xFFCC8D5B);
    shape(Path()..moveTo(182, 95)..lineTo(187, 179)..lineTo(240, 249)
      ..lineTo(163, 193)..close(), 0xFFE4AA7B);
    line(Path()..moveTo(186, 106)..cubicTo(200, 44, 223, 36, 223, 115), 0xFFB47D4D, 8);
    final face = Paint()..color = const Color(0xFFF00036);
    canvas.drawOval(const Rect.fromLTWH(202, 137, 14, 10), face);
    canvas.drawOval(const Rect.fromLTWH(222, 143, 14, 10), face);
    line(Path()..moveTo(202, 159)..quadraticBezierTo(213, 180, 235, 164), 0xFFF00036, 5);
    // Green confirmation seal.
    canvas.drawCircle(const Offset(284, 219), 34, Paint()..color = const Color(0xFF009D68));
    canvas.drawCircle(const Offset(280, 214), 28, Paint()..color = const Color(0xFF0EB27B));
    line(Path()..moveTo(266, 217)..lineTo(277, 228)..lineTo(298, 204), 0xFFFFFFFF, 7);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _DeliveryBagPainter oldDelegate) => false;
}
