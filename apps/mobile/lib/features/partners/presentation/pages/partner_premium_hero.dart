import '../../../../core/localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/prime_brand.dart';
class PartnerPremiumHero extends StatelessWidget {
 const PartnerPremiumHero({super.key,required this.name,required this.businessName,required this.balance,required this.onWallet,required this.onShare});
 final String name,businessName,balance;final VoidCallback onWallet,onShare;
 @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  ClipRRect(borderRadius:BorderRadius.circular(AppRadius.xl),child:ColoredBox(color:AppColors.ocean900,child:Stack(children:[const Positioned.fill(child:PrimeCoastArtwork()),Padding(padding:const EdgeInsets.all(26),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Row(children:[PrimeBrandMark(size:34),SizedBox(width:12),Expanded(child:PrimeText('REDE PORTO PRIME',style:TextStyle(color:Colors.white70,fontSize:10,letterSpacing:1.3,fontWeight:FontWeight.w800)))]),const SizedBox(height:24),PrimeText('Olá, $name.',style:const TextStyle(color:Colors.white,fontSize:32,fontWeight:FontWeight.w800,letterSpacing:-.8)),const SizedBox(height:8),PrimeText(businessName,style:const TextStyle(color:Color(0xFFD4EAE3),fontSize:13,height:1.6)),const SizedBox(height:22),OutlinedButton.icon(style:OutlinedButton.styleFrom(backgroundColor:Colors.white.withValues(alpha:.1),foregroundColor:Colors.white,side:const BorderSide(color:Colors.white24)),onPressed:onShare,icon:const Icon(AppIcons.share,size:17),label:const PrimeText('Meu link e QR de indicação'))]))]))),
  const SizedBox(height:12),Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(AppRadius.lg),border:Border.all(color:AppColors.stroke)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const PrimeText('SALDO DISPONÍVEL',style:TextStyle(color:AppColors.muted,fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1.2)),const SizedBox(height:8),FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:PrimeText(balance,style:const TextStyle(color:AppColors.ocean900,fontSize:32,fontWeight:FontWeight.w800,letterSpacing:-1))),const SizedBox(height:14),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:onWallet,icon:const Icon(AppIcons.wallet,size:18),label:const PrimeText('Carteira e saques')))])),
 ]);
}
