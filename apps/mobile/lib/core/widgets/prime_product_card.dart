import '../localization/prime_localization.dart';
import 'prime_reference_home.dart';
import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'prime_category_artwork.dart';

class PrimeProductCard extends StatefulWidget {
  const PrimeProductCard({super.key, required this.product, this.onOpen, this.referenceStyle = false});

  final bool referenceStyle;
  final dynamic product;
  final VoidCallback? onOpen;

  @override
  State<PrimeProductCard> createState() => _PrimeProductCardState();
}

class _PrimeProductCardState extends State<PrimeProductCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final state = AppState.instance;
    final id = p['id'].toString();
    final price = double.tryParse(p['price']?.toString() ?? '') ?? 0;
    final oldPrice = double.tryParse(
      (p['oldPrice'] ?? p['compareAtPrice'] ?? '').toString(),
    );
    final qty = state.cart[id] ?? 0;
    final image = (p['imageUrl'] ?? '').toString().trim();
    final description = (p['description'] ?? '').toString().trim();
    final category = (p['category']?['name'] ?? 'Porto Prime').toString();
    final stock = int.tryParse(p['stock']?.toString() ?? '')??0;
    final available = state.storeStatusKnown && state.storeOpen && p['active'] != false && stock > 0;

    final discount = oldPrice != null && oldPrice > price && oldPrice > 0
        ? (((oldPrice - price) / oldPrice) * 100).round()
        : null;

    if(widget.referenceStyle) {
      final fallback=_FallbackProduct(icon:AppIcons.categoryVisual(category,iconKey:p['category']?['iconKey']?.toString()).icon,exact:p['category']?['iconKey']!=null);
      return ReferenceProductSurface(name:(p['name']??'Produto').toString(),description:description,
        price:_money(price),oldPrice:oldPrice!=null&&oldPrice>price?_money(oldPrice):null,
        discount:discount,available:available,onOpen:widget.onOpen,fullWidthControl:qty>0,
        image:image.isNotEmpty?Image.network(image,fit:BoxFit.cover,alignment:Alignment.center,cacheWidth:768,errorBuilder:(_,__,___)=>fallback):fallback,
        control:!available?const SizedBox(height:44):qty==0
          ?_AddButton(onTap:()=>state.addProduct(id),productName:(p['name']??'produto').toString(),compact:false,cartIcon:true)
          :_QuantityControl(qty:qty,onMinus:()=>state.changeQty(id,-1),onPlus:state.canIncreaseQuantity(id)?()=>state.changeQty(id,1):null));
    }

    return Semantics(
      button: widget.onOpen != null,
      enabled: available,
      label: translateLabel( (p['name'] ?? 'Produto').toString()),
      child: MouseRegion(
        cursor: widget.onOpen != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _pressed ? .985 : 1,
          duration: AppMotion.resolve(context, AppMotion.fast),
          curve: AppMotion.curve,
          child: GestureDetector(
            onTapDown: widget.onOpen == null
                ? null
                : (_) => setState(() => _pressed = true),
            onTapCancel: widget.onOpen == null
                ? null
                : () => setState(() => _pressed = false),
            onTapUp: widget.onOpen == null
                ? null
                : (_) {
                    setState(() => _pressed = false);
                    widget.onOpen?.call();
                  },
            child: AnimatedContainer(
              duration: AppMotion.resolve(context, AppMotion.standard),
              curve: AppMotion.curve,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: qty > 0 ? AppColors.ocean300 : _hovered
                      ? AppColors.ocean300.withValues(alpha: .72)
                      : AppColors.stroke,
                ),
                boxShadow: _hovered ? AppShadows.elevated : AppShadows.soft,
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 166;
                  final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: largeText ? 36 : 46,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              margin: EdgeInsets.zero,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.surface,
                                    AppColors.surfaceMuted,
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                                border: Border.all(
                                  color: Colors.transparent,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: image.isNotEmpty
                                  ? Image.network(image, fit: BoxFit.cover, alignment: Alignment.center,
                                      cacheWidth: 768, filterQuality: FilterQuality.medium,
                                      errorBuilder: (_, __, ___) =>
                                        _FallbackProduct(icon: AppIcons.categoryVisual(category, iconKey: p['category']?['iconKey']?.toString()).icon,
                                          exact: p['category']?['iconKey'] != null))
                                  : _FallbackProduct(icon: AppIcons.categoryVisual(category, iconKey: p['category']?['iconKey']?.toString()).icon,
                                      exact: p['category']?['iconKey'] != null),
                            ),
                            if (discount != null)
                              Positioned(
                                top: 14,
                                left: 14,
                                child: _DiscountBadge(value: discount),
                              ),
                            if (!available)
                              Positioned.fill(
                                child: Container(
                                  margin: EdgeInsets.zero,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .76),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const _UnavailableBadge(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: largeText ? 64 : 54,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 10 : 12,
                            7,
                            compact ? 10 : 12,
                            compact ? 10 : 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PrimeText(
                                category.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.muted,
                                      fontSize: AppFontSize.caption,
                                      letterSpacing: .72,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              PrimeText(
                                (p['name'] ?? '').toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontSize: AppFontSize.body,
                                      height: 1.16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.18,
                                    ),
                              ),
                              if (description.isNotEmpty && !compact) ...[
                                const SizedBox(height: 4),
                                PrimeText(
                                  description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontSize: AppFontSize.label),
                                ),
                              ],
                              const Spacer(),
                              if (oldPrice != null && oldPrice > price)
                                PrimeText(
                                  _money(oldPrice),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColors.subtle,
                                        fontSize: AppFontSize.caption,
                                      ),
                                ),
                              const SizedBox(height: 1),
                              PrimeText(
                                _money(price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontSize: 18,
                                      fontWeight: AppFontWeight.display,
                                      letterSpacing: -.4,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration: AppMotion.resolve(
                                        context,
                                        AppMotion.standard,
                                      ),
                                      switchInCurve: AppMotion.curve,
                                      switchOutCurve: AppMotion.curve,
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                            opacity: animation,
                                            child: ScaleTransition(
                                              scale: Tween<double>(
                                                begin: .91,
                                                end: 1,
                                              ).animate(animation),
                                              child: child,
                                            ),
                                          ),
                                      child: !available
                                          ? const SizedBox.shrink(
                                              key: ValueKey('unavailable'),
                                            )
                                          : qty == 0
                                          ? _AddButton(
                                              key: const ValueKey('add'),
                                              compact: compact,
                                              onTap: () => state.addProduct(id),
                                              productName:
                                                  (p['name'] ?? 'produto')
                                                      .toString(),
                                            )
                                          : _QuantityControl(
                                              key: const ValueKey('qty'),
                                              qty: qty,
                                              onMinus: () =>
                                                  state.changeQty(id, -1),
                                              onPlus: state.canIncreaseQuantity(id) ? () =>
                                                  state.changeQty(id, 1) : null,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _money(double value) =>
    'R\$ ' + value.toStringAsFixed(2).replaceAll('.', ',');

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.coral600,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      boxShadow: [
        BoxShadow(
          color: AppColors.coral600.withValues(alpha: .18),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: PrimeText(
      '-' + value.toString() + '%',
      style: const TextStyle(
        color: Colors.white,
        fontSize: AppFontSize.caption,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _UnavailableBadge extends StatelessWidget {
  const _UnavailableBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.ink.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: const PrimeText(
      'INDISPONÍVEL',
      style: TextStyle(
        color: Colors.white,
        fontSize: AppFontSize.caption,
        fontWeight: FontWeight.w800,
        letterSpacing: .6,
      ),
    ),
  );
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    super.key,
    required this.onTap,
    required this.productName,
    required this.compact,
    this.cartIcon=false,
  });

  final VoidCallback onTap;
  final String productName;
  final bool compact;
  final bool cartIcon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: translateLabel( 'Adicionar ' + productName),
    child: Material(
      color: cartIcon ? AppColors.ocean100 : AppColors.ocean900,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          height: AppControl.minTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.plus, color: cartIcon?AppColors.ocean700:AppColors.sun500, size: 18),
                if(!cartIcon) const SizedBox(width: 5),
                if(!cartIcon) const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: PrimeText(
                      'Adicionar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.label,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    super.key,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) => Container(
    height: AppControl.minTap,
    padding: const EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(
      color: AppColors.ocean50,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.ocean100),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QtyButton(
          icon: AppIcons.minus,
          onTap: onMinus,
          semanticLabel: translateLabel( 'Diminuir quantidade'),
        ),
        Expanded(
          child: PrimeText(
            qty.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.ocean800,
              fontWeight: FontWeight.w800,
              fontSize: AppFontSize.label,
            ),
          ),
        ),
        _QtyButton(
          icon: AppIcons.plus,
          onTap: onPlus,
          semanticLabel: translateLabel( onPlus==null?'Limite de estoque atingido':'Aumentar quantidade'),
        ),
      ],
    ),
  );
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap!=null,
    label: translateLabel( semanticLabel),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: AppControl.minTap,
        height: AppControl.minTap,
        child: Icon(icon, size: 14, color: onTap==null?AppColors.subtle:AppColors.ocean800),
      ),
    ),
  );
}

class _FallbackProduct extends StatelessWidget {
  const _FallbackProduct({required this.icon, this.exact = false});
  final IconData icon;
  final bool exact;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.ocean50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: exact ? Icon(icon, color: AppColors.ocean700, size: 32) : PrimeCategoryArtwork(icon: icon, color: AppColors.ocean700, size: 42),
    ),
  );
}

