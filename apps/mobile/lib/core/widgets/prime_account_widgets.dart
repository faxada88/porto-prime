import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Account presentation only. Authentication and routing stay with ProfilePage.
class PrimeAccountWelcome extends StatelessWidget {
  const PrimeAccountWelcome({super.key, required this.onLogin, required this.onCreate});
  final VoidCallback onLogin, onCreate;

  @override
  Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(24),
    decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(28),
      border:Border.all(color:AppColors.strokeStrong,width:1.4)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Row(children:[
        Container(width:46,height:46,decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(16)),
          child:const Icon(AppIcons.user,size:24,color:AppColors.ink)),
        const SizedBox(width:12),const Expanded(child:PrimeText('PORTO PRIME',style:TextStyle(fontSize:11,letterSpacing:1.4,fontWeight:FontWeight.w800,color:AppColors.inkSoft))),
      ]),
      const SizedBox(height:24),
      const PrimeText('Seu próximo pedido\ncomeça com você.',style:TextStyle(fontSize:30,height:1.14,letterSpacing:-1,fontWeight:FontWeight.w800,color:AppColors.ink)),
      const SizedBox(height:12),
      const PrimeText('Crie sua conta para pedir, acompanhar a entrega e usar seu saldo Porto Prime.',
        style:TextStyle(fontSize:14,height:1.65,color:AppColors.inkSoft)),
      const SizedBox(height:22),
      Wrap(spacing:14,runSpacing:12,children:[
        _benefit(AppIcons.receipt_long_rounded,'Seus pedidos'),
        _benefit(AppIcons.location_on_rounded,'Seus endereços'),
        _benefit(AppIcons.wallet,'Seu saldo'),
      ]),
      const SizedBox(height:26),
      FilledButton(onPressed:onCreate,style:FilledButton.styleFrom(
        backgroundColor:AppColors.ink,foregroundColor:Colors.white,
        padding:const EdgeInsets.symmetric(horizontal:18,vertical:18),
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),
        child:const Row(children:[Expanded(child:PrimeText('Criar minha conta',textAlign:TextAlign.center,style:TextStyle(fontSize:14,fontWeight:FontWeight.w800))),SizedBox(width:10),Icon(AppIcons.arrowRight,size:19)])),
      const SizedBox(height:12),
      OutlinedButton(onPressed:onLogin,style:OutlinedButton.styleFrom(
        foregroundColor:AppColors.ink,side:const BorderSide(color:AppColors.inkSoft,width:1.3),
        padding:const EdgeInsets.symmetric(horizontal:18,vertical:18),
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),
        child:const PrimeText('Entrar na minha conta',textAlign:TextAlign.center,style:TextStyle(fontSize:14,fontWeight:FontWeight.w700))),
      const SizedBox(height:18),
      const Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(AppIcons.lock,size:14,color:AppColors.inkSoft),SizedBox(width:7),
        Flexible(child:PrimeText('Uma conta. Tudo organizado.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,height:1.5,color:AppColors.inkSoft)))]),
    ]),
  );
  Widget _benefit(IconData icon,String label)=>Row(mainAxisSize:MainAxisSize.min,children:[
    Icon(icon,size:17,color:AppColors.ocean700),const SizedBox(width:6),
    PrimeText(label,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:AppColors.inkSoft)),
  ]);
}

class PrimeAccountActionTile extends StatelessWidget {
  const PrimeAccountActionTile({super.key, required this.icon, required this.title,
    required this.subtitle, required this.onTap, this.highlighted = false});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Material(
    color: highlighted ? AppColors.sand50 : Colors.transparent,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(17),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: highlighted ? AppColors.sun200 : AppColors.ocean50,
            borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: AppColors.ocean900, size: 21)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PrimeText(title, style: const TextStyle(fontSize: 14, height: 1.3,
            fontWeight: FontWeight.w800, letterSpacing: -.2, color: AppColors.ocean900)),
          const SizedBox(height: 5),
          PrimeText(subtitle, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted)),
        ])),
        const SizedBox(width: 10),
        const Padding(padding: EdgeInsets.only(top: 12),
          child: Icon(AppIcons.chevronRight, size: 17, color: AppColors.ocean700)),
      ]))),
  );
}

class PrimeAccountIdentity extends StatelessWidget {
  const PrimeAccountIdentity({super.key, required this.name, required this.email,
    required this.roleLabel});
  final String name, email, roleLabel;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.ocean900,
      borderRadius: BorderRadius.circular(28), boxShadow: AppShadows.soft),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 14, runSpacing: 14, crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(width: 58, height: 58, alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.sun500,
              borderRadius: BorderRadius.circular(20)),
            child: Padding(padding: const EdgeInsets.all(8), child: FittedBox(fit: BoxFit.scaleDown,
              child: PrimeText(name.isEmpty ? 'P' : name.substring(0,1).toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ocean900))))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: AppColors.ocean800, borderRadius: BorderRadius.circular(30)),
            child: PrimeText(roleLabel, style: const TextStyle(color: AppColors.ocean100,
              fontSize: 10, height: 1.4, fontWeight: FontWeight.w800, letterSpacing: 1))),
        ]),
      const SizedBox(height: 22),
      PrimeText(name, style: const TextStyle(fontSize: 25, height: 1.2,
        fontWeight: FontWeight.w800, letterSpacing: -.6, color: Colors.white)),
      const SizedBox(height: 7),
      PrimeText(email, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.ocean100)),
      const SizedBox(height: 20),
      const Divider(color: AppColors.ocean800, height: 1),
      const SizedBox(height: 14),
      const PrimeText('Sua conta Porto Prime', style: TextStyle(fontSize: 11,
        height: 1.5, color: AppColors.ocean300, fontWeight: FontWeight.w600)),
    ]),
  );
}
