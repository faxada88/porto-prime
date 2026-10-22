import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';
import 'home_reference_artwork.dart';

/// The original horizontal campaign artwork, isolated from the supplied reference.
/// The entire banner delegates to the real offers destination.
class PrimeBrandBanner extends StatelessWidget {
 const PrimeBrandBanner({super.key, this.onExplore});
 final VoidCallback? onExplore;
 static const asset = HomeReferenceArtwork.asset;
 @override Widget build(BuildContext context) => Semantics(
  button: onExplore != null, label: translateLabel('Ver ofertas'),
  child: Material(color: const Color(0xFF18120A), borderRadius: BorderRadius.circular(16),
   clipBehavior: Clip.antiAlias, child: InkWell(onTap: onExplore,
    child: AspectRatio(aspectRatio: 744 / 429,
     child: HomeReferenceArtwork(source: HomeReferenceArtwork.banner,
      fallback: const ColoredBox(color: Color(0xFF18120A)))))));
}
