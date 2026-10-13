import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';

class CustomerCancellationPanel extends StatefulWidget {
 const CustomerCancellationPanel({super.key,required this.order});
 final Map<String,dynamic> order;
 @override
 State<CustomerCancellationPanel> createState()=>_CustomerCancellationPanelState();
}
class _CustomerCancellationPanelState extends State<CustomerCancellationPanel> {
 bool _loading=false;String? _error;
 String money(dynamic value)=>'R\$ ${(double.tryParse('$value')??0).toStringAsFixed(2).replaceAll('.',',')}';
 Future<void> _refresh()async{await Future.wait([AppState.instance.loadOrders(),AppState.instance.loadActiveOrder(),AppState.instance.loadCustomerCredit()]);}
 Future<void> _open()async{
  if(_loading)return;setState((){_loading=true;_error=null;});
  final id=widget.order['id'].toString();
  try{
   final result=await AppState.instance.api.request('GET','/orders/$id/cancellation-quote');if(!mounted)return;
   if(result['alreadyCanceled']==true){await _refresh();return;}
   var quote=Map<String,dynamic>.from(result as Map);String reason='Mudei de ideia';bool saving=false;String? error;
   await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,showDragHandle:true,builder:(sheet)=>StatefulBuilder(builder:(sheet,update)=>SingleChildScrollView(padding:EdgeInsets.fromLTRB(24,8,24,24+MediaQuery.viewInsetsOf(sheet).bottom),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Icon(AppIcons.receipt,size:32,color:AppColors.ocean700),const SizedBox(height:16),const Text('Cancelar este pedido?',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800,letterSpacing:-.6)),const SizedBox(height:10),
    const Text('A entrega será interrompida. Confira os valores antes de confirmar.',style:TextStyle(color:AppColors.muted,height:1.6)),const SizedBox(height:20),
    DropdownButtonFormField<String>(initialValue:reason,isExpanded:true,decoration:const InputDecoration(labelText:'Motivo do cancelamento'),items:['Mudei de ideia','Endereço incorreto','Demora no atendimento','Outro motivo'].map((r)=>DropdownMenuItem(value:r,child:Text(r))).toList(),onChanged:saving?null:(r)=>update(()=>reason=r??reason)),const SizedBox(height:20),
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:AppColors.canvas,borderRadius:BorderRadius.circular(18),border:Border.all(color:AppColors.stroke)),child:Column(children:[_line('Valor retido',quote['fee']),_line('Devolução no pagamento original',quote['cashRefund']),_line('Devolução no Cartão Porto Prime',quote['creditRefund'])])),const SizedBox(height:12),
    Text((double.tryParse('${quote['fee']}')??0)>0?'O entregador já aceitou sua entrega. O valor retido será repassado integralmente a ele.':'Este cancelamento não terá custo.',style:const TextStyle(fontSize:12,height:1.6,color:AppColors.muted)),
    const SizedBox(height:8),const Text('A devolução pelo pagamento original pode depender do prazo da instituição financeira.',style:TextStyle(fontSize:11,color:AppColors.muted,height:1.5)),
    if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:PrimeErrorBanner(message:error!)),const SizedBox(height:22),
    SizedBox(width:double.infinity,height:54,child:FilledButton(onPressed:saving?null:()async{
     update((){saving=true;error=null;});
     try{await AppState.instance.api.request('POST','/orders/$id/cancel',body:{'reason':reason,'expectedFee':double.tryParse('${quote['fee']}')??0,'expectedCashRefund':double.tryParse('${quote['cashRefund']}')??0,'expectedCreditRefund':double.tryParse('${quote['creditRefund']}')??0});if(!sheet.mounted||!mounted)return;Navigator.of(sheet).pop();await _refresh();}
     catch(e){if(!sheet.mounted)return;try{final fresh=await AppState.instance.api.request('GET','/orders/$id/cancellation-quote');if(!sheet.mounted)return;if(fresh['alreadyCanceled']==true){Navigator.of(sheet).pop();await _refresh();return;}update(()=>quote=Map<String,dynamic>.from(fresh as Map));}catch(_){}if(sheet.mounted)update(()=>error='${PrimeMessages.friendly(e)} Confira os valores antes de tentar novamente.');}
     finally{if(sheet.mounted)update(()=>saving=false);}
    },child:saving?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('Confirmar cancelamento'))),
    SizedBox(width:double.infinity,child:TextButton(onPressed:saving?null:()=>Navigator.of(sheet).pop(),child:const Text('Manter meu pedido'))),
   ]))));
  }catch(e){if(mounted)setState(()=>_error=PrimeMessages.friendly(e));}
  finally{if(mounted)setState(()=>_loading=false);}
 }
 Widget _line(String label,dynamic amount)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(children:[Expanded(child:Text(label,style:const TextStyle(fontSize:12,color:AppColors.muted))),const SizedBox(width:12),Text(money(amount),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14))]));
 @override
 Widget build(BuildContext context){
  final record=widget.order['cancellation'];
  if(record is Map){final done=record['status']=='COMPLETED';final review=record['status']=='REVIEW';return Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:AppColors.stroke)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(done?AppIcons.checkCircle:AppIcons.clock,color:AppColors.ocean700,size:22),const SizedBox(width:10),Expanded(child:Text(done?'Cancelamento concluído':'Pedido cancelado',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)))]),const SizedBox(height:10),Text(done?'As devoluções foram registradas. Consulte seu pagamento e o Cartão Porto Prime.':review?'A entrega foi interrompida. A loja está verificando a devolução.':'A entrega foi interrompida. Estamos processando as devoluções.',style:const TextStyle(color:AppColors.muted,fontSize:12,height:1.6)),const SizedBox(height:12),_line('Valor retido',record['fee']),_line('Pagamento original',record['cashRefund']),_line('Cartão Porto Prime',record['creditRefund'])]));}
  final status=widget.order['status'];
  if(['DELIVERED','CANCELED'].contains(status)||widget.order['deliveredAt']!=null||!['PAID','PARTIALLY_REFUNDED'].contains(widget.order['paymentStatus']))return const SizedBox.shrink();
  return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[OutlinedButton.icon(onPressed:_loading?null:_open,icon:_loading?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(AppIcons.close,size:17),label:const Text('Cancelar pedido')),if(_error!=null)Padding(padding:const EdgeInsets.only(top:8),child:PrimeErrorBanner(message:_error!))]);
 }
}
