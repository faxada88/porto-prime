import '../../../../core/localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';

String _money(dynamic value) => 'R\$ ${(double.tryParse('$value') ?? 0).toStringAsFixed(2).replaceAll('.', ',')}';

class CustomerCancellationPanel extends StatefulWidget {
  const CustomerCancellationPanel({super.key, required this.order});
  final Map<String, dynamic> order;
  @override
  State<CustomerCancellationPanel> createState() => _CustomerCancellationPanelState();
}
class _CustomerCancellationPanelState extends State<CustomerCancellationPanel> {
  bool _loading = false;
  String? _error;
  Future<void> _refresh() async { await Future.wait([AppState.instance.loadOrders(), AppState.instance.loadActiveOrder(), AppState.instance.loadCustomerCredit()]); }
  Future<void> _open() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final id = widget.order['id'].toString();
      final quote = await AppState.instance.api.request('GET', '/orders/$id/cancellation-quote');
      if (!mounted) return;
      if (quote['alreadyCanceled'] == true) { await _refresh(); return; }
      final canceled = await showModalBottomSheet<bool>(
        context: context, isScrollControlled: true, useSafeArea: true,
        backgroundColor: Colors.white, showDragHandle: false,
        constraints: const BoxConstraints(maxWidth: 520),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => _CancellationSheet(id: id, initialQuote: Map<String, dynamic>.from(quote as Map)),
      );
      if (canceled == true) await _refresh();
    } catch (e) { if (mounted) setState(() => _error = PrimeMessages.friendly(e)); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    final record = widget.order['cancellation'];
    if (record is Map) {
      final done = record['status'] == 'COMPLETED';
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.stroke)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(done ? AppIcons.checkCircle : AppIcons.clock, color: AppColors.ocean700), const SizedBox(width: 12), Expanded(child: PrimeText(done ? 'Cancelamento concluído' : 'Pedido cancelado', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))]),
          const SizedBox(height: 12),
          PrimeText(done ? 'Devoluções registradas nas formas de pagamento utilizadas.' : record['status'] == 'REVIEW' ? 'A entrega foi interrompida. A loja está verificando o estorno do pagamento.' : 'A entrega foi interrompida. Seu saldo volta ao Cartão Porto Prime e o estorno do pagamento está em processamento.', style: const TextStyle(color: AppColors.muted, height: 1.5)),
          const SizedBox(height: 14),
          _RefundRow(icon: AppIcons.creditCard, label: 'Pagamento via Stripe', amount: record['cashRefund']),
          _RefundRow(icon: AppIcons.wallet, label: 'Cartão Porto Prime', amount: record['creditRefund']),
          if ((double.tryParse('${record['fee']}') ?? 0) > 0) _RefundRow(icon: AppIcons.bike, label: 'Taxa de cancelamento', amount: record['fee']),
        ]),
      );
    }
    if (['DELIVERED', 'CANCELED'].contains(widget.order['status']) || widget.order['deliveredAt'] != null || !['PAID', 'PARTIALLY_REFUNDED'].contains(widget.order['paymentStatus'])) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      OutlinedButton.icon(onPressed: _loading ? null : _open, icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(AppIcons.close, size: 18), label: const PrimeText('Cancelar pedido')),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: PrimeErrorBanner(message: _error!)),
    ]);
  }
}

class _CancellationSheet extends StatefulWidget {
  const _CancellationSheet({required this.id, required this.initialQuote});
  final String id;
  final Map<String, dynamic> initialQuote;
  @override
  State<_CancellationSheet> createState() => _CancellationSheetState();
}
class _CancellationSheetState extends State<_CancellationSheet> {
  late Map<String, dynamic> quote = widget.initialQuote;
  String reason = 'Mudei de ideia';
  bool saving = false;
  String? error;
  double value(String key) => double.tryParse('${quote[key]}') ?? 0;
  Future<void> _confirm() async {
    setState(() { saving = true; error = null; });
    try {
      await AppState.instance.api.request('POST', '/orders/${widget.id}/cancel', body: {'reason': reason, 'expectedFee': value('fee'), 'expectedCashRefund': value('cashRefund'), 'expectedCreditRefund': value('creditRefund')});
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      try {
        final fresh = await AppState.instance.api.request('GET', '/orders/${widget.id}/cancellation-quote');
        if (!mounted) return;
        if (fresh['alreadyCanceled'] == true) { Navigator.of(context).pop(true); return; }
        setState(() => quote = Map<String, dynamic>.from(fresh as Map));
      } catch (_) {}
      if (mounted) setState(() => error = '${PrimeMessages.friendly(e)} Revise os valores antes de confirmar novamente.');
    } finally { if (mounted) setState(() => saving = false); }
  }
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .88,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 16, 12, 8), child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.ocean50, borderRadius: BorderRadius.circular(14)), child: const Icon(AppIcons.receipt, color: AppColors.ocean700)),
          const SizedBox(width: 12), const Expanded(child: PrimeText('Revisar cancelamento', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
          IconButton(tooltip: translateLabel( 'Fechar'), onPressed: saving ? null : () => Navigator.of(context).pop(), icon: const Icon(AppIcons.close)),
        ])),
        const Divider(height: 1),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PrimeText('Antes de cancelar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.7)),
          const SizedBox(height: 8), const PrimeText('A entrega será interrompida. Cada valor retorna à forma de pagamento utilizada.', style: TextStyle(color: AppColors.muted, height: 1.5)),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(itemHeight: null, initialValue: reason, isExpanded: true, decoration: const PrimeInputDecoration(labelText: 'Por que deseja cancelar?'), items: ['Mudei de ideia', 'Endereço incorreto', 'Demora no atendimento', 'Outro motivo'].map((r) => DropdownMenuItem(value: r, child: PrimeText(r, overflow: TextOverflow.ellipsis))).toList(), onChanged: saving ? null : (r) => setState(() => reason = r ?? reason)),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.ocean50, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.ocean100)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const PrimeText('VOCÊ RECEBE DE VOLTA', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.ocean700)),
            const SizedBox(height: 8), PrimeText(_money(value('cashRefund') + value('creditRefund')), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ocean900)),
            const SizedBox(height: 12),
            if (value('cashRefund') > 0) _RefundRow(icon: AppIcons.creditCard, label: 'Pagamento via Stripe', amount: quote['cashRefund']),
            if (value('creditRefund') > 0) _RefundRow(icon: AppIcons.wallet, label: 'Cartão Porto Prime', amount: quote['creditRefund']),
          ])),
          const SizedBox(height: 16),
          if (value('fee') > 0) ...[
            _RefundRow(icon: AppIcons.bike, label: 'Taxa de cancelamento', amount: quote['fee']),
            const PrimeText('Este valor já foi descontado das devoluções acima e será repassado ao entregador. Após a coleta, a taxa de entrega é retida integralmente para cobrir o retorno à distribuidora.', style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5)),
          ] else const PrimeText('Cancelamento sem custo.', style: TextStyle(color: AppColors.ocean700, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16), const PrimeText('O saldo retorna ao Cartão Porto Prime. O prazo do estorno Stripe depende da instituição financeira.', style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5)),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 16), child: PrimeErrorBanner(message: error!)),
        ]))),
        Container(padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.paddingOf(context).bottom), decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.stroke))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: 52, child: FilledButton(onPressed: saving ? null : _confirm, child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const PrimeText('Confirmar cancelamento'))),
          TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(), child: const PrimeText('Manter meu pedido')),
        ])),
      ]),
    ),
  );
}
class _RefundRow extends StatelessWidget {
  const _RefundRow({required this.icon, required this.label, required this.amount});
  final IconData icon;
  final String label;
  final dynamic amount;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 18, color: AppColors.ocean700), const SizedBox(width: 10), Expanded(child: PrimeText(label, style: const TextStyle(fontSize: 12, height: 1.5))), const SizedBox(width: 12), PrimeText(_money(amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))]));
}

