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
  final bool showEstimatedLine;
  final ValueChanged<Object>? onTileError;

  const OsmDeliveryMap({
    super.key,
    required this.branch,
    required this.destination,
    this.riderLocation,
    this.showEstimatedLine = true,
    this.onTileError,
  });

  @override
  State<OsmDeliveryMap> createState() => _OsmDeliveryMapState();
}

class _OsmDeliveryMapState extends State<OsmDeliveryMap> {
  bool _hasTileError = false;

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

  @override
  Widget build(BuildContext context) {
    final estimatePoints = _estimatePoints;
    final markerPoints = _markerPoints;
    final cameraPoints = estimatePoints.length > 1
        ? estimatePoints
        : markerPoints;
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
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: cameraPoints.length > 1 ? 13 : 12,
            initialCameraFit: fit,
            backgroundColor: const Color(0xffe0e0e0),
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
            if (estimatePoints.length > 1 && widget.showEstimatedLine)
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
        if (estimatePoints.length > 1 && widget.showEstimatedLine)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            right: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  'Straight-line estimate',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
