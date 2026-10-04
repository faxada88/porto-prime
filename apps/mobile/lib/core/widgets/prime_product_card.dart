import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class PrimeProductCard extends StatefulWidget {
  const PrimeProductCard({super.key, required this.product, this.onOpen});
  final dynamic product;
  final VoidCallback? onOpen;

  @override
  State<PrimeProductCard> createState() => _PrimeProductCardState();
}

class _PrimeProductCardState extends State<PrimeProductCard> {
  bool added = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final state = AppState.instance;
    final id = p['id'].toString();
    final price = double.tryParse(p['price'].toString()) ?? 0;
    final qty = state.cart[id] ?? 0;
    final image = p['imageUrl']?.toString();

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.stroke),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ColoredBox(
                          color: AppColors.mint,
                          child: image != null && image.isNotEmpty
                              ? Image.network(
                                  image,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (_, __, ___) => const _Fallback(),
                                )
                              : const _Fallback(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 1, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (p['name'] ?? '').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.15, fontWeight: FontWeight.w900, letterSpacing: -.2),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (p['category']?['name'] ?? 'Porto Prime').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9.5, color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -.3),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Adicionar ${p['name']}',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                state.addProduct(id);
                                setState(() => added = true);
                                Future<void>.delayed(const Duration(milliseconds: 650), () {
                                  if (mounted) setState(() => added = false);
                                });
                              },
                              child: AnimatedScale(
                                scale: added ? 1.12 : 1,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutBack,
                                child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: added ? AppColors.success : AppColors.ink,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 160),
                                  child: Icon(
                                    added ? Symbols.check_rounded : Symbols.add_rounded,
                                    key: ValueKey(added),
                                    color: Colors.white,
                                    size: 21,
                                    weight: 650,
                                  ),
                                ),
                              ),
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
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();
  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(Symbols.local_drink_rounded, size: 52, color: AppColors.oceanDeep, weight: 420),
  );
}
