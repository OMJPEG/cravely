import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'models.dart';

/// Single app-wide state: cart, favourites, orders, coupon, profile.
class AppState extends ChangeNotifier {
  static const int deliveryFee = 40;
  static const int freeDeliveryAbove = 299;
  static const int platformFee = 5;

  final List<CartItem> cart = [];
  final Set<String> favourites = {};
  final List<Order> orders = [];
  String? coupon; // applied coupon code
  String userName = 'Om Dodia';
  String userPhone = '9876543210';
  bool signedIn = true;
  bool onboarded = false;
  bool darkMode = false;
  bool _placing = false;
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    favourites.addAll(_prefs!.getStringList('favs') ?? []);
    onboarded = _prefs!.getBool('onboarded') ?? false;
    darkMode = _prefs!.getBool('dark') ?? false;
    userName = _prefs!.getString('name') ?? userName;
    userPhone = _prefs!.getString('phone') ?? userPhone;
    // Mock previous orders
    orders.add(Order(
      id: 'CRV-1001',
      items: [CartItem(dish: dishes[0], size: 'Regular', addons: [], unitPrice: dishes[0].price)],
      total: dishes[0].price + deliveryFee + platformFee,
      time: DateTime.now().subtract(const Duration(days: 2)),
      address: savedAddresses[0],
      status: 'Delivered',
    ));
    notifyListeners();
  }

  // ---------- Cart ----------
  int get cartCount => cart.fold(0, (s, i) => s + i.qty);
  int get subtotal => cart.fold(0, (s, i) => s + i.total);
  int get delivery => cart.isEmpty ? 0 : (subtotal >= freeDeliveryAbove ? 0 : deliveryFee);
  int get platform => cart.isEmpty ? 0 : platformFee;

  /// CRAVE50: 50% off up to Rs 100, minimum subtotal Rs 199.
  int get discount {
    if (coupon == 'CRAVE50' && subtotal >= 199) {
      final d = subtotal ~/ 2;
      return d > 100 ? 100 : d;
    }
    return 0;
  }

  int get total => cart.isEmpty ? 0 : subtotal + delivery + platform - discount;

  void addToCart(Dish d, {String size = 'Regular', List<String> addons = const [], int qty = 1, String note = ''}) {
    int unit = d.price + (size == 'Large' ? 50 : 0);
    for (final a in addons) {
      unit += addonPrice[a] ?? 0;
    }
    final item = CartItem(dish: d, size: size, addons: List.of(addons), unitPrice: unit, note: note, qty: qty);
    final i = cart.indexWhere((c) => c.key == item.key);
    if (i >= 0) {
      cart[i].qty += qty;
    } else {
      cart.add(item);
    }
    _revalidateCoupon();
    notifyListeners();
  }

  void changeQty(CartItem item, int delta) {
    item.qty += delta;
    if (item.qty <= 0) cart.remove(item);
    _revalidateCoupon();
    notifyListeners();
  }

  int qtyOf(Dish d) => cart.where((c) => c.dish.id == d.id).fold(0, (s, c) => s + c.qty);

  void _revalidateCoupon() {
    if (cart.isEmpty) coupon = null;
  }

  /// Returns an error message or null on success.
  String? applyCoupon(String code) {
    final c = code.trim().toUpperCase();
    if (cart.isEmpty) return 'Your cart is empty';
    if (c != 'CRAVE50') return 'Invalid coupon code';
    if (subtotal < 199) return 'Add items worth Rs ${199 - subtotal} more to use CRAVE50';
    coupon = c;
    notifyListeners();
    return null;
  }

  void removeCoupon() {
    coupon = null;
    notifyListeners();
  }

  // ---------- Favourites ----------
  bool isFav(String id) => favourites.contains(id);

  void toggleFav(String id) {
    if (!favourites.add(id)) favourites.remove(id);
    _prefs?.setStringList('favs', favourites.toList());
    notifyListeners();
  }

  // ---------- Orders ----------
  /// Returns the new order, or null if cart is empty / already submitting.
  Order? placeOrder(String address) {
    if (_placing || cart.isEmpty) return null;
    _placing = true;
    final order = Order(
      id: 'CRV-${1002 + orders.length}',
      items: cart.map((c) => CartItem(dish: c.dish, size: c.size, addons: c.addons, unitPrice: c.unitPrice, note: c.note, qty: c.qty)).toList(),
      total: total,
      time: DateTime.now(),
      address: address,
    );
    orders.insert(0, order);
    cart.clear();
    coupon = null;
    _placing = false;
    notifyListeners();
    return order;
  }

  void reorder(Order o) {
    for (final i in o.items) {
      addToCart(i.dish, size: i.size, addons: i.addons, qty: i.qty);
    }
  }

  void setStatus(Order o, String s) {
    o.status = s;
    notifyListeners();
  }

  // ---------- Profile / settings ----------
  void updateProfile(String name, String phone) {
    userName = name;
    userPhone = phone;
    _prefs?.setString('name', name);
    _prefs?.setString('phone', phone);
    notifyListeners();
  }

  void finishOnboarding() {
    onboarded = true;
    _prefs?.setBool('onboarded', true);
    notifyListeners();
  }

  void setDark(bool v) {
    darkMode = v;
    _prefs?.setBool('dark', v);
    notifyListeners();
  }

  void toggleSignIn() {
    signedIn = !signedIn;
    notifyListeners();
  }
}
