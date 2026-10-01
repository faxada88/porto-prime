import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
class AppState extends ChangeNotifier {
 AppState._();static final instance=AppState._();final api=ApiClient.instance;Map<String,dynamic>? user;List<dynamic> products=[];List<dynamic> addresses=[];List<dynamic> orders=[];final Map<String,int> cart={};bool loading=false;String? error;
 bool get loggedIn=>user!=null;bool get isCustomer=>user?['role']=='CUSTOMER';int get cartCount=>cart.values.fold(0,(a,b)=>a+b);
 Future<void> loadProducts()async{try{products=List<dynamic>.from(await api.request('GET','/products'));notifyListeners();}catch(_){}}
 Future<Map<String,dynamic>> register(Map<String,dynamic>d)async{loading=true;error=null;notifyListeners();try{final created=Map<String,dynamic>.from(await api.request('POST','/auth/register',body:d));if(d['role']=='CUSTOMER')return await login(d['email'],d['password']);user=created;return created;}catch(e){error=e.toString().replaceFirst('Exception: ','');rethrow;}finally{loading=false;notifyListeners();}}
 Future<Map<String,dynamic>> login(String email,String password)async{loading=true;error=null;notifyListeners();try{final x=Map<String,dynamic>.from(await api.request('POST','/auth/login',body:{'email':email,'password':password}));api.token=x['token'];user=Map<String,dynamic>.from(x['user']);if(isCustomer){await loadAddresses();await loadOrders();}return x;}catch(e){error=e.toString().replaceFirst('Exception: ','');rethrow;}finally{loading=false;notifyListeners();}}
 Future<void> logout()async{try{await api.request('POST','/auth/logout');}catch(_){}api.token=null;user=null;addresses=[];orders=[];cart.clear();notifyListeners();}
 void addProduct(String id){cart[id]=(cart[id]??0)+1;notifyListeners();}void changeQty(String id,int d){final n=(cart[id]??0)+d;if(n<=0)cart.remove(id);else cart[id]=n;notifyListeners();}
 dynamic product(String id){for(final p in products){if(p['id']==id)return p;}return null;}
 Future<void> loadAddresses()async{if(!isCustomer)return;addresses=List<dynamic>.from(await api.request('GET','/addresses'));notifyListeners();}
 Future<void> addAddress(Map<String,dynamic>d)async{await api.request('POST','/addresses',body:d);await loadAddresses();}
 Future<void> loadOrders()async{if(!isCustomer)return;orders=List<dynamic>.from(await api.request('GET','/orders/mine'));notifyListeners();}
 Future<void> checkout(String addressId)async{if(!isCustomer)throw Exception('Entre como cliente para finalizar');if(cart.isEmpty)throw Exception('Sua sacola está vazia');await api.request('POST','/orders',body:{'addressId':addressId,'items':cart.entries.map((e)=>{'productId':e.key,'quantity':e.value}).toList()});cart.clear();await loadOrders();notifyListeners();}
}