import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

import 'package:mad_assignment/rider/rider_route_service.dart';

void main() {
  test('parses an OSRM road geometry, distance, and duration', () async {
    Uri? requestedUri;
    final service = OsrmRiderRouteService(
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 1840.5,
                'duration': 312.2,
                'geometry': {
                  'coordinates': [
                    [101.6869, 3.1390],
                    [101.6900, 3.1420],
                    [101.7000, 3.1600],
                  ],
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final route = await service.fetchRoute(
      origin: const LatLng(3.1390, 101.6869),
      destination: const LatLng(3.1600, 101.7000),
    );

    expect(requestedUri?.host, OsrmRiderRouteService.host);
    expect(requestedUri?.path, contains('/route/v1/driving/'));
    expect(requestedUri?.queryParameters['geometries'], 'geojson');
    expect(route.points, [
      const LatLng(3.1390, 101.6869),
      const LatLng(3.1420, 101.6900),
      const LatLng(3.1600, 101.7000),
    ]);
    expect(route.distanceMetres, 1840.5);
    expect(route.duration, const Duration(seconds: 312));
  });

  test('reports a no-route response as a typed failure', () async {
    final service = OsrmRiderRouteService(
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'code': 'NoRoute', 'routes': []}), 200),
      ),
    );

    expect(
      service.fetchRoute(
        origin: const LatLng(3.1390, 101.6869),
        destination: const LatLng(3.1600, 101.7000),
      ),
      throwsA(isA<RiderRouteException>()),
    );
  });
}
