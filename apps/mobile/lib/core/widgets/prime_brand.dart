import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Decorative identity only: never intercepts gestures or reads application state.
class PrimeCoastArtwork extends StatelessWidget {
  const PrimeCoastArtwork({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(child: CustomPaint(painter: _CoastPainter())),
  );
}

class _CoastPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sun = Paint()..color = AppColors.sun500;
    canvas.drawCircle(Offset(size.width * .88, size.height * .16), size.shortestSide * .27, sun);
    for (var i = 0; i < 3; i++) {
      final y = size.height * (.70 + i * .13);
      final path = Path()..moveTo(0, y);
      path.cubicTo(size.width * .24, y - 48, size.width * .60, y + 55, size.width, y - 30);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = [AppColors.electric.withValues(alpha: .18), AppColors.electric.withValues(alpha: .14), Colors.white.withValues(alpha: .06)][i]);
    }
    final line = Paint()..color = Colors.white.withValues(alpha: .12)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width * .88, size.height * .16), size.shortestSide * .35, line);
  }
  @override
  bool shouldRepaint(covariant _CoastPainter oldDelegate) => false;
}

class PrimeEditorialHeader extends StatelessWidget {
  const PrimeEditorialHeader({super.key, required this.title, required this.subtitle, required this.icon, this.eyebrow = 'PORTO PRIME'});
  final String title, subtitle, eyebrow;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.surface, AppColors.sky]),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: AppColors.stroke),
      boxShadow: AppShadows.soft,
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow, style: const TextStyle(color: AppColors.ocean700, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
        const SizedBox(height: 10),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ])),
      const SizedBox(width: 12),
      Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.actionSoft, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppColors.action, size: 24)),
    ]),
  );
}
