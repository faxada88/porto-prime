import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

class PrimeProductCard extends StatefulWidget {
  const PrimeProductCard({
    super.key,
    required this.product,
    this.onOpen,
  });

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
    final price = double.tryParse(p['price'].toString()) ?? 0;
    final oldPrice = double.tryParse(
      (p['oldPrice'] ?? p['compareAtPrice'] ?? '').toString(),
    );
    final qty = state.cart[id] ?? 0;
    final image = p['imageUrl']?.toString() ?? '';
    final description = (p['description'] ?? '').toString().trim();
    final category = (p['category']?['name'] ?? 'Porto Prime').toString();

    final discount = oldPrice != null && oldPrice > price && oldPrice > 0
        ? (((oldPrice - price) / oldPrice) * 100).round()
        : null;

    return Semantics(
      button: widget.onOpen != null,
      label: (p['name'] ?? 'Produto').toString(),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _pressed ? .985 : 1,
          duration: AppMotion.fast,
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
              duration: AppMotion.standard,
              curve: AppMotion.curve,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color:
                      _hovered ? AppColors.strokeStrong : AppColors.stroke,
                ),
                boxShadow:
                    _hovered ? AppShadows.elevated : AppShadows.soft,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 58,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.stroke.withValues(alpha: .6),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: image.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(7),
                                  child: Image.network(
                                    image,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                    errorBuilder: (_, __, ___) =>
                                        const _FallbackProduct(),
                                  ),
                                )
                              : const _FallbackProduct(),
                        ),
                        if (discount != null)
                          Positioned(
                            top: 14,
                            left: 14,
                            child: _DiscountBadge(value: discount),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 42,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.ocean600,
                                      fontSize: 7.6,
                                      letterSpacing: .72,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (p['name'] ?? '').toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontSize: 12.6,
                                      height: 1.18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.15,
                                    ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 9.5),
                            ),
                          ],
                          const Spacer(),
                          if (oldPrice != null && oldPrice > price)
                            Text(
                              'R\$ ' +
                                  oldPrice
                                      .toStringAsFixed(2)
                                      .replaceAll('.', ','),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.subtle,
                                    fontSize: 9.2,
                                  ),
                            ),
                          const SizedBox(height: 1),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  'R\$ ' +
                                      price
                                          .toStringAsFixed(2)
                                          .replaceAll('.', ','),
                                  maxLines: 1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.35,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedSwitcher(
                                duration: AppMotion.standard,
                                switchInCurve: AppMotion.curve,
                                switchOutCurve: AppMotion.curve,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                      begin: .92,
                                      end: 1,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                                child: qty == 0
                                    ? _AddButton(
                                        key: const ValueKey('add'),
                                        onTap: () => state.addProduct(id),
                                        productName:
                                            (p['name'] ?? 'produto').toString(),
                                      )
                                    : _QuantityControl(
                                        key: const ValueKey('qty'),
                                        qty: qty,
                                        onMinus: () =>
                                            state.changeQty(id, -1),
                                        onPlus: () => state.changeQty(id, 1),
                                      ),
                              ),
                            ],
                          ),
                        ],
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
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
        child: Text(
          '-' + value.toString() + '%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    super.key,
    required this.onTap,
    required this.productName,
  });

  final VoidCallback onTap;
  final String productName;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Adicionar ' + productName,
        child: Material(
          color: AppColors.ocean800,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: const SizedBox(
              height: 36,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.plus,
                      color: Colors.white,
                      size: 15,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Adicionar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.8,
                        fontWeight: FontWeight.w800,
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
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.ocean50,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.ocean100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QtyButton(icon: AppIcons.minus, onTap: onMinus),
            SizedBox(
              width: 21,
              child: Text(
                qty.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.ocean800,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.2,
                    ),
              ),
            ),
            _QtyButton(icon: AppIcons.plus, onTap: onPlus),
          ],
        ),
      );
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            width: 26,
            height: 31,
            child: Icon(
              icon,
              size: 14,
              color: AppColors.ocean800,
            ),
          ),
        ),
      );
}

class _FallbackProduct extends StatelessWidget {
  const _FallbackProduct();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.ocean50,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(
            AppIcons.package,
            size: 30,
            color: AppColors.ocean600,
          ),
        ),
      );
}
