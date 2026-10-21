import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'prime_brand.dart';

class PrimeRegistrationChoiceIntro extends StatelessWidget {
  const PrimeRegistrationChoiceIntro({super.key, required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Expanded(child:Text('Vamos começar',style:TextStyle(fontSize:27,height:1.2,fontWeight:FontWeight.w800,letterSpacing:-.7,color:AppColors.ink))),
      IconButton(tooltip:'Fechar',onPressed:onClose,icon:const Icon(AppIcons.close,size:21,color:AppColors.ink))]),
    const SizedBox(height:10),
    const Text('Escolha como você quer usar a Porto Prime.',style:TextStyle(fontSize:14,height:1.6,color:AppColors.inkSoft)),
  ]);
}

class PrimeRegistrationRoleCard extends StatelessWidget {
  const PrimeRegistrationRoleCard({super.key, required this.title,
    required this.subtitle, required this.icon, required this.background,
    required this.onTap});
  final String title, subtitle;
  final IconData icon;
  final Color background;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(color: AppColors.surface,
    borderRadius: BorderRadius.circular(22), clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Container(
      padding: const EdgeInsets.all(18), decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.strokeStrong,width:1.3)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: background,
          borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, size: 24, color: AppColors.ocean900)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, height: 1.25,
            fontWeight: FontWeight.w800, letterSpacing: -.4, color: AppColors.ocean900)),
          const SizedBox(height: 7),
          Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted)),
          const SizedBox(height: 12),
          const Text('Começar cadastro', style: TextStyle(fontSize: 11,
            height: 1.5, fontWeight: FontWeight.w800, color: AppColors.ocean700)),
        ])),
        const SizedBox(width: 8),
        const Padding(padding: EdgeInsets.only(top: 3),
          child: Icon(AppIcons.arrowUpRight, size: 19, color: AppColors.ocean700)),
      ])),
    ));
}

class PrimeRegistrationHeader extends StatelessWidget {
  const PrimeRegistrationHeader({super.key, required this.roleLabel,
    required this.step, required this.total, required this.onBack});
  final String roleLabel;
  final int step, total;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 760),
    child: Padding(padding: const EdgeInsets.fromLTRB(12, 10, 20, 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          IconButton(tooltip: step == 0 ? 'Fechar cadastro' : 'Voltar etapa',
            onPressed: onBack, icon: Icon(step == 0 ? AppIcons.close : AppIcons.arrowLeft,
              color: AppColors.ocean900, size: 22)),
          const SizedBox(width: 6),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Conta de $roleLabel', style: const TextStyle(fontSize: 16, height: 1.3,
              fontWeight: FontWeight.w800, color: AppColors.ocean900)),
            const SizedBox(height: 3),
            Text('Etapa ${step + 1} de $total', style: const TextStyle(
              fontSize: 11, height: 1.4, color: AppColors.muted)),
          ])),
          const SizedBox(width: 12), const PrimeBrandMark(size: 34),
        ]),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.only(left: 12),
          child: Semantics(label: 'Progresso do cadastro', value: '${step + 1} de $total',
            child: LinearProgressIndicator(value: (step + 1) / total,
              minHeight: 4, borderRadius: BorderRadius.circular(8),
              color: AppColors.ocean700, backgroundColor: AppColors.stroke))),
      ])),
  ));
}

class PrimeRegistrationContinue extends StatelessWidget {
  const PrimeRegistrationContinue({super.key, required this.label,
    required this.loading, required this.onContinue});
  final String label;
  final bool loading;
  final VoidCallback? onContinue;
  @override
  Widget build(BuildContext context) => ColoredBox(color: AppColors.surface,
    child: SafeArea(top: false, child: Center(heightFactor: 1,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(padding: const EdgeInsets.fromLTRB(20,12,20,16),
          child: SizedBox(width: double.infinity, child: FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(backgroundColor: AppColors.ocean900,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(child: Text(loading ? 'Aguarde…' : label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
              const SizedBox(width: 12),
              if (loading) const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              else const Icon(AppIcons.arrowRight, size: 20),
            ])),
          )),
      )),
    ));
}
