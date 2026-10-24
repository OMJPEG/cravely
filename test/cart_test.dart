import 'package:flutter_test/flutter_test.dart';
import 'package:cravely/data.dart';
import 'package:cravely/state.dart';

void main() {
  test('same dish with different add-ons makes separate cart lines', () {
    final s = AppState();
    s.addToCart(dishes[0]);
    s.addToCart(dishes[0]);
    s.addToCart(dishes[0], addons: ['Extra raita (+15)']);
    expect(s.cart.length, 2);
    expect(s.cartCount, 3);
  });

  test('totals and coupon are correct', () {
    final s = AppState();
    s.addToCart(dishes[0], qty: 2); // 2 x 199 = 398
    expect(s.subtotal, 398);
    expect(s.delivery, 0); // free above 299
    expect(s.applyCoupon('CRAVE50'), isNull);
    expect(s.discount, 100); // capped
    expect(s.total, 398 + 0 + 5 - 100);
    expect(s.applyCoupon('WRONG'), isNotNull);
  });

  test('placing an order clears the cart and adds history', () {
    final s = AppState();
    s.addToCart(dishes[1]);
    final o = s.placeOrder('Home');
    expect(o, isNotNull);
    expect(s.cart, isEmpty);
    expect(s.orders.first.id, o!.id);
    expect(s.placeOrder('Home'), isNull);
  });
}
