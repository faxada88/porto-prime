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

    final discount = oldPrice != null && oldPrice > price && oldPrice > 0
        ? (((oldPrice - price) / oldPrice) * 100).round()
        : null;

    return Semantics(
      button: widget.onOpen != null,
      label: (p['name'] ?? 'Produto').toString(),
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
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.stroke),
              boxShadow: AppShadows.soft,
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
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: image.isNotEmpty
                            ? Image.network(
                                image,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, __, ___) =>
                                    const _FallbackProduct(),
                              )
                            : const _FallbackProduct(),
                      ),
                      if (discount != null)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.coral600,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              '-' + discount.toString() + '%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 42,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (p['name'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 12.5,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            (p['category']?['name'] ?? 'Porto Prime')
                                .toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const Spacer(),
                        if (oldPrice != null && oldPrice > price)
                          Text(
                            'R\$ ' +
                                oldPrice
                                    .toStringAsFixed(2)
                                    .replaceAll('.', ','),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppColors.subtle,
                                      fontSize: 9.5,
                                    ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                'R\$ ' +
                                    price
                                        .toStringAsFixed(2)
                                        .replaceAll('.', ','),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: AppMotion.standard,
                              switchInCurve: AppMotion.curve,
                              switchOutCurve: AppMotion.curve,
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
                                      onMinus: () => state.changeQty(id, -1),
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
    );
  }
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
              width: 38,
              height: 38,
              child: Icon(
                AppIcons.plus,
                color: Colors.white,
                size: 18,
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
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 3),
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
              width: 24,
              child: Text(
                qty.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.ocean800,
                      fontWeight: FontWeight.w800,
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
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: SizedBox(
          width: 30,
          height: 32,
          child: Icon(
            icon,
            size: 15,
            color: AppColors.ocean800,
          ),
        ),
      );
}

class _FallbackProduct extends StatelessWidget {
  const _FallbackProduct();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(
          AppIcons.package,
          size: 44,
          color: AppColors.ocean600,
        ),
      );
}
