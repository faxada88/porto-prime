import '../../../../core/localization/prime_localization.dart';
import 'dart:convert';
import '../../../support/presentation/pages/support_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/state/app_state.dart';

/// Restricted accounts retain their authenticated identity and recovery channel.
class CourierAccountStatus extends StatelessWidget {
  const CourierAccountStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final status = state.user?['status']?.toString() ?? 'PENDING';
    final blocked = status == 'BLOCKED' || state.courierProfile['approvalStatus'] == 'REJECTED';
    final suspended = status == 'SUSPENDED' || state.courierProfile['approvalStatus'] == 'SUSPENDED';
    final title = blocked ? 'Conta bloqueada' : suspended ? 'Conta suspensa' : 'Vamos regularizar sua conta';
    final requirements = (state.courierProfile['requirements'] as List? ?? [])
        .whereType<Map>().where((r) => r['status'] != 'RESOLVED' && r['canceledAt'] == null).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      appBar: AppBar(title: const PrimeText('Minha conta'), actions: [
        IconButton(tooltip: 'Sair da conta', onPressed: state.logout, icon: const Icon(Icons.logout)),
      ]),
      body: RefreshIndicator(onRefresh: state.refreshCourier, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(24),
        children: [Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(blocked ? Icons.lock_outline : suspended ? Icons.pause_circle_outline : Icons.assignment_outlined,
              size: 48, color: const Color(0xFF073E43)),
            const SizedBox(height: 20),
            PrimeText(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            PrimeText(blocked || suspended
              ? 'Novas entregas estão indisponíveis. Consulte as orientações abaixo. O acesso será atualizado após a revisão administrativa.'
              : 'Confira o que falta e envie sua resposta por aqui. Você não precisa informar seu CPF novamente.',
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (state.courierProfile['restrictionReason'] != null) Card(child: Padding(padding: const EdgeInsets.all(20), child: PrimeText(state.courierProfile['restrictionReason'].toString()))),
            if (requirements.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20),
              child: PrimeText('Aguardando análise administrativa. Nenhuma exigência adicional foi registrada.'))),
            for (final requirement in requirements) _RequirementCard(
              key: ValueKey(requirement['id']), requirement: requirement, canReply: !blocked && !suspended),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportPage())), icon: const Icon(Icons.support_agent), label: const PrimeText('Falar com o suporte')),
            OutlinedButton.icon(onPressed: () async {
              try { await state.refreshCourier(); } catch (_) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: PrimeText('Não foi possível atualizar. Tente novamente.')));
              }
            }, icon: const Icon(Icons.refresh), label: const PrimeText('Atualizar situação')),
          ],
        )))],
      )),
    );
  }
}

class _RequirementCard extends StatefulWidget {
  const _RequirementCard({super.key, required this.requirement, required this.canReply});
  final Map requirement;
  final bool canReply;
  @override
  State<_RequirementCard> createState() => _RequirementCardState();
}

class _RequirementCardState extends State<_RequirementCard> {
  final answer = TextEditingController();
  String? photo;
  String? error;
  bool busy = false;
  @override
  void dispose() { answer.dispose(); super.dispose(); }

  Future<void> attach() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery,
        maxWidth: 1024, maxHeight: 1024, imageQuality: 55, requestFullMetadata: false);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 60 * 1024) throw Exception('Escolha uma imagem de até 60 KB.');
      final jpeg = bytes.length > 2 && bytes[0] == 255 && bytes[1] == 216;
      final png = bytes.length > 8 && bytes[0] == 137 && bytes[1] == 80;
      if (!jpeg && !png) throw Exception('Escolha uma imagem JPEG ou PNG.');
      if (mounted) setState(() { photo = 'data:image/${jpeg ? 'jpeg' : 'png'};base64,${base64Encode(bytes)}'; error = null; });
    } catch (e) { if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
  }

  Future<void> send() async {
    if (busy) return;
    if (answer.text.trim().isEmpty) { setState(() => error = 'Escreva uma resposta antes de enviar.'); return; }
    setState(() { busy = true; error = null; });
    try {
      await AppState.instance.api.request('POST', '/couriers/requirements/${widget.requirement['id']}/respond',
        body: {'response': answer.text.trim(), if (photo != null) 'documentPhoto': photo});
      if (!mounted) return;
      answer.clear();
      setState(() => photo = null);
      await AppState.instance.refreshCourierAccount();
    } catch (e) { if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PrimeText(widget.requirement['title']?.toString() ?? 'Exigência', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8), PrimeText(widget.requirement['description']?.toString() ?? ''),
      if (widget.requirement['status'] == 'ANSWERED') const Padding(padding: EdgeInsets.symmetric(vertical: 12),
        child: PrimeText('Resposta enviada • aguardando análise')),
      if (widget.canReply) ...[
        const SizedBox(height: 16),
        TextField(controller: answer, enabled: !busy, minLines: 2, maxLines: 6, maxLength: 4000,
          scrollPadding: const EdgeInsets.all(80), decoration: const PrimeInputDecoration(labelText: 'Sua resposta', border: OutlineInputBorder())),
        TextButton.icon(onPressed: busy ? null : attach, icon: const Icon(Icons.attach_file),
          label: PrimeText(photo == null ? 'Anexar imagem do documento' : 'Documento anexado • substituir')),
        if (error != null) PrimeText(error!, style: const TextStyle(color: Colors.red)),
        FilledButton(onPressed: busy ? null : send, child: PrimeText(busy ? 'Enviando…' : 'Enviar para análise')),
      ],
    ])),
  );
}
