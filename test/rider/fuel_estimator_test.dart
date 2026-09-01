import 'package:flutter_test/flutter_test.dart';

import 'package:mad_assignment/Order/order.dart';
import 'package:mad_assignment/rider/fuel_price_snapshot.dart';
import 'package:mad_assignment/rider/rider_fuel_estimator.dart';

void main() {
  final branch = const BranchSnapshot(
    branchId: 'branch-test',
    name: 'Test Branch',
    stateCode: 'WPKL',
    latitude: 0,
    longitude: 0,
  );
  final address = const DeliveryAddressSnapshot(
    label: 'Home',
    formattedAddress: 'Test address',
    stateCode: 'WPKL',
    latitude: 1,
    longitude: 0,
  );
  final fuelPrice = FuelPriceSnapshot(
    ron95RinggitPerLitre: 2.05,
    effectiveDate: DateTime.utc(2026, 9, 1),
    fetchedAt: DateTime.utc(2026, 9, 1, 10),
    sourceUrl: 'https://data.gov.my/data-catalogue/fuelprice',
    isFromCache: false,
  );

  test('estimator calculates one-way distance, litres, and cost', () {
    final result = const RiderFuelEstimator().calculate(
      fulfilmentType: FulfilmentType.delivery,
      branch: branch,
      deliveryAddress: address,
      fuelPrice: fuelPrice,
    );

    expect(result.isAvailable, isTrue);
    expect(result.distanceKm, closeTo(111.195, 0.01));
    expect(result.fuelLitres, closeTo(111.195 / 35, 0.001));
    expect(result.estimatedCostSen, closeTo(651, 2));
  });

  test('pickup orders do not receive a fabricated fuel estimate', () {
    final result = const RiderFuelEstimator().calculate(
      fulfilmentType: FulfilmentType.pickup,
      branch: branch,
      deliveryAddress: null,
      fuelPrice: fuelPrice,
    );

    expect(result.isAvailable, isFalse);
    expect(result.unavailableReason, contains('not applicable'));
  });

  test('fuel cache freshness rejects future and stale snapshots', () {
    expect(fuelPrice.isFresh(now: DateTime.utc(2026, 9, 1, 20)), isTrue);
    expect(fuelPrice.isFresh(now: DateTime.utc(2026, 9, 2, 11)), isFalse);
    expect(fuelPrice.isFresh(now: DateTime.utc(2026, 9, 1, 9)), isFalse);
  });
}
