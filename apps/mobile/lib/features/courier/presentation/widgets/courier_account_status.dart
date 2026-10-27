import 'courier_review_success.dart';
import '../../../../core/localization/prime_localization.dart';
import 'dart:async';
import 'dart:convert';
import '../../../support/presentation/pages/support_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/state/app_state.dart';

String _courierRequestDate(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return 'Solicitação recente';
  final local = parsed.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return two(local.day) + '/' + two(local.month) + '/' +
      local.year.toString() + ', ' + two(local.hour) + ':' + two(local.minute);
}

/// Restricted accounts retain their authenticated identity and recovery channel.
class CourierAccountStatus extends StatefulWidget {
  const CourierAccountStatus({super.key});

  @override
  State<CourierAccountStatus> createState() => _CourierAccountStatusState();
}

class _CourierAccountStatusState extends State<CourierAccountStatus> {
  Timer? _accountRefresh;
  bool _refreshingAccount = false;

  Future<void> _checkRequirements() async {
    if (!mounted || _refreshingAccount || !AppState.instance.isCourier) return;
    _refreshingAccount = true;
    try {
      await AppState.instance.refreshCourierAccount();
    } catch (_) {
      // The next poll recovers after an offline or temporarily failing API.
    } finally {
      _refreshingAccount = false;
    }
  }

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_showLatestRequirements);
    // The socket updates instantly; a single in-flight polling request
    // recovers missed events without racing itself on a slow connection.
    unawaited(_checkRequirements());
    _accountRefresh = Timer.periodic(
      const Duration(seconds: 6), (_) => unawaited(_checkRequirements()));
  }

  void _showLatestRequirements() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _accountRefresh?.cancel();
    AppState.instance.removeListener(_showLatestRequirements);
    super.dispose();
  }

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


    final actionable = requirements.any((r) => r['status'] == 'OPEN');
    requirements.sort((a, b) {
      final aTime = DateTime.tryParse(a['requestedAt']?.toString() ?? '');
      final bTime = DateTime.tryParse(b['requestedAt']?.toString() ?? '');
      return (bTime ?? DateTime(1970)).compareTo(aTime ?? DateTime(1970));
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D252D),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Row(children: [
          Icon(Icons.workspace_premium_outlined, color: Color(0xFF063A41), size: 24),
          SizedBox(width: 8),
          PrimeText('PORTO PRIME',
            style: TextStyle(color: Color(0xFF063A41), fontSize: 14,
              fontWeight: FontWeight.w900, letterSpacing: .4)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: state.logout,
            icon: const Icon(Icons.logout_outlined, color: Color(0xFF0B4149)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshCourier,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 190),
              padding: const EdgeInsets.fromLTRB(20, 23, 20, 27),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD9F5F3), Color(0xFFBCE9EF), Color(0xFFF5E6B8)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PrimeText('DOCUMENTAÇÃO',
                    style: TextStyle(color: Color(0xFF008A76), fontSize: 11,
                      fontWeight: FontWeight.w900, letterSpacing: 1.3)),
                  const SizedBox(height: 17),
                  PrimeText(
                    blocked ? 'Sua conta está bloqueada' :
                    suspended ? 'Sua conta está suspensa' :
                    'Seu cadastro está em análise',
                    style: const TextStyle(color: Color(0xFF073B42),
                      fontSize: 27, height: 1.13, fontWeight: FontWeight.w900,
                      letterSpacing: -.65),
                  ),
                  const SizedBox(height: 15),
                  const PrimeText('Acompanhe as solicitações da equipe por aqui.',
                    style: TextStyle(color: Color(0xFF416F79),
                      fontSize: 12, height: 1.55)),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 17, 13, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.courierProfile['restrictionReason'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF8D7B3)),
                          ),
                          child: PrimeText(
                            state.courierProfile['restrictionReason'].toString(),
                            style: const TextStyle(color: Color(0xFF8A5727),
                              fontSize: 12, height: 1.5),
                          ),
                        ),
                      ],
                      if (requirements.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(21),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(children: [
                            const Icon(Icons.hourglass_top_rounded,
                              size: 32, color: Color(0xFF087E70)),
                            const SizedBox(height: 12),
                            const PrimeText('Sua candidatura está em análise.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w800, color: Color(0xFF103B45))),
                            const SizedBox(height: 8),
                            const PrimeText('Nenhuma documentação adicional foi solicitada.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF69838D))),
                            const SizedBox(height: 17),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SupportPage())),
                              icon: const Icon(Icons.headset_mic_outlined, size: 18),
                              label: const PrimeText('Falar com o suporte'),
                            ),
                          ]),
                        ),
                      for (final requirement in requirements)
                        _RequirementCard(
                          key: ValueKey(requirement['id']),
                          requirement: requirement,
                          canReply: !blocked && !suspended,
                        ),
                      if (requirements.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(actionable ? Icons.sync_rounded : Icons.check_circle_outline,
                              color: const Color(0xFFB2D4D3), size: 15),
                            const SizedBox(width: 7),
                            const Flexible(child: PrimeText(
                              'Atualizações automáticas quando houver conexão',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFFB2D4D3),
                                fontSize: 10, height: 1.4))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
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
  bool editing = false;
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
  Widget build(BuildContext context) {
    final status = widget.requirement['status']?.toString() ?? 'OPEN';
    final isAnswered = sent || status == 'ANSWERED';
    final open = status == 'OPEN';
    final when = _courierRequestDate(widget.requirement['requestedAt']);

    const ink = Color(0xFF12384B);
    const teal = Color(0xFF093F45);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF4DBB4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
          color: const Color(0xFFFFF4E6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded,
                size: 22, color: Color(0xFFC1790D)),
              const SizedBox(width: 10),
              Expanded(child: PrimeText(
                isAnswered ? 'Resposta enviada para análise' :
                  open ? 'Nova pendência solicitada' : 'Solicitação em acompanhamento',
                style: const TextStyle(color: Color(0xFFA36611),
                  fontSize: 13, fontWeight: FontWeight.w800))),
            ]),
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 7),
              child: PrimeText(when,
                style: const TextStyle(fontSize: 10, color: Color(0xFFA5937B))),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 17, 15, 17),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PrimeText(widget.requirement['title']?.toString() ?? 'Documentação solicitada',
              style: const TextStyle(color: ink, fontSize: 15,
                height: 1.35, fontWeight: FontWeight.w800)),
            const SizedBox(height: 13),
            PrimeText(widget.requirement['description']?.toString() ?? '',
              style: const TextStyle(color: Color(0xFF68849A),
                fontSize: 12, height: 1.55)),
            if (isAnswered) ...[
              const SizedBox(height: 17),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EF),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFD1EADC)),
                ),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.check_circle_rounded, size: 22,
                    color: Color(0xFF10836D)),
                  SizedBox(width: 10),
                  Expanded(child: PrimeText(
                    'Resposta recebida! A equipe está conferindo o documento.',
                    style: TextStyle(color: Color(0xFF176F61),
                      fontSize: 12, height: 1.5, fontWeight: FontWeight.w700))),
                ]),
              ),
            ],
            if (open && widget.canReply && !isAnswered) ...[
              const SizedBox(height: 17),
              if (!editing)
                FilledButton.icon(
                  onPressed: () => setState(() { editing = true; error = null; }),
                  style: FilledButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const PrimeText('Enviar documento',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              if (editing) ...[
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCE8EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PrimeText('Envie sua resposta',
                        style: TextStyle(color: ink,
                          fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const PrimeText('Explique a correção e anexe uma foto, se solicitada.',
                        style: TextStyle(color: Color(0xFF718B9A),
                          fontSize: 11, height: 1.5)),
                      const SizedBox(height: 13),
                      TextField(
                        controller: answer,
                        enabled: !busy,
                        minLines: 2,
                        maxLines: 5,
                        maxLength: 4000,
                        scrollPadding: const EdgeInsets.all(110),
                        decoration: InputDecoration(
                          labelText: 'Sua resposta',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFD4E3E8))),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF087E70))),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy ? null : attach,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: teal,
                          side: const BorderSide(color: Color(0xFFBFD6D7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9)),
                        ),
                        icon: const Icon(Icons.attach_file_rounded, size: 18),
                        label: PrimeText(photo == null ?
                          'Anexar foto do documento' : 'Trocar foto anexada',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                      if (photo != null) ...[
                        const SizedBox(height: 9),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.memory(
                            base64Decode(photo!.split(',').last),
                            height: 145,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        PrimeText(error!, style: const TextStyle(
                          color: Color(0xFFB83F36), fontSize: 11, height: 1.4)),
                      ],
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: busy ? null : send,
                        style: FilledButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9)),
                        ),
                        icon: busy ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2,
                            color: Colors.white)) :
                          const Icon(Icons.send_rounded, size: 17),
                        label: PrimeText(busy ? 'Enviando…' : 'Enviar para análise',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => setState(() => editing = false),
                        child: const PrimeText('Voltar',
                          style: TextStyle(color: Color(0xFF5A7785), fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
              if (!editing && error != null) ...[
                const SizedBox(height: 9),
                PrimeText(error!, style: const TextStyle(
                  color: Color(0xFFB83F36), fontSize: 11)),
              ],
            ],
            if (!widget.canReply && open) ...[
              const SizedBox(height: 13),
              const PrimeText(
                'O envio de documentos está indisponível para este status. Fale com o suporte.',
                style: TextStyle(color: Color(0xFF96601D), fontSize: 11, height: 1.5)),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SupportPage())),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B505C),
                backgroundColor: const Color(0xFFF7FAFA),
                side: const BorderSide(color: Color(0xFFB8D1D6)),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              ),
              icon: const Icon(Icons.headset_mic_outlined, size: 18),
              label: const PrimeText('Falar com o suporte',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ]),
        ),
      ]),
    );
  }

}
