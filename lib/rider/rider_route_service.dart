import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RiderRoute {
  final List<LatLng> points;
  final double distanceMetres;
  final Duration duration;

  RiderRoute({
    required List<LatLng> points,
    required this.distanceMetres,
    required this.duration,
  }) : points = List.unmodifiable(points) {
    if (this.points.length < 2) {
      throw const RiderRouteException('The route has too few coordinates.');
    }
    if (!distanceMetres.isFinite || distanceMetres < 0) {
      throw const RiderRouteException('The route distance is invalid.');
    }
    if (duration.isNegative) {
      throw const RiderRouteException('The route duration is invalid.');
    }
  }
}

class RiderRouteException implements Exception {
  final String message;

  const RiderRouteException(this.message);

  @override
  String toString() => message;
}

/// Fetches road geometry from the public OSRM demo service.
///
/// The service is suitable for coursework/demo traffic. A production app
/// should use a separately hosted or contractually supported routing backend.
class OsrmRiderRouteService {
  static const host = 'router.project-osrm.org';

  final http.Client httpClient;
  final bool _ownsHttpClient;

  OsrmRiderRouteService({http.Client? client})
    : httpClient = client ?? http.Client(),
      _ownsHttpClient = client == null;

  Future<RiderRoute> fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.https(
      host,
      '/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}',
      const {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
    );

    http.Response response;
    try {
      response = await httpClient
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const RiderRouteException('Road route request timed out.');
    } catch (_) {
      throw const RiderRouteException('Road route request failed.');
    }

    if (response.statusCode != 200) {
      throw RiderRouteException(
        'Road route returned HTTP ${response.statusCode}.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const RiderRouteException('Road route response was invalid.');
    }
    if (decoded is! Map) {
      throw const RiderRouteException('Road route response was malformed.');
    }
    if (decoded['code']?.toString() != 'Ok') {
      throw RiderRouteException(
        'No road route was found (${decoded['code'] ?? 'unknown'}).',
      );
    }

    final rawRoutes = decoded['routes'];
    if (rawRoutes is! List || rawRoutes.isEmpty || rawRoutes.first is! Map) {
      throw const RiderRouteException('No road route was found.');
    }
    final route = Map<String, dynamic>.from(rawRoutes.first as Map);
    final distance = _number(route['distance']);
    final durationSeconds = _number(route['duration']);
    final geometry = route['geometry'];
    if (distance == null || durationSeconds == null || geometry is! Map) {
      throw const RiderRouteException('Road route response was incomplete.');
    }
    final rawCoordinates = geometry['coordinates'];
    if (rawCoordinates is! List) {
      throw const RiderRouteException('Road route geometry was malformed.');
    }

    final points = <LatLng>[];
    for (final rawPoint in rawCoordinates) {
      if (rawPoint is! List || rawPoint.length < 2) {
        throw const RiderRouteException('Road route geometry was malformed.');
      }
      final longitude = _number(rawPoint[0]);
      final latitude = _number(rawPoint[1]);
      if (longitude == null || latitude == null) {
        throw const RiderRouteException('Road route geometry was malformed.');
      }
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        throw const RiderRouteException(
          'Road route geometry was out of range.',
        );
      }
      points.add(LatLng(latitude, longitude));
    }

    return RiderRoute(
      points: points,
      distanceMetres: distance,
      duration: Duration(seconds: durationSeconds.round()),
    );
  }

  void dispose() {
    if (_ownsHttpClient) {
      httpClient.close();
    }
  }
}

double? _number(Object? value) {
  if (value is num && value.toDouble().isFinite) {
    return value.toDouble();
  }
  final parsed = double.tryParse('$value');
  return parsed != null && parsed.isFinite ? parsed : null;
}
