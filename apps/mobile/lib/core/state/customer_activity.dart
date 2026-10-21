import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';

/// Account-scoped activity derived from authenticated order and wallet updates.
class CustomerActivity extends ChangeNotifier {
 CustomerActivity._(){AppState.instance.addListener(_changed);}
 static final instance=CustomerActivity._();
 String? _owner;
 bool _loading=false;
 List<Map<String,dynamic>> entries=[];
 Map<String,String> _seen={};
 int get unread=>entries.where((e)=>e['read']!=true).length;
 void start()=>_changed();
 String _key(String id)=>'customer-activity-v1-$id';
 Future<void> _changed()async{
  final app=AppState.instance;
  String? id;
  if (app.isCustomer) {
    final customer = app.user;
    id = customer == null ? null : customer['id']?.toString();
  }
  if(id!=_owner){
   _owner=id;entries=[];_seen={};_loading=id!=null;notifyListeners();
   if(id==null)return;
   final prefs=await SharedPreferences.getInstance();
   if(_owner!=id)return;
   try{
    final raw=prefs.getString(_key(id));
    if(raw!=null){final saved=jsonDecode(raw) as Map;entries=(saved['entries'] as List).map((e)=>Map<String,dynamic>.from(e)).toList();_seen=Map<String,String>.from(saved['seen'] as Map);}
   }catch(_){/* Ignore invalid local cache; server data remains authoritative. */}
   _loading=false;
  }
  if(id==null||_loading||id!=_owner)return;
  final orders=<String,Map>{};
  for(final o in [if(app.activeOrder!=null)app.activeOrder!,...app.orders]){
   if(o is Map&&o['adminDeletedAt']==null)orders[o['id'].toString()]=o;
  }
  final liveIds=orders.keys.toSet();
  entries.removeWhere((e)=>e['kind']=='order'&&!liveIds.contains(e['orderId'])&&app.orders.isNotEmpty);
  for(final o in orders.values){
   final orderId=o['id'].toString();final status=o['status'].toString();
   final key='order:$orderId';final before=_seen[key];
   final version='$status:${o['paymentStatus']}';
   _seen[key]=version;
   if(before==version)continue;
   final title=['REFUNDED','PARTIALLY_REFUNDED'].contains(o['paymentStatus'])&&status!='CANCELED'
    ?'Reembolso atualizado':switch(status){
    'CANCELED'=>'Pedido cancelado','DELIVERED'=>'Pedido entregue',
    'OUT_FOR_DELIVERY'=>'Seu entregador iniciou a rota',
    'PICKED_UP'=>'Seu pedido foi coletado','COURIER_ASSIGNED'=>'Entregador aceitou seu pedido',
    'SEARCHING_COURIER'=>'Estamos procurando um entregador','PREPARING'=>'Pedido em preparação',
    _=>'Pedido atualizado',
   };
   // Never announce an unpaid checkout as a confirmed order.
   if(!['PAID','PARTIALLY_REFUNDED','REFUNDED'].contains(o['paymentStatus'])&&status!='CANCELED')continue;
   _add({'id':'$key:$version','kind':'order','orderId':orderId,'title':title,
    'detail':'Toque para acompanhar os detalhes.', 'date':o['updatedAt']??o['createdAt']??DateTime.now().toIso8601String()});
  }
  for(final raw in (app.customerCreditCard['entries'] as List? ?? [])){
   if(raw is! Map)continue;
   final key='credit:${raw['id']??'${raw['createdAt']}:${raw['amount']}'}';
   if(_seen.containsKey(key))continue;_seen[key]='seen';
   final amount=double.tryParse('${raw['amount']}')??0;
   _add({'id':key,'kind':'credit','title':amount>=0?'Crédito recebido':'Saldo atualizado',
    'detail':'${raw['description']??'Cartão Porto Prime'} · R\$ ${amount.abs().toStringAsFixed(2).replaceAll('.',',')}',
    'date':raw['createdAt']??DateTime.now().toIso8601String()});
  }
  entries.sort((a,b)=>'${b['date']}'.compareTo('${a['date']}'));
  if(entries.length>100)entries=entries.take(100).toList();
  notifyListeners();await _save();
 }
 void _add(Map<String,dynamic> entry){if(!entries.any((e)=>e['id']==entry['id']))entries.add({...entry,'read':false});}
 Future<void> markRead()async{entries=entries.map((e)=>{...e,'read':true}).toList();notifyListeners();await _save();}
 Future<void> _save()async{
  final id=_owner;if(id==null)return;
  final value=jsonEncode({'entries':entries,'seen':_seen});
  final prefs=await SharedPreferences.getInstance();await prefs.setString(_key(id),value);
 }
}
