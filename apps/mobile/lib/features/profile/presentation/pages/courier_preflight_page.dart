import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

class CourierPreflightPage extends StatefulWidget {
  const CourierPreflightPage({
    super.key,
    required this.onClose,
    required this.onReady,
  });

  final VoidCallback onClose;
  final VoidCallback onReady;

  @override
  State<CourierPreflightPage> createState() => _CourierPreflightPageState();
}

class _CourierPreflightPageState extends State<CourierPreflightPage> {
  static const _pfUrl =
      'https://www.gov.br/pf/pt-br/assuntos/antecedentes-criminais';

  static const _items = <({String title, String detail, IconData icon})>[
    (
      title: 'CPF em mãos',
      detail: 'Você vai informar e validar o CPF logo na primeira etapa.',
      icon: AppIcons.badge_outlined,
    ),
    (
      title: 'CNH válida',
      detail: 'Tenha número, categoria e validade da habilitação.',
      icon: AppIcons.credit_card_outlined,
    ),
    (
      title: 'Dados do veículo',
      detail: 'Marca, modelo, ano e placa usados nas entregas.',
      icon: AppIcons.two_wheeler_outlined,
    ),
    (
      title: 'Certidão de antecedentes em PDF',
      detail:
          'Emita a certidão oficial da Polícia Federal. Ela é gratuita e tem validade de 90 dias.',
      icon: AppIcons.shield_outlined,
    ),
    (
      title: 'Celular, WhatsApp e e-mail disponíveis',
      detail:
          'Você receberá avisos sobre análise, pendências e aprovação do cadastro.',
      icon: AppIcons.phone_outlined,
    ),
  ];

  final Set<int> _checked = <int>{};

  bool get _ready => _checked.length == _items.length;

  Future<void> _openFederalCertificate() async {
    final uri = Uri.parse(_pfUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o site da Polícia Federal agora.',
          ),
        ),
      );
    }
  }

  Future<void> _sendChecklistToWhatsApp() async {
    const text = '''PORTO PRIME • Checklist para cadastro de motoboy

Antes de começar, deixe separado:
✅ CPF
✅ CNH válida
✅ Dados do veículo (marca, modelo, ano e placa)
✅ Certidão de antecedentes criminais da Polícia Federal em PDF
✅ Celular/WhatsApp e e-mail com acesso

Certidão oficial:
https://www.gov.br/pf/pt-br/assuntos/antecedentes-criminais

Quando estiver com tudo em mãos, volte ao Porto Prime e continue seu cadastro.''';

    final uri = Uri.parse(
      'https://wa.me/?text=\${Uri.encodeComponent(text)}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o WhatsApp agora.'),
        ),
      );
    }
  }

  void _toggle(int index) {
    setState(() {
      if (!_checked.add(index)) {
        _checked.remove(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFB77818);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.stroke),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: widget.onClose,
                      icon: const Icon(AppIcons.close_rounded),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        AppIcons.two_wheeler_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cadastro de motoboy',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.25,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'PREPARAÇÃO • ANTES DO CPF',
                            style: TextStyle(
                              fontSize: 8.5,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .75,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.sand, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: accent.withValues(alpha: .15),
                        ),
                      ),
                      child: const Icon(
                        AppIcons.fact_check_rounded,
                        color: accent,
                        size: 29,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Prepare tudo.\nCadastre uma vez.',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.02,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Para o cadastro não parar no meio, confirme o que você já tem em mãos. Se faltar algo, salve este checklist no WhatsApp e volte quando estiver pronto.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.55,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.stroke),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                        children: List.generate(_items.length, (index) {
                          final item = _items[index];
                          final selected = _checked.contains(index);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _items.length - 1 ? 0 : 10,
                            ),
                            child: Material(
                              color: selected
                                  ? AppColors.mint
                                  : AppColors.canvas,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              child: InkWell(
                                onTap: () => _toggle(index),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.mintStrong
                                          : AppColors.stroke,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? Colors.white
                                              : AppColors.sand,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.sm,
                                          ),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          color: selected
                                              ? AppColors.oceanDeep
                                              : accent,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.detail,
                                              style: const TextStyle(
                                                fontSize: 9.8,
                                                height: 1.42,
                                                color: AppColors.muted,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        width: 27,
                                        height: 27,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AppColors.oceanDeep
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: selected
                                                ? AppColors.oceanDeep
                                                : AppColors.stroke,
                                          ),
                                        ),
                                        child: selected
                                            ? const Icon(
                                                AppIcons.check_rounded,
                                                size: 17,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                AppIcons.shield_rounded,
                                color: accent,
                                size: 21,
                              ),
                              SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Ainda não tem a certidão?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Você pode emitir gratuitamente pela Polícia Federal, baixar o PDF e depois voltar para continuar.',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.45,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openFederalCertificate,
                              icon: const Icon(
                                AppIcons.externalLink,
                                size: 17,
                              ),
                              label: const Text(
                                'Emitir certidão oficial',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _sendChecklistToWhatsApp,
                              icon: const Icon(AppIcons.phone, size: 17),
                              label: const Text(
                                'Enviar checklist no WhatsApp',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          AppIcons.info_outline_rounded,
                          color: AppColors.muted,
                          size: 17,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Marcar a caixa significa apenas que o documento está com você. A análise do cadastro continua sendo feita pela equipe Porto Prime.',
                            style: TextStyle(
                              fontSize: 9.5,
                              height: 1.45,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: _ready ? widget.onReady : null,
                    icon: Icon(
                      _ready
                          ? AppIcons.arrow_forward_rounded
                          : AppIcons.fact_check_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _ready
                          ? 'Tenho tudo. Começar cadastro'
                          : '\${_checked.length} de \${_items.length} itens prontos',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
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
