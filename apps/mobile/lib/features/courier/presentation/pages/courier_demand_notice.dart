import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';

/// Visual presentation only: bonus and availability still come from AppState.
class CourierDemandNotice extends StatelessWidget {
  const CourierDemandNotice({super.key, required this.online, required this.bonusAmount});
  final bool online;
  final double bonusAmount;

  @override
  Widget build(BuildContext context) {
    final bonus = bonusAmount.toStringAsFixed(2).replaceAll('.', ',');
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [BoxShadow(color: Color(0x26082E39), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(children: [
            Positioned.fill(child: DecoratedBox(decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF082E39), Color(0xFF095F61)]),
            ))),
            Positioned(right: -50, top: -75, child: ExcludeSemantics(child: Container(
              width: 210, height: 210,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x1A8BDED1), width: 30)),
            ))),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(color: const Color(0xFFF5D478), borderRadius: BorderRadius.circular(30)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(AppIcons.energy, color: Color(0xFF163C3B), size: 15),
                      SizedBox(width: 5),
                      Text('ALTA DEMANDA ATIVA', style: TextStyle(color: Color(0xFF163C3B), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .7)),
                    ]),
                  ),
                  const Text('INCENTIVO PORTO PRIME', style: TextStyle(color: Color(0xFFC4E8E1), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                ]),
                const SizedBox(height: 18),
                const Text('Sua próxima entrega\nvale mais.', style: TextStyle(color: Colors.white, fontSize: 26, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -.7)),
                const SizedBox(height: 17),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFF123F46), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF50857C))),
                  child: Wrap(spacing: 16, runSpacing: 7, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text('+R\$ $bonus', style: const TextStyle(color: Color(0xFFFFDF89), fontSize: 34, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -.9)),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text('EXTRA POR ENTREGA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .6)),
                      SizedBox(height: 4),
                      Text('Direto na sua carteira', style: TextStyle(color: Color(0xFFC4E8E1), fontSize: 11)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 13),
                Text(online ? 'Você está online. Confira o bônus nas ofertas enquanto durar a alta demanda.' : 'Fique online quando estiver disponível e aproveite o bônus nas novas ofertas.', style: const TextStyle(color: Color(0xFFD3EBE5), fontSize: 12, height: 1.5)),
                const SizedBox(height: 10),
                const Text('Bônus da oferta aceita garantido até concluir a entrega.', style: TextStyle(color: Color(0xFFB9DCD5), fontSize: 10, height: 1.4)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
