import 'fuel_price_snapshot.dart';

class RiderFuelEstimate {
  final double? distanceKm;
  final double? fuelLitres;
  final int? estimatedCostSen;
  final FuelPriceSnapshot? fuelPrice;
  final String? unavailableReason;

  const RiderFuelEstimate.available({
    required this.distanceKm,
    required this.fuelLitres,
    required this.estimatedCostSen,
    required this.fuelPrice,
  }) : unavailableReason = null;

  const RiderFuelEstimate.unavailable(this.unavailableReason)
    : distanceKm = null,
      fuelLitres = null,
      estimatedCostSen = null,
      fuelPrice = null;

  bool get isAvailable => unavailableReason == null;

  bool get isFromCache => fuelPrice?.isFromCache ?? false;

  String get sourceUrl => fuelPrice?.sourceUrl ?? '';

  DateTime? get effectiveDate => fuelPrice?.effectiveDate;
}
