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

  test('card payment uses the exact values and method reference', () {
    const paymentMethodId = '11111111-1111-1111-1111-111111111111';
    final submission = OrderSubmission(
      orderNumber: 'ORD-1006',
      paymentIdempotencyKey: 'payment-1006',
      paymentType: 'Card',
      paymentStatus: 'Completed',
      paymentMethodId: paymentMethodId,
      fulfilmentType: FulfilmentType.delivery,
      branchSnapshot: branch,
      deliveryAddressSnapshot: address,
      subtotalSen: 2500,
      discountSen: 200,
      deliveryFeeSen: 300,
      totalSen: 2600,
      items: [item],
    );

    expect(submission.hasPaymentDetails, isTrue);
    expect(
      submission.toPaymentRpcParams(),
      containsPair('p_payment_type', 'Card'),
    );
    expect(
      submission.toPaymentRpcParams(),
      containsPair('p_payment_status', 'Completed'),
    );
    expect(
      submission.toPaymentRpcParams(),
      containsPair('p_payment_method_id', paymentMethodId),
    );
  });

  test('COD payment keeps payment method reference null', () {
    final submission = OrderSubmission(
      orderNumber: 'ORD-1007',
      paymentIdempotencyKey: 'payment-1007',
      paymentType: 'COD',
      paymentStatus: 'Pending',
      fulfilmentType: FulfilmentType.delivery,
      branchSnapshot: branch,
      deliveryAddressSnapshot: address,
      subtotalSen: 2500,
      discountSen: 200,
      deliveryFeeSen: 300,
      totalSen: 2600,
      items: [item],
    );

    expect(
      submission.toPaymentRpcParams(),
      containsPair('p_payment_method_id', isNull),
    );
  });

  test('payment contract rejects unsupported or inconsistent values', () {
    expect(supportedPaymentTypes, {'COD', 'Card'});
    expect(
      () => OrderSubmission(
        orderNumber: 'ORD-1008',
        paymentIdempotencyKey: 'payment-1008',
        paymentType: 'Cash',
        paymentStatus: 'Pending',
        fulfilmentType: FulfilmentType.delivery,
        branchSnapshot: branch,
        deliveryAddressSnapshot: address,
        subtotalSen: 2500,
        discountSen: 200,
        deliveryFeeSen: 300,
        totalSen: 2600,
        items: [item],
      ),
      throwsA(isA<InvalidOrderException>()),
    );
    expect(
      () => OrderSubmission(
        orderNumber: 'ORD-1009',
        paymentIdempotencyKey: 'payment-1009',
        paymentType: 'Card',
        paymentStatus: 'Completed',
        fulfilmentType: FulfilmentType.delivery,
        branchSnapshot: branch,
        deliveryAddressSnapshot: address,
        subtotalSen: 2500,
        discountSen: 200,
        deliveryFeeSen: 300,
        totalSen: 2600,
        items: [item],
      ),
      throwsA(isA<InvalidOrderException>()),
    );
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

  test('delivery distance policy allows the 12 kilometre road boundary', () {
    expect(
      () => DeliveryDistancePolicy.ensureRoadDistanceWithinLimit(
        roadDistanceKm: 12.0,
      ),
      returnsNormally,
    );
  });

  test('delivery distance policy rejects addresses beyond 12 kilometres', () {
    final farAddress = const DeliveryAddressSnapshot(
      label: 'Far away',
      formattedAddress: 'Far away from the branch',
      stateCode: 'WPKL',
      latitude: 3.25,
      longitude: 101.6869,
    );

    expect(
      DeliveryDistancePolicy.estimateKm(
        branch: branch,
        destination: farAddress,
      ),
      greaterThan(DeliveryDistancePolicy.maximumDistanceKm),
    );
    expect(
      () => OrderSubmission(
        orderNumber: 'ORD-1003',
        paymentIdempotencyKey: 'payment-1003',
        fulfilmentType: FulfilmentType.delivery,
        branchSnapshot: branch,
        deliveryAddressSnapshot: farAddress,
        subtotalSen: 2500,
        discountSen: 200,
        deliveryFeeSen: 300,
        totalSen: 2600,
        items: [item],
      ),
      throwsA(isA<InvalidOrderException>()),
    );
  });

  test('delivery distance policy requires coordinates for validation', () {
    final addressWithoutCoordinates = const DeliveryAddressSnapshot(
      label: 'Unknown',
      formattedAddress: 'Coordinates not available',
      stateCode: 'WPKL',
    );

    expect(
      () => OrderSubmission(
        orderNumber: 'ORD-1004',
        paymentIdempotencyKey: 'payment-1004',
        fulfilmentType: FulfilmentType.delivery,
        branchSnapshot: branch,
        deliveryAddressSnapshot: addressWithoutCoordinates,
        subtotalSen: 2500,
        discountSen: 200,
        deliveryFeeSen: 300,
        totalSen: 2600,
        items: [item],
      ),
      throwsA(isA<InvalidOrderException>()),
    );
  });

  test('routed submissions reject road routes beyond 12 kilometres', () {
    expect(
      () => OrderSubmission(
        orderNumber: 'ORD-1005',
        paymentIdempotencyKey: 'payment-1005',
        fulfilmentType: FulfilmentType.delivery,
        branchSnapshot: branch,
        deliveryAddressSnapshot: address,
        subtotalSen: 2500,
        discountSen: 200,
        deliveryFeeSen: 300,
        totalSen: 2600,
        roadDistanceKm: 12.01,
        items: [item],
      ),
      throwsA(isA<DeliveryDistanceLimitException>()),
    );
  });
}
