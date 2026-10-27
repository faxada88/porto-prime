import 'package:flutter/material.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/state/app_state.dart';
import '../../../support/presentation/pages/support_page.dart';

class CourierReviewSuccess extends StatefulWidget {
  const CourierReviewSuccess({super.key, this.approved = false, this.onOnline, this.requirements = const []});
  final bool approved;
  final VoidCallback? onOnline;
  final List<Map> requirements;
  @override
  State<CourierReviewSuccess> createState() => _CourierReviewSuccessState();
}

class _CourierReviewSuccessState extends State<CourierReviewSuccess> {
  bool busy = false;
  String? error;
  static const ink = Color(0xFF082632);
  static const green = Color(0xFF078873);
  Future<void> goOnline() async {
    if (busy || AppState.instance.courierRestricted) return;
    setState(() { busy = true; error = null; });
    try {
      await AppState.instance.setCourierOnline(true);
      if (mounted && AppState.instance.courierOnline) widget.onOnline?.call();
    } catch (_) {
      if (mounted) setState(() => error = 'Não foi possível ficar online. Tente novamente.');
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, automaticallyImplyLeading: false,
      title: const PrimeText('Minha conta', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
      actions: [IconButton(tooltip: 'Sair da conta', onPressed: AppState.instance.logout, icon: const Icon(Icons.logout_rounded, color: ink))]),
    body: SafeArea(top: false, child: SingleChildScrollView(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560), child: Padding(padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 116, height: 116, decoration: const BoxDecoration(color: Color(0xFFF0FAF6), shape: BoxShape.circle),
          child: Center(child: Container(width: 84, height: 84, decoration: const BoxDecoration(color: Color(0xFFD9F2E8), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, size: 52, color: green))))),
        const SizedBox(height: 18),
        PrimeText(widget.approved ? 'Sua conta está liberada!' : 'Documentação enviada\ncom sucesso', textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 27, height: 1.15, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 12),
        PrimeText(widget.approved ? 'Tudo pronto para voltar às entregas. Fique online quando quiser começar.' : 'Recebemos sua resposta para análise. Você será avisado assim que houver uma atualização.',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF70838C))),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFEFF9F5), borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [Icon(Icons.info_outline, color: green, size: 22), SizedBox(width: 12), Expanded(child: PrimeText('Não é necessário reenviar o CPF.', style: TextStyle(color: green, fontWeight: FontWeight.w600)))])),
        for (final item in widget.requirements) ...[
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE4EBEF)), borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(30)), child: const PrimeText('Pendência ativa', style: TextStyle(color: Color(0xFF9A510B), fontSize: 12, fontWeight: FontWeight.w600))),
              const SizedBox(height: 10), PrimeText(item['title']?.toString() ?? 'Documento enviado', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: ink)),
              const SizedBox(height: 8), const PrimeText('Sua resposta foi enviada para análise. Não é necessário enviar novamente.', style: TextStyle(color: Color(0xFF70838C), height: 1.5)),
            ])),
        ],
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, constraints) {
          final labels = ['Pendência identificada', 'Documento enviado', 'Em análise', 'Conta regularizada'];
          final compact = constraints.maxWidth < 340 || MediaQuery.textScalerOf(context).scale(14) > 20;
          final steps = List.generate(4, (i) => Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(i < 2 || widget.approved ? Icons.check_circle : i == 2 ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: i < 3 || widget.approved ? green : const Color(0xFFA7B6BF), size: 28),
            const SizedBox(height: 7), PrimeText(labels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 11, height: 1.3, color: i == 2 ? green : const Color(0xFF70838C), fontWeight: i == 2 ? FontWeight.w700 : FontWeight.w400)),
          ]));
          return compact ? Wrap(spacing: 12, runSpacing: 16, children: steps.map((s) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: s)).toList()) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: steps.map((s) => Expanded(child: s)).toList());
        }),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEDF9F4), Color(0xFFDDF3EC)]), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(widget.approved ? Icons.check_circle_outline : Icons.manage_search_rounded, color: green), const SizedBox(width: 8), Expanded(child: PrimeText(widget.approved ? 'Conta regularizada' : 'Em análise', style: const TextStyle(color: green, fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 14), PrimeText(widget.approved ? 'Vamos começar?' : 'Tudo certo por enquanto', style: const TextStyle(color: ink, fontSize: 23, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8), PrimeText(widget.approved ? 'Você decide quando ficar disponível para receber entregas.' : 'Enquanto nossa equipe revisa sua documentação, sua solicitação permanece salva e segura.', style: const TextStyle(color: Color(0xFF607F87), height: 1.5)),
        ])),
        const SizedBox(height: 22),
        if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: PrimeText(error!, style: const TextStyle(color: Colors.red))),
        if (widget.approved) Padding(padding: const EdgeInsets.only(bottom: 12), child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: green, padding: const EdgeInsets.all(18)), onPressed: busy ? null : goOnline, icon: const Icon(Icons.power_settings_new), label: PrimeText(busy ? 'Conectando…' : 'Ficar online'))),
        OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: ink, padding: const EdgeInsets.all(18), side: const BorderSide(color: Color(0xFFBDCFD8)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportPage())), icon: const Icon(Icons.headset_mic_outlined), label: const PrimeText('Falar com suporte')),
      ]))))),
    ),
  );
}
