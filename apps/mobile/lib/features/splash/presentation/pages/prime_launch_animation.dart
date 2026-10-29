import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Presentation only. Startup, sessions and navigation remain on SplashPage.
class PrimeLaunchAnimation extends StatefulWidget {
  const PrimeLaunchAnimation({super.key});
  @override
  State<PrimeLaunchAnimation> createState() => _PrimeLaunchAnimationState();
}

class _PrimeLaunchAnimationState extends State<PrimeLaunchAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1700));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      _motion.value = 1;
    } else if (!_started) {
      _started = true;
      _motion.forward();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAFAFA),
    body: SafeArea(child: LayoutBuilder(builder: (context, box) {
      final size = math.min(260.0, math.min(box.maxWidth * .70, box.maxHeight * .70));
      return Center(child: RepaintBoundary(child: SizedBox(
        width: size, height: size,
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, child) {
            final t = _motion.value;
            final entrance = const Interval(0, .55, curve: Curves.easeOutCubic).transform(t);
            final settle = const Interval(0, .65, curve: Curves.easeOutBack).transform(t);
            return Stack(alignment: Alignment.center, children: [
              Positioned.fill(child: CustomPaint(painter: _RoutePainter(t))),
              Opacity(opacity: entrance, child: Transform.translate(
                offset: Offset(0, 12 * (1 - entrance)),
                child: Transform.scale(scale: .88 + .12 * settle, child: child))),
            ]);
          },
          child: Container(
            width: size * .64, height: size * .64,
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: const Color(0xFF004650).withValues(alpha: .09),
                blurRadius: 30, offset: const Offset(0, 12)),
            ]),
            child: ClipOval(child: Image.asset(
              'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
              fit: BoxFit.contain, semanticLabel: 'Porto Prime',
            )),
          ),
        ),
      )));
    })),
  );
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = const Interval(.12, .95, curve: Curves.easeInOutCubic).transform(progress);
    final fade = math.sin(math.pi * t);
    if (fade <= .001) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .43;
    final angle = -math.pi / 2 + t * math.pi * 2;
    final paint = Paint()
      ..color = const Color(0xFFF6C64F).withValues(alpha: fade * .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
      angle - math.pi * .65, math.pi * .65, false, paint);
    final dot = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(dot, 4.5, Paint()..color = const Color(0xFF004650).withValues(alpha: fade));
    canvas.drawCircle(dot, 9, Paint()..color = const Color(0xFFF6C64F).withValues(alpha: fade * .16));
    final haloRadius = size.shortestSide * (.33 + .13 * t);
    canvas.drawCircle(center, haloRadius, Paint()
      ..color = const Color(0xFF004650).withValues(alpha: fade * .05)
      ..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.progress != progress;
}
