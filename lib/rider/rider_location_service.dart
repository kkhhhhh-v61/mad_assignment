import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Order/order.dart';

abstract interface class LocationProvider {
  Future<bool> isServiceEnabled();

  Future<LocationPermission> checkPermission();

  Future<LocationPermission> requestPermission();

  Stream<Position> watchPosition();
}

class GeolocatorLocationProvider implements LocationProvider {
  const GeolocatorLocationProvider();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    );
  }
}

class RiderLocation {
  final String orderId;
  final String riderId;
  final double latitude;
  final double longitude;
  final double accuracyMetres;
  final DateTime recordedAt;

  RiderLocation({
    required this.orderId,
    required this.riderId,
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    required this.recordedAt,
  }) {
    if (orderId.trim().isEmpty || riderId.trim().isEmpty) {
      throw const InvalidOrderException('Location identity is required.');
    }
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const InvalidOrderException('Location coordinates are invalid.');
    }
    if (!accuracyMetres.isFinite || accuracyMetres < 0) {
      throw const InvalidOrderException('Location accuracy is invalid.');
    }
  }

  factory RiderLocation.fromJson(Map<String, dynamic> json) {
    return RiderLocation(
      orderId: _requiredString(json, const ['order_id', 'orderId']),
      riderId: _requiredString(json, const ['rider_id', 'riderId']),
      latitude: _requiredDouble(json, const ['latitude']),
      longitude: _requiredDouble(json, const ['longitude']),
      accuracyMetres: _requiredDouble(json, const [
        'accuracy_metres',
        'accuracyMetres',
      ]),
      recordedAt: _requiredDate(json, const ['recorded_at', 'recordedAt']),
    );
  }

  factory RiderLocation.fromPosition({
    required String orderId,
    required String riderId,
    required Position position,
    DateTime Function()? now,
  }) {
    return RiderLocation(
      orderId: orderId,
      riderId: riderId,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMetres: position.accuracy,
      recordedAt: (now ?? DateTime.now)().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'rider_id': riderId,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy_metres': accuracyMetres,
    'recorded_at': recordedAt.toUtc().toIso8601String(),
  };
}

class LocationUnavailableException implements Exception {
  final String message;

  const LocationUnavailableException(this.message);

  @override
  String toString() => message;
}

class RiderLocationService {
  final LocationProvider provider;

  const RiderLocationService({
    this.provider = const GeolocatorLocationProvider(),
  });

  Future<Stream<RiderLocation>> start({
    required String orderId,
    required String riderId,
  }) async {
    if (!await provider.isServiceEnabled()) {
      throw const LocationUnavailableException(
        'Location services are disabled.',
      );
    }
    var permission = await provider.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await provider.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationUnavailableException(
        'Location permission was denied.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationUnavailableException(
        'Location permission is permanently denied. Enable it in app settings.',
      );
    }
    if (permission == LocationPermission.unableToDetermine) {
      throw const LocationUnavailableException(
        'Location permission could not be determined.',
      );
    }
    return provider.watchPosition().map(
      (position) => RiderLocation.fromPosition(
        orderId: orderId,
        riderId: riderId,
        position: position,
      ),
    );
  }
}

abstract interface class RiderLocationRepository {
  Future<RiderLocation> updateLocation(RiderLocation location);

  Stream<RiderLocation> watchLocation(String orderId);
}

class SupabaseRiderLocationRepository implements RiderLocationRepository {
  final SupabaseClient client;

  const SupabaseRiderLocationRepository(this.client);

  @override
  Future<RiderLocation> updateLocation(RiderLocation location) async {
    final response = await client.rpc(
      'update_rider_location',
      params: {
        'p_order_id': location.orderId,
        'p_latitude': location.latitude,
        'p_longitude': location.longitude,
        'p_accuracy_metres': location.accuracyMetres,
        'p_recorded_at': location.recordedAt.toUtc().toIso8601String(),
      },
    );
    if (response is Map) {
      return RiderLocation.fromJson(Map<String, dynamic>.from(response));
    }
    if (response is List && response.isNotEmpty && response.first is Map) {
      return RiderLocation.fromJson(
        Map<String, dynamic>.from(response.first as Map),
      );
    }
    throw const LocationUnavailableException(
      'Location response was malformed.',
    );
  }

  @override
  Stream<RiderLocation> watchLocation(String orderId) {
    final controller = StreamController<RiderLocation>();
    final channel = client
        .channel(
          'rider-location-$orderId-${DateTime.now().microsecondsSinceEpoch}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rider_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isNotEmpty && !controller.isClosed) {
              try {
                controller.add(RiderLocation.fromJson(row));
              } catch (error, stackTrace) {
                controller.addError(error, stackTrace);
              }
            }
          },
        )
        .subscribe();
    controller.onCancel = () async {
      await channel.unsubscribe();
      await controller.close();
    };
    return controller.stream;
  }
}

class RiderLocationUploader {
  final RiderLocationRepository repository;
  final DateTime Function() now;
  RiderLocation? _lastUploaded;
  DateTime? _lastUploadedAt;

  RiderLocationUploader({required this.repository, DateTime Function()? now})
    : now = now ?? DateTime.now;

  Future<bool> uploadIfDue(RiderLocation location) async {
    final previous = _lastUploaded;
    final previousTime = _lastUploadedAt;
    final movedMetres = previous == null
        ? double.infinity
        : haversineDistanceKm(
                startLatitude: previous.latitude,
                startLongitude: previous.longitude,
                endLatitude: location.latitude,
                endLongitude: location.longitude,
              ) *
              1000;
    final elapsed = previousTime == null
        ? const Duration(days: 1)
        : now().difference(previousTime);
    if (previous != null &&
        movedMetres < 20 &&
        elapsed < const Duration(seconds: 10)) {
      return false;
    }
    await repository.updateLocation(location);
    _lastUploaded = location;
    _lastUploadedAt = now();
    return true;
  }
}

String _requiredString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  throw const LocationUnavailableException('Location text field is missing.');
}

double _requiredDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num && value.toDouble().isFinite) {
      return value.toDouble();
    }
  }
  throw const LocationUnavailableException('Location number field is invalid.');
}

DateTime _requiredDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final parsed = value is DateTime ? value : DateTime.tryParse('$value');
    if (parsed != null) {
      return parsed.toUtc();
    }
  }
  throw const LocationUnavailableException('Location timestamp is invalid.');
}
