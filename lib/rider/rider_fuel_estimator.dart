import 'package:mad_assignment/Order/order.dart';

import 'fuel_price_repository.dart';
import 'fuel_price_snapshot.dart';
import 'rider_fuel_estimate.dart';

class RiderFuelEstimator {
  static const motorcycleEfficiencyKmPerLitre = 35.0;

  const RiderFuelEstimator();

  RiderFuelEstimate calculate({
    required FulfilmentType fulfilmentType,
    required BranchSnapshot branch,
    required DeliveryAddressSnapshot? deliveryAddress,
    required FuelPriceSnapshot fuelPrice,
  }) {
    if (fulfilmentType == FulfilmentType.pickup) {
      return const RiderFuelEstimate.unavailable(
        'Fuel estimate is not applicable to pickup orders.',
      );
    }
    final branchLatitude = branch.latitude;
    final branchLongitude = branch.longitude;
    final addressLatitude = deliveryAddress?.latitude;
    final addressLongitude = deliveryAddress?.longitude;
    if (branchLatitude == null ||
        branchLongitude == null ||
        addressLatitude == null ||
        addressLongitude == null) {
      return const RiderFuelEstimate.unavailable(
        'Fuel estimate requires branch and delivery coordinates.',
      );
    }
    try {
      final distanceKm = haversineDistanceKm(
        startLatitude: branchLatitude,
        startLongitude: branchLongitude,
        endLatitude: addressLatitude,
        endLongitude: addressLongitude,
      );
      final fuelLitres = distanceKm / motorcycleEfficiencyKmPerLitre;
      final estimatedCostSen = roundCostSen(
        fuelPrice.ron95RinggitPerLitre,
        fuelLitres,
      );
      return RiderFuelEstimate.available(
        distanceKm: distanceKm,
        fuelLitres: fuelLitres,
        estimatedCostSen: estimatedCostSen,
        fuelPrice: fuelPrice,
      );
    } on OrderDataException catch (error) {
      return RiderFuelEstimate.unavailable(error.message);
    } on FuelPriceDataException catch (error) {
      return RiderFuelEstimate.unavailable(error.message);
    }
  }
}

class RiderFuelEstimateService {
  final FuelPriceRepository repository;
  final RiderFuelEstimator estimator;

  const RiderFuelEstimateService({
    required this.repository,
    this.estimator = const RiderFuelEstimator(),
  });

  Future<RiderFuelEstimate> forOrder(Order order) async {
    if (order.fulfilmentType == FulfilmentType.pickup) {
      return const RiderFuelEstimate.unavailable(
        'Fuel estimate is not applicable to pickup orders.',
      );
    }
    try {
      final fuelPrice = await repository.getLatest();
      return estimator.calculate(
        fulfilmentType: order.fulfilmentType,
        branch: order.branchSnapshot,
        deliveryAddress: order.deliveryAddressSnapshot,
        fuelPrice: fuelPrice,
      );
    } on FuelDataUnavailableException catch (error) {
      return RiderFuelEstimate.unavailable(error.message);
    }
  }
}
