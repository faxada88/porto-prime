import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';

class CourierPage extends StatefulWidget {
  const CourierPage({super.key});
  @override State<CourierPage> createState()=>_CourierPageState();
}
class _CourierPageState extends State<CourierPage>{
  Timer? timer;
  @override void initState(){super.initState();AppState.instance.refreshCourier();timer=Timer.periodic(const Duration(seconds:4),(_)=>AppState.instance.refreshCourier());}
  @override void dispose(){timer?.cancel();super.dispose();}
  @override Widget build(BuildContext context)=>AnimatedBuilder(
    animation:AppState.instance,
    builder:(_,__){
      final s=AppState.instance,o=s.courierDelivery,offers=s.courierOffers;
      final first=(s.user?['name']??'Motoboy').toString().split(' ').first;
      return Scaffold(backgroundColor:AppColors.canvas,body:SafeArea(child:RefreshIndicator(
        onRefresh:s.refreshCourier,
        child:ListView(padding:const EdgeInsets.fromLTRB(20,20,20,40),children:[
          Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('PORTO PRIME DRIVER',style:TextStyle(fontSize:9,fontWeight:FontWeight.w900,letterSpacing:1.3,color:AppColors.oceanDeep)),
            const SizedBox(height:5),Text('Olá, $first',style:const TextStyle(fontSize:27,fontWeight:FontWeight.w900)),
          ])),IconButton(onPressed:()=>s.logout(),icon:const Icon(Icons.logout_rounded))]),
          const SizedBox(height:18),
          Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF173B35),AppColors.oceanDeep]),borderRadius:BorderRadius.circular(30),boxShadow:AppShadows.elevated),child:Row(children:[
            const Icon(Icons.delivery_dining_rounded,color:Colors.white,size:38),const SizedBox(width:16),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(o!=null?'Entrega em andamento':s.courierOnline?'Você está online':'Você está offline',style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w900)),
              Text(o!=null?'Conclua sua rota atual.':s.courierOnline?'Procurando pedidos automaticamente...':'Ative para receber entregas.',style:const TextStyle(color:Colors.white70,fontSize:10)),
            ])),
            if(o==null)Switch(value:s.courierOnline,onChanged:s.setCourierOnline),
          ])),
          const SizedBox(height:22),
          if(o!=null)_Delivery(order:o) else ...[
            const Text('Entregas disponíveis',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:12),
            if(!s.courierOnline)_Empty('Fique online para começar a receber pedidos.')
            else if(offers.isEmpty)_Empty('Buscando novas entregas... Os pedidos liberados pelo Admin aparecem aqui automaticamente.')
            else ...offers.map((x)=>_Offer(order:x)),
          ]
        ]),
      )));
    },
  );
}
class _Offer extends StatelessWidget{
  const _Offer({required this.order});final dynamic order;
  @override Widget build(BuildContext context){final a=order['address'];return Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.stroke)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Icon(Icons.bolt_rounded,color:AppColors.oceanDeep),const SizedBox(width:7),const Text('NOVA ENTREGA',style:TextStyle(fontSize:9,fontWeight:FontWeight.w900)),const Spacer(),Text('R\$ '+order['total'].toString(),style:const TextStyle(fontWeight:FontWeight.w900))]),
    const SizedBox(height:14),Text((a?['street']??'')+', '+(a?['number']??''),style:const TextStyle(fontSize:14,fontWeight:FontWeight.w900)),Text((a?['neighborhood']??'')+' • '+(a?['city']??''),style:const TextStyle(fontSize:10,color:AppColors.muted)),
    const SizedBox(height:14),SizedBox(width:double.infinity,height:48,child:FilledButton(onPressed:()=>AppState.instance.acceptDelivery(order['id']),child:const Text('Aceitar entrega',style:TextStyle(fontWeight:FontWeight.w900))))
  ]));}
}
class _Delivery extends StatelessWidget{
  const _Delivery({required this.order});final dynamic order;
  @override Widget build(BuildContext context){final s=order['status'].toString(),a=order['address'];final next=s=='COURIER_ASSIGNED'?'PICKED_UP':s=='PICKED_UP'?'OUT_FOR_DELIVERY':s=='OUT_FOR_DELIVERY'?'DELIVERED':null;final label=next=='PICKED_UP'?'Confirmar coleta':next=='OUT_FOR_DELIVERY'?'Iniciar entrega':'Confirmar entrega';return Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(28),border:Border.all(color:AppColors.stroke)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('ENTREGA ATUAL',style:TextStyle(fontSize:9,fontWeight:FontWeight.w900,color:AppColors.oceanDeep)),const SizedBox(height:8),
    Text(order['customer']?['name']??'Cliente',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:15),
    _line(Icons.location_on_rounded,'Destino',(a?['street']??'')+', '+(a?['number']??'')+' · '+(a?['neighborhood']??'')),
    _line(Icons.shopping_bag_rounded,'Pedido',((order['items'] as List?)?.length??0).toString()+' itens'),
    if(next!=null)SizedBox(width:double.infinity,height:54,child:FilledButton(onPressed:()=>AppState.instance.advanceDelivery(order['id'],next),child:Text(label,style:const TextStyle(fontWeight:FontWeight.w900))))
  ]));}
}
Widget _line(IconData i,String a,String b)=>Padding(padding:const EdgeInsets.only(bottom:14),child:Row(children:[Icon(i,color:AppColors.oceanDeep),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:9,color:AppColors.muted)),Text(b,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w900))]))]));
class _Empty extends StatelessWidget{const _Empty(this.text);final String text;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(28),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24)),child:Column(children:[const Icon(Icons.radar_rounded,size:40,color:AppColors.oceanDeep),const SizedBox(height:12),Text(text,textAlign:TextAlign.center,style:const TextStyle(color:AppColors.muted,fontSize:11,height:1.5,fontWeight:FontWeight.w700))]));}
