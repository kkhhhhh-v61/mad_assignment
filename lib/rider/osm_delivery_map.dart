import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Order/order.dart';
import 'rider_location_service.dart';

class OsmMapConfig {
  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const copyrightUrl = 'https://www.openstreetmap.org/copyright';
  static const userAgentPackageName = 'my.edu.tarumt.mad_assignment';
  static const fallbackCenter = LatLng(3.1390, 101.6869);
}

class OsmDeliveryMap extends StatefulWidget {
  final BranchSnapshot branch;
  final DeliveryAddressSnapshot? destination;
  final RiderLocation? riderLocation;
  final List<LatLng>? roadRoute;
  final bool roadRouteLoading;
  final bool showEstimatedLine;
  final ValueChanged<Object>? onTileError;

  const OsmDeliveryMap({
    super.key,
    required this.branch,
    required this.destination,
    this.riderLocation,
    this.roadRoute,
    this.roadRouteLoading = false,
    this.showEstimatedLine = true,
    this.onTileError,
  });

  @override
  State<OsmDeliveryMap> createState() => _OsmDeliveryMapState();
}

class _OsmDeliveryMapState extends State<OsmDeliveryMap> {
  final MapController _mapController = MapController();
  bool _hasTileError = false;
  bool _followRider = true;
  bool _mapReady = false;

  List<LatLng> get _estimatePoints {
    final points = <LatLng>[];
    final branch = _latLng(widget.branch.latitude, widget.branch.longitude);
    final destination = _latLng(
      widget.destination?.latitude,
      widget.destination?.longitude,
    );
    if (branch != null) points.add(branch);
    if (destination != null) points.add(destination);
    return points;
  }

  List<LatLng> get _markerPoints {
    final points = _estimatePoints;
    final rider = widget.riderLocation == null
        ? null
        : LatLng(
            widget.riderLocation!.latitude,
            widget.riderLocation!.longitude,
          );
    if (rider != null) points.add(rider);
    return points;
  }

  List<LatLng>? get _usableRoadRoute {
    final route = widget.roadRoute;
    return route != null && route.length > 1 ? route : null;
  }

  @override
  void didUpdateWidget(covariant OsmDeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.riderLocation != oldWidget.riderLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveToRider();
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _handleMapReady() {
    _mapReady = true;
    if (widget.riderLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveToRider(ensureGpsZoom: true);
      });
    }
  }

  void _handlePositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture && _followRider && mounted) {
      setState(() => _followRider = false);
    }
  }

  void _moveToRider({bool ensureGpsZoom = false}) {
    if (!mounted || !_mapReady || !_followRider) return;
    final location = widget.riderLocation;
    if (location == null) return;
    final zoom = ensureGpsZoom
        ? _mapController.camera.zoom.clamp(15.0, 17.0).toDouble()
        : _mapController.camera.zoom;
    _mapController.move(
      LatLng(location.latitude, location.longitude),
      zoom,
      id: 'rider-gps-follow',
    );
  }

  void _centerOnRider() {
    if (widget.riderLocation == null) return;
    setState(() => _followRider = true);
    _moveToRider(ensureGpsZoom: true);
  }

  @override
  Widget build(BuildContext context) {
    final estimatePoints = _estimatePoints;
    final markerPoints = _markerPoints;
    final roadRoute = _usableRoadRoute;
    final cameraPoints =
        roadRoute ??
        (estimatePoints.length > 1 ? estimatePoints : markerPoints);
    final initialCenter = cameraPoints.isEmpty
        ? OsmMapConfig.fallbackCenter
        : cameraPoints.first;
    final fit = cameraPoints.length > 1
        ? CameraFit.coordinates(
            coordinates: cameraPoints,
            padding: const EdgeInsets.fromLTRB(48, 120, 48, 260),
            maxZoom: 16,
          )
        : null;
    final branch = _latLng(widget.branch.latitude, widget.branch.longitude);
    final destination = _latLng(
      widget.destination?.latitude,
      widget.destination?.longitude,
    );
    final rider = widget.riderLocation == null
        ? null
        : LatLng(
            widget.riderLocation!.latitude,
            widget.riderLocation!.longitude,
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: cameraPoints.length > 1 ? 13 : 12,
            initialCameraFit: fit,
            backgroundColor: const Color(0xffe0e0e0),
            onMapReady: _handleMapReady,
            onPositionChanged: _handlePositionChanged,
          ),
          children: [
            TileLayer(
              urlTemplate: OsmMapConfig.tileUrl,
              userAgentPackageName: OsmMapConfig.userAgentPackageName,
              errorTileCallback: (_, error, _) {
                if (mounted && !_hasTileError) {
                  setState(() => _hasTileError = true);
                }
                widget.onTileError?.call(error);
              },
            ),
            if (roadRoute != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: roadRoute,
                    strokeWidth: 5,
                    color: const Color(0xff1565c0),
                  ),
                ],
              )
            else if (estimatePoints.length > 1 && widget.showEstimatedLine)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: estimatePoints,
                    strokeWidth: 4,
                    color: const Color(0xff2196f3),
                    pattern: StrokePattern.dashed(segments: [8, 8]),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (branch != null)
                  Marker(
                    point: branch,
                    width: 46,
                    height: 46,
                    child: const _MapMarker(
                      icon: Icons.storefront,
                      color: Color(0xff673ab7),
                    ),
                  ),
                if (destination != null)
                  Marker(
                    point: destination,
                    width: 50,
                    height: 50,
                    child: const _MapMarker(
                      icon: Icons.location_on,
                      color: Color(0xffe53935),
                    ),
                  ),
                if (rider != null)
                  Marker(
                    point: rider,
                    width: 46,
                    height: 46,
                    child: const _MapMarker(
                      icon: Icons.two_wheeler,
                      color: Color(0xff2196f3),
                    ),
                  ),
              ],
            ),
            SimpleAttributionWidget(
              alignment: Alignment.topRight,
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              source: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  color: Color(0xff333333),
                  decoration: TextDecoration.underline,
                  fontSize: 11,
                ),
              ),
              onTap: _openCopyright,
            ),
          ],
        ),
        if (_hasTileError)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 52,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  'Map tiles are unavailable. Delivery controls remain usable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        if (roadRoute != null ||
            (estimatePoints.length > 1 && widget.showEstimatedLine))
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            right: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  roadRoute != null
                      ? 'Road route'
                      : widget.roadRouteLoading
                      ? 'Calculating road route…'
                      : 'Straight-line estimate',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        if (rider != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 58,
            right: 16,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: IconButton(
                tooltip: _followRider
                    ? 'Following rider location'
                    : 'Center on rider location',
                onPressed: _centerOnRider,
                icon: Icon(
                  _followRider ? Icons.my_location : Icons.location_searching,
                  color: _followRider
                      ? const Color(0xff2196f3)
                      : const Color(0xff616161),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openCopyright() async {
    final uri = Uri.parse(OsmMapConfig.copyrightUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MapMarker({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
        ],
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

LatLng? _latLng(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) {
    return null;
  }
  if (!latitude.isFinite ||
      !longitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    return null;
  }
  return LatLng(latitude, longitude);
}
