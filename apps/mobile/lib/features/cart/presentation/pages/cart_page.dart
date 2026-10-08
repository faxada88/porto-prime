import '../../../addresses/presentation/pages/address_book_page.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';
import '../../../checkout/presentation/pages/stripe_checkout_page.dart';
import '../../../orders/presentation/pages/order_tracking_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppState.instance,
    builder: (_, __) {
      final s = AppState.instance;
      final entries = s.cart.entries.toList();
      final quotedFee =
          double.tryParse(s.deliveryQuote['deliveryFee']?.toString() ?? '');
      final delivery = entries.isEmpty ? 0.0 : (quotedFee ?? 0.0);
      final total = s.cartSubtotal + delivery;

      return SafeArea(
        bottom: false,
        child: PrimePageViewport(child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sua sacola',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Revise tudo antes de seguir para o pagamento.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ocean50,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    s.cartCount.toString() +
                        (s.cartCount == 1 ? ' item' : ' itens'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.ocean800,
                          fontWeight: AppFontWeight.display,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _Delivery(quote: s.deliveryQuote),
            const SizedBox(height: 14),

            if (entries.isEmpty)
              const _EmptyCart()
            else ...[
              for (final entry in entries) ...[
                _LiveItem(id: entry.key, qty: entry.value),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.stroke),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  children: [
                    _Price(
                      'Subtotal',
                      _brl(s.cartSubtotal),
                    ),
                    const SizedBox(height: 10),
                    _Price(
                      'Entrega',
                      entries.isNotEmpty && quotedFee == null
                          ? 'Calculada no endereço'
                          : _brl(delivery),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1),
                    ),
                    _Price('Total', _brl(total), strong: true),
                  ],
                ),
              ),
              if (s.storeStatusKnown && !s.storeOpen) Padding(
                padding: const EdgeInsets.only(top:14),
                child: Text(s.storeMessage, style: const TextStyle(color: Color(0xFF795D28), height:1.5)),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: s.loading || !s.storeOpen ? null : () => _checkout(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ocean800,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: s.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              !s.storeStatusKnown ? 'Verificando disponibilidade…' : s.storeOpen ? 'Continuar para pagamento' : 'Loja fechada no momento',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: AppFontWeight.display,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              AppIcons.arrowRight,
                              color: Colors.white,
                              size: 19,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ],
        )),
      );
    },
  );
}

String _brl(double value) =>
    'R\$ ' + value.toStringAsFixed(2).replaceAll('.', ',');

class _Delivery extends StatelessWidget {
  const _Delivery({required this.quote});
  final Map<String,dynamic> quote;

  @override
  Widget build(BuildContext context) {
    final fee=double.tryParse(quote['deliveryFee']?.toString()??'');
    final distance=double.tryParse(quote['distanceKm']?.toString()??'');
    final duration=quote['durationMinutes'];
    final detail=fee==null
        ?'O valor é calculado pelo endereço e pela rota viária.'
        :distance==null
            ?_brl(fee)+' • taxa configurada'
            :_brl(fee)+' • '+distance.toStringAsFixed(1)+' km • ~'+duration.toString()+' min';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(AppIcons.route, color: AppColors.coral),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entrega Prime',
                  style: TextStyle(fontWeight: AppFontWeight.display),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.muted,
                    height: 1.35,
                    fontWeight: AppFontWeight.medium,
                  ),
                ),
              ],
            ),
          ),
          const Icon(AppIcons.chevronRight),
        ],
      ),
    );
  }
}

class _LiveItem extends StatelessWidget {
  const _LiveItem({required this.id, required this.qty});
  final String id;
  final int qty;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final p = s.product(id);
    if (p == null) return const SizedBox.shrink();

    final price = double.tryParse(p['price'].toString()) ?? 0;
    final image = (p['imageUrl'] ?? '').toString();
    final detail = (p['category']?['name'] ?? 'Porto Prime').toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.stroke),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.surfaceSoft, AppColors.surfaceMuted],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.stroke),
            ),
            child: image.isEmpty
                ? const Icon(
                    AppIcons.package,
                    size: 30,
                    color: AppColors.ocean700,
                  )
                : Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.network(
                      image,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => const Icon(
                        AppIcons.package,
                        size: 30,
                        color: AppColors.ocean700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.ocean600,
                        fontSize: AppFontSize.caption,
                        letterSpacing: .65,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  (p['name'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 13.2,
                        fontWeight: AppFontWeight.display,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _brl(price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14.5,
                        fontWeight: AppFontWeight.display,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Semantics(
                button: true,
                label: 'Remover produto da sacola',
                child: InkWell(
                  onTap: () => s.removeProduct(id),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: const SizedBox(
                    width: AppControl.minTap,
                    height: AppControl.minTap,
                    child: Icon(
                      AppIcons.trash,
                      size: 16,
                      color: AppColors.subtle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Container(
                height: AppControl.minTap,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.ocean50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.ocean100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CartQtyButton(
                      icon: AppIcons.minus,
                      label: 'Diminuir quantidade',
                      onTap: () => s.changeQty(id, -1),
                    ),
                    SizedBox(
                      width: 23,
                      child: Text(
                        qty.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.ocean800,
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.display,
                        ),
                      ),
                    ),
                    _CartQtyButton(
                      icon: AppIcons.plus,
                      label: 'Aumentar quantidade',
                      onTap: () => s.changeQty(id, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartQtyButton extends StatelessWidget {
  const _CartQtyButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            width: AppControl.minTap,
            height: AppControl.minTap,
            child: Icon(
              icon,
              size: 14,
              color: AppColors.ocean800,
            ),
          ),
        ),
      );
}

class _Price extends StatelessWidget {
  const _Price(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: strong ? AppColors.ink : AppColors.muted,
            fontWeight: strong ? AppFontWeight.display : AppFontWeight.medium,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: strong ? 18 : 13,
          fontWeight: AppFontWeight.display,
        ),
      ),
    ],
  );
}

class _CheckoutStages extends StatelessWidget {
  const _CheckoutStages();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceOcean,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.ocean100),
        ),
        child: const Row(
          children: [
            _CheckoutStage(icon: AppIcons.mapPin, label: 'Endereço', active: true),
            _StageConnector(active: true),
            _CheckoutStage(icon: AppIcons.route, label: 'Entrega', active: true),
            _StageConnector(active: false),
            _CheckoutStage(icon: AppIcons.creditCard, label: 'Pagamento'),
          ],
        ),
      );
}

class _CheckoutStage extends StatelessWidget {
  const _CheckoutStage({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: active ? AppColors.ocean800 : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? AppColors.ocean800 : AppColors.strokeStrong,
                ),
              ),
              child: Icon(
                icon,
                size: 14,
                color: active ? Colors.white : AppColors.subtle,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.display,
                color: active ? AppColors.ocean800 : AppColors.subtle,
              ),
            ),
          ],
        ),
      );
}

class _StageConnector extends StatelessWidget {
  const _StageConnector({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 17),
          decoration: BoxDecoration(
            color: active ? AppColors.ocean300 : AppColors.stroke,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) => PrimeEmptyState(
        icon: AppIcons.bag,
        title: 'Sua sacola está vazia',
        message:
            'Escolha seus produtos favoritos e volte aqui para finalizar.',
        actionLabel: 'Descobrir produtos',
        onAction: () => AppNav.instance.go(1),
      );
}

Future<void> _checkout(BuildContext context) async {
  final s = AppState.instance;

  if (!s.loggedIn || !s.isCustomer) {
    AppNav.instance.go(3);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entre ou crie sua conta de cliente para continuar.'),
      ),
    );
    return;
  }

  final selection = await Navigator.of(context).push<Map<String,dynamic>>(
    MaterialPageRoute(builder: (_) => const AddressBookPage(selectForCheckout: true)),
  );
  if (selection == null || !context.mounted) return;
  final selected=selection['addressId'].toString();
  final agreed=Map<String,dynamic>.from(selection['quote']);

  try {
    final order = await s.createOrder(selected,pricingRevision:(agreed['pricingRevision'] as num?)?.toInt(),expectedDeliveryFee:(agreed['deliveryFee'] as num?)?.toDouble());
    if (!context.mounted) return;

    final orderId = order['id'].toString();
    final payment = await s.createCheckout(orderId);
    if (!context.mounted) return;

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => StripeCheckoutPage(
          clientSecret: payment['clientSecret'].toString(),
          publishableKey: payment['publishableKey'].toString(),
          orderId: orderId,
        ),
      ),
    );

    if (!context.mounted) return;

    if (result == 'track') {
      s.clearCart();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderTrackingPage(orderId: orderId),
        ),
      );
    } else if (result == 'shop') {
      s.clearCart();
      AppNav.instance.go(0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pedido criado. Você pode concluir o pagamento depois.',
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(PrimeMessages.friendly(e)),
        ),
      );
    }
  }
}
