import 'package:flutter_test/flutter_test.dart';

import 'package:mad_assignment/Order/order.dart';
import 'package:mad_assignment/customer/order_details.dart';

Order _orderWithStatus(OrderStatus status) {
  final now = DateTime.utc(2026, 9, 5);
  return Order(
    id: 'order-1',
    orderNumber: 'ORD-1',
    paymentIdempotencyKey: 'checkout-1',
    customerId: 'customer-1',
    riderId: null,
    fulfilmentType: FulfilmentType.pickup,
    status: status,
    branchSnapshot: const BranchSnapshot(
      branchId: 'branch-1',
      name: 'DoorDish Test',
      stateCode: '07',
    ),
    deliveryAddressSnapshot: null,
    subtotalSen: 1000,
    discountSen: 0,
    deliveryFeeSen: 0,
    totalSen: 1000,
    items: [
      OrderItemSnapshot(
        foodId: 'food-1',
        name: 'Test meal',
        quantity: 1,
        unitPriceSen: 1000,
        selectedOptions: const {},
        lineTotalSen: 1000,
        isStateSpecial: false,
      ),
    ],
    proofPhotoPath: null,
    deliveryComments: null,
    createdAt: now,
    updatedAt: now,
    completedAt: null,
  );
}

void main() {
  test('order details accepts dynamic item maps from customer orders', () {
    final orderDetails = OrderDetails(
      order: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Classic Beef Burger',
            'quantity': 2,
            'price': 16.90,
            'imageUrl': null,
          },
        ],
      },
    );

    expect(orderDetails.itemsList, hasLength(1));
    expect(orderDetails.itemsList.single['name'], 'Classic Beef Burger');
    expect(orderDetails.itemsList.single['quantity'], 2);
  });

  test(
    'order details exposes the rider proof path for the customer viewer',
    () {
      const proofPath =
          'c4d3a211-6b2e-4f11-8c55-2e7d9f3a6101/'
          '9e6a2b44-7f51-4b90-8d32-1a5c6e7f8091.jpg';
      final orderDetails = OrderDetails(
        order: <String, dynamic>{'proofPhotoPath': proofPath},
      );

      expect(orderDetails.proofPhotoPath, proofPath);
    },
  );

  test('only placed orders expose the customer cancel action', () {
    final placed = OrderDetails(
      order: <String, dynamic>{
        'typedOrder': _orderWithStatus(OrderStatus.placed),
      },
    );
    final preparing = OrderDetails(
      order: <String, dynamic>{
        'typedOrder': _orderWithStatus(OrderStatus.preparing),
      },
    );

    expect(placed.canCancel, isTrue);
    expect(preparing.canCancel, isFalse);
  });
}
