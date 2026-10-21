import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

final appState = AppState();

/// خدمة التفعيل. حالياً تجريبية: تولّد رمز محلياً وتعرضه على الشاشة.
/// للإنتاج: استبدل sendCode/verify باستدعاء مزود OTP (SMS / WhatsApp)
/// عبر API الخاص بك، وأرسل الرمز فعلياً لرقم العميل.
class ActivationService {
  String? _code;
  String? _phone;

  Future<String> sendCode(String phone) async {
    _phone = phone;
    _code = (100000 + Random().nextInt(900000)).toString();
    return _code!;
  }

  bool verify(String phone, String code) =>
      _code != null && _phone == phone && _code == code;
}

class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;

  bool activated = false;
  String name = '';
  String phone = '';
  String role = 'customer'; // customer | courier
  List<Order> orders = [];

  Store? cartStore;
  final Map<String, CartLine> cart = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    activated = _prefs.getBool('activated') ?? false;
    name = _prefs.getString('name') ?? '';
    phone = _prefs.getString('phone') ?? '';
    role = _prefs.getString('role') ?? 'customer';
    final raw = _prefs.getString('orders');
    if (raw != null) {
      orders = (jsonDecode(raw) as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _save() async {
    await _prefs.setBool('activated', activated);
    await _prefs.setString('name', name);
    await _prefs.setString('phone', phone);
    await _prefs.setString('role', role);
    await _prefs.setString(
        'orders', jsonEncode(orders.map((o) => o.toJson()).toList()));
  }

  // ---------- الحساب ----------
  void activate(String n, String p, String r) {
    name = n;
    phone = p;
    role = r;
    activated = true;
    _save();
    notifyListeners();
  }

  void switchRole() {
    role = role == 'customer' ? 'courier' : 'customer';
    _save();
    notifyListeners();
  }

  void logout() {
    activated = false;
    clearCart();
    _save();
    notifyListeners();
  }

  // ---------- السلة ----------
  int get cartCount => cart.values.fold<int>(0, (s, l) => s + l.qty);
  double get cartSubtotal =>
      cart.values.fold<double>(0, (s, l) => s + l.item.price * l.qty);

  int qtyOf(MenuItem m) => cart[m.id]?.qty ?? 0;

  /// يرجع false إذا كانت السلة تحتوي منتجات من متجر آخر.
  bool addToCart(Store store, MenuItem item) {
    if (cartStore != null && cartStore!.id != store.id && cart.isNotEmpty) {
      return false;
    }
    cartStore = store;
    final line = cart[item.id];
    if (line == null) {
      cart[item.id] = CartLine(item, 1);
    } else {
      line.qty++;
    }
    notifyListeners();
    return true;
  }

  void removeFromCart(MenuItem item) {
    final line = cart[item.id];
    if (line == null) return;
    line.qty--;
    if (line.qty <= 0) cart.remove(item.id);
    if (cart.isEmpty) cartStore = null;
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    cartStore = null;
    notifyListeners();
  }

  // ---------- الطلبات ----------
  void placeOrder(String address) {
    if (cart.isEmpty || cartStore == null) return;
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: name,
      customerPhone: phone,
      storeName: cartStore!.name,
      address: address,
      lines: cart.values
          .map((l) => OrderLine(l.item.name, l.item.price, l.qty))
          .toList(),
      fee: kDeliveryFee,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    orders.insert(0, order);
    clearCart();
    _save();
    notifyListeners();
  }

  List<Order> get myOrders =>
      orders.where((o) => o.customerPhone == phone).toList();

  List<Order> get availableOrders =>
      orders.where((o) => o.status == OrderStatus.placed).toList();

  List<Order> get courierOrders =>
      orders.where((o) => o.courierPhone == phone).toList();

  double get courierEarnings => courierOrders
      .where((o) => o.status == OrderStatus.delivered)
      .fold<double>(0, (s, o) => s + o.fee);

  void acceptOrder(Order o) {
    o.status = OrderStatus.accepted;
    o.courierName = name;
    o.courierPhone = phone;
    _save();
    notifyListeners();
  }

  void advanceOrder(Order o) {
    if (o.status == OrderStatus.accepted) {
      o.status = OrderStatus.pickedUp;
    } else if (o.status == OrderStatus.pickedUp) {
      o.status = OrderStatus.delivered;
    }
    _save();
    notifyListeners();
  }
}
