import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

class AppState extends ChangeNotifier {
  AppState._();
  static final instance=AppState._();
  final api=ApiClient.instance;

  Map<String,dynamic>? user;
  List<dynamic> products=[];
  List<dynamic> addresses=[];
  List<dynamic> orders=[];
  Map<String,dynamic>? activeOrder;
  Map<String,dynamic>? courierDelivery;
  List<dynamic> courierOffers=[];
  bool courierOnline=false;
  final Map<String,int> cart={};
  bool loading=false;
  String? error;
  String catalogCategory='Todos';
  bool _catalogPolling=false;

  bool get loggedIn=>user!=null;
  bool get isCustomer=>user?['role']=='CUSTOMER';
  bool get isCourier=>user?['role']=='COURIER';
  int get cartCount=>cart.values.fold(0,(a,b)=>a+b);
  double get cartSubtotal=>cart.entries.fold(0,(sum,e){final p=product(e.key);return sum+(p==null?0:(double.tryParse(p['price'].toString())??0)*e.value);});

  Future<void> bootstrap()async{await loadProducts();startCatalogSync();if(loggedIn&&isCustomer){await Future.wait([loadAddresses(),loadOrders(),loadActiveOrder()]);}}
  void startCatalogSync(){
    if(_catalogPolling)return;
    _catalogPolling=true;
    Future<void>(()async{
      while(_catalogPolling){
        await Future<void>.delayed(const Duration(seconds:5));
        try{await loadProducts(silent:true);}catch(_){}
      }
    });
  }

  Future<void> loadProducts({bool silent=false})async{try{final next=List<dynamic>.from(await api.request('GET','/products'));final changed=next.toString()!=products.toString();products=next;if(changed)notifyListeners();}catch(e){if(!silent){error=e.toString();notifyListeners();}}}
  Future<Map<String,dynamic>> lookupPostalCode(String cep) async {
    final q=Uri(queryParameters:{'cep':cep}).query;
    return Map<String,dynamic>.from(await api.request('GET','/auth/postal-code?$q'));
  }

  Future<Map<String,dynamic>> checkAvailability(String field,String value) async {
    final q=Uri(queryParameters:{'field':field,'value':value}).query;
    return Map<String,dynamic>.from(await api.request('GET','/auth/availability?$q'));
  }

  Future<Map<String,dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? businessName,
    String? document,
    Map<String, dynamic>? profileData,
  }) async {
    final d = <String,dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
      if (businessName != null && businessName.trim().isNotEmpty)
        'businessName': businessName,
      if (document != null && document.trim().isNotEmpty)
        'document': document,
      if (role == 'COURIER' && profileData != null) ...{
        if ((profileData['cnh'] ?? '').toString().trim().isNotEmpty)
          'cnh': profileData['cnh'].toString().trim(),
        if ((profileData['cnhCategory'] ?? '').toString().trim().isNotEmpty)
          'cnhCategory': profileData['cnhCategory'].toString().trim(),
        if ((profileData['vehicleBrand'] ?? '').toString().trim().isNotEmpty)
          'vehicleBrand': profileData['vehicleBrand'].toString().trim(),
        if ((profileData['vehicleModel'] ?? '').toString().trim().isNotEmpty)
          'vehicleModel': profileData['vehicleModel'].toString().trim(),
        if ((profileData['vehiclePlate'] ?? '').toString().trim().isNotEmpty)
          'vehiclePlate': profileData['vehiclePlate'].toString().trim(),
        if (int.tryParse((profileData['vehicleYear'] ?? '').toString()) != null)
          'vehicleYear': int.parse(profileData['vehicleYear'].toString()),
      },
    };
    loading = true;
    error = null;
    notifyListeners();
    try {
      final created = Map<String,dynamic>.from(
        await api.request('POST', '/auth/register', body: d),
      );
      if (role == 'CUSTOMER') {
        return await login(email, password);
      }
      // Motoboy e parceiro aguardam aprovação: não criamos sessão local.
      user = null;
      api.token = null;
      return created;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Map<String,dynamic>> forgotPassword(String email) async => Map<String,dynamic>.from(await api.request('POST','/auth/forgot-password',body:{'email':email.trim()}));
  Future<void> resetPassword(String token,String password) async { await api.request('POST','/auth/reset-password',body:{'token':token,'password':password}); }

  Future<Map<String,dynamic>> login(String email,String password)async{loading=true;error=null;notifyListeners();try{final x=Map<String,dynamic>.from(await api.request('POST','/auth/login',body:{'email':email.trim(),'password':password}));api.token=x['token'];user=Map<String,dynamic>.from(x['user']);if(isCustomer){await Future.wait([loadAddresses(),loadOrders(),loadActiveOrder()]);}if(isCourier){await refreshCourier();}return x;}catch(e){error=e.toString().replaceFirst('Exception: ','');rethrow;}finally{loading=false;notifyListeners();}}
  Future<void> logout()async{try{await api.request('POST','/auth/logout');}catch(_){}api.token=null;user=null;addresses=[];orders=[];activeOrder=null;cart.clear();error=null;notifyListeners();}

  void addProduct(String id){cart[id]=(cart[id]??0)+1;notifyListeners();}
  void changeQty(String id,int d){final n=(cart[id]??0)+d;if(n<=0)cart.remove(id);else cart[id]=n;notifyListeners();}
  void removeProduct(String id){cart.remove(id);notifyListeners();}
  void clearCart(){cart.clear();notifyListeners();}
  void selectCatalogCategory(String name){catalogCategory=name;notifyListeners();}
  dynamic product(String id){for(final p in products){if(p['id']==id)return p;}return null;}

  Future<void> loadAddresses()async{if(!isCustomer)return;addresses=List<dynamic>.from(await api.request('GET','/addresses'));notifyListeners();}
  Future<void> addAddress(Map<String,dynamic>d)async{await api.request('POST','/addresses',body:d);await loadAddresses();}
  Future<void> updateAddress(String id,Map<String,dynamic>d)async{await api.request('PATCH','/addresses/$id',body:d);await loadAddresses();}
  Future<void> removeAddress(String id)async{await api.request('DELETE','/addresses/$id');await loadAddresses();}
  Future<int> clearPendingOrders()async{if(!isCustomer)return 0;final x=Map<String,dynamic>.from(await api.request('DELETE','/orders/pending'));await Future.wait([loadOrders(),loadActiveOrder()]);return (x['deleted'] as num?)?.toInt()??0;}
  Future<void> loadOrders()async{if(!isCustomer)return;orders=List<dynamic>.from(await api.request('GET','/orders/mine'));notifyListeners();}
  Future<void> loadActiveOrder()async{if(!isCustomer)return;final x=await api.request('GET','/orders/active');activeOrder=x==null?null:Map<String,dynamic>.from(x);notifyListeners();}

  Future<void> refreshCourier()async{if(!isCourier)return;final current=await api.request('GET','/orders/courier/current');courierDelivery=current==null?null:Map<String,dynamic>.from(current);courierOffers=List<dynamic>.from(await api.request('GET','/orders/courier/available'));notifyListeners();}
  Future<void> setCourierOnline(bool online)async{await api.request('PATCH','/orders/courier/online',body:{'online':online});courierOnline=online;await refreshCourier();}
  Future<void> acceptDelivery(String id)async{courierDelivery=Map<String,dynamic>.from(await api.request('PATCH','/orders/$id/courier/accept'));courierOnline=false;await refreshCourier();}
  Future<void> advanceDelivery(String id,String status)async{courierDelivery=Map<String,dynamic>.from(await api.request('PATCH','/orders/$id/courier/status',body:{'status':status}));if(status=='DELIVERED'){courierOnline=true;}await refreshCourier();}

  Future<Map<String,dynamic>> createOrder(String addressId)async{
    if(!isCustomer)throw Exception('Entre como cliente para finalizar');
    if(cart.isEmpty)throw Exception('Sua sacola está vazia');
    loading=true;error=null;notifyListeners();
    try{
      final order=Map<String,dynamic>.from(await api.request('POST','/orders',body:{'addressId':addressId,'items':cart.entries.map((e)=>{'productId':e.key,'quantity':e.value}).toList()}));
      await Future.wait([loadOrders(),loadActiveOrder()]);return order;
    }catch(e){error=e.toString().replaceFirst('Exception: ','');rethrow;}finally{loading=false;notifyListeners();}
  }

  Future<Map<String,dynamic>> createCheckout(String orderId)async{
    loading=true;error=null;notifyListeners();
    try{
      final origin=Uri.base.origin;
      return Map<String,dynamic>.from(await api.request('POST','/payments/checkout',body:{
        'orderId':orderId,
        'successUrl':'$origin/checkout-return?checkout=success&orderId=$orderId',
        'cancelUrl':'$origin/checkout-return?checkout=cancel&orderId=$orderId'
      }));
    }catch(e){error=e.toString().replaceFirst('Exception: ','');rethrow;}finally{loading=false;notifyListeners();}
  }

  Future<bool> refreshPayment(String orderId)async{
    for(var i=0;i<10;i++){
      await Future.wait([loadOrders(),loadActiveOrder()]);
      for(final o in orders){if(o['id'].toString()==orderId&&o['paymentStatus']=='PAID')return true;}
      await Future<void>.delayed(const Duration(milliseconds:900));
    }
    return false;
  }
}
