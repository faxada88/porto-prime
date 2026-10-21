import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Customer-only presentation. Existing profile handlers own every action.
class CustomerAccountWorkspace extends StatelessWidget {
 const CustomerAccountWorkspace({super.key,required this.name,required this.email,
  required this.onOrders,required this.onAddresses,required this.onWallet,
  required this.onSupport,required this.onCommercial,required this.onLogout});
 final String name,email;
 final VoidCallback onOrders,onAddresses,onWallet,onSupport,onCommercial,onLogout;
 @override Widget build(BuildContext context){
  final displayName=name.trim().isEmpty?'Cliente Porto Prime':name.trim();
  return SafeArea(bottom:false,child:Center(child:ConstrainedBox(
   constraints:const BoxConstraints(maxWidth:640),child:ListView(
    padding:const EdgeInsets.fromLTRB(20,24,20,28),children:[
     const PrimeText('Minha conta',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800,letterSpacing:-.8,color:AppColors.ink)),
     const SizedBox(height:20),
     Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(
      color:AppColors.ocean50,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.stroke)),
      child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Container(width:52,height:52,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),
        child:const Icon(AppIcons.user,color:AppColors.ocean700,size:26)),
       const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        PrimeText(displayName,style:const TextStyle(fontSize:20,height:1.25,fontWeight:FontWeight.w800,color:AppColors.ink)),
        if(email.isNotEmpty)...[const SizedBox(height:6),PrimeText(email,style:const TextStyle(fontSize:12,height:1.5,color:AppColors.muted))],
       ])),
      ])),
     const SizedBox(height:26),
     _section('Pedidos e entregas'),
     _group([
      _entry(AppIcons.receipt_long_rounded,'Meus pedidos','Acompanhe entregas e veja seu histórico',onOrders),
      _entry(AppIcons.location_on_rounded,'Endereços','Adicione, edite ou remova locais de entrega',onAddresses),
     ]),
     const SizedBox(height:24),
     _section('Saldo e benefícios'),
     _group([_entry(AppIcons.wallet,'Cartão Porto Prime','Consulte seu saldo, vouchers e movimentações',onWallet)]),
     const SizedBox(height:24),
     _section('Atendimento'),
     _group([
      _entry(AppIcons.support_agent_rounded,'Ajuda e suporte','Resolva dúvidas e acompanhe atendimentos',onSupport),
      _entry(AppIcons.store,'Parcerias e patrocínios','Fale com nossa equipe comercial',onCommercial),
     ]),
     const SizedBox(height:24),
     TextButton.icon(onPressed:onLogout,icon:const Icon(AppIcons.logout_rounded,size:19),
      label:const PrimeText('Sair da conta'),style:TextButton.styleFrom(foregroundColor:AppColors.muted,minimumSize:const Size(48,52))),
    ]))));
 }
 Widget _section(String title)=>Padding(padding:const EdgeInsets.only(left:4,bottom:10),child:PrimeText(title,
  style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:AppColors.inkSoft)));
 Widget _group(List<Widget> entries)=>Material(color:AppColors.surface,
  shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22),side:const BorderSide(color:AppColors.stroke)),
  clipBehavior:Clip.antiAlias,child:Column(children:[for(var i=0;i<entries.length;i++)...[
   if(i>0)const Divider(height:1,indent:68,endIndent:18,color:AppColors.stroke),entries[i],
  ]]));
 Widget _entry(IconData icon,String title,String subtitle,VoidCallback onTap)=>InkWell(
  onTap:onTap,child:Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:19),
   child:Row(children:[
    Container(width:38,height:42,decoration:BoxDecoration(color:AppColors.surfaceMuted,borderRadius:BorderRadius.circular(13)),
     child:Icon(icon,size:21,color:AppColors.ocean700)),
    const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     PrimeText(title,style:const TextStyle(fontSize:15,height:1.3,fontWeight:FontWeight.w700,color:AppColors.ink)),
     const SizedBox(height:4),PrimeText(subtitle,style:const TextStyle(fontSize:12,height:1.5,color:AppColors.muted)),
    ])),const SizedBox(width:10),const Icon(Icons.chevron_right_rounded,size:19,color:AppColors.subtle),
   ])));
}
