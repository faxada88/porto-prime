import '../../../../core/localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/prime_brand.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';
import '../../../orders/presentation/pages/order_tracking_page.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});
  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  bool refreshing = false;

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    try {
      await AppState.instance.loadOrders();
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  double _money(dynamic value) =>
      double.tryParse(value?.toString() ?? '0') ?? 0;
  String _brl(dynamic value) =>
      'R\$ ${_money(value).toStringAsFixed(2).replaceAll('.', ',')}';
  String _short(dynamic id) {
    final value = id.toString().toUpperCase();
    return value.length > 8 ? value.substring(0, 8) : value;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppState.instance,
    builder: (_, __) {
      final orders = AppState.instance.orders;
      final paid = orders.where((o) => o['paymentStatus'] == 'PAID').toList();
      final pending = orders
          .where(
            (o) =>
                o['paymentStatus'] == 'PENDING' ||
                o['paymentStatus'] == 'FAILED',
          )
          .toList();
      final paidTotal = paid.fold<double>(
        0,
        (sum, o) => sum + _money(o['total']),
      );

      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(

          backgroundColor: AppColors.canvas,
          surfaceTintColor: AppColors.canvas,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(AppIcons.arrow_back_rounded),
          ),
          title: const PrimeText(
            'Pagamentos',
            style: TextStyle(fontSize: 17, fontWeight: AppFontWeight.display),
          ),
          actions: [
            IconButton(
              onPressed: refreshing ? null : _refresh,
              icon: refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.refresh_rounded),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: PrimePageViewport(child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const PrimeEditorialHeader(title: 'Tudo em ordem.', subtitle: 'Consulte os pagamentos e os valores dos seus pedidos.', icon: AppIcons.creditCard, eyebrow: 'PAGAMENTOS'),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.midnight, AppColors.ocean700],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0A3C34),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .11),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            AppIcons.account_balance_wallet_rounded,
                            color: Color(0xFF8CFFE4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const PrimeText(
                            'PORTO PRIME PAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.display,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const PrimeText(
                      'Total confirmado',
                      style: TextStyle(
                        color: Color(0xFFB9D7D1),
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.strong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    PrimeText(
                      _brl(paidTotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        fontWeight: AppFontWeight.display,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _metric(
                          AppIcons.verified_rounded,
                          '${paid.length}',
                          'pagos',
                        ),
                        const SizedBox(width: 9),
                        _metric(
                          AppIcons.schedule_rounded,
                          '${pending.length}',
                          'pendentes',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: PrimeText(
                      'Movimentações',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: AppFontWeight.display,
                        letterSpacing: -.4,
                      ),
                    ),
                  ),
                  PrimeText(
                    '${orders.length} pedido(s)',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.strong,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const PrimeText(
                'Cobranças, créditos e devoluções organizados por pedido.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: AppFontSize.caption,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              if (pending.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.info_outline_rounded,
                        color: AppColors.oceanDeep,
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: PrimeText(
                          'Há pagamentos ainda não concluídos. Você pode limpar somente as pendências, sem alterar pedidos pagos.',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            height: 1.4,
                            fontWeight: AppFontWeight.strong,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _clearPending,
                        icon: const Icon(AppIcons.delete_sweep_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (orders.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 54,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: const Color(0xFFE6EBE7)),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        AppIcons.receipt_long_outlined,
                        size: 44,
                        color: AppColors.muted,
                      ),
                      SizedBox(height: 12),
                      PrimeText(
                        'Nenhum pagamento ainda',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: AppFontWeight.display,
                        ),
                      ),
                      SizedBox(height: 5),
                      PrimeText(
                        'Quando você fizer um pedido, o histórico financeiro aparecerá aqui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: AppFontSize.caption,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...orders.map(_paymentCard),
            ],
          )),
        ),
      );
    },
  );

  Widget _metric(IconData icon, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8CFFE4)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrimeText(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: AppFontWeight.display,
                ),
              ),
              PrimeText(
                label,
                style: const TextStyle(
                  color: Color(0xFFB9D7D1),
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.strong,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _paymentCard(dynamic order) {
    final status = order['paymentStatus']?.toString() ?? 'PENDING';
    final isPaid = status == 'PAID';
    final failed = status == 'FAILED';
    final id = order['id'].toString();
    final label = isPaid
        ? 'Pagamento confirmado'
        : failed
        ? 'Pagamento não concluído'
        : 'Aguardando pagamento';
    final created = order['createdAt']?.toString();
    final method = (double.tryParse('${order['total']}')??0)==0&&(double.tryParse('${order['storeCreditUsed']}')??0)>0?'Cartão Porto Prime':order['paymentMethod']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderTrackingPage(orderId: id)),
          ),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE6EBE7)),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isPaid ? AppColors.mint : AppColors.sand,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    isPaid
                        ? AppIcons.check_circle_rounded
                        : failed
                        ? AppIcons.error_outline_rounded
                        : AppIcons.schedule_rounded,
                    color: AppColors.oceanDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: PrimeText(
                              label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: AppFontWeight.display,
                              ),
                            ),
                          ),
                          PrimeText(
                            _brl(order['total']),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: AppFontWeight.display,
                              color: AppColors.oceanDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      PrimeText(
                        'Pedido #${_short(id)}${method == null ? '' : ' • $method'}',
                        style: const TextStyle(
                          fontSize: AppFontSize.caption,
                          color: AppColors.muted,
                          fontWeight: AppFontWeight.strong,
                        ),
                      ),
                      if (created != null) ...[
                        const SizedBox(height: 3),
                        PrimeText(
                          created.replaceFirst('T', ' ').split('.').first,
                          style: const TextStyle(
                            fontSize: AppFontSize.caption,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  AppIcons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearPending() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const PrimeText('Limpar pendências?'),
        content: const PrimeText(
          'Somente pedidos não pagos serão apagados. Pagamentos confirmados serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const PrimeText('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const PrimeText('Limpar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final count = await AppState.instance.clearPendingOrders();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: PrimeText('$count pendência(s) removida(s).')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: PrimeText(PrimeMessages.friendly(e))),
        );
    }
  }
}

