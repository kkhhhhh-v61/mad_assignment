import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Order/order.dart';
import '../Order/order_repository.dart';
import '../global.dart';
import '../rider/osm_delivery_map.dart';
import '../rider/rider_location_service.dart';
import '../rider/rider_route_service.dart';
import 'customer_rider_location_repository.dart';

class OrderTracking extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTracking({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final typedOrder = order['typedOrder'] ?? order['orderModel'];
    if (typedOrder is Order) {
      return CustomerLiveOrderTracking(order: typedOrder);
    }

    return Scaffold(
      body: Stack(
        children: [
          const OrderTrackingMapPlaceholder(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.only(left: 6.0),
                  child: Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: Color.fromARGB(221, 0, 0, 0),
                  ),
                ),
              ),
            ),
          ),
          OrderTrackingSheet(order: order),
        ],
      ),
    );
  }
}

//TODO: Replace with actual map widget and live location tracking from backend
class OrderTrackingMapPlaceholder extends StatelessWidget {
  const OrderTrackingMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 224, 224, 224),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: Color.fromARGB(255, 229, 57, 53),
                  size: 64,
                ),
                SizedBox(height: 8),
                Text(
                  'Delivering to Destination...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderTrackingSheet extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTrackingSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? driver =
        order['driver'] as Map<String, dynamic>?;
    final List<Map<String, dynamic>> timeline = order['timeline'] != null
        ? List<Map<String, dynamic>>.from(order['timeline'])
        : [];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(24.0),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 224, 224, 224),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                        color: Color.fromARGB(255, 117, 117, 117),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order['info'] as String? ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(221, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      33,
                      150,
                      243,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['status'] as String? ?? 'In Progress',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 33, 150, 243),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Color.fromARGB(255, 238, 238, 238), height: 1),
            const SizedBox(height: 24),

            if (driver != null) ...[
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 243, 224),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromARGB(255, 255, 204, 128),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: Color.fromARGB(255, 255, 152, 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['name'] as String? ?? 'Unknown Driver',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(221, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driver['rating'] as String? ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 117, 117, 117),
                              ),
                            ),
                            Text(
                              ' (${driver['deliveries']} deliveries)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 158, 158, 158),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 76, 175, 80),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(
                color: Color.fromARGB(255, 238, 238, 238),
                height: 1,
              ),
              const SizedBox(height: 24),
            ] else ...[
              const FallbackMessage(
                icon: Icons.person_off_outlined,
                title: 'Driver not assigned',
                description: 'We are finding a driver for your order.',
              ),
              const SizedBox(height: 24),
              const Divider(
                color: Color.fromARGB(255, 238, 238, 238),
                height: 1,
              ),
              const SizedBox(height: 24),
            ],

            if (timeline.isNotEmpty) ...[
              ...timeline.asMap().entries.map((entry) {
                int idx = entry.key;
                Map<String, dynamic> step = entry.value;
                return OrderTrackingTimelineStep(
                  title: step['title'] as String? ?? '',
                  subtitle: step['subtitle'] as String? ?? '',
                  icon: step['icon'] as IconData? ?? Icons.info,
                  isCompleted: step['isCompleted'] as bool? ?? false,
                  isActive: step['isActive'] as bool? ?? false,
                  isLast: idx == timeline.length - 1,
                );
              }),
            ] else ...[
              const FallbackMessage(
                icon: Icons.timeline,
                title: 'Timeline Unavailable',
                description: 'Tracking details will appear here soon.',
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class OrderTrackingTimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  const OrderTrackingTimelineStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    this.isActive = false,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isActive
        ? const Color.fromARGB(255, 33, 150, 243)
        : (isCompleted
              ? const Color.fromARGB(255, 76, 175, 80)
              : const Color.fromARGB(255, 189, 189, 189));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted || isActive ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                icon,
                color: isCompleted || isActive ? Colors.white : color,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? const Color.fromARGB(255, 76, 175, 80)
                    : const Color.fromARGB(255, 238, 238, 238),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isActive
                      ? const Color.fromARGB(221, 0, 0, 0)
                      : const Color.fromARGB(255, 117, 117, 117),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color.fromARGB(255, 158, 158, 158),
                ),
              ),
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomerLiveOrderTracking extends StatefulWidget {
  final Order order;
  final OrderRepository? orderRepository;
  final CustomerRiderLocationRepository? locationRepository;
  final OsrmRiderRouteService? routeService;

  const CustomerLiveOrderTracking({
    super.key,
    required this.order,
    this.orderRepository,
    this.locationRepository,
    this.routeService,
  });

  @override
  State<CustomerLiveOrderTracking> createState() =>
      _CustomerLiveOrderTrackingState();
}

class _CustomerLiveOrderTrackingState extends State<CustomerLiveOrderTracking> {
  late Order _order;
  OrderRepository? _orderRepository;
  CustomerRiderLocationRepository? _locationRepository;
  late OsrmRiderRouteService _routeService;
  bool _ownsRouteService = false;
  RiderLocation? _riderLocation;
  RiderRoute? _roadRoute;
  StreamSubscription<Order>? _orderSubscription;
  StreamSubscription<RiderLocation>? _locationSubscription;
  bool _locationLoading = false;
  bool _locationStarting = false;
  bool _roadRouteLoading = false;
  String? _trackingMessage;
  String? _roadRouteMessage;
  LatLng? _lastRouteOrigin;
  DateTime? _lastRouteRequestedAt;
  String? _lastRouteTargetKey;
  int _routeRequestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _orderRepository = widget.orderRepository ?? _defaultOrderRepository();
    _locationRepository =
        widget.locationRepository ?? _defaultLocationRepository();
    _routeService = widget.routeService ?? OsrmRiderRouteService();
    _ownsRouteService = widget.routeService == null;
    unawaited(_loadTracking());
  }

  OrderRepository? _defaultOrderRepository() {
    try {
      return SupabaseOrderRepository(Supabase.instance.client);
    } catch (_) {
      return null;
    }
  }

  CustomerRiderLocationRepository? _defaultLocationRepository() {
    try {
      return SupabaseCustomerRiderLocationRepository(Supabase.instance.client);
    } catch (_) {
      return null;
    }
  }

  User? _currentUser() {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get _canShowRiderLocation =>
      _order.isDelivery &&
      _order.riderId != null &&
      (_order.status == OrderStatus.pickedUp ||
          _order.status == OrderStatus.delivering);

  Future<void> _loadTracking() async {
    final user = _currentUser();
    if (user == null) {
      if (mounted) {
        setState(() => _trackingMessage = 'Sign in to view live tracking.');
      }
      return;
    }
    if (user.id != _order.customerId) {
      if (mounted) {
        setState(
          () => _trackingMessage =
              'This order is not available for the signed-in customer.',
        );
      }
      return;
    }

    final orderRepository = _orderRepository;
    final locationRepository = _locationRepository;
    if (orderRepository == null || locationRepository == null) {
      if (mounted) {
        setState(() => _trackingMessage = 'Live tracking is not configured.');
      }
      return;
    }

    try {
      final latestOrder = await orderRepository.findOrder(_order.id);
      if (!mounted) return;
      if (latestOrder == null) {
        setState(() => _trackingMessage = 'This order could not be found.');
        return;
      }
      setState(() {
        _order = latestOrder;
        _trackingMessage = null;
      });
      _subscribeToOrder(orderRepository);
      await _ensureLocationSubscription(locationRepository);
    } catch (_) {
      if (mounted) {
        setState(
          () => _trackingMessage = 'Live tracking is unavailable right now.',
        );
      }
    }
  }

  void _subscribeToOrder(OrderRepository repository) {
    if (_orderSubscription != null) return;
    _orderSubscription = repository
        .watchOrder(_order.id)
        .listen(_handleOrderUpdate, onError: (_) {});
  }

  void _handleOrderUpdate(Order updated) {
    if (!mounted) return;
    setState(() {
      _order = updated;
      if (updated.status == OrderStatus.delivering && _riderLocation != null) {
        _trackingMessage = null;
      }
    });
    if (_canShowRiderLocation) {
      final repository = _locationRepository;
      if (repository != null) {
        unawaited(_ensureLocationSubscription(repository));
      }
    } else {
      _stopLocationSubscription();
    }
  }

  Future<void> _ensureLocationSubscription(
    CustomerRiderLocationRepository repository,
  ) async {
    if (!_canShowRiderLocation ||
        _locationSubscription != null ||
        _locationStarting) {
      return;
    }
    _locationStarting = true;
    if (mounted) setState(() => _locationLoading = true);
    try {
      final latest = await repository.fetchLatest(_order.id);
      if (!mounted || !_canShowRiderLocation) return;
      setState(() {
        _riderLocation = latest;
        _trackingMessage = latest == null
            ? 'Waiting for the rider to share a location...'
            : null;
      });
      if (latest != null) _requestRoadRoute(latest);

      _locationSubscription = repository
          .watchLocation(_order.id)
          .listen(
            _handleLocationUpdate,
            onError: (_) {
              if (mounted) {
                setState(
                  () => _trackingMessage =
                      'Live location updates are temporarily unavailable.',
                );
              }
            },
          );
    } catch (_) {
      if (mounted) {
        setState(
          () => _trackingMessage = 'Rider location is unavailable right now.',
        );
      }
    } finally {
      _locationStarting = false;
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  void _handleLocationUpdate(RiderLocation location) {
    if (!mounted ||
        location.orderId != _order.id ||
        (_order.riderId != null && location.riderId != _order.riderId)) {
      return;
    }
    setState(() {
      _riderLocation = location;
      _trackingMessage = null;
    });
    _requestRoadRoute(location);
  }

  void _stopLocationSubscription() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _riderLocation = null;
    _resetRoadRoute();
  }

  void _resetRoadRoute() {
    _routeRequestGeneration++;
    _roadRoute = null;
    _roadRouteLoading = false;
    _roadRouteMessage = null;
    _lastRouteOrigin = null;
    _lastRouteRequestedAt = null;
    _lastRouteTargetKey = null;
  }

  LatLng? _routeTarget() {
    if (!_canShowRiderLocation) return null;
    final destination = _order.deliveryAddressSnapshot;
    return _validCustomerLatLng(destination?.latitude, destination?.longitude);
  }

  void _requestRoadRoute(RiderLocation location) {
    final target = _routeTarget();
    if (target == null) return;
    final origin = LatLng(location.latitude, location.longitude);
    final targetKey = '${target.latitude},${target.longitude}';
    if (_lastRouteTargetKey != targetKey) {
      _resetRoadRoute();
      _lastRouteTargetKey = targetKey;
    }
    final previousOrigin = _lastRouteOrigin;
    final movedMetres = previousOrigin == null
        ? double.infinity
        : haversineDistanceKm(
                startLatitude: previousOrigin.latitude,
                startLongitude: previousOrigin.longitude,
                endLatitude: origin.latitude,
                endLongitude: origin.longitude,
              ) *
              1000;
    final elapsed = _lastRouteRequestedAt == null
        ? const Duration(days: 1)
        : DateTime.now().difference(_lastRouteRequestedAt!);
    if (_roadRouteLoading ||
        (previousOrigin != null &&
            movedMetres < 100 &&
            elapsed < const Duration(seconds: 20))) {
      return;
    }
    _lastRouteOrigin = origin;
    _lastRouteRequestedAt = DateTime.now();
    final generation = ++_routeRequestGeneration;
    if (mounted) {
      setState(() {
        _roadRouteLoading = true;
        _roadRouteMessage = null;
      });
    }
    unawaited(
      _loadRoadRoute(origin: origin, target: target, generation: generation),
    );
  }

  Future<void> _loadRoadRoute({
    required LatLng origin,
    required LatLng target,
    required int generation,
  }) async {
    try {
      final route = await _routeService.fetchRoute(
        origin: origin,
        destination: target,
      );
      if (!mounted || generation != _routeRequestGeneration) return;
      setState(() {
        _roadRoute = route;
        _roadRouteLoading = false;
        _roadRouteMessage = null;
      });
    } catch (_) {
      if (!mounted || generation != _routeRequestGeneration) return;
      setState(() {
        _roadRoute = null;
        _roadRouteLoading = false;
        _roadRouteMessage =
            'Road route unavailable; showing the straight-line estimate.';
      });
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _stopLocationSubscription();
    if (_ownsRouteService) _routeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = _order.deliveryAddressSnapshot;
    final hasMapCoordinates =
        _validCustomerLatLng(destination?.latitude, destination?.longitude) !=
        null;
    return Scaffold(
      body: Stack(
        children: [
          if (_order.isDelivery && hasMapCoordinates)
            OsmDeliveryMap(
              branch: _order.branchSnapshot,
              destination: destination,
              riderLocation: _riderLocation,
              roadRoute: _roadRoute?.points,
              roadRouteLoading: _roadRouteLoading,
            )
          else
            const OrderTrackingMapPlaceholder(),
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
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DraggableScrollableSheet(
                initialChildSize: 0.50,
                minChildSize: 0.16,
                maxChildSize: 0.86,
                snap: true,
                snapSizes: const [0.16, 0.50, 0.86],
                expand: false,
                builder: (context, scrollController) {
                  return _CustomerLiveTrackingSheet(
                    scrollController: scrollController,
                    order: _order,
                    riderLocation: _riderLocation,
                    locationLoading: _locationLoading,
                    trackingMessage: _trackingMessage,
                    roadRoute: _roadRoute,
                    roadRouteLoading: _roadRouteLoading,
                    roadRouteMessage: _roadRouteMessage,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerLiveTrackingSheet extends StatelessWidget {
  final ScrollController? scrollController;
  final Order order;
  final RiderLocation? riderLocation;
  final bool locationLoading;
  final String? trackingMessage;
  final RiderRoute? roadRoute;
  final bool roadRouteLoading;
  final String? roadRouteMessage;

  const _CustomerLiveTrackingSheet({
    required this.scrollController,
    required this.order,
    required this.riderLocation,
    required this.locationLoading,
    required this.trackingMessage,
    required this.roadRoute,
    required this.roadRouteLoading,
    required this.roadRouteMessage,
  });

  @override
  Widget build(BuildContext context) {
    final lastUpdated = riderLocation?.recordedAt.toLocal();
    final locationStale =
        lastUpdated != null &&
        DateTime.now().difference(lastUpdated) > const Duration(minutes: 2);
    final eta = _customerEtaValue(
      status: order.status,
      roadRoute: roadRoute,
      roadRouteLoading: roadRouteLoading,
    );
    final etaTime = _customerEtaTimeValue(
      status: order.status,
      roadRoute: roadRoute,
    );
    return Container(
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
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          child: Column(
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
                        eta,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xdd000000),
                        ),
                      ),
                      if (etaTime != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          etaTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xff757575),
                          ),
                        ),
                      ],
                    ],
                  ),
                  _CustomerStatusChip(status: order.status),
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
                      color: const Color(0xffe3f2fd),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xff90caf9),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.two_wheeler,
                      color: Color(0xff2196f3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery rider',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xdd000000),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.deliveryAddressSnapshot?.formattedAddress ??
                              'Delivery address unavailable',
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
              if (locationLoading || trackingMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  locationLoading
                      ? 'Loading the rider location...'
                      : trackingMessage!,
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
              if (roadRouteLoading ||
                  roadRoute != null ||
                  roadRouteMessage != null) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      roadRoute != null ? Icons.alt_route : Icons.info_outline,
                      size: 16,
                      color: roadRoute != null
                          ? const Color(0xff1565c0)
                          : const Color(0xff757575),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        roadRouteLoading
                            ? 'Calculating real road route...'
                            : roadRoute != null
                            ? 'Road route: ${_formatCustomerRouteDistance(roadRoute!.distanceMetres)} · ${_formatCustomerRouteDuration(roadRoute!.duration)}'
                            : roadRouteMessage!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff757575),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Live location is shared only while the rider is handling this order.',
                style: TextStyle(fontSize: 11, color: Color(0xff9e9e9e)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerStatusChip extends StatelessWidget {
  final OrderStatus status;

  const _CustomerStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == OrderStatus.delivering
        ? const Color(0xff2196f3)
        : status == OrderStatus.delivered || status == OrderStatus.collected
        ? const Color(0xff4caf50)
        : const Color(0xffffa07a);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _customerStatusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

String _customerStatusLabel(OrderStatus status) {
  return switch (status) {
    OrderStatus.placed => 'Placed',
    OrderStatus.preparing => 'Preparing',
    OrderStatus.ready => 'Ready',
    OrderStatus.pickedUp => 'Picked up',
    OrderStatus.delivering => 'Delivering',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.collected => 'Collected',
    OrderStatus.cancelled => 'Cancelled',
  };
}

String _customerEtaValue({
  required OrderStatus status,
  required RiderRoute? roadRoute,
  required bool roadRouteLoading,
}) {
  if (status != OrderStatus.delivering) {
    return status == OrderStatus.pickedUp ? 'Awaiting delivery' : 'Unavailable';
  }
  if (roadRouteLoading) return 'Calculating...';
  if (roadRoute == null) return 'Unavailable';
  return _formatCustomerRouteDuration(roadRoute.duration);
}

String? _customerEtaTimeValue({
  required OrderStatus status,
  required RiderRoute? roadRoute,
}) {
  if (status != OrderStatus.delivering || roadRoute == null) return null;
  final eta = DateTime.now().add(roadRoute.duration).toLocal();
  return 'Around ${DateFormat('h:mm a').format(eta)}';
}

String _formatCustomerRouteDistance(double metres) {
  if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
  return '${metres.round()} m';
}

String _formatCustomerRouteDuration(Duration duration) {
  final minutes = duration.inMinutes + (duration.inSeconds % 60 == 0 ? 0 : 1);
  if (minutes < 60) return '${minutes < 1 ? 1 : minutes} min';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return remainingMinutes == 0
      ? '$hours hr'
      : '$hours hr $remainingMinutes min';
}

LatLng? _validCustomerLatLng(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return null;
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
