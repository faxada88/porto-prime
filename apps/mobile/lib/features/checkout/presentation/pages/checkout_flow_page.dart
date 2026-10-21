import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../addresses/presentation/pages/address_book_page.dart';
import 'stripe_checkout_page.dart';

class CheckoutFlowPage extends StatefulWidget {
 const CheckoutFlowPage({super.key});
 @override
 State<CheckoutFlowPage> createState()=>_CheckoutFlowPageState();
}
class _CheckoutFlowPageState extends State<CheckoutFlowPage> {
 String? _orderId,_signature;Map<String,dynamic>? _order;
 bool _preparing=false;
 Future<void> _closeDraft(String id) async {
  try {
   final app=AppState.instance;
   await app.api.request('POST','/payments/abandon',body:{'orderId':id});
   await Future.wait([app.loadOrders(),app.loadActiveOrder(),app.loadCustomerCredit()]);
  } catch (_) { /* Server lists independently exclude unpaid drafts, including offline exits. */ }
 }
 @override void dispose() {
  final id=_orderId;
  if(id!=null)unawaited(_closeDraft(id));
  super.dispose();
 }

 Future<void> _continue(Map<String,dynamic> selection) async {
  if(_preparing)return;
  _preparing=true;
  final app=AppState.instance;
  try {
   final quote=Map<String,dynamic>.from(selection['quote'] as Map);
   final credit=(selection['storeCreditRequested'] as num?)?.toDouble()??0;
   final items=app.cart.entries.toList()..sort((a,b)=>a.key.compareTo(b.key));
   final signature=jsonEncode({'address':selection['addressId'],'items':items.map((e)=>[e.key,e.value]).toList(),'credit':credit,'revision':quote['pricingRevision'],'fee':quote['deliveryFee']});
   if(_orderId!=null&&_signature==signature){
    final paid=await app.refreshPayment(_orderId!);
    if(!mounted)return;
    if(paid){Navigator.of(context).pop(<String,dynamic>{'result':'track','orderId':_orderId});return;}
   }
   if(_orderId==null||_signature!=signature){
    _order=await app.createOrder(selection['addressId'].toString(),pricingRevision:(quote['pricingRevision'] as num?)?.toInt(),expectedDeliveryFee:(quote['deliveryFee'] as num?)?.toDouble(),storeCreditRequested:credit,expectedTotal:app.cartSubtotal+(double.tryParse(quote['deliveryFee'].toString())??0)-credit);
    _orderId=_order!['id'].toString();_signature=signature;
    if(!mounted){await _closeDraft(_orderId!);return;}
   }
   if(!mounted)return;
   final payment=await app.createCheckout(_orderId!);
   if(!mounted)return;
   final summary=payment['summary'] is Map?Map<String,dynamic>.from(payment['summary'] as Map):_order;
   final result=await Navigator.of(context).push<String>(MaterialPageRoute(builder:(_)=>StripeCheckoutPage(clientSecret:(payment['clientSecret']??'').toString(),publishableKey:(payment['publishableKey']??'').toString(),creditOnly:payment['creditOnly']==true,orderId:_orderId!,summary:summary)));
   if(!mounted)return;
   if(result=='abandoned'){_orderId=null;_order=null;_signature=null;return;}
   if(result=='track'||result=='shop'||result=='home')Navigator.of(context).pop(<String,dynamic>{'result':result,'orderId':_orderId});
  } finally {_preparing=false;}
 }
 @override
 Widget build(BuildContext context)=>AddressBookPage(selectForCheckout:true,onContinue:_continue);
}

