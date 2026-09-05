import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Coordinates captured from an OSM address selection.
///
/// The current hosted address tables store the formatted address text only, so
/// this small device-local cache keeps the coordinates that were returned by
/// OSM until Checkout copies them into the order snapshot.
class AddressCoordinates {
  final double latitude;
  final double longitude;

  const AddressCoordinates({required this.latitude, required this.longitude});
}

class AddressCoordinateCache {
  static const _preferencesKey = 'doordish.address_coordinates.v1';

  static Future<Map<String, AddressCoordinates>> loadAll() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_preferencesKey);
      if (raw == null || raw.trim().isEmpty) return {};

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};

      final result = <String, AddressCoordinates>{};
      for (final entry in decoded.entries) {
        final address = entry.key.toString().trim();
        final value = entry.value;
        if (address.isEmpty || value is! Map) continue;
        final latitude = double.tryParse('${value['latitude']}');
        final longitude = double.tryParse('${value['longitude']}');
        if (_validCoordinate(latitude, longitude)) {
          result[address] = AddressCoordinates(
            latitude: latitude!,
            longitude: longitude!,
          );
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> save({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final key = address.trim();
    if (key.isEmpty || !_validCoordinate(latitude, longitude)) return;

    final values = await loadAll();
    values[key] = AddressCoordinates(latitude: latitude, longitude: longitude);
    await _write(values);
  }

  static Future<void> remove(String address) async {
    final key = address.trim();
    if (key.isEmpty) return;
    final values = await loadAll();
    if (!values.containsKey(key)) return;
    values.remove(key);
    await _write(values);
  }

  static Future<void> _write(Map<String, AddressCoordinates> values) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = <String, Map<String, double>>{};
      for (final entry in values.entries) {
        encoded[entry.key] = {
          'latitude': entry.value.latitude,
          'longitude': entry.value.longitude,
        };
      }
      await preferences.setString(_preferencesKey, jsonEncode(encoded));
    } catch (_) {
      // A local cache failure must not prevent a valid address from saving.
    }
  }

  static bool _validCoordinate(double? latitude, double? longitude) {
    return latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}
