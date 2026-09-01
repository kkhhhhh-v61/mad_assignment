import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Order/order.dart';
import '../Order/order_repository.dart';
import '../main.dart';
import 'delivery_completion.dart';
import 'osm_delivery_map.dart';
import 'rider_delivery.dart';
import 'rider_location_service.dart';

class DeliveryTracking extends StatefulWidget {
  final RiderDelivery delivery;
  final RiderLocationService? locationService;
  final RiderLocationRepository? locationRepository;
  final OrderRepository? orderRepository;

  const DeliveryTracking({
    super.key,
    required this.delivery,
    this.locationService,
    this.locationRepository,
    this.orderRepository,
  });

  @override
  State<DeliveryTracking> createState() => _DeliveryTrackingState();
}

class _DeliveryTrackingState extends State<DeliveryTracking> {
  late RiderDelivery _delivery;
  RiderLocation? _currentLocation;
  StreamSubscription<RiderLocation>? _locationSubscription;
  StreamSubscription<RiderLocation>? _remoteLocationSubscription;
  RiderLocationUploader? _locationUploader;
  bool _locationLoading = false;
  String? _locationMessage;
  bool _actionLoading = false;
  RiderLocationService? _resolvedLocationService;
  RiderLocationRepository? _resolvedLocationRepository;
  OrderRepository? _resolvedOrderRepository;

  @override
  void initState() {
    super.initState();
    _delivery = widget.delivery;
    _resolvedLocationService =
        widget.locationService ?? const RiderLocationService();
    _resolvedLocationRepository =
        widget.locationRepository ?? _defaultLocationRepository();
    _resolvedOrderRepository =
        widget.orderRepository ?? _defaultOrderRepository();
    _startTracking();
  }

  RiderLocationRepository? _defaultLocationRepository() {
    try {
      if (supabase.auth.currentUser == null) return null;
      return SupabaseRiderLocationRepository(supabase);
    } catch (_) {
      return null;
    }
  }

  OrderRepository? _defaultOrderRepository() {
    try {
      if (supabase.auth.currentUser == null) return null;
      return SupabaseOrderRepository(supabase);
    } catch (_) {
      return null;
    }
  }

  Future<void> _startTracking() async {
    if (_delivery.order.status != OrderStatus.pickedUp &&
        _delivery.order.status != OrderStatus.delivering) {
      return;
    }
    if (_locationSubscription != null) {
      return;
    }
    final orderId = _delivery.order.id;
    final riderId = _delivery.order.riderId;
    final locationService = _resolvedLocationService;
    final locationRepository = _resolvedLocationRepository;
    if (riderId == null ||
        locationService == null ||
        locationRepository == null) {
      return;
    }
    setState(() => _locationLoading = true);
    _locationUploader = RiderLocationUploader(repository: locationRepository);
    try {
      final stream = await locationService.start(
        orderId: orderId,
        riderId: riderId,
      );
      _locationSubscription = stream.listen(
        (location) async {
          if (!mounted) {
            return;
          }
          setState(() {
            _currentLocation = location;
            _locationMessage = 'Location sharing is active';
          });
          try {
            await _locationUploader?.uploadIfDue(location);
          } catch (_) {
            if (mounted) {
              setState(
                () => _locationMessage =
                    'Location could not be uploaded; retrying.',
              );
            }
          }
        },
        onError: (Object error) {
          if (mounted) setState(() => _locationMessage = error.toString());
        },
      );
      _remoteLocationSubscription = locationRepository
          .watchLocation(orderId)
          .listen((location) {
            if (mounted) setState(() => _currentLocation = location);
          }, onError: (_) {});
      if (mounted) setState(() => _locationLoading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _locationMessage = error.toString();
      });
    }
  }

  Future<void> _advanceStatus() async {
    final repository = _resolvedOrderRepository;
    if (repository == null) {
      _showMessage('Order status service is not configured.');
      return;
    }
    final current = _delivery.order.status;
    final next = current == OrderStatus.ready
        ? OrderStatus.pickedUp
        : OrderStatus.delivering;
    setState(() => _actionLoading = true);
    try {
      final updated = await repository.transitionStatus(
        orderId: _delivery.order.id,
        expectedStatus: current,
        nextStatus: next,
      );
      if (!mounted) return;
      setState(() {
        _delivery = RiderDelivery(
          order: updated,
          customerName: _delivery.customerName,
          customerPhone: _delivery.customerPhone,
        );
        _actionLoading = false;
      });
      if (next == OrderStatus.pickedUp || next == OrderStatus.delivering) {
        await _startTracking();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      _showMessage('The order status could not be updated.');
    }
  }

  void _openCompletion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryCompletion(
          delivery: _delivery,
          orderRepository: _resolvedOrderRepository,
          onCompleted: _stopTracking,
        ),
      ),
    );
  }

  void _stopTracking() {
    _locationSubscription?.cancel();
    _remoteLocationSubscription?.cancel();
    _locationSubscription = null;
    _remoteLocationSubscription = null;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          OsmDeliveryMap(
            branch: _delivery.order.branchSnapshot,
            destination: _delivery.order.deliveryAddressSnapshot,
            riderLocation: _currentLocation,
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            left: 16,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                  color: Color(0xdd000000),
                ),
              ),
            ),
          ),
          DeliveryTrackingSheet(
            delivery: _delivery,
            currentLocation: _currentLocation,
            locationLoading: _locationLoading,
            locationMessage: _locationMessage,
            actionLoading: _actionLoading,
            onAdvanceStatus: _advanceStatus,
            onComplete: _openCompletion,
          ),
        ],
      ),
    );
  }
}

class DeliveryTrackingSheet extends StatelessWidget {
  final RiderDelivery delivery;
  final RiderLocation? currentLocation;
  final bool locationLoading;
  final String? locationMessage;
  final bool actionLoading;
  final VoidCallback onAdvanceStatus;
  final VoidCallback onComplete;

  const DeliveryTrackingSheet({
    super.key,
    required this.delivery,
    this.currentLocation,
    required this.locationLoading,
    required this.locationMessage,
    required this.actionLoading,
    required this.onAdvanceStatus,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final status = delivery.order.status;
    final canAdvance =
        status == OrderStatus.ready || status == OrderStatus.pickedUp;
    final actionLabel = status == OrderStatus.ready
        ? 'Pick Up Order'
        : 'Start Delivery';
    final lastUpdated = currentLocation?.recordedAt.toLocal();
    final locationStale =
        lastUpdated != null &&
        DateTime.now().difference(lastUpdated) > const Duration(minutes: 2);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xffe0e0e0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Arrival',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff757575),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status == OrderStatus.delivering
                            ? 'Unavailable'
                            : 'Awaiting pickup',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xdd000000),
                        ),
                      ),
                    ],
                  ),
                  _StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xffeeeeee), height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xfff3e5f5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xffce93d8),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.person, color: Color(0xff9c27b0)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xdd000000),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          delivery.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xff757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (locationLoading || locationMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  locationLoading
                      ? 'Requesting foreground location...'
                      : locationMessage!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff757575),
                  ),
                ),
              ],
              if (lastUpdated != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${locationStale ? 'Stale location' : 'Last location update'}: ${DateFormat('h:mm:ss a').format(lastUpdated)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: locationStale
                        ? const Color(0xffd32f2f)
                        : const Color(0xff757575),
                    fontWeight: locationStale
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: actionLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: canAdvance
                            ? onAdvanceStatus
                            : status == OrderStatus.delivering
                            ? onComplete
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4caf50),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xffbdbdbd),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          canAdvance ? actionLabel : 'Complete Delivery',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      OrderStatus.ready => 'Ready',
      OrderStatus.pickedUp => 'Picked up',
      OrderStatus.delivering => 'In progress',
      _ => status.databaseValue,
    };
    final color = status == OrderStatus.delivering
        ? const Color(0xff2196f3)
        : const Color(0xffffa07a);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
