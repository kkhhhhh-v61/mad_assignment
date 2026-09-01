import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mad_assignment/rider/rider_location_service.dart';

class RecordingLocationRepository implements RiderLocationRepository {
  final List<RiderLocation> updates = [];

  @override
  Future<RiderLocation> updateLocation(RiderLocation location) async {
    updates.add(location);
    return location;
  }

  @override
  Stream<RiderLocation> watchLocation(String orderId) => const Stream.empty();
}

void main() {
  test(
    'location uploader throttles small movements and short intervals',
    () async {
      var now = DateTime.utc(2026, 9, 1, 12);
      final repository = RecordingLocationRepository();
      final uploader = RiderLocationUploader(
        repository: repository,
        now: () => now,
      );
      final first = RiderLocation(
        orderId: 'order-1',
        riderId: 'rider-1',
        latitude: 3.139,
        longitude: 101.687,
        accuracyMetres: 8,
        recordedAt: now,
      );
      final nearby = RiderLocation(
        orderId: 'order-1',
        riderId: 'rider-1',
        latitude: 3.13901,
        longitude: 101.68701,
        accuracyMetres: 8,
        recordedAt: now.add(const Duration(seconds: 5)),
      );

      expect(await uploader.uploadIfDue(first), isTrue);
      expect(await uploader.uploadIfDue(nearby), isFalse);
      expect(repository.updates, hasLength(1));

      now = now.add(const Duration(seconds: 11));
      expect(await uploader.uploadIfDue(nearby), isTrue);
      expect(repository.updates, hasLength(2));
    },
  );

  test(
    'location service reports disabled service and denied permission',
    () async {
      final disabled = RiderLocationService(
        provider: StubLocationProvider(serviceEnabled: false),
      );
      expect(
        disabled.start(orderId: 'order-1', riderId: 'rider-1'),
        throwsA(isA<LocationUnavailableException>()),
      );

      final denied = RiderLocationService(
        provider: StubLocationProvider(
          serviceEnabled: true,
          permission: LocationPermission.denied,
        ),
      );
      expect(
        denied.start(orderId: 'order-1', riderId: 'rider-1'),
        throwsA(isA<LocationUnavailableException>()),
      );
    },
  );
}

class StubLocationProvider implements LocationProvider {
  final bool serviceEnabled;
  final LocationPermission permission;

  const StubLocationProvider({
    required this.serviceEnabled,
    this.permission = LocationPermission.deniedForever,
  });

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Stream<Position> watchPosition() => const Stream.empty();
}
