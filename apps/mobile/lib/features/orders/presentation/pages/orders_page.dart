import 'package:flutter/material.dart';
import '../../../../core/widgets/prime_brand.dart';

import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';
import 'order_tracking_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await Future.wait([
        AppState.instance.loadOrders(),
        AppState.instance.loadActiveOrder(),
      ]);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool _finished(dynamic order) =>
      order['status'] == 'DELIVERED' || order['status'] == 'CANCELED';

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          leading: Navigator.of(context).canPop() ? const PrimeBackButton() : null,
          title: const Text('Pedidos'),
          actions: [
            IconButton(
              tooltip: 'Início',
              onPressed: AppNav.instance.home,
              icon: const Icon(AppIcons.home),
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: AppState.instance,
          builder: (_, __) {
            final all = AppState.instance.orders;
            final active = all.where((o) => !_finished(o)).toList();
            final history = all.where(_finished).toList();

            if (loading && all.isEmpty) {
              return const _OrdersSkeleton();
            }

            if (all.isEmpty) {
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 30),
                  children: [
                    PrimeEmptyState(
                      icon: AppIcons.receipt,
                      title: 'Nenhum pedido ainda',
                      message:
                          'Quando você fizer seu primeiro pedido, ele aparecerá aqui com acompanhamento completo.',
                      actionLabel: 'Explorar produtos',
                      onAction: AppNav.instance.home,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
                children: [
                  const PrimeEditorialHeader(title: 'Cada pedido, bem acompanhado.', subtitle: 'Sua compra atual e seus bons momentos anteriores, no mesmo lugar.', icon: AppIcons.receipt, eyebrow: 'SEUS PEDIDOS'),
                  const SizedBox(height: 24),
                  if (active.isNotEmpty) ...[
                    const PrimeSectionHeader(
                      eyebrow: 'AGORA',
                      title: 'Pedido atual',
                      subtitle: 'Acompanhe cada etapa em tempo real.',
                    ),
                    const SizedBox(height: 14),
                    ...active.map(
                      (o) => _OrderCard(order: o, active: true),
                    ),
                  ],
                  if (history.isNotEmpty) ...[
                    SizedBox(height: active.isEmpty ? 4 : 26),
                    const PrimeSectionHeader(
                      eyebrow: 'HISTÓRICO',
                      title: 'Pedidos anteriores',
                    ),
                    const SizedBox(height: 12),
                    ...history.map(
                      (o) => _OrderCard(order: o, active: false),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.active,
  });

  final dynamic order;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final id = order['id'].toString();
    final items = (order['items'] as List?) ?? const [];
    final status = order['status'].toString();
    final paid = order['paymentStatus'] == 'PAID';
    final shortId =
        id.substring(0, id.length < 8 ? id.length : 8).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: active ? AppColors.ocean900 : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingPage(orderId: id),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: active
                  ? Border.all(color: Colors.white.withValues(alpha: .07))
                  : Border.all(color: AppColors.stroke),
              boxShadow: active ? AppShadows.elevated : AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PrimeStatusPill(
                      label: active ? 'EM ANDAMENTO' : _status(status),
                      tone: active
                          ? PrimeStatusTone.success
                          : status == 'CANCELED'
                              ? PrimeStatusTone.danger
                              : PrimeStatusTone.neutral,
                    ),
                    const Spacer(),
                    Icon(
                      AppIcons.chevronRight,
                      color: active ? Colors.white70 : AppColors.muted,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  'Pedido #' + shortId,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: active ? Colors.white : AppColors.ink,
                        fontWeight: AppFontWeight.display,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  items.isEmpty
                      ? 'Pedido Porto Prime'
                      : items
                          .map(
                            (x) =>
                                x['quantity'].toString() +
                                'x ' +
                                (x['productName'] ?? 'Produto').toString(),
                          )
                          .join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: active
                            ? Colors.white.withValues(alpha: .68)
                            : AppColors.muted,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      paid ? AppIcons.checkCircle : AppIcons.clock,
                      size: 16,
                      color: active
                          ? const Color(0xFF9FFFE7)
                          : AppColors.ocean700,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        paid ? 'Pagamento aprovado' : 'Pagamento pendente',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: active
                                      ? Colors.white.withValues(alpha: .7)
                                      : AppColors.muted,
                                ),
                      ),
                    ),
                    Text(
                      _money(order['total']),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: active ? Colors.white : AppColors.ink,
                            fontWeight: AppFontWeight.display,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          PrimeSkeleton(height: 25, width: 180),
          SizedBox(height: 8),
          PrimeSkeleton(height: 14, width: 240),
          SizedBox(height: 18),
          PrimeSkeleton(height: 170, radius: AppRadius.lg),
          SizedBox(height: 12),
          PrimeSkeleton(height: 130, radius: AppRadius.lg),
        ],
      );
}

String _money(dynamic value) {
  final number = double.tryParse(value.toString()) ?? 0;
  return 'R\$ ' + number.toStringAsFixed(2).replaceAll('.', ',');
}

String _status(String status) => switch (status) {
      'DELIVERED' => 'ENTREGUE',
      'CANCELED' => 'CANCELADO',
      _ => status.replaceAll('_', ' '),
    };
