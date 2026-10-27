import 'courier_review_success.dart';
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
    final outstanding = (state.courierProfile['requirements'] as List? ?? []).whereType<Map>().where((r) => r['canceledAt'] == null && r['status'] != 'RESOLVED').toList();
    final waiting = outstanding.isNotEmpty && outstanding.every((r) => r['status'] == 'ANSWERED');
    final requirements = (state.courierProfile['requirements'] as List? ?? [])
        .whereType<Map>().where((r) => r['status'] != 'RESOLVED' && r['canceledAt'] == null).toList();
    if (waiting && !blocked && !suspended) return CourierReviewSuccess(requirements: outstanding);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FB),
      appBar: AppBar(
        title: const PrimeText('Minha conta',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF0B3540))),
        backgroundColor: Colors.white, surfaceTintColor: Colors.white,
        actions: [IconButton(tooltip: 'Sair da conta', onPressed: state.logout,
          icon: const Icon(Icons.logout_rounded, color: Color(0xFF123B45)))],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshCourier,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 17, 18, 35),
          children: [Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 590),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                clipBehavior: Clip.antiAlias,
                constraints: const BoxConstraints(minHeight: 183),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  image: const DecorationImage(
                    image: AssetImage('assets/reference_home/coast-banner.webp'), fit: BoxFit.cover)),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight,
                      colors: [Color(0xF3F0FAF7), Color(0xDEE6F6F2), Color(0x57E6F4F4)])),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                      const PrimeText('PORTO PRIME  /  DOCUMENTAÇÃO',
                        style: TextStyle(color: Color(0xFF097768), fontSize: 11,
                          fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 13),
                      PrimeText(blocked ? 'Sua conta está bloqueada' :
                        suspended ? 'Sua conta está suspensa' : 'Seu cadastro está em análise',
                        style: const TextStyle(fontSize: 25, height: 1.17,
                          color: Color(0xFF083B44), fontWeight: FontWeight.w900)),
                      const SizedBox(height: 9),
                      const PrimeText('Acompanhe as solicitações e as atualizações da equipe por aqui.',
                        style: TextStyle(fontSize: 12, height: 1.55, color: Color(0xFF426E76))),
                    ]),
                ),
              ),
              const SizedBox(height: 17),
              if (state.courierProfile['restrictionReason'] != null) ...[
                Container(padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFFFF4E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF9E1C6))),
                  child: PrimeText(state.courierProfile['restrictionReason'].toString())),
                const SizedBox(height: 14),
              ],
              if (requirements.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFFFF1DD),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFFFDEB3))),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, size: 23, color: Color(0xFFCF840D)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      PrimeText(requirements.any((r) => r['status'] == 'OPEN')
                        ? 'Nova pendência solicitada' : 'Documentação em análise',
                        style: const TextStyle(color: Color(0xFF985C0C),
                          fontWeight: FontWeight.w850, fontSize: 13)),
                      const SizedBox(height: 4),
                      const PrimeText('Confira abaixo o que a equipe precisa que você envie.',
                        style: TextStyle(color: Color(0xFF95734B), fontSize: 11, height: 1.45)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 14),
              ],
              if (requirements.isEmpty)
                Container(padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE0EAEF))),
                  child: const PrimeText('Nenhuma documentação adicional foi solicitada no momento.')),
              for (final requirement in requirements)
                _RequirementCard(key: ValueKey(requirement['id']),
                  requirement: requirement, canReply: !blocked && !suspended),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SupportPage())),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: const Color(0xFF0A444B),
                  side: const BorderSide(color: Color(0xFFBBD1D9)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                icon: const Icon(Icons.headset_mic_outlined),
                label: const PrimeText('Falar com o suporte',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              Center(child: TextButton.icon(
                onPressed: () async {
                  try { await state.refreshCourier(); }
                  catch (_) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: PrimeText('Não foi possível atualizar. Tente novamente.')));
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const PrimeText('Atualizar situação',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              )),
            ]),
          ))],
        ),
      ),
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
  bool sent = false;
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
      FocusScope.of(context).unfocus();
      answer.clear();
      setState(() { photo = null; sent = true; });
      // A successful submission stays confirmed even if the follow-up refresh fails.
      try { await AppState.instance.refreshCourierAccount(); } catch (_) {}
    } catch (e) { if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PrimeText(widget.requirement['title']?.toString() ?? 'Exigência', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8), PrimeText(widget.requirement['description']?.toString() ?? ''),
      if (sent || widget.requirement['status'] == 'ANSWERED') ...[
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
          color: const Color(0xFFEAF6F0), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCEE5DA))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.check_circle_rounded, size: 36, color: Color(0xFF127765)),
            SizedBox(height: 12),
            PrimeText('Pronto! Agora é só aguardar.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF073E43))),
            SizedBox(height: 8),
            PrimeText('Sua resposta foi enviada para análise. Avisaremos por aqui quando houver uma atualização.'),
          ])),
      ],
      if (widget.canReply && !sent && widget.requirement['status'] != 'ANSWERED') ...[
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
