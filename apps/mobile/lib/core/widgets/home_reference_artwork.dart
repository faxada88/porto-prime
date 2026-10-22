import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Only the promotional artwork and category illustrations are read from the
/// supplied reference atlas. Address, menus, text, products and actions are live.
class HomeReferenceArtwork extends StatefulWidget {
  const HomeReferenceArtwork({super.key, required this.source, required this.fallback});
  final Rect source;
  final Widget fallback;
  static const asset = 'assets/reference_home/home-reference-artwork.webp';
  static const banner = Rect.fromLTWH(54, 710, 744, 429);
  static const categories = <String, Rect>{
    'beer': Rect.fromLTWH(63, 357, 155, 120),
    'barbecue': Rect.fromLTWH(263, 358, 144, 117),
    'fitness': Rect.fromLTWH(456, 358, 138, 117),
    'wine': Rect.fromLTWH(640, 358, 143, 117),
    'energy': Rect.fromLTWH(64, 547, 121, 103),
    'ice': Rect.fromLTWH(220, 547, 120, 103),
    'spirits': Rect.fromLTWH(378, 547, 119, 103),
    'offers': Rect.fromLTWH(535, 547, 117, 103),
    'snacks': Rect.fromLTWH(683, 547, 117, 103),
  };
  @override State<HomeReferenceArtwork> createState() => _HomeReferenceArtworkState();
}
class _HomeReferenceArtworkState extends State<HomeReferenceArtwork> {
  ImageStream? stream;
  ImageStreamListener? listener;
  ImageInfo? info;
  @override void didChangeDependencies() {
    super.didChangeDependencies();
    if (stream != null) return;
    stream = const AssetImage(HomeReferenceArtwork.asset).resolve(createLocalImageConfiguration(context));
    listener = ImageStreamListener((value, _) {
      if (!mounted) { value.dispose(); return; }
      setState(() { info?.dispose(); info = value; });
    }, onError: (Object _, StackTrace? __) {});
    stream!.addListener(listener!);
  }
  @override void dispose() {
    if (listener != null) stream?.removeListener(listener!);
    info?.dispose(); super.dispose();
  }
  @override Widget build(BuildContext context) => info == null ? widget.fallback :
    ExcludeSemantics(child: CustomPaint(painter: _ReferencePainter(info!.image, widget.source), child: const SizedBox.expand()));
}
class _ReferencePainter extends CustomPainter {
  const _ReferencePainter(this.image, this.source);
  final ui.Image image;
  final Rect source;
  @override void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(source.left * image.width / 851, source.top * image.height / 1847,
      source.width * image.width / 851, source.height * image.height / 1847);
    final fit = applyBoxFit(BoxFit.contain, src.size, size);
    canvas.drawImageRect(image, src, Alignment.center.inscribe(fit.destination, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.high);
  }
  @override bool shouldRepaint(covariant _ReferencePainter old) => old.image != image || old.source != source;
}
