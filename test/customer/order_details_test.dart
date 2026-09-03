import 'package:flutter_test/flutter_test.dart';

import 'package:mad_assignment/customer/order_details.dart';

void main() {
  test('order details accepts dynamic item maps from customer orders', () {
    final orderDetails = OrderDetails(
      order: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Classic Beef Burger',
            'quantity': 2,
            'price': 16.90,
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
}
