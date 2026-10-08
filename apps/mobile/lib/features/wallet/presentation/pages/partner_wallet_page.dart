import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

class PartnerWalletPage extends StatefulWidget {
  const PartnerWalletPage({super.key});
  @override State<PartnerWalletPage> createState()=>_PartnerWalletPageState();
}
class _PartnerWalletPageState extends State<PartnerWalletPage> {
  Timer? _timer;
  bool _loading=true;
  String? _error;
  int _tab=0;
  String _brl(dynamic value)=>'R\$ ${(double.tryParse(value.toString())??0).toStringAsFixed(2).replaceAll('.',',')}';
  String _status(dynamic value)=>const {'PENDING':'Solicitado','PROCESSING':'Em processamento','PAID':'Pago','REJECTED':'Rejeitado','CANCELED':'Cancelado'}[value]??'Solicitado';
  String _date(dynamic value){final d=DateTime.tryParse(value.toString())?.toLocal();return d==null?'': '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';}
  @override void initState(){super.initState();_refresh();_timer=Timer.periodic(const Duration(seconds:10),(_)=>_refresh());}
  @override void dispose(){_timer?.cancel();super.dispose();}
  Future<void> _refresh()async{try{await AppState.instance.loadWallet();if(mounted)setState(()=>_error=null);}catch(_){if(mounted)setState(()=>_error='Não foi possível atualizar a carteira. Tente novamente.');}finally{if(mounted)setState(()=>_loading=false);}}
  Future<void> _withdraw()async{
    final s=AppState.instance; final amount=TextEditingController(),pix=TextEditingController(text:s.walletSummary['pixKey']?.toString()??'');
    var type=s.walletSummary['pixKeyType']?.toString()??'EMAIL'; if(!['CPF','CNPJ','EMAIL','PHONE','RANDOM'].contains(type))type='EMAIL';
    final key=GlobalKey<FormState>();final requestId=s.newFinanceRequestId();bool busy=false;String? error;
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,isDismissible:false,enableDrag:false,backgroundColor:AppColors.surface,
      shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(24))),
      builder:(sheet)=>StatefulBuilder(builder:(sheet,setModal)=>PopScope(canPop:!busy,child:Padding(
        padding:EdgeInsets.fromLTRB(22,24,22,MediaQuery.of(sheet).viewInsets.bottom+24),
        child:SingleChildScrollView(child:Form(key:key,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,mainAxisSize:MainAxisSize.min,children:[
          const Text('Solicitar saque',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),
          const SizedBox(height:8),Text('Saldo disponível: ${_brl(s.walletSummary['availableBalance'])}',style:const TextStyle(color:AppColors.muted)),
          const SizedBox(height:22),TextFormField(controller:amount,enabled:!busy,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Valor (R\$)'),validator:(v){final raw=v?.trim()??'';final number=double.tryParse(raw.replaceAll(',','.'));return !RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(raw)||number==null||number<=0||number>(double.tryParse(s.walletSummary['availableBalance'].toString())??0)?'Informe um valor dentro do saldo disponível':null;}),
          const SizedBox(height:14),DropdownButtonFormField<String>(initialValue:type,decoration:const InputDecoration(labelText:'Tipo de chave PIX'),items:['CPF','CNPJ','EMAIL','PHONE','RANDOM'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:busy?null:(v){if(v!=null)setModal(()=>type=v);}),
          const SizedBox(height:14),TextFormField(controller:pix,enabled:!busy,maxLength:250,decoration:const InputDecoration(labelText:'Chave PIX'),validator:(v)=>(v??'').trim().isEmpty?'Informe sua chave PIX':null),
          const SizedBox(height:12),const Text('O valor fica reservado até a equipe concluir o repasse. Uma rejeição devolve o valor à carteira.',style:TextStyle(color:AppColors.muted,height:1.5,fontSize:12)),
          if(error!=null)Padding(padding:const EdgeInsets.only(top:14),child:Text(error!,style:const TextStyle(color:Color(0xFFA33F32)))),
          const SizedBox(height:20),FilledButton(onPressed:busy?null:()async{if(!key.currentState!.validate())return;setModal((){busy=true;error=null;});try{await s.requestWithdrawal(double.parse(amount.text.replaceAll(',','.')),pixKey:pix.text.trim(),pixKeyType:type,requestId:requestId);if(sheet.mounted)Navigator.pop(sheet);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Saque solicitado. Acompanhe o status na carteira.')));}catch(e){if(sheet.mounted)setModal(()=>error=e.toString().replaceFirst('Exception: ',''));}finally{if(sheet.mounted)setModal(()=>busy=false);}},child:Text(busy?'Solicitando…':'Confirmar solicitação')),
          TextButton(onPressed:busy?null:()=>Navigator.pop(sheet),child:const Text('Cancelar')),
        ]))),
      ))),
    );
    // Controllers stay alive until the route closing animation is complete.
    await Future<void>.delayed(const Duration(milliseconds:350));amount.dispose();pix.dispose();
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Carteira do parceiro')),
    body:AnimatedBuilder(animation:AppState.instance,builder:(_,__){final s=AppState.instance;final entries=_tab==0?s.walletLedger:s.withdrawals;
      return RefreshIndicator(onRefresh:_refresh,child:ListView(padding:const EdgeInsets.fromLTRB(20,18,20,40),children:[
        Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppColors.oceanDeep,AppColors.ocean]),borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('PORTO PRIME · PARCEIRO',style:TextStyle(color:Colors.white70,fontSize:11,fontWeight:FontWeight.w700,letterSpacing:1.3)),const SizedBox(height:20),const Text('Saldo disponível',style:TextStyle(color:Colors.white70)),const SizedBox(height:6),Text(_brl(s.walletSummary['availableBalance']),style:const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.w800)),const SizedBox(height:8),Text('${_brl(s.walletSummary['pendingWithdrawals'])} reservado em saques',style:const TextStyle(color:Colors.white70,fontSize:12)),const SizedBox(height:22),SizedBox(width:double.infinity,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:Colors.white,foregroundColor:AppColors.oceanDeep),onPressed:_loading||(double.tryParse(s.walletSummary['availableBalance'].toString())??0)<=0?null:_withdraw,child:const Text('Solicitar saque'))),
        ])),
        if(_error!=null)Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(_error!,style:const TextStyle(color:Color(0xFFA33F32)))),
        const SizedBox(height:22),Row(children:[Expanded(child:TextButton(onPressed:()=>setState(()=>_tab=0),child:Text('Movimentações',style:TextStyle(fontWeight:_tab==0?FontWeight.w800:FontWeight.w500)))),Expanded(child:TextButton(onPressed:()=>setState(()=>_tab=1),child:Text('Saques',style:TextStyle(fontWeight:_tab==1?FontWeight.w800:FontWeight.w500))))]),
        if(_loading)Container(height:120,margin:const EdgeInsets.only(top:16),decoration:BoxDecoration(color:AppColors.surfaceOcean,borderRadius:BorderRadius.circular(18)))
        else if(entries.isEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:44),child:Column(children:[const Icon(AppIcons.wallet,size:34,color:AppColors.muted),const SizedBox(height:14),Text(_tab==0?'Nenhuma movimentação ainda':'Nenhum saque solicitado',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700)),const SizedBox(height:8),const Text('Sua atividade financeira aparecerá aqui.',style:TextStyle(color:AppColors.muted))]))
        else ...entries.map((e){final amount=double.tryParse(e['amount'].toString())??0;return Container(margin:const EdgeInsets.only(top:10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.surface,border:Border.all(color:AppColors.stroke),borderRadius:BorderRadius.circular(16)),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(AppIcons.wallet,color:AppColors.oceanDeep,size:20),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(_tab==0?e['description']?.toString()??'Movimentação':_status(e['status']),style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:5),Text(_date(e[_tab==0?'createdAt':'requestedAt']),style:const TextStyle(color:AppColors.muted,fontSize:11)),if(_tab==1)Text('${e['pixKeyType']} · ${e['pixKey']}',style:const TextStyle(color:AppColors.muted,fontSize:11))])),const SizedBox(width:8),Text('${_tab==0&&amount>0?'+ ':''}${_brl(amount)}',style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.oceanDeep))]));}),
      ]));
    }),
  );
}
