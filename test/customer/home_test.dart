import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_assignment/customer/header.dart';
import 'package:mad_assignment/customer/home.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CustomerHeader.setPreloadedAddress(
      const AddressOption(
        label: 'Current Location',
        fullAddress: 'George Town, Penang',
        state: 'Pulau Pinang',
        isDetected: true,
      ),
    );
  });

  tearDown(() {
    CustomerHeader.clearLocationCache();
  });

  final mockItem1 = {
    'id': 'food_1',
    'name': 'Crispy Chicken Burger',
    'price': 14.90,
    'description': 'Juicy fried chicken patty with fresh lettuce',
    'prepTime': '15 mins',
    'category': 'Burger',
    'is_available': true,
    'image_url': null,
  };

  final mockItem2 = {
    'id': 'food_2',
    'name': 'Cheesy Pepperoni Pizza',
    'price': 25.50,
    'description': 'Wood fired pizza with mozzarella and pepperoni',
    'prepTime': '20 mins',
    'category': 'Pizza',
    'is_available': true,
    'image_url': null,
  };

  final mockItem3 = {
    'id': 'food_3',
    'name': 'Iced Caramel Macchiato',
    'price': 12.00,
    'description': 'Espresso with steamed milk and vanilla syrup',
    'prepTime': '5 mins',
    'category': 'Beverage',
    'is_available': true,
    'image_url': null,
  };

  final mockItem4 = {
    'id': 'food_4',
    'name': 'Spaghetti Bolognese',
    'price': 18.00,
    'description': 'Classic pasta with slow cooked minced beef sauce',
    'prepTime': '18 mins',
    'category': 'Pasta',
    'is_available': true,
    'image_url': null,
  };

  group('CustomerHome Recently Ordered Section', () {
    testWidgets('hides Recently Ordered section when user is not logged in', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomerHome(
              initialIsLoggedIn: false,
              initialRecentOrders: [],
              initialBestSellers: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recently Ordered'), findsNothing);
      expect(find.text('View Orders'), findsNothing);
    });

    testWidgets('hides Recently Ordered section when user is logged in but has no recent orders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomerHome(
              initialIsLoggedIn: true,
              initialRecentOrders: [],
              initialBestSellers: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recently Ordered'), findsNothing);
      expect(find.text('View Orders'), findsNothing);
    });

    testWidgets('displays Recently Ordered section when user is logged in and has recent orders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerHome(
              initialIsLoggedIn: true,
              initialRecentOrders: [mockItem1, mockItem2],
              initialBestSellers: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recently Ordered'), findsOneWidget);
      expect(find.text('View Orders'), findsOneWidget);
      expect(find.text('Crispy Chicken Burger'), findsOneWidget);
      expect(find.text('Cheesy Pepperoni Pizza'), findsOneWidget);
      expect(find.text('RM 14.90'), findsOneWidget);
      expect(find.text('RM 25.50'), findsOneWidget);
    });
  });

  group('CustomerHome Best Sellers Section', () {
    testWidgets('displays Best Sellers section with up to 3 items and rank badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerHome(
              initialIsLoggedIn: false,
              initialRecentOrders: [],
              initialBestSellers: [mockItem1, mockItem2, mockItem3, mockItem4],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Best Sellers'), findsOneWidget);
      expect(find.text('Top 3 most popular picks by order volume'), findsNothing);
      expect(find.text('See All'), findsOneWidget);

      // Rank badges
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      expect(find.text('#4'), findsNothing); // Must only show up to three

      // Item names
      expect(find.text('Crispy Chicken Burger'), findsOneWidget);
      expect(find.text('Cheesy Pepperoni Pizza'), findsOneWidget);
      expect(find.text('Iced Caramel Macchiato'), findsOneWidget);
      expect(find.text('Spaghetti Bolognese'), findsNothing); // 4th item excluded
    });

    testWidgets('displays both Recently Ordered and Best Sellers when both have data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerHome(
              initialIsLoggedIn: true,
              initialRecentOrders: [mockItem1],
              initialBestSellers: [mockItem2, mockItem3],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recently Ordered'), findsOneWidget);
      expect(find.text('Best Sellers'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);

      // Verify layout order: Recently Ordered should appear before Best Sellers
      final recentOrdersPos = tester.getTopLeft(find.text('Recently Ordered'));
      final bestSellersPos = tester.getTopLeft(find.text('Best Sellers'));
      expect(recentOrdersPos.dy, lessThan(bestSellersPos.dy));
    });

    testWidgets('does not display Quick Categories or Most Popular section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerHome(
              initialIsLoggedIn: true,
              initialRecentOrders: [mockItem1],
              initialBestSellers: [mockItem2],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Categories'), findsNothing);
      expect(find.text('Most Popular'), findsNothing);
    });
  });
}
