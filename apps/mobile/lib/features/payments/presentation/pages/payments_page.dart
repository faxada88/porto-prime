import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
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

  double _money(dynamic value) => double.tryParse(value?.toString() ?? '0') ?? 0;
  String _brl(dynamic value) => 'R\$ ${_money(value).toStringAsFixed(2).replaceAll('.', ',')}';
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
      final pending = orders.where((o) => o['paymentStatus'] == 'PENDING' || o['paymentStatus'] == 'FAILED').toList();
      final paidTotal = paid.fold<double>(0, (sum, o) => sum + _money(o['total']));

      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: AppColors.canvas,
          elevation: 0,
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
          title: const Text('Pagamentos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          actions: [IconButton(onPressed: refreshing ? null : _refresh, icon: refreshing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded))],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF102D28), Color(0xFF08786D)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Color(0x1A0A3C34), blurRadius: 28, offset: Offset(0, 14))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .11), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF8CFFE4))),
                    const Spacer(),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: const Text('PORTO PRIME PAY', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .8))),
                  ]),
                  const SizedBox(height: 22),
                  const Text('Total confirmado', style: TextStyle(color: Color(0xFFB9D7D1), fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_brl(paidTotal), style: const TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const SizedBox(height: 18),
                  Row(children: [
                    _metric(Icons.verified_rounded, '${paid.length}', 'pagos'),
                    const SizedBox(width: 9),
                    _metric(Icons.schedule_rounded, '${pending.length}', 'pendentes'),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: Text('Movimentações', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4))),
                Text('${orders.length} pedido(s)', style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 5),
              const Text('Cada cobrança está ligada ao pedido real e ao status confirmado pelo backend.', style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.4)),
              const SizedBox(height: 14),
              if (pending.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.oceanDeep),
                    const SizedBox(width: 11),
                    const Expanded(child: Text('Há pagamentos ainda não concluídos. Você pode limpar somente as pendências, sem alterar pedidos pagos.', style: TextStyle(fontSize: 9.5, height: 1.4, fontWeight: FontWeight.w700))),
                    IconButton(onPressed: _clearPending, icon: const Icon(Icons.delete_sweep_outlined)),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              if (orders.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFE6EBE7))),
                  child: const Column(children: [Icon(Icons.receipt_long_outlined, size: 44, color: AppColors.muted), SizedBox(height: 12), Text('Nenhum pagamento ainda', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('Quando você fizer um pedido, o histórico financeiro aparecerá aqui.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.4))]),
                )
              else
                ...orders.map(_paymentCard),
            ],
          ),
        ),
      );
    },
  );

  Widget _metric(IconData icon, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .09), borderRadius: BorderRadius.circular(17)),
      child: Row(children: [Icon(icon, size: 18, color: const Color(0xFF8CFFE4)), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Color(0xFFB9D7D1), fontSize: 8, fontWeight: FontWeight.w700))])]),
    ),
  );

  Widget _paymentCard(dynamic order) {
    final status = order['paymentStatus']?.toString() ?? 'PENDING';
    final isPaid = status == 'PAID';
    final failed = status == 'FAILED';
    final id = order['id'].toString();
    final label = isPaid ? 'Pagamento confirmado' : failed ? 'Pagamento não concluído' : 'Aguardando pagamento';
    final created = order['createdAt']?.toString();
    final method = order['paymentMethod']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderTrackingPage(orderId: id))),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE6EBE7)), borderRadius: BorderRadius.circular(23)),
            child: Row(children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: isPaid ? AppColors.mint : AppColors.sand, borderRadius: BorderRadius.circular(17)), child: Icon(isPaid ? Icons.check_circle_rounded : failed ? Icons.error_outline_rounded : Icons.schedule_rounded, color: AppColors.oceanDeep)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))), Text(_brl(order['total']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.oceanDeep))]),
                const SizedBox(height: 4),
                Text('Pedido #${_short(id)}${method == null ? '' : ' • $method'}', style: const TextStyle(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.w700)),
                if (created != null) ...[const SizedBox(height: 3), Text(created.replaceFirst('T', ' ').split('.').first, style: const TextStyle(fontSize: 8.5, color: AppColors.muted))],
              ])),
              const SizedBox(width: 5),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _clearPending() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Limpar pendências?'),
        content: const Text('Somente pedidos não pagos serão apagados. Pagamentos confirmados serão preservados.'),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Limpar'))],
      ),
    );
    if (confirm != true) return;
    try {
      final count = await AppState.instance.clearPendingOrders();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count pendência(s) removida(s).')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }
}
