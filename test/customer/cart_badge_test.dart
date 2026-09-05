import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_assignment/customer/cart.dart';
import 'package:mad_assignment/customer/header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeaderIconWithBadge widget tests', () {
    testWidgets('renders dot badge when badgeCount is null and showBadge is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderIconWithBadge(
              icon: Icons.notifications_outlined,
              showBadge: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Finds the icon
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      // Finds container for the dot
      expect(find.byType(Container), findsOneWidget);
      // No text inside the dot
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders number count badge when badgeCount > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderIconWithBadge(
              icon: Icons.shopping_cart_outlined,
              showBadge: true,
              badgeCount: 3,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders 99+ when badgeCount > 99', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderIconWithBadge(
              icon: Icons.shopping_cart_outlined,
              showBadge: true,
              badgeCount: 150,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('hides badge when badgeCount is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderIconWithBadge(
              icon: Icons.shopping_cart_outlined,
              showBadge: true,
              badgeCount: 0,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('0'), findsNothing);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('hides badge when showBadge is false even if badgeCount > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderIconWithBadge(
              icon: Icons.shopping_cart_outlined,
              showBadge: false,
              badgeCount: 5,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('5'), findsNothing);
      expect(find.byType(Container), findsNothing);
    });
  });

  group('CartStorage item count calculation & notifier tests', () {
    test('calculateItemCount sums quantities of all cart items', () {
      final items = [
        CartItem(name: 'Burger', price: 15.0, quantity: 2),
        CartItem(name: 'Fries', price: 6.0, quantity: 1),
        CartItem(name: 'Drink', price: 4.0, quantity: 3),
      ];

      expect(CartStorage.calculateItemCount(items), 6);
      expect(CartStorage.calculateItemCount(<CartItem>[]), 0);
    });

    testWidgets('HeaderActionButtons dynamically updates cart badge count via cartCountNotifier', (tester) async {
      CartStorage.cartCountNotifier.value = 0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeaderActionButtons(),
          ),
        ),
      );

      // Initially cart count is 0, no badge text
      expect(find.text('0'), findsNothing);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);

      // Simulate item added to cart
      CartStorage.cartCountNotifier.value = 4;
      await tester.pump();

      // Badge should now display '4'
      expect(find.text('4'), findsOneWidget);

      // Simulate cart cleared
      CartStorage.cartCountNotifier.value = 0;
      await tester.pump();

      // Badge disappears
      expect(find.text('4'), findsNothing);
    });
  });
}
