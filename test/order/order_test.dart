import 'package:flutter_test/flutter_test.dart';

import 'package:mad_assignment/Order/order.dart';

void main() {
  final branch = const BranchSnapshot(
    branchId: 'branch-kl',
    name: 'Kuala Lumpur Branch',
    stateCode: 'WPKL',
    latitude: 3.139,
    longitude: 101.6869,
  );
  final address = const DeliveryAddressSnapshot(
    label: 'Home',
    formattedAddress: '1 Jalan Test, Kuala Lumpur',
    stateCode: 'WPKL',
    latitude: 3.149,
    longitude: 101.6969,
  );
  final item = OrderItemSnapshot(
    foodId: 'combo-wpkl',
    name: 'Kuala Lumpur Combo',
    quantity: 2,
    unitPriceSen: 1250,
    selectedOptions: const {'drink': 'tea'},
    lineTotalSen: 2500,
    isStateSpecial: true,
    specialStateCode: 'WPKL',
  );

  test('valid submission preserves money and state-special item data', () {
    final submission = OrderSubmission(
      orderNumber: 'ORD-1001',
      paymentIdempotencyKey: 'payment-1001',
      fulfilmentType: FulfilmentType.delivery,
      branchSnapshot: branch,
      deliveryAddressSnapshot: address,
      subtotalSen: 2500,
      discountSen: 200,
      deliveryFeeSen: 300,
      totalSen: 2600,
      items: [item],
    );

    expect(submission.items.single.specialStateCode, 'WPKL');
    expect(submission.toRpcParams()['p_total_sen'], 2600);
  });

  test('invalid total is rejected before a repository call', () {
    expect(
      () => OrderSubmission(
        orderNumber: 'ORD-1002',
        paymentIdempotencyKey: 'payment-1002',
        fulfilmentType: FulfilmentType.delivery,
        branchSnapshot: branch,
        deliveryAddressSnapshot: address,
        subtotalSen: 2500,
        discountSen: 200,
        deliveryFeeSen: 300,
        totalSen: 2500,
        items: [item],
      ),
      throwsA(isA<InvalidOrderException>()),
    );
  });

  test('rider can only advance an assigned delivery in order', () {
    expect(
      OrderTransitionPolicy.isAllowed(
        current: OrderStatus.ready,
        next: OrderStatus.pickedUp,
        fulfilmentType: FulfilmentType.delivery,
        actorRole: 'rider',
        isOwner: false,
        isAssignedRider: true,
      ),
      isTrue,
    );
    expect(
      OrderTransitionPolicy.isAllowed(
        current: OrderStatus.ready,
        next: OrderStatus.delivering,
        fulfilmentType: FulfilmentType.delivery,
        actorRole: 'rider',
        isOwner: false,
        isAssignedRider: true,
      ),
      isFalse,
    );
  });

  test('haversine distance validates coordinates and returns kilometres', () {
    final distance = haversineDistanceKm(
      startLatitude: 0,
      startLongitude: 0,
      endLatitude: 1,
      endLongitude: 0,
    );

    expect(distance, closeTo(111.195, 0.01));
    expect(
      () => haversineDistanceKm(
        startLatitude: 91,
        startLongitude: 0,
        endLatitude: 0,
        endLongitude: 0,
      ),
      throwsA(isA<InvalidOrderException>()),
    );
  });
}
