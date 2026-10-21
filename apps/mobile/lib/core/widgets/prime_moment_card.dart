import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

class PrimeMomentCard extends StatefulWidget {
  const PrimeMomentCard({super.key, required this.title, required this.subtitle,
    required this.scene, required this.onTap});
  final String title, subtitle;
  final int scene;
  final VoidCallback onTap;
  @override
  State<PrimeMomentCard> createState() => _PrimeMomentCardState();
}

class _PrimeMomentCardState extends State<PrimeMomentCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final dark = widget.scene == 2;
    // Give enlarged text the full card width instead of reserving artwork space.
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 15;
    final background = switch (widget.scene) {
      0 => AppColors.sand100, 1 => AppColors.ocean100, _ => AppColors.ocean900,
    };
    return Semantics(button: true, label: translateLabel( '${widget.title}. ${widget.subtitle}. Explorar catálogo'),
      excludeSemantics: true, onTap: widget.onTap,
      child: MouseRegion(onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(scale: _hovered ? .985 : 1,
          duration: AppMotion.resolve(context, AppMotion.fast),
          child: Material(color: background, borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias, child: InkWell(onTap: widget.onTap,
              child: Stack(children: [
                if (!largeText) Positioned(top: 0, right: 0, bottom: 0, width: 130,
                  child: IgnorePointer(child: CustomPaint(painter: _MomentScene(widget.scene)))),
                Padding(padding: const EdgeInsets.all(20),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(child: Column(mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                        PrimeText(widget.title, style: TextStyle(fontSize: 21, height: 1.15,
                          letterSpacing: -.5, fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : AppColors.ocean900)),
                        const SizedBox(height: 7),
                        PrimeText(widget.subtitle, style: TextStyle(fontSize: 12, height: 1.5,
                          color: dark ? AppColors.ocean100 : AppColors.inkSoft)),
                        const SizedBox(height: 18),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Flexible(child: PrimeText('Explorar', style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: dark ? AppColors.sun500 : AppColors.ocean900))),
                          const SizedBox(width: 8), Icon(AppIcons.arrowUpRight,
                            size: 17, color: dark ? AppColors.sun500 : AppColors.ocean900),
                        ]),
                      ])),
                    if (!largeText) const SizedBox(width: 82),
                  ])),
              ])),
          ),
        ),
      ));
  }
}

/// Three lightweight, original coastal scenes. No remote images or animation loop.
class _MomentScene extends CustomPainter {
  const _MomentScene(this.scene);
  final int scene;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width - 112, size.height / 2 - 50);
    canvas.clipRect(const Rect.fromLTWH(0, -100, 130, 350));
    final ink = Paint()..style = PaintingStyle.stroke..strokeWidth = 2
      ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round
      ..color = (scene == 2 ? AppColors.sun500 : AppColors.ocean700);
    final wash = Paint()..color = (scene == 2 ? AppColors.sun500 : AppColors.ocean500).withValues(alpha: .14);
    canvas.drawCircle(const Offset(69,50),47,wash);
    if (scene == 0) {
      canvas.drawCircle(const Offset(91,17),10,Paint()..color=AppColors.sun500);
      final canopy=Path()..moveTo(21,43)..quadraticBezierTo(51,-1,87,36)..close();
      canvas.drawPath(canopy,Paint()..color=AppColors.sun500);canvas.drawPath(canopy,ink);
      canvas.drawLine(const Offset(55,39),const Offset(65,82),ink);
      canvas.drawPath(Path()..moveTo(20,88)..quadraticBezierTo(38,80,57,88)..quadraticBezierTo(77,96,101,85),ink);
      canvas.drawPath(Path()..moveTo(29,99)..quadraticBezierTo(49,91,67,99)..quadraticBezierTo(85,105,106,95),ink);
    } else if (scene == 1) {
      canvas.drawArc(const Rect.fromLTWH(24,30,66,45),0,3.14,false,ink);
      canvas.drawLine(const Offset(22,51),const Offset(92,51),ink);
      canvas.drawLine(const Offset(37,70),const Offset(29,91),ink);
      canvas.drawLine(const Offset(75,70),const Offset(85,91),ink);
      for (var i=0;i<3;i++) {
        final x=40.0+i*17;
        canvas.drawPath(Path()..moveTo(x,23)..cubicTo(x-8,16,x+8,10,x,3),ink);
      }
    } else {
      canvas.drawCircle(const Offset(69,30),24,Paint()..color=AppColors.sun500);
      canvas.drawPath(Path()..moveTo(28,61)..lineTo(108,61),ink);
      for (var i=0;i<3;i++) {
        final y=73.0+i*12;
        canvas.drawPath(Path()..moveTo(21,y)..quadraticBezierTo(43,y-7,64,y)..quadraticBezierTo(85,y+7,108,y),ink);
      }
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _MomentScene old) => old.scene != scene;
}
