import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../realtime/realtime_client.dart';

class AppState extends ChangeNotifier {
  AppState._() {
    realtime.onEvent = _handleRealtimeEvent;
    api.onAccessTokenChanged = (freshToken) {
      if (freshToken == null) {
        realtime.disconnect();
      } else if (user != null) {
        realtime.reconnect(freshToken);
      }
    };
  }

  static final instance=AppState._();
  final api=ApiClient.instance;
  final realtime=RealtimeClient.instance;

  Map<String,dynamic>? user;
  List<dynamic> products=[];
  List<dynamic> addresses=[];
  List<dynamic> orders=[];
  Map<String,dynamic>? activeOrder;
  Map<String,dynamic>? courierDelivery;
  List<dynamic> courierOffers=[];
  bool courierOnline=false;
  String courierPresenceStatus='OFFLINE';
  Map<String,dynamic> walletSummary={};
  List<dynamic> walletLedger=[];
  List<dynamic> withdrawals=[];
  List<dynamic> courierHistory=[];
  Map<String,dynamic> courierProfile={};
  Map<String,dynamic> deliveryQuote={};
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

  Future<void> bootstrap() async {
    await loadProducts();
    startCatalogSync();

    if (api.token != null || api.refreshToken != null) {
      try {
        final me = await api.request('GET', '/auth/me');
        user = Map<String, dynamic>.from(me as Map);
        if (api.token != null) realtime.connect(api.token!);
      } catch (_) {
        await api.clearSession();
        user = null;
      }
    }

    if (loggedIn && isCustomer) {
      await Future.wait([
        loadAddresses(),
        loadOrders(),
        loadActiveOrder(),
      ]);
    }
    if (loggedIn && isCourier) {
      await refreshCourier();
    }
    notifyListeners();
  }

  void _handleRealtimeEvent(String event, dynamic payload) {
    if (event == 'session.revoked') {
      Future<void>(() async {
        realtime.disconnect();
        await api.clearSession();
        user=null;
        addresses=[];
        orders=[];
        activeOrder=null;
        courierDelivery=null;
        courierOffers=[];
        courierOnline=false;
        courierPresenceStatus='OFFLINE';
        walletSummary={};
        walletLedger=[];
        withdrawals=[];
        courierHistory=[];
        courierProfile={};
        deliveryQuote={};
        cart.clear();
        notifyListeners();
      });
      return;
    }

    if (!loggedIn) return;

    if (isCustomer &&
        (event == 'order.updated' || event == 'order.created')) {
      Future<void>(() async {
        try {
          await Future.wait([loadOrders(), loadActiveOrder()]);
        } catch (_) {}
      });
      return;
    }

    if (isCourier &&
        (event == 'delivery.offer' ||
            event == 'delivery.offer.closed' ||
            event == 'delivery.accepted' ||
            event == 'order.updated' ||
            event == 'courier.presence')) {
      Future<void>(() async {
        try {
          await refreshCourier();
        } catch (_) {}
      });
      return;
    }

    if (isCourier && event == 'wallet.updated') {
      Future<void>(() async {
        try {
          await loadWallet();
        } catch (_) {}
      });
    }
  }
  void startCatalogSync(){
    if(_catalogPolling)return;
    _catalogPolling=true;
    Future<void>(()async{
      while(_catalogPolling){
        await Future<void>.delayed(const Duration(seconds:30));
        try{await loadProducts(silent:true);}catch(_){}
      }
    });
  }

  bool _sameCatalog(List<dynamic> a, List<dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i] as Map?;
      final right = b[i] as Map?;
      if (left == null || right == null) return false;
      for (final key in const [
        'id',
        'name',
        'price',
        'stock',
        'active',
        'imageUrl',
        'updatedAt',
      ]) {
        if (left[key]?.toString() != right[key]?.toString()) return false;
      }
      final leftCategory = left['category'] as Map?;
      final rightCategory = right['category'] as Map?;
      if (leftCategory?['id']?.toString() !=
          rightCategory?['id']?.toString()) {
        return false;
      }
    }
    return true;
  }

  Future<void> loadProducts({bool silent=false}) async {
    try {
      final next =
          List<dynamic>.from(await api.request('GET', '/products'));
      if (_sameCatalog(next, products)) return;
      products = next;
      notifyListeners();
    } catch (e) {
      if (!silent) {
        error = e.toString();
        notifyListeners();
      }
    }
  }
  Future<Map<String,dynamic>> lookupPostalCode(String cep) async {
    final q=Uri(queryParameters:{'cep':cep}).query;
    return Map<String,dynamic>.from(await api.request('GET','/auth/postal-code?$q'));
  }

  Future<Map<String,dynamic>> checkAvailability(String field,String value) async {
    final q=Uri(queryParameters:{'field':field,'value':value}).query;
    return Map<String,dynamic>.from(await api.request('GET','/auth/availability?$q'));
  }
  Future<Map<String, dynamic>> lookupCourierCpf(String cpf, String birthDate) async {
    return Map<String, dynamic>.from(await api.request(
      'POST', '/auth/courier-cpf',
      body: {'cpf': cpf, 'birthDate': birthDate},
      timeout: const Duration(seconds: 70),
      retryOnUnauthorized: false,
    ));
  }

  Future<Map<String,dynamic>> courierApplicationStatus(String document) async {
    return Map<String,dynamic>.from(
      await api.request(
        'POST',
        '/couriers/application/status',
        body: {'document': document},
      ),
    );
  }

  Future<Map<String,dynamic>> respondCourierApplicationRequirement(
    String requirementId,
    String document,
    String response,
  ) async {
    return Map<String,dynamic>.from(
      await api.request(
        'POST',
        '/couriers/application/requirements/' + requirementId + '/respond',
        body: {
          'document': document,
          'response': response,
        },
      ),
    );
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
      if (profileData != null) 'profileData': profileData,
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
        await api.request('POST', '/auth/register', body: d,
          timeout: role == 'COURIER' ? const Duration(seconds: 75) : null),
      );
      if (role == 'CUSTOMER') {
        return await login(email, password);
      }
      // Motoboy e parceiro aguardam aprovação: não criamos sessão local.
      user = null;
      await api.clearSession();
      realtime.disconnect();
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

  Future<Map<String,dynamic>> login(String email,String password) async {
    loading=true;
    error=null;
    notifyListeners();
    try {
      final x=Map<String,dynamic>.from(
        await api.request(
          'POST',
          '/auth/login',
          body:{'email':email.trim(),'password':password},
        ),
      );
      await api.setSession(x);
      user=Map<String,dynamic>.from(x['user']);
      if(api.token!=null)realtime.connect(api.token!);
      if(isCustomer){
        await Future.wait([loadAddresses(),loadOrders(),loadActiveOrder()]);
      }
      if(isCourier){
        await refreshCourier();
      }
      return x;
    } catch(e) {
      error=e.toString().replaceFirst('Exception: ','');
      rethrow;
    } finally {
      loading=false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try{await api.request('POST','/auth/logout');}catch(_){}
    realtime.disconnect();
    await api.clearSession();
    user=null;
    addresses=[];
    orders=[];
    activeOrder=null;
    courierDelivery=null;
    courierOffers=[];
    courierOnline=false;
    courierPresenceStatus='OFFLINE';
    walletSummary={};
    walletLedger=[];
    withdrawals=[];
    courierHistory=[];
    courierProfile={};
    deliveryQuote={};
    cart.clear();
    error=null;
    notifyListeners();
  }

  void addProduct(String id){cart[id]=(cart[id]??0)+1;notifyListeners();}
  void changeQty(String id,int d){final n=(cart[id]??0)+d;if(n<=0)cart.remove(id);else cart[id]=n;notifyListeners();}
  void removeProduct(String id){cart.remove(id);notifyListeners();}
  void clearCart(){cart.clear();notifyListeners();}
  void selectCatalogCategory(String name){catalogCategory=name;notifyListeners();}
  dynamic product(String id){for(final p in products){if(p['id']==id)return p;}return null;}

  Future<void> loadAddresses() async {
    if(!isCustomer)return;
    addresses=List<dynamic>.from(await api.request('GET','/addresses'));
    if(addresses.isNotEmpty){
      final selected=addresses.firstWhere(
        (a)=>a['isDefault']==true,
        orElse:()=>addresses.first,
      );
      try{
        deliveryQuote=await quoteDelivery(selected['id'].toString());
      }catch(_){
        deliveryQuote={};
      }
    }else{
      deliveryQuote={};
    }
    notifyListeners();
  }
  Future<void> addAddress(Map<String,dynamic>d)async{await api.request('POST','/addresses',body:d);await loadAddresses();}
  Future<void> updateAddress(String id,Map<String,dynamic>d)async{await api.request('PATCH','/addresses/$id',body:d);await loadAddresses();}
  Future<void> removeAddress(String id)async{await api.request('DELETE','/addresses/$id');await loadAddresses();}
  Future<int> clearPendingOrders()async{if(!isCustomer)return 0;final x=Map<String,dynamic>.from(await api.request('DELETE','/orders/pending'));await Future.wait([loadOrders(),loadActiveOrder()]);return (x['deleted'] as num?)?.toInt()??0;}
  Future<void> loadOrders()async{if(!isCustomer)return;orders=List<dynamic>.from(await api.request('GET','/orders/mine'));notifyListeners();}
  Future<void> loadActiveOrder()async{if(!isCustomer)return;final x=await api.request('GET','/orders/active');activeOrder=x==null?null:Map<String,dynamic>.from(x);notifyListeners();}

  Future<void>? _courierRefreshFuture;

  Future<void> refreshCourier() {
    final running = _courierRefreshFuture;
    if (running != null) return running;

    final future = _refreshCourierOnce();
    _courierRefreshFuture = future;
    future.whenComplete(() {
      if (identical(_courierRefreshFuture, future)) {
        _courierRefreshFuture = null;
      }
    });
    return future;
  }

  Future<void> _refreshCourierOnce() async {
    if(!isCourier)return;

    final results=await Future.wait([
      api.request('GET','/orders/courier/presence'),
      api.request('GET','/orders/courier/current'),
      api.request('GET','/orders/courier/available'),
      api.request('GET','/wallet/summary'),
      api.request('GET','/orders/courier/history'),
      api.request('GET','/couriers/application/me'),
    ]);

    final presence=Map<String,dynamic>.from(results[0] as Map);
    courierPresenceStatus=(presence['presenceStatus']??'OFFLINE').toString();
    courierOnline=presence['isOnline']==true ||
        courierPresenceStatus=='AVAILABLE' ||
        courierPresenceStatus=='OFFERED';

    final current=results[1];
    courierDelivery=current==null
        ?null
        :Map<String,dynamic>.from(current as Map);
    courierOffers=List<dynamic>.from(results[2] as List);
    walletSummary=Map<String,dynamic>.from(results[3] as Map);
    courierHistory=List<dynamic>.from(results[4] as List);
    courierProfile=Map<String,dynamic>.from(results[5] as Map);
    notifyListeners();
  }

  Future<void> heartbeatCourier({
    double? latitude,
    double? longitude,
  }) async {
    if(!isCourier)return;
    final result=Map<String,dynamic>.from(
      await api.request(
        'PATCH',
        '/orders/courier/heartbeat',
        body:{
          'online':courierOnline,
          if(latitude!=null)'latitude':latitude,
          if(longitude!=null)'longitude':longitude,
        },
      ),
    );
    final nextPresence =
        (result['presenceStatus'] ?? 'OFFLINE').toString();
    final nextOnline = result['isOnline'] == true ||
        nextPresence == 'AVAILABLE' ||
        nextPresence == 'OFFERED';
    final changed =
        nextPresence != courierPresenceStatus || nextOnline != courierOnline;
    courierPresenceStatus = nextPresence;
    courierOnline = nextOnline;
    if (changed) notifyListeners();
  }

  Future<void> setCourierOnline(bool online) async {
    final result=Map<String,dynamic>.from(
      await api.request(
        'PATCH',
        '/orders/courier/online',
        body:{'online':online},
      ),
    );
    courierPresenceStatus=(result['presenceStatus']??'OFFLINE').toString();
    courierOnline=result['isOnline']==true ||
        courierPresenceStatus=='AVAILABLE' ||
        courierPresenceStatus=='OFFERED';
    await refreshCourier();
  }

  Future<void> acceptDelivery(String id) async {
    courierDelivery=Map<String,dynamic>.from(
      await api.request('PATCH','/orders/$id/courier/accept'),
    );
    courierOnline=false;
    courierPresenceStatus='DELIVERING';
    await refreshCourier();
  }

  Future<void> rejectDelivery(String id) async {
    await api.request('PATCH','/orders/$id/courier/reject');
    await refreshCourier();
  }

  Future<void> advanceDelivery(
    String id,
    String status, {
    String? pin,
  }) async {
    courierDelivery=Map<String,dynamic>.from(
      await api.request(
        'PATCH',
        '/orders/$id/courier/status',
        body:{
          'status':status,
          if(pin!=null&&pin.trim().isNotEmpty)'pin':pin.trim(),
        },
      ),
    );
    if(status=='DELIVERED'){
      courierOnline=true;
      courierPresenceStatus='AVAILABLE';
      await loadWallet();
    }else{
      courierPresenceStatus='DELIVERING';
    }
    await refreshCourier();
  }

  Future<void> loadWallet() async {
    if(!isCourier)return;
    final result=await Future.wait([
      api.request('GET','/wallet/summary'),
      api.request('GET','/wallet/ledger?take=100'),
      api.request('GET','/wallet/withdrawals'),
    ]);
    walletSummary=Map<String,dynamic>.from(result[0] as Map);
    walletLedger=List<dynamic>.from(result[1] as List);
    withdrawals=List<dynamic>.from(result[2] as List);
    notifyListeners();
  }

  Future<Map<String,dynamic>> requestWithdrawal(double amount) async {
    final created=Map<String,dynamic>.from(
      await api.request(
        'POST',
        '/wallet/withdrawals',
        body:{'amount':amount},
      ),
    );
    await loadWallet();
    return created;
  }

  Future<Map<String,dynamic>> quoteDelivery(String addressId) async {
    final query=Uri(queryParameters:{'addressId':addressId}).query;
    final quote=Map<String,dynamic>.from(
      await api.request('GET','/delivery/quote?$query'),
    );
    deliveryQuote=quote;
    notifyListeners();
    return quote;
  }

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
