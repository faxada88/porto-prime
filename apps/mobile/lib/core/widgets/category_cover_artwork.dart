import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import 'prime_category_3d.dart';

/// Every category has the same photographic cover and fitting rules.
/// Admin cover photos override the bundled backdrop; product photos remain inset.
class CategoryCoverArtwork extends StatelessWidget {
 const CategoryCoverArtwork({super.key, required this.name, this.iconKey,
  this.photoUrl = '', this.productUrl = ''});
 final String name, photoUrl, productUrl;
 final String? iconKey;
 static const baseAsset = 'assets/reference_home/category-coast-base.webp';
 static const beerAsset = 'assets/reference_home/coast-banner.webp';

 Widget fallback(BuildContext context) {
  final visual = AppIcons.categoryVisual(name, iconKey: iconKey);
  return Stack(fit: StackFit.expand, children: [
   Image.asset(iconKey == 'beer' ? beerAsset : baseAsset, fit: BoxFit.cover, cacheWidth: 1200,
    errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF164B56))),
   if (iconKey != 'beer') LayoutBuilder(builder: (context, box) {
    final width = (box.maxWidth * .4).clamp(110.0, 210.0).toDouble();
    final illustration = PrimeCategory3D(iconKey: iconKey,
     fallback: Icon(visual.icon, size: 86, color: const Color(0xFFD3EDF0)));
    return Align(alignment: Alignment.bottomRight, child: Padding(
     padding: const EdgeInsets.only(right: 14, bottom: 10),
     child: SizedBox(width: width, height: 145,
      child: productUrl.isEmpty || PrimeCategory3D.keys.contains(iconKey) ? illustration : Container(
       padding: const EdgeInsets.all(6),
       decoration: BoxDecoration(color: const Color(0xEEFFFFFF), borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFD6E9EC))),
       child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(productUrl,
        fit: BoxFit.contain, cacheWidth: 400, errorBuilder: (_, __, ___) => illustration))))));
   }),
  ]);
 }
 @override Widget build(BuildContext context) => ExcludeSemantics(child: photoUrl.isEmpty
  ? fallback(context)
  : Image.network(photoUrl, fit: BoxFit.cover, cacheWidth: 1200,
    errorBuilder: (_, __, ___) => fallback(context)));
}
