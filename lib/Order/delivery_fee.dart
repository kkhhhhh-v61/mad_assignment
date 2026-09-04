import 'package:latlong2/latlong.dart';

import '../rider/fuel_price_repository.dart';
import '../rider/fuel_price_snapshot.dart';
import '../rider/rider_route_service.dart';
import 'order.dart';

abstract interface class DeliveryRoadRouteProvider {
  Future<double> fetchRoadDistanceKm({
    required BranchSnapshot branch,
    required DeliveryAddressSnapshot destination,
  });
}

class OsrmDeliveryRoadRouteProvider implements DeliveryRoadRouteProvider {
  final OsrmRiderRouteService routeService;
  final bool _ownsRouteService;

  OsrmDeliveryRoadRouteProvider({OsrmRiderRouteService? routeService})
    : routeService = routeService ?? OsrmRiderRouteService(),
      _ownsRouteService = routeService == null;

  @override
  Future<double> fetchRoadDistanceKm({
    required BranchSnapshot branch,
    required DeliveryAddressSnapshot destination,
  }) async {
    final origin = _toLatLng(branch.latitude, branch.longitude);
    final target = _toLatLng(destination.latitude, destination.longitude);
    if (origin == null || target == null) {
      throw const DeliveryRouteUnavailableException(
        'Branch and delivery coordinates are required to calculate the road route.',
      );
    }

    try {
      final route = await routeService.fetchRoute(
        origin: origin,
        destination: target,
      );
      final distanceKm = route.distanceMetres / 1000.0;
      if (!distanceKm.isFinite || distanceKm < 0) {
        throw const DeliveryRouteUnavailableException(
          'The road route distance was invalid.',
        );
      }
      return distanceKm;
    } on RiderRouteException catch (error) {
      throw DeliveryRouteUnavailableException(error.message);
    }
  }

  void dispose() {
    if (_ownsRouteService) {
      routeService.dispose();
    }
  }
}

class RoadDeliveryFeeCalculator {
  static const baseFeeSen = 300;
  static const motorcycleEfficiencyKmPerLitre = 35.0;

  const RoadDeliveryFeeCalculator();

  DeliveryFeeQuote calculate({
    required double oneWayRoadDistanceKm,
    required FuelPriceSnapshot fuelPrice,
    bool returnRequired = false,
  }) {
    if (!oneWayRoadDistanceKm.isFinite || oneWayRoadDistanceKm < 0) {
      throw const DeliveryFeeException('Road distance must be non-negative.');
    }

    final legs = returnRequired ? 2 : 1;
    final chargedDistanceKm = oneWayRoadDistanceKm * legs;
    final fuelLitres = chargedDistanceKm / motorcycleEfficiencyKmPerLitre;
    final fuelCostSen = roundCostSen(
      fuelPrice.ron95RinggitPerLitre,
      fuelLitres,
    );
    return DeliveryFeeQuote(
      oneWayRoadDistanceKm: oneWayRoadDistanceKm,
      chargedRoadDistanceKm: chargedDistanceKm,
      fuelLitres: fuelLitres,
      fuelCostSen: fuelCostSen,
      deliveryFeeSen: baseFeeSen + fuelCostSen,
      fuelPrice: fuelPrice,
      returnRequired: returnRequired,
    );
  }
}

class RoadDeliveryFeeService {
  final DeliveryRoadRouteProvider routeProvider;
  final FuelPriceRepository fuelPriceRepository;
  final RoadDeliveryFeeCalculator calculator;

  const RoadDeliveryFeeService({
    required this.routeProvider,
    required this.fuelPriceRepository,
    this.calculator = const RoadDeliveryFeeCalculator(),
  });

  Future<DeliveryFeeQuote> quote({
    required BranchSnapshot branch,
    required DeliveryAddressSnapshot destination,
    bool returnRequired = false,
  }) async {
    final roadDistanceKm = await routeProvider.fetchRoadDistanceKm(
      branch: branch,
      destination: destination,
    );
    DeliveryDistancePolicy.ensureRoadDistanceWithinLimit(
      roadDistanceKm: roadDistanceKm,
    );
    final fuelPrice = await fuelPriceRepository.getLatest();
    return calculator.calculate(
      oneWayRoadDistanceKm: roadDistanceKm,
      fuelPrice: fuelPrice,
      returnRequired: returnRequired,
    );
  }
}

class DeliveryFeeQuote {
  final double oneWayRoadDistanceKm;
  final double chargedRoadDistanceKm;
  final double fuelLitres;
  final int fuelCostSen;
  final int deliveryFeeSen;
  final FuelPriceSnapshot fuelPrice;
  final bool returnRequired;

  const DeliveryFeeQuote({
    required this.oneWayRoadDistanceKm,
    required this.chargedRoadDistanceKm,
    required this.fuelLitres,
    required this.fuelCostSen,
    required this.deliveryFeeSen,
    required this.fuelPrice,
    required this.returnRequired,
  });
}

class DeliveryFeeException implements Exception {
  final String message;

  const DeliveryFeeException(this.message);

  @override
  String toString() => message;
}

class DeliveryRouteUnavailableException extends DeliveryFeeException {
  const DeliveryRouteUnavailableException(super.message);
}

LatLng? _toLatLng(double? latitude, double? longitude) {
  if (latitude == null ||
      longitude == null ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    return null;
  }
  return LatLng(latitude, longitude);
}
