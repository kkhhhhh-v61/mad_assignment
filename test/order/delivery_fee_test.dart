import 'package:flutter_test/flutter_test.dart';

import 'package:mad_assignment/Order/delivery_fee.dart';
import 'package:mad_assignment/Order/order.dart';
import 'package:mad_assignment/rider/fuel_price_repository.dart';
import 'package:mad_assignment/rider/fuel_price_snapshot.dart';

class FakeRouteProvider implements DeliveryRoadRouteProvider {
  final double? distanceKm;
  final DeliveryFeeException? failure;
  int calls = 0;

  FakeRouteProvider({this.distanceKm, this.failure});

  @override
  Future<double> fetchRoadDistanceKm({
    required BranchSnapshot branch,
    required DeliveryAddressSnapshot destination,
  }) async {
    calls++;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return distanceKm!;
  }
}

class FakeFuelPriceRepository implements FuelPriceRepository {
  final FuelPriceSnapshot snapshot;
  int calls = 0;

  FakeFuelPriceRepository(this.snapshot);

  @override
  Future<FuelPriceSnapshot> getLatest({bool forceRefresh = false}) async {
    calls++;
    return snapshot;
  }
}

void main() {
  const branch = BranchSnapshot(
    branchId: 'branch-kl',
    name: 'Kuala Lumpur Branch',
    stateCode: 'WPKL',
    latitude: 3.139,
    longitude: 101.6869,
  );
  const destination = DeliveryAddressSnapshot(
    label: 'Home',
    formattedAddress: '1 Jalan Test, Kuala Lumpur',
    stateCode: 'WPKL',
    latitude: 3.149,
    longitude: 101.6969,
  );
  final fuelPrice = FuelPriceSnapshot(
    ron95RinggitPerLitre: 3.77,
    effectiveDate: DateTime.utc(2026, 9, 3),
    fetchedAt: DateTime.utc(2026, 9, 4),
    sourceUrl: 'https://data.gov.my/data-catalogue/fuelprice',
    isFromCache: false,
  );

  test('route success produces a one-way road-based fee quote', () async {
    final routes = FakeRouteProvider(distanceKm: 8.0);
    final prices = FakeFuelPriceRepository(fuelPrice);
    final service = RoadDeliveryFeeService(
      routeProvider: routes,
      fuelPriceRepository: prices,
    );

    final quote = await service.quote(branch: branch, destination: destination);

    expect(routes.calls, 1);
    expect(prices.calls, 1);
    expect(quote.oneWayRoadDistanceKm, 8.0);
    expect(quote.chargedRoadDistanceKm, 8.0);
    expect(quote.fuelCostSen, 86);
    expect(quote.deliveryFeeSen, 386);
    expect(quote.returnRequired, isFalse);
  });

  test('no route blocks the quote before reading the fuel price', () async {
    final routes = FakeRouteProvider(
      failure: const DeliveryRouteUnavailableException('No road route found.'),
    );
    final prices = FakeFuelPriceRepository(fuelPrice);
    final service = RoadDeliveryFeeService(
      routeProvider: routes,
      fuelPriceRepository: prices,
    );

    expect(
      service.quote(branch: branch, destination: destination),
      throwsA(isA<DeliveryRouteUnavailableException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(prices.calls, 0);
  });

  test('fee calculation uses the government fuel price and rounds to sen', () {
    const calculator = RoadDeliveryFeeCalculator();

    final quote = calculator.calculate(
      oneWayRoadDistanceKm: 8.0,
      fuelPrice: fuelPrice,
    );

    expect(quote.fuelLitres, closeTo(8 / 35, 0.000001));
    expect(quote.fuelCostSen, 86);
    expect(quote.deliveryFeeSen, 386);
  });

  test('explicit return trip doubles the charged road distance', () async {
    final service = RoadDeliveryFeeService(
      routeProvider: FakeRouteProvider(distanceKm: 8.0),
      fuelPriceRepository: FakeFuelPriceRepository(fuelPrice),
    );

    final quote = await service.quote(
      branch: branch,
      destination: destination,
      returnRequired: true,
    );

    expect(quote.oneWayRoadDistanceKm, 8.0);
    expect(quote.chargedRoadDistanceKm, 16.0);
    expect(quote.fuelCostSen, 172);
    expect(quote.deliveryFeeSen, 472);
    expect(quote.returnRequired, isTrue);
  });

  test('road routes over 10 kilometres are rejected', () async {
    final prices = FakeFuelPriceRepository(fuelPrice);
    final service = RoadDeliveryFeeService(
      routeProvider: FakeRouteProvider(distanceKm: 10.01),
      fuelPriceRepository: prices,
    );

    expect(
      service.quote(branch: branch, destination: destination),
      throwsA(isA<DeliveryDistanceLimitException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(prices.calls, 0);
  });
}
