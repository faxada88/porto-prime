import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';

class DeliveryReturnPage extends StatefulWidget {
  const DeliveryReturnPage({super.key, required this.order});
  final Map<String, dynamic> order;
  @override
  State<DeliveryReturnPage> createState() => _DeliveryReturnPageState();
}
class _DeliveryReturnPageState extends State<DeliveryReturnPage> {
  bool busy = false;
  String? error;
  Future<void> advance(String step) async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    try {
      await AppState.instance.api.request('POST', '/orders/cancellations/${widget.order['cancellation']['id']}/return/$step');
      await AppState.instance.refreshCourier();
    } catch (e) { if (mounted) setState(() => error = PrimeMessages.friendly(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final record = widget.order['cancellation'];
    final status = record['returnStatus'];
    final stage = status == 'ARRIVED' ? 2 : status == 'IN_TRANSIT' ? 1 : 0;
    final alreadyPaid = widget.order['returnFeePaid'] == true;
    final fee = double.tryParse('${record['fee']}') ?? 0;
    final items = (widget.order['items'] as List? ?? []).whereType<Map>().where((item) => !['REFUNDED', 'REFUND_PROCESSING', 'VOUCHERED'].contains(item['availabilityStatus'])).toList();
    final id = widget.order['id'].toString();
    final number = id.substring(id.length > 8 ? id.length - 8 : 0).toUpperCase();
    final title = stage == 2 ? 'Produtos na loja.\nFalta a conferência.' : stage == 1 ? 'Seu destino agora\né a distribuidora.' : 'Vamos retornar\ncom os produtos.';
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Retorno à loja'), actions: [IconButton(tooltip: 'Atualizar retorno', onPressed: busy ? null : () => AppState.instance.refreshCourier(), icon: const Icon(AppIcons.refresh))]),
      body: SafeArea(bottom: false, child: RefreshIndicator(onRefresh: () => AppState.instance.refreshCourier(), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ocean900, AppColors.ocean700]), borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.elevated), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: const Text('OPERAÇÃO DE RETORNO', style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w800))), const Spacer(), const Icon(AppIcons.route, color: Colors.white, size: 28)]),
          const SizedBox(height: 24), Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -.6)),
          const SizedBox(height: 16), const Text('O pedido foi cancelado após a coleta. Retorne ao mesmo ponto de retirada com os produtos preservados.', style: TextStyle(color: Color(0xFFD4ECE7), fontSize: 13, height: 1.6)),
          const SizedBox(height: 22), Row(children: [const Icon(AppIcons.receipt, color: Colors.white70, size: 16), const SizedBox(width: 8), Text('Pedido #$number', style: const TextStyle(color: Colors.white70, fontSize: 12))]),
        ])),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.stroke)), child: Column(children: [
          _step(0, stage, AppIcons.route, 'Iniciar retorno', 'Avise que está retornando à distribuidora.'),
          _step(1, stage, AppIcons.store, 'Chegar e entregar os produtos', 'Entregue os itens à equipe da loja.'),
          _step(2, stage, AppIcons.checkCircle, 'Recebimento pela distribuidora', 'O Admin confere e confirma. Seu repasse é liberado.', last: true),
        ])),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.ocean50, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.ocean100)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(AppIcons.wallet, color: AppColors.ocean700, size: 20), const SizedBox(width: 10), Expanded(child: Text(alreadyPaid ? 'REPASSE JÁ REGISTRADO' : 'REPASSE APÓS O RETORNO', style: const TextStyle(color: AppColors.ocean700, fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w800)))]),
          const SizedBox(height: 12), Text('R\$ ${fee.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ocean900)),
          const SizedBox(height: 6), Text(alreadyPaid ? 'Valor já registrado na versão anterior. A devolução dos produtos ainda precisa ser confirmada pela loja.' : 'Valor pendente. Entra na sua carteira somente após a confirmação dos produtos recebidos pelo Admin.', style: const TextStyle(color: AppColors.ocean700, fontSize: 12, height: 1.6)),
        ])),
        if (items.isNotEmpty) ...[const SizedBox(height: 18), Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.stroke)), child: ExpansionTile(shape: const Border(), collapsedShape: const Border(), leading: const Icon(AppIcons.package, color: AppColors.ocean700), title: const Text('Produtos para devolver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)), childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16), children: items.map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${item['quantity']}×', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ocean700)), const SizedBox(width: 12), Expanded(child: Text('${item['productName'] ?? 'Produto'}', style: const TextStyle(fontSize: 13)))]))).toList()))],
        if (error != null) Padding(padding: const EdgeInsets.only(top: 16), child: PrimeErrorBanner(message: error!)),
      ]))))),
      bottomNavigationBar: SafeArea(top: false, child: Container(padding: const EdgeInsets.fromLTRB(20, 14, 20, 16), decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.stroke))), child: Center(heightFactor: 1, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(stage == 2 ? 'Aguarde a conferência. Você ainda está nesta operação.' : 'Você volta a receber entregas após o recebimento confirmado.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.5)),
        const SizedBox(height: 12), SizedBox(height: 54, child: FilledButton.icon(onPressed: busy || stage == 2 ? null : () => advance(stage == 0 ? 'start' : 'arrived'), icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(stage == 2 ? AppIcons.clock : AppIcons.arrowRight), label: Text(busy ? 'Atualizando…' : stage == 0 ? 'Iniciar retorno' : stage == 1 ? 'Entreguei os produtos na loja' : 'Aguardando confirmação do Admin'))),
      ]))))),
    );
  }
  Widget _step(int index, int stage, IconData icon, String title, String subtitle, {bool last = false}) => Padding(padding: EdgeInsets.only(bottom: last ? 0 : 20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(color: index <= stage ? AppColors.ocean50 : AppColors.canvas, borderRadius: BorderRadius.circular(12)), child: Icon(index < stage ? AppIcons.check : icon, size: 18, color: index <= stage ? AppColors.ocean700 : AppColors.muted)),
    const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: index == stage ? AppColors.ocean900 : AppColors.muted)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5))])),
  ]));
}

