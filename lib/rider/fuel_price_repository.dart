import 'fuel_price_snapshot.dart';

abstract interface class FuelPriceRepository {
  Future<FuelPriceSnapshot> getLatest({bool forceRefresh = false});
}
