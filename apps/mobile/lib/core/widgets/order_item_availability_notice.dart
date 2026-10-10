import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../../features/wallet/presentation/pages/customer_prime_card_page.dart';

class OrderItemAvailabilityNotice extends StatefulWidget {
  const OrderItemAvailabilityNotice({super.key, required this.order});
  final Map<String, dynamic> order;
  @override
  State<OrderItemAvailabilityNotice> createState() => _NoticeState();
}

class _NoticeState extends State<OrderItemAvailabilityNotice> {
  bool busy = false;
  String? error;
  String money(dynamic value) => 'R\$ ${(double.tryParse(value.toString()) ?? 0).toStringAsFixed(2).replaceAll('.', ',')}';
  final _ink = const Color(0xFF183E48);
  final _muted = const Color(0xFF617680);

  Future<void> choose(dynamic item, String choice, {String? productId}) async {
    final voucher = choice == 'VOUCHER';
    final replacement = choice == 'REPLACEMENT';
    final title = replacement ? 'Confirmar a substituição' : voucher ? 'Receber no Cartão Porto Prime' : 'Devolver pelo pagamento original';
    final text = replacement
        ? 'O produto escolhido entra no lugar deste item, sem custo adicional.'
        : voucher
            ? 'O valor do item ficará disponível em Perfil → Cartão Porto Prime, para usar em produtos na próxima compra.'
            : 'O item será removido. A parte paga pelo Stripe será devolvida pelo pagamento original; créditos usados voltam ao seu Cartão Porto Prime.';
    final confirmed = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Icon(voucher ? Icons.credit_card_rounded : replacement ? Icons.swap_horiz_rounded : Icons.undo_rounded, size: 34, color: const Color(0xFF197D6C)),
        const SizedBox(height: 16), Text(title, style: TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 12), Text(text, style: TextStyle(height: 1.6, color: _muted)),
        const SizedBox(height: 18), Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF3F7F7), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${item['quantity']}× ${item['productName']}', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(money(item['total']), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: _ink))])),
        const SizedBox(height: 12), Text('Os produtos restantes continuam no pedido. Se todos forem removidos, a entrega também será devolvida e o pedido será cancelado.', style: TextStyle(fontSize: 12, height: 1.5, color: _muted)),
        const SizedBox(height: 24), SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Confirmar minha escolha')))),
        SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.pop(sheetContext, false), child: const Text('Voltar às opções'))),
      ]))),
    );
    if (confirmed != true || !mounted) return;
    setState(() { busy = true; error = null; });
    try {
      await AppState.instance.resolveUnavailable(widget.order['id'].toString(), item['id'].toString(), choice, productId: productId);
      if (!mounted) return;
      await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (sheetContext) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(14), decoration: const BoxDecoration(color: Color(0xFFE6F5EC), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Color(0xFF198366), size: 30)),
        const SizedBox(height: 18), Text(voucher ? 'Seu crédito já está no cartão.' : replacement ? 'Substituição confirmada.' : 'Escolha registrada. Item removido.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 10), Text(voucher ? 'Acesse Perfil → Cartão Porto Prime para consultar o saldo e usar na próxima compra.' : replacement ? 'Seu pedido foi atualizado com o produto escolhido.' : 'Acompanhe a confirmação da devolução aqui. Os itens restantes podem seguir para preparação e entrega.', style: TextStyle(height: 1.6, color: _muted)),
        const SizedBox(height: 24), SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(sheetContext), child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Continuar acompanhando')))),
        if (voucher) SizedBox(width: double.infinity, child: TextButton.icon(icon: const Icon(Icons.credit_card_rounded), label: const Text('Abrir meu Cartão Porto Prime'), onPressed: () { Navigator.pop(sheetContext); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerPrimeCardPage())); })),
      ]))));
    } catch (_) {
      if (mounted) setState(() => error = 'Não conseguimos atualizar agora. Atualize o pedido para conferir sua escolha antes de tentar novamente.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget option({required IconData icon, required String title, required String subtitle, required VoidCallback action, bool preferred = false}) => Padding(padding: const EdgeInsets.only(top: 10), child: Material(color: preferred ? const Color(0xFFEAF6F1) : Colors.white, borderRadius: BorderRadius.circular(16), child: InkWell(onTap: busy ? null : action, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: preferred ? const Color(0xFF96CDB7) : const Color(0xFFDCE6E8)), borderRadius: BorderRadius.circular(16)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: preferred ? Colors.white : const Color(0xFFF1F6F6), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF1A766A), size: 23)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink)), const SizedBox(height: 5), Text(subtitle, style: TextStyle(fontSize: 12, height: 1.5, color: _muted))])), const SizedBox(width: 8), const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF5C807B))])))));

  @override
  Widget build(BuildContext context) {
    final items = ((widget.order['items'] as List?) ?? []).where((i) => i['availabilityStatus'] != null && i['availabilityStatus'] != 'AVAILABLE').toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final awaiting = items.any((i) => i['availabilityStatus'] == 'AWAITING_CUSTOMER');
    return Padding(padding: const EdgeInsets.only(bottom: 18), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: awaiting ? const Color(0xFFFFF5F2) : const Color(0xFFF0F8F5), borderRadius: BorderRadius.circular(24), border: Border.all(color: awaiting ? const Color(0xFFF0C3B9) : const Color(0xFFBCDCCC))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(awaiting ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: awaiting ? const Color(0xFFB24232) : const Color(0xFF247D64)), const SizedBox(width: 10), Expanded(child: Text(awaiting ? 'Vamos resolver isso com você.' : 'Seu pedido foi atualizado.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: _ink)))]),
      const SizedBox(height: 10), Text(awaiting ? 'Um produto está indisponível. Escolha como prefere resolver, de forma simples e segura.' : widget.order['status'] == 'CANCELED' ? 'Todos os produtos foram removidos. Confira abaixo a devolução de cada item.' : 'Os itens removidos não serão entregues. Os produtos restantes continuam no pedido.', style: TextStyle(height: 1.6, fontSize: 13, color: _muted)),
      ...items.map((item) {
        final status = item['availabilityStatus'];
        return Container(margin: const EdgeInsets.only(top: 18), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text('${item['quantity']}× ${item['productName']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink))), const SizedBox(width: 10), Text(money(item['total']), style: TextStyle(fontWeight: FontWeight.w800, color: _ink))]),
          const SizedBox(height: 10),
          if (status == 'AWAITING_CUSTOMER') ...[
            Text(item['availabilityNote'] ?? 'Este item ficou indisponível.', style: TextStyle(height: 1.5, fontSize: 13, color: _muted)),
            ...((item['availabilityOptions'] as List?) ?? []).map((p) => option(icon: Icons.swap_horiz_rounded, title: 'Trocar por ${p['name']}', subtitle: 'Mesmo valor. Sem cobrança adicional.', action: () => choose(item, 'REPLACEMENT', productId: p['id'].toString()))),
            option(icon: Icons.credit_card_rounded, title: 'Receber voucher Porto Prime', subtitle: 'Crédito no seu cartão para produtos na próxima compra.', preferred: true, action: () => choose(item, 'VOUCHER')),
            option(icon: Icons.undo_rounded, title: 'Reembolso no pagamento original', subtitle: 'Devolução pelo Stripe. Créditos usados voltam ao cartão.', action: () => choose(item, 'REFUND')),
          ],
          if (status == 'REFUND_PROCESSING') Text(['failed', 'canceled'].contains(item['refundStatus']) ? 'Item removido • a loja está verificando sua devolução. A entrega dos itens restantes não fica bloqueada.' : 'Item removido • reembolso solicitado. A confirmação da devolução aparecerá aqui.', style: TextStyle(height: 1.6, fontSize: 13, color: _muted)),
          if (status == 'REFUNDED') Text('Item removido e reembolso confirmado: ${money(item['refundAmount'])}.${(double.tryParse(item['creditAmount'].toString()) ?? 0) > 0 ? ' Créditos restaurados no cartão: ${money(item['creditAmount'])}.' : ''}', style: const TextStyle(height: 1.6, fontSize: 13, color: Color(0xFF21785F))),
          if (status == 'VOUCHERED') ...[Text('Item removido • ${money(item['creditAmount'])} disponíveis no Cartão Porto Prime.', style: const TextStyle(height: 1.6, fontSize: 13, color: Color(0xFF21785F))), TextButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerPrimeCardPage())), icon: const Icon(Icons.credit_card_rounded, size: 18), label: const Text('Ver meu cartão e voucher'))],
          if (status == 'REPLACED') Text('Substitui ${item['originalProductName']}. Produto confirmado no seu pedido, sem custo adicional.', style: TextStyle(height: 1.6, fontSize: 13, color: _muted)),
        ]));
      }),
      if (busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Color(0xFFB44333), height: 1.5))),
    ])));
  }
}
