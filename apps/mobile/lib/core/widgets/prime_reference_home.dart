import 'home_reference_artwork.dart';
import '../localization/prime_localization.dart';
import 'prime_brand_banner.dart';
import 'prime_category_3d.dart';
import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

abstract final class ReferenceHomeTokens {
 static const green=AppColors.ocean800;
 static const gold=AppColors.ocean100;
 static const canvas=Color(0xFFF6F9FA);
 static const shadow=[BoxShadow(color:Color(0x05003B3E),blurRadius:22,offset:Offset(0,7))];
 static const heroAsset='assets/reference_home/coast-banner.webp';
 static const categoryAsset='assets/reference_home/category-atlas.webp';
}
class ReferenceHomeHeader extends StatelessWidget {
 const ReferenceHomeHeader({super.key, required this.address, required this.region,
  required this.cartCount, required this.onAddress, required this.onCart,
  required this.onProfile, this.greeting, this.notificationCount = 0});
 final String address, region;
 final String? greeting;
 final int cartCount, notificationCount;
 final VoidCallback onAddress, onCart, onProfile;
 @override Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Expanded(child: InkWell(onTap: onAddress, borderRadius: BorderRadius.circular(14),
   child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
     PrimeText(greeting ?? 'Olá! Onde vamos entregar?', style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF52616D))),
     const SizedBox(height: 7),
     Row(children: [
      const Icon(Icons.location_on_rounded, color: Color(0xFF00474D), size: 20),
      const SizedBox(width: 5),
      Flexible(child: PrimeText(address, maxLines: 1, overflow: TextOverflow.ellipsis,
       style: const TextStyle(fontSize: 14, height: 1.2, fontWeight: FontWeight.w800, color: Color(0xFF0C2330)))),
      const SizedBox(width: 3), const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF0C2330)),
     ]),
     if (region.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 25, top: 5),
      child: PrimeText(region, maxLines: 1, overflow: TextOverflow.ellipsis,
       style: const TextStyle(fontSize: 11, color: Color(0xFF52616D)))),
   ])))),
  const SizedBox(width: 6),
  Semantics(button: true, label: translateLabel('Abrir notificações'),
   child: Material(color: Colors.white, borderRadius: BorderRadius.circular(16),
    elevation: 2, shadowColor: const Color(0x100C2830),
    child: InkWell(onTap: onProfile, borderRadius: BorderRadius.circular(16),
     child: SizedBox(width: 40, height: 44, child: Stack(alignment: Alignment.center, children: [
      const Icon(Icons.notifications_rounded, color: Color(0xFF00525B), size: 24),
      if (notificationCount > 0) Positioned(right: 7, top: 6, child: Container(width: 9, height: 9,
       decoration: BoxDecoration(color: const Color(0xFFEF233C), shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5)))),
     ]))))),
  const SizedBox(width: 8), const LanguagePicker(),
 ]);
}
class ReferenceHomeSearch extends StatelessWidget {
 const ReferenceHomeSearch({super.key, required this.onTap});
 final VoidCallback onTap;
 @override Widget build(BuildContext context) => Material(color: const Color(0xFFF7F4EE),
  borderRadius: BorderRadius.circular(18), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
   child: Container(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFDDDCD7))),
    child: Row(children: [
     const Icon(AppIcons.search, size: 24, color: Color(0xFF0C2330)),
     const SizedBox(width: 13),
     const Expanded(child: PrimeText('O que você quer pedir hoje?', style: TextStyle(fontSize: 13, color: Color(0xFF6B7780)))),
     const SizedBox(width: 10), const Icon(AppIcons.filter, size: 19, color: Color(0xFF0C2330)),
    ]))));
}
class ReferenceCoastHero extends StatelessWidget {
 const ReferenceCoastHero({super.key,this.onTap});final VoidCallback? onTap;
 @override Widget build(BuildContext context)=>PrimeBrandBanner(onExplore:onTap);
}

class ReferenceCategoryTile extends StatelessWidget {
 const ReferenceCategoryTile({super.key, required this.name, required this.onTap, this.iconKey, this.selected = false});
 final String name;
 final String? iconKey;
 final bool selected;
 final VoidCallback onTap;
 @override Widget build(BuildContext context) {
  final visual = AppIcons.categoryVisual(name, iconKey: iconKey);
  final source = HomeReferenceArtwork.categories[visual.key];
  return Semantics(button: true, selected: selected,
   label: translateLabel('Categoria ${AppLanguage.instance.translate(name)}'),
   child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(19),
    child: Column(children: [
     Expanded(child: source == null ?
      DecoratedBox(decoration: BoxDecoration(color: visual.background, borderRadius: BorderRadius.circular(23)),
       child: SizedBox.expand(child: PrimeCategory3D(iconKey: visual.key,
        fallback: Icon(visual.icon, size: 35, color: visual.foreground)))) :
      HomeReferenceArtwork(source: source, fallback: PrimeCategory3D(iconKey: visual.key,
       fallback: Icon(visual.icon, size: 35, color: visual.foreground)))),
     const SizedBox(height: 3),
     Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: selected ? const Color(0xFFFFEBC3) : Colors.transparent,
       borderRadius: BorderRadius.circular(12)),
      child: PrimeText(name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
       style: const TextStyle(fontSize: 11, height: 1.12, fontWeight: FontWeight.w600, color: Color(0xFF0C2330)))),
    ])));
 }
}

class ReferenceProductSurface extends StatelessWidget {
  const ReferenceProductSurface({super.key, required this.name, required this.description,
    required this.price, required this.image, required this.control, required this.available,
    this.oldPrice, this.discount, this.onOpen, this.fullWidthControl = false});
  final String name, description, price;
  final String? oldPrice;
  final int? discount;
  final Widget image, control;
  final bool available, fullWidthControl;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onOpen != null, label: translateLabel(name),
    child: Material(color: Colors.white, borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onOpen, borderRadius: BorderRadius.circular(22),
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.stroke)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
              child: Stack(fit: StackFit.expand, children: [
                ColoredBox(color: AppColors.surfaceSoft, child: image),
                if (discount != null) Positioned(left: 10, top: 10, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.coral600, borderRadius: BorderRadius.circular(9)),
                  child: PrimeText('−$discount%', textScaler: TextScaler.noScaling,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
                if (!available) const Center(child: Chip(label: PrimeText('Indisponível', style: TextStyle(fontSize: 10)))),
              ]),
            )),
            Expanded(child: Padding(padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                PrimeText(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  PrimeText(description, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                ],
                const Spacer(),
                if (oldPrice != null) PrimeText(oldPrice!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted, decoration: TextDecoration.lineThrough)),
                const SizedBox(height: 7),
                if (fullWidthControl) ...[
                  PrimeText(price, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 7), control,
                ] else Row(children: [
                  Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                    child: PrimeText(price, maxLines: 1,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)))),
                  const SizedBox(width: 4), SizedBox(width: 44, child: control),
                ]),
              ]),
            )),
          ]),
        ),
      ),
    ),
  );
}
