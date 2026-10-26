import 'package:flutter/material.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_icons.dart';

/// Restricted access: the courier can inspect and answer administrative
/// requirements, but cannot enable availability or receive new deliveries.
class CourierAccountReview extends StatelessWidget {
  const CourierAccountReview({super.key});

  static String _statusLabel(String status) {
    switch (status) {
      case 'BLOCKED': return 'Conta bloqueada';
      case 'SUSPENDED': return 'Conta suspensa';
      case 'PENDING': return 'Cadastro em análise';
      default: return 'Regularização necessária';
    }
  }

  static Future<void> _respond(
    BuildContext context,
    String requirementId,
    String title,
    String previousAnswer,
  ) async {
    final controller = TextEditingController(text: previousAnswer);
    var sending = false;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setModalState) => AlertDialog(
            scrollable: true,
            title: Text(title),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Envie sua resposta diretamente à administração. Nenhum CPF adicional é necessário.'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1500,
                  decoration: const InputDecoration(
                    labelText: 'Sua resposta',
                    hintText: 'Descreva a correção ou informação solicitada',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: sending ? null : () async {
                  final answer = controller.text.trim();
                  if (answer.length < 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informe uma resposta com pelo menos 3 caracteres.')),
                    );
                    return;
                  }
                  setModalState(() => sending = true);
                  try {
                    await AppState.instance.respondCourierRequirement(requirementId, answer);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Resposta enviada. Aguarde a análise da administração.')),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
                      );
                    }
                  } finally {
                    if (dialogContext.mounted) setModalState(() => sending = false);
                  }
                },
                child: Text(sending ? 'Enviando...' : 'Enviar resposta'),
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final profile = state.courierProfile;
    final accountStatus = (profile['userStatus'] ?? state.user?['status'] ?? 'PENDING').toString();
    final accountName = (state.user?['name'] ?? 'Motoboy').toString();
    final description = (profile['accountNotice'] ?? 'Sua conta está sob análise da administração.').toString();
    final requirements = (profile['requirements'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final openCount = requirements.where((r) => r['status'] == 'OPEN').length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: state.refreshCourier,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 40),
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(AppIcons.bike, color: Color(0xFF00695C)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PORTO PRIME DELIVERY', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(accountName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sair da conta',
                    onPressed: state.logout,
                    icon: const Icon(AppIcons.logout),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(AppIcons.shield, size: 34, color: Color(0xFFB45309)),
                    const SizedBox(height: 14),
                    Text(_statusLabel(accountStatus), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(description, style: const TextStyle(fontSize: 15, height: 1.5)),
                    const SizedBox(height: 14),
                    const Text('Enquanto a conta estiver em análise, seu perfil permanecerá OFFLINE e você não receberá novas entregas.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(
                    child: Text('Solicitações da administração', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  ),
                  if (openCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(20)),
                      child: Text('$openCount pendente(s)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (requirements.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Text(
                    'Não há solicitações registradas neste momento. Aguarde a decisão administrativa ou entre em contato com o suporte.',
                    style: TextStyle(height: 1.5),
                  ),
                )
              else
                for (final requirement in requirements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReviewRequirementCard(
                      requirement: requirement,
                      onRespond: () => _respond(
                        context,
                        requirement['id'].toString(),
                        requirement['title']?.toString() ?? 'Responder solicitação',
                        requirement['response']?.toString() ?? '',
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await state.refreshCourier();
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
                      );
                    }
                  }
                },
                icon: const Icon(AppIcons.refresh),
                label: const Text('Atualizar situação da conta'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Se você já respondeu, a administração precisa analisar e liberar sua conta. Sua situação será atualizada automaticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRequirementCard extends StatelessWidget {
  const _ReviewRequirementCard({required this.requirement, required this.onRespond});

  final Map<String, dynamic> requirement;
  final VoidCallback onRespond;

  @override
  Widget build(BuildContext context) {
    final status = requirement['status']?.toString() ?? 'OPEN';
    final resolved = status == 'RESOLVED';
    final answered = status == 'ANSWERED';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(requirement['title']?.toString() ?? 'Pendência', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Text(resolved ? 'RESOLVIDA' : answered ? 'EM ANÁLISE' : 'PENDENTE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: resolved ? const Color(0xFF047857) : const Color(0xFFB45309))),
            ],
          ),
          const SizedBox(height: 10),
          Text(requirement['description']?.toString() ?? '', style: const TextStyle(height: 1.5)),
          if ((requirement['response'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Sua resposta:', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(requirement['response'].toString(), style: const TextStyle(height: 1.4)),
          ],
          if (!resolved) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRespond,
                icon: const Icon(AppIcons.edit_note_rounded),
                label: Text(answered ? 'Atualizar resposta' : 'Resolver pendência'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
