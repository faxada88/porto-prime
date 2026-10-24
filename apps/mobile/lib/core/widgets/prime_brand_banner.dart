import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';

/// Informational artwork; offers are available through the bottom navigation.
class PrimeBrandBanner extends StatelessWidget {
 const PrimeBrandBanner({super.key});
 static const asset = 'assets/reference_home/campaign-banner-clean.webp';
 @override Widget build(BuildContext context) => Semantics(
  image: true, label: translateLabel('Bebidas para o seu momento'),
  child: Material(color: const Color(0xFF18120A), borderRadius: BorderRadius.circular(16),
   clipBehavior: Clip.antiAlias, child: AspectRatio(aspectRatio: 744 / 429,
    child: Image.asset(asset, fit: BoxFit.cover, excludeFromSemantics: true,
     errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF18120A))))));
}
