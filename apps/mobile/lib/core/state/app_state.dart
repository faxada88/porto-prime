import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();
  final api = ApiClient();
  AppUser? user;
  List<CategoryModel> categories = [];
  List<ProductModel> products = [];
  final List<CartLine> cart = [];
  bool loading = false;
  String? error;

  int get cartCount => cart.fold(0, (n, e) => n + e.quantity);
  double get cartTotal => cart.fold(0, (n, e) => n + e.total);

  Future<void> bootstrap() async {
    loading = true; error = null; notifyListeners();
    try {
      final results = await Future.wait([api.get('/categories'), api.get('/products')]);
      categories = (results[0] as List).map((e) => CategoryModel.fromJson(Map<String,dynamic>.from(e))).toList();
      products = (results[1] as List).map((e) => ProductModel.fromJson(Map<String,dynamic>.from(e))).toList();
    } catch (e) { error = e.toString(); }
    loading = false; notifyListeners();
  }

  void add(ProductModel product) {
    final i = cart.indexWhere((e) => e.product.id == product.id);
    if (i < 0) cart.add(CartLine(product: product)); else cart[i].quantity++;
    notifyListeners();
  }
  void changeQty(ProductModel product, int delta) {
    final i = cart.indexWhere((e) => e.product.id == product.id);
    if (i < 0) return;
    cart[i].quantity += delta;
    if (cart[i].quantity <= 0) cart.removeAt(i);
    notifyListeners();
  }
  Future<void> login(String email, String password) async {
    final data = Map<String,dynamic>.from(await api.post('/auth/login', body:{'email':email,'password':password}));
    api.token = data['token']?.toString();
    user = AppUser.fromJson(Map<String,dynamic>.from(data['user']));
    notifyListeners();
  }
  Future<void> register({required String name, required String email, required String password, required String role, String? phone, String? businessName, String? document}) async {
    await api.post('/auth/register', body:{'name':name,'email':email,'password':password,'role':role,'phone':phone,'businessName':businessName,'document':document});
    if (role == 'CUSTOMER') await login(email,password);
  }
  Future<void> logout() async {
    try { await api.post('/auth/logout', authenticated:true); } catch (_) {}
    api.token=null; user=null; notifyListeners();
  }
}
