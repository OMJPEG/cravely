import 'package:cravely/data.dart';
import 'package:cravely/models.dart';
import 'package:cravely/screens.dart';
import 'package:cravely/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child, AppState state) {
  return ChangeNotifierProvider.value(
    value: state,
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  testWidgets('Smoke test: OnboardingScreen renders and navigates', (tester) async {
    final state = AppState();
    await tester.pumpWidget(_wrap(const OnboardingScreen(), state));
    expect(find.text('Discover food'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Smoke test: HomeShell and Tabs render', (tester) async {
    final state = AppState();
    await tester.pumpWidget(_wrap(const HomeShell(), state));
    await tester.pumpAndSettle();

    expect(find.text('Popular near you'), findsOneWidget);
    expect(find.text('Bestsellers'), findsOneWidget);

    // Switch to Search Tab
    tabIndex.value = 1;
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsWidgets);

    // Switch to Orders Tab
    tabIndex.value = 2;
    await tester.pumpAndSettle();
    expect(find.text('Orders'), findsWidgets);

    // Switch to Profile Tab
    tabIndex.value = 3;
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);

    // Reset tab
    tabIndex.value = 0;
  });

  testWidgets('Smoke test: RestaurantScreen renders', (tester) async {
    final state = AppState();
    await tester.pumpWidget(_wrap(RestaurantScreen(dishes[0].restaurant), state));
    await tester.pumpAndSettle();
    expect(find.text(dishes[0].restaurant), findsWidgets);
  });

  testWidgets('Smoke test: CartScreen and CheckoutScreen render', (tester) async {
    final state = AppState();
    state.addToCart(dishes[0]);
    await tester.pumpWidget(_wrap(const CartScreen(), state));
    await tester.pumpAndSettle();

    expect(find.text('Your cart'), findsOneWidget);
    expect(find.text(dishes[0].name), findsOneWidget);

    await tester.pumpWidget(_wrap(const CheckoutScreen(), state));
    await tester.pumpAndSettle();
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Delivery address'), findsOneWidget);
  });

  testWidgets('Smoke test: FavouritesScreen renders', (tester) async {
    final state = AppState();
    state.toggleFav(dishes[0].id);
    await tester.pumpWidget(_wrap(const FavouritesScreen(), state));
    await tester.pumpAndSettle();

    expect(find.text('Favourites'), findsOneWidget);
    expect(find.text(dishes[0].name), findsOneWidget);
  });

  testWidgets('Smoke test: ConfirmScreen renders', (tester) async {
    final state = AppState();
    final order = Order(
      id: 'CRV-TEST',
      items: [CartItem(dish: dishes[0], size: 'Regular', addons: [], unitPrice: dishes[0].price)],
      total: 244,
      time: DateTime.now(),
      address: savedAddresses[0],
    );
    await tester.pumpWidget(_wrap(ConfirmScreen(order), state));
    await tester.pump();
    expect(find.text('Order confirmed'), findsOneWidget);
    expect(find.text('Order CRV-TEST'), findsOneWidget);
  });
}
