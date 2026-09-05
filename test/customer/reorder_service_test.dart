import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mad_assignment/Order/order.dart';
import 'package:mad_assignment/customer/cart.dart';
import 'package:mad_assignment/customer/header.dart';
import 'package:mad_assignment/customer/orders.dart';
import 'package:mad_assignment/customer/reorder_service.dart';

const _customerId = 'customer-reorder-test';

Order _order({
  FulfilmentType fulfilmentType = FulfilmentType.delivery,
  OrderStatus status = OrderStatus.delivered,
  double? destinationLatitude = 5.4100,
  double? destinationLongitude = 100.3200,
}) {
  final now = DateTime.utc(2026, 9, 5);
  final destination = fulfilmentType == FulfilmentType.delivery
      ? DeliveryAddressSnapshot(
          label: 'Home',
          formattedAddress: 'Home, George Town, Pulau Pinang',
          stateCode: '07',
          latitude: destinationLatitude,
          longitude: destinationLongitude,
        )
      : null;

  return Order(
    id: 'order-reorder-test',
    orderNumber: 'ORD-REORDER-TEST',
    paymentIdempotencyKey: 'checkout-reorder-test',
    customerId: _customerId,
    riderId: null,
    fulfilmentType: fulfilmentType,
    status: status,
    branchSnapshot: const BranchSnapshot(
      branchId: 'branch-penang',
      name: 'DoorDish Bukit Mertajam',
      stateCode: '07',
      latitude: 5.4110,
      longitude: 100.3150,
    ),
    deliveryAddressSnapshot: destination,
    subtotalSen: 1850,
    discountSen: 0,
    deliveryFeeSen: fulfilmentType == FulfilmentType.delivery ? 300 : 0,
    totalSen: fulfilmentType == FulfilmentType.delivery ? 2150 : 1850,
    items: [
      OrderItemSnapshot(
        foodId: 'food-burger',
        name: 'Classic Burger',
        quantity: 2,
        unitPriceSen: 925,
        selectedOptions: const {
          'customizations': [
            {'name': 'No onions', 'price': 0.0},
          ],
        },
        lineTotalSen: 1850,
        isStateSpecial: false,
      ),
    ],
    proofPhotoPath: null,
    deliveryComments: null,
    createdAt: now,
    updatedAt: now,
    completedAt: now,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reorders a covered delivery into the customer cart', () async {
    final result = await CustomerReorderService.addOrderToCart(
      order: _order(),
      currentAddress: const AddressOption(
        label: 'Home',
        fullAddress: 'Home, George Town, Pulau Pinang',
        state: 'Pulau Pinang',
        latitude: 5.4100,
        longitude: 100.3200,
      ),
    );

    final cart = await CartStorage.loadCart(_customerId);
    expect(result.itemCount, 2);
    expect(result.branchDistanceKm, lessThan(12));
    expect(cart, hasLength(1));
    expect(cart.single.id, 'food-burger');
    expect(cart.single.quantity, 2);
    expect(cart.single.customizations.single.name, 'No onions');
  });

  test('rejects a delivery outside the previous branch coverage', () async {
    final order = _order();
    final address = const AddressOption(
      label: 'Work',
      fullAddress: 'Work, Johor Bahru, Johor',
      state: 'Johor',
      latitude: 1.4927,
      longitude: 103.7414,
    );

    expect(
      () => CustomerReorderService.addOrderToCart(
        order: order,
        currentAddress: address,
      ),
      throwsA(isA<ReorderException>()),
    );
    expect(await CartStorage.loadCart(_customerId), isEmpty);
  });

  test('allows a pickup reorder without a delivery coordinate check', () async {
    await CustomerReorderService.addOrderToCart(
      order: _order(fulfilmentType: FulfilmentType.pickup),
    );

    final cart = await CartStorage.loadCart(_customerId);
    expect(cart.single.quantity, 2);
  });

  test('does not reorder an active order', () {
    expect(
      () => CustomerReorderService.addOrderToCart(
        order: _order(status: OrderStatus.preparing),
      ),
      throwsA(isA<ReorderException>()),
    );
  });

  testWidgets('completed order card enables and invokes Reorder', (
    tester,
  ) async {
    var called = false;
    final order = _order(fulfilmentType: FulfilmentType.pickup);
    final map = <String, dynamic>{
      'orderId': order.orderNumber,
      'date': '05 Sep 2026, 12:00 PM',
      'status': 'Completed',
      'items': [
        {'name': 'Classic Burger', 'quantity': 2, 'price': 9.25},
      ],
      'totalPrice': 'RM 18.50',
      'info': 'Delivered',
      'icon': Icons.fastfood,
      'typedOrder': order,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderCard(
            order: map,
            onReorder: (_) async {
              called = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Reorder'));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('order card displays the first food image when available', (
    tester,
  ) async {
    final order = _order(fulfilmentType: FulfilmentType.pickup);
    final map = <String, dynamic>{
      'orderId': order.orderNumber,
      'date': '05 Sep 2026, 12:00 PM',
      'status': 'Completed',
      'items': [
        {
          'name': 'Spicy Noodles',
          'quantity': 1,
          'price': 7.0,
          'imageUrl': 'https://example.com/spicy-noodles.jpg',
        },
      ],
      'totalPrice': 'RM 7.00',
      'info': 'Delivered',
      'icon': Icons.fastfood,
      'typedOrder': order,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderCard(order: map),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
  });
}
