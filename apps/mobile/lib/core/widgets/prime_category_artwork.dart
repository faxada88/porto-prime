import 'package:flutter/material.dart';
import '../theme/app_icons.dart';

/// Small, original vector illustrations with one optical grid and stroke weight.
/// The existing category mapping remains the source of truth.
class PrimeCategoryArtwork extends StatelessWidget {
  const PrimeCategoryArtwork({super.key, required this.icon, required this.color, this.size = 40});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final curated = [AppIcons.beer, AppIcons.wine, AppIcons.spirits,
      AppIcons.softDrink, AppIcons.energy, AppIcons.water, AppIcons.ice,
      AppIcons.convenience, AppIcons.combo, AppIcons.offers].contains(icon);
    return ExcludeSemantics(child: SizedBox.square(dimension: size,
      child: curated ? CustomPaint(painter: _CategoryPainter(icon, color))
        : Icon(icon, size: size * .76, color: color)));
  }
}

class _CategoryPainter extends CustomPainter {
  const _CategoryPainter(this.icon, this.color);
  final IconData icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    final outline = Paint()..color = color..style = PaintingStyle.stroke
      ..strokeWidth = 2..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final wash = Paint()..color = color.withValues(alpha: .14);
    void line(double x, double y, double a, double b) => canvas.drawLine(Offset(x,y), Offset(a,b), outline);
    void shape(Path p) { canvas.drawPath(p, wash); canvas.drawPath(p, outline); }
    void box(double x, double y, double w, double h, double r) {
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h), Radius.circular(r));
      canvas.drawRRect(rect, wash); canvas.drawRRect(rect, outline);
    }
    if (icon == AppIcons.beer) {
      box(10,15,23,25,4);
      canvas.drawPath(Path()..moveTo(33,20)..lineTo(37,20)..quadraticBezierTo(42,20,42,26)..quadraticBezierTo(42,32,37,32)..lineTo(33,32), outline);
      shape(Path()..moveTo(10,17)..cubicTo(5,10,12,6,17,10)..cubicTo(18,3,27,4,28,10)..cubicTo(36,6,40,16,33,17)..close());
      line(17,23,17,33); line(25,23,25,33);
    } else if (icon == AppIcons.wine) {
      shape(Path()..moveTo(13,7)..lineTo(35,7)..lineTo(33,19)..cubicTo(31,31,17,31,15,19)..close());
      line(16,18,32,18); line(24,29,24,40); line(16,41,32,41);
    } else if (icon == AppIcons.spirits) {
      box(18,5,12,7,2);
      shape(Path()..moveTo(19,12)..lineTo(19,17)..quadraticBezierTo(10,20,10,26)..lineTo(10,39)..quadraticBezierTo(10,43,15,43)..lineTo(33,43)..quadraticBezierTo(38,43,38,39)..lineTo(38,26)..quadraticBezierTo(38,20,29,17)..lineTo(29,12)..close());
      box(15,27,18,10,2); line(21,30,27,30); line(21,34,27,34);
    } else if (icon == AppIcons.softDrink) {
      shape(Path()..moveTo(12,15)..lineTo(36,15)..lineTo(32,41)..lineTo(16,41)..close());
      line(10,15,38,15); line(25,23,28,6); line(28,6,37,6);
      canvas.drawCircle(const Offset(24,29),5,outline);
    } else if (icon == AppIcons.energy) {
      box(13,7,22,35,5); line(16,11,32,11); line(16,38,32,38);
      shape(Path()..moveTo(26,15)..lineTo(19,26)..lineTo(24,26)..lineTo(22,34)..lineTo(30,23)..lineTo(25,23)..close());
    } else if (icon == AppIcons.water) {
      box(19,4,10,6,2);
      shape(Path()..moveTo(19,10)..lineTo(19,15)..quadraticBezierTo(13,18,13,23)..lineTo(13,38)..quadraticBezierTo(13,43,18,43)..lineTo(30,43)..quadraticBezierTo(35,43,35,38)..lineTo(35,23)..quadraticBezierTo(35,18,29,15)..lineTo(29,10)..close());
      shape(Path()..moveTo(24,22)..cubicTo(13,34,35,34,24,22)..close());
      line(17,36,31,36);
    } else if (icon == AppIcons.ice) {
      shape(Path()..moveTo(8,16)..lineTo(23,7)..lineTo(40,16)..lineTo(40,34)..lineTo(25,43)..lineTo(8,34)..close());
      line(8,16,25,25); line(25,25,40,16); line(25,25,25,43);
      line(14,18,20,21); line(30,29,35,26);
    } else if (icon == AppIcons.convenience) {
      shape(Path()..moveTo(7,17)..lineTo(40,17)..lineTo(35,35)..lineTo(13,35)..close());
      line(14,17,20,7); line(33,17,27,7);
      line(17,23,19,30); line(24,23,24,30); line(31,23,29,30);
      canvas.drawCircle(const Offset(16,40),2,outline); canvas.drawCircle(const Offset(33,40),2,outline);
    } else if (icon == AppIcons.combo) {
      box(6,23,36,19,3); box(10,8,10,15,2); box(27,5,11,18,2);
      line(13,8,17,8); line(30,5,35,5); line(24,23,24,42);
      line(11,30,18,30); line(30,30,37,30);
    } else {
      shape(Path()..moveTo(7,9)..lineTo(28,9)..lineTo(42,23)..lineTo(24,41)..lineTo(7,24)..close());
      canvas.drawCircle(const Offset(14,16),2,outline);
      line(22,30,32,20); canvas.drawCircle(const Offset(22,21),2,outline);
      canvas.drawCircle(const Offset(32,30),2,outline);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CategoryPainter old) => old.icon != icon || old.color != color;
}
