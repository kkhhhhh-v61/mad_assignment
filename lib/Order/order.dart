import 'dart:math' as math;

enum FulfilmentType {
  delivery,
  pickup;

  String get databaseValue => name;

  static FulfilmentType fromDatabase(Object? value) {
    switch (value?.toString()) {
      case 'delivery':
        return FulfilmentType.delivery;
      case 'pickup':
        return FulfilmentType.pickup;
      default:
        throw OrderDataException('Unknown fulfilment type: $value');
    }
  }
}

enum OrderStatus {
  placed,
  preparing,
  ready,
  pickedUp,
  delivering,
  delivered,
  collected,
  cancelled;

  String get databaseValue {
    switch (this) {
      case OrderStatus.pickedUp:
        return 'picked_up';
      default:
        return name;
    }
  }

  static OrderStatus fromDatabase(Object? value) {
    switch (value?.toString()) {
      case 'placed':
        return OrderStatus.placed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'delivering':
        return OrderStatus.delivering;
      case 'delivered':
        return OrderStatus.delivered;
      case 'collected':
        return OrderStatus.collected;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        throw OrderDataException('Unknown order status: $value');
    }
  }
}

class OrderDataException implements Exception {
  final String message;

  const OrderDataException(this.message);

  @override
  String toString() => message;
}

class InvalidOrderException extends OrderDataException {
  const InvalidOrderException(super.message);
}

class InvalidOrderTransitionException extends OrderDataException {
  const InvalidOrderTransitionException(super.message);
}

class DeliveryDistanceLimitException extends InvalidOrderException {
  const DeliveryDistanceLimitException(super.message);
}

const supportedPaymentTypes = <String>{'COD', 'Card', 'PayPal'};
const supportedPaymentStatuses = <String>{'Pending', 'Completed', 'Failed'};

void validatePaymentFields({
  required String? paymentType,
  required String? paymentStatus,
  required String? paymentMethodId,
}) {
  final hasPaymentFields =
      paymentType != null || paymentStatus != null || paymentMethodId != null;
  if (!hasPaymentFields) return;

  if (paymentType == null || !supportedPaymentTypes.contains(paymentType)) {
    throw const InvalidOrderException('Payment type is invalid.');
  }
  if (paymentStatus == null ||
      !supportedPaymentStatuses.contains(paymentStatus)) {
    throw const InvalidOrderException('Payment status is invalid.');
  }

  if (paymentMethodId != null && paymentMethodId.trim().isEmpty) {
    throw const InvalidOrderException('Payment method ID cannot be blank.');
  }
  final hasPaymentMethod = paymentMethodId != null;
  if (paymentType == 'Card' && !hasPaymentMethod) {
    throw const InvalidOrderException(
      'Card payments require a payment method ID.',
    );
  }
  if (paymentType != 'Card' && hasPaymentMethod) {
    throw const InvalidOrderException(
      'Only card payments may include a payment method ID.',
    );
  }
}

class BranchSnapshot {
  final String branchId;
  final String name;
  final String stateCode;
  final double? latitude;
  final double? longitude;

  const BranchSnapshot({
    required this.branchId,
    required this.name,
    required this.stateCode,
    this.latitude,
    this.longitude,
  });

  factory BranchSnapshot.fromJson(Map<String, dynamic> json) {
    return BranchSnapshot(
      branchId: _requiredString(json, const [
        'branch_id',
        'branchId',
      ], 'branchId'),
      name: _requiredString(json, const ['name'], 'name'),
      stateCode: _requiredString(json, const [
        'state_code',
        'stateCode',
      ], 'stateCode'),
      latitude: _optionalDouble(json, const ['latitude']),
      longitude: _optionalDouble(json, const ['longitude']),
    );
  }

  Map<String, dynamic> toJson() => {
    'branch_id': branchId,
    'name': name,
    'state_code': stateCode,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class DeliveryAddressSnapshot {
  final String label;
  final String formattedAddress;
  final String stateCode;
  final double? latitude;
  final double? longitude;

  const DeliveryAddressSnapshot({
    required this.label,
    required this.formattedAddress,
    required this.stateCode,
    this.latitude,
    this.longitude,
  });

  factory DeliveryAddressSnapshot.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressSnapshot(
      label: _requiredString(json, const ['label'], 'label'),
      formattedAddress: _requiredString(json, const [
        'formatted_address',
        'formattedAddress',
      ], 'formattedAddress'),
      stateCode: _requiredString(json, const [
        'state_code',
        'stateCode',
      ], 'stateCode'),
      latitude: _optionalDouble(json, const ['latitude']),
      longitude: _optionalDouble(json, const ['longitude']),
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'formatted_address': formattedAddress,
    'state_code': stateCode,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class OrderItemSnapshot {
  final String foodId;
  final String name;
  final int quantity;
  final int unitPriceSen;
  final Map<String, dynamic> selectedOptions;
  final int lineTotalSen;
  final bool isStateSpecial;
  final String? specialStateCode;

  OrderItemSnapshot({
    required this.foodId,
    required this.name,
    required this.quantity,
    required this.unitPriceSen,
    required Map<String, dynamic> selectedOptions,
    required this.lineTotalSen,
    required this.isStateSpecial,
    this.specialStateCode,
  }) : selectedOptions = Map.unmodifiable(selectedOptions) {
    if (foodId.trim().isEmpty) {
      throw const InvalidOrderException('Food ID is required.');
    }
    if (name.trim().isEmpty) {
      throw const InvalidOrderException('Food name is required.');
    }
    if (quantity <= 0) {
      throw const InvalidOrderException('Quantity must be greater than zero.');
    }
    if (unitPriceSen < 0 || lineTotalSen < 0) {
      throw const InvalidOrderException('Money values cannot be negative.');
    }
    if (lineTotalSen != quantity * unitPriceSen) {
      throw const InvalidOrderException(
        'Line total must equal quantity multiplied by unit price.',
      );
    }
    if (isStateSpecial &&
        (specialStateCode == null || specialStateCode!.trim().isEmpty)) {
      throw const InvalidOrderException(
        'A state-special item must include a state code.',
      );
    }
    if (!isStateSpecial && specialStateCode != null) {
      throw const InvalidOrderException(
        'A regular item cannot include a special state code.',
      );
    }
  }

  factory OrderItemSnapshot.fromJson(Map<String, dynamic> json) {
    final selectedOptions =
        json['selected_options'] ??
        json['selectedOptions'] ??
        <String, dynamic>{};
    if (selectedOptions is! Map) {
      throw const InvalidOrderException(
        'Selected options must be a JSON object.',
      );
    }
    return OrderItemSnapshot(
      foodId: _requiredString(json, const ['food_id', 'foodId'], 'foodId'),
      name: _requiredString(json, const ['name'], 'name'),
      quantity: _requiredInt(json, const ['quantity'], 'quantity'),
      unitPriceSen: _requiredInt(json, const [
        'unit_price_sen',
        'unitPriceSen',
      ], 'unitPriceSen'),
      selectedOptions: Map<String, dynamic>.from(selectedOptions),
      lineTotalSen: _requiredInt(json, const [
        'line_total_sen',
        'lineTotalSen',
      ], 'lineTotalSen'),
      isStateSpecial: _requiredBool(json, const [
        'is_state_special',
        'isStateSpecial',
      ], 'isStateSpecial'),
      specialStateCode: _optionalString(json, const [
        'special_state_code',
        'specialStateCode',
      ]),
    );
  }

  Map<String, dynamic> toJson() => {
    'food_id': foodId,
    'name': name,
    'quantity': quantity,
    'unit_price_sen': unitPriceSen,
    'selected_options': selectedOptions,
    'line_total_sen': lineTotalSen,
    'is_state_special': isStateSpecial,
    'special_state_code': specialStateCode,
  };
}

class DeliveryDistancePolicy {
  const DeliveryDistancePolicy._();

  static const maximumDistanceKm = 10.0;

  static double? estimateKm({
    required BranchSnapshot branch,
    required DeliveryAddressSnapshot destination,
  }) {
    final branchLatitude = branch.latitude;
    final branchLongitude = branch.longitude;
    final destinationLatitude = destination.latitude;
    final destinationLongitude = destination.longitude;
    if (branchLatitude == null ||
        branchLongitude == null ||
        destinationLatitude == null ||
        destinationLongitude == null) {
      return null;
    }
    return haversineDistanceKm(
      startLatitude: branchLatitude,
      startLongitude: branchLongitude,
      endLatitude: destinationLatitude,
      endLongitude: destinationLongitude,
    );
  }

  static void ensureRoadDistanceWithinLimit({required double roadDistanceKm}) {
    if (!roadDistanceKm.isFinite || roadDistanceKm < 0) {
      throw const InvalidOrderException('Road distance must be non-negative.');
    }
    if (roadDistanceKm > maximumDistanceKm) {
      throw DeliveryDistanceLimitException(
        'Road delivery distance is ${roadDistanceKm.toStringAsFixed(2)} km; '
        'the maximum allowed is ${maximumDistanceKm.toStringAsFixed(0)} km.',
      );
    }
  }

  static void ensureWithinLimit({
    required BranchSnapshot branch,
    required DeliveryAddressSnapshot destination,
  }) {
    final distanceKm = estimateKm(branch: branch, destination: destination);
    if (distanceKm == null) {
      throw const InvalidOrderException(
        'Delivery coordinates are required to validate the delivery limit.',
      );
    }
    if (distanceKm > maximumDistanceKm) {
      throw InvalidOrderException(
        'Delivery address is ${distanceKm.toStringAsFixed(1)} km from the branch; '
        'the maximum allowed is ${maximumDistanceKm.toStringAsFixed(0)} km.',
      );
    }
  }
}

class OrderSubmission {
  final String orderNumber;
  final String paymentIdempotencyKey;
  final String? paymentType;
  final String? paymentStatus;
  final String? paymentMethodId;
  final FulfilmentType fulfilmentType;
  final BranchSnapshot branchSnapshot;
  final DeliveryAddressSnapshot? deliveryAddressSnapshot;
  final int subtotalSen;
  final int discountSen;
  final int deliveryFeeSen;
  final int totalSen;
  final double? roadDistanceKm;
  final List<OrderItemSnapshot> items;

  OrderSubmission({
    required this.orderNumber,
    required this.paymentIdempotencyKey,
    this.paymentType,
    this.paymentStatus,
    this.paymentMethodId,
    required this.fulfilmentType,
    required this.branchSnapshot,
    required this.deliveryAddressSnapshot,
    required this.subtotalSen,
    required this.discountSen,
    required this.deliveryFeeSen,
    required this.totalSen,
    this.roadDistanceKm,
    required List<OrderItemSnapshot> items,
  }) : items = List.unmodifiable(items) {
    if (orderNumber.trim().isEmpty || paymentIdempotencyKey.trim().isEmpty) {
      throw const InvalidOrderException(
        'Order number and payment idempotency key are required.',
      );
    }
    if (items.isEmpty) {
      throw const InvalidOrderException(
        'An order must contain at least one item.',
      );
    }
    validatePaymentFields(
      paymentType: paymentType,
      paymentStatus: paymentStatus,
      paymentMethodId: paymentMethodId,
    );
    if (subtotalSen < 0 ||
        discountSen < 0 ||
        deliveryFeeSen < 0 ||
        totalSen < 0) {
      throw const InvalidOrderException('Money values cannot be negative.');
    }
    if (totalSen != subtotalSen - discountSen + deliveryFeeSen) {
      throw const InvalidOrderException(
        'Order total does not match its components.',
      );
    }
    final itemTotal = items.fold<int>(
      0,
      (sum, item) => sum + item.lineTotalSen,
    );
    if (itemTotal != subtotalSen) {
      throw const InvalidOrderException(
        'Item totals do not match the subtotal.',
      );
    }
    if (fulfilmentType == FulfilmentType.delivery &&
        deliveryAddressSnapshot == null) {
      throw const InvalidOrderException(
        'Delivery orders require a delivery address snapshot.',
      );
    }
    if (fulfilmentType == FulfilmentType.pickup &&
        deliveryAddressSnapshot != null) {
      throw const InvalidOrderException(
        'Pickup orders cannot include a delivery address snapshot.',
      );
    }
    if (fulfilmentType == FulfilmentType.pickup && roadDistanceKm != null) {
      throw const InvalidOrderException(
        'Pickup orders cannot include a road delivery distance.',
      );
    }
    if (fulfilmentType == FulfilmentType.delivery) {
      final routedDistance = roadDistanceKm;
      if (routedDistance != null) {
        DeliveryDistancePolicy.ensureRoadDistanceWithinLimit(
          roadDistanceKm: routedDistance,
        );
      } else {
        DeliveryDistancePolicy.ensureWithinLimit(
          branch: branchSnapshot,
          destination: deliveryAddressSnapshot!,
        );
      }
    }
  }

  bool get hasPaymentDetails =>
      paymentType != null || paymentStatus != null || paymentMethodId != null;

  Map<String, dynamic> toRpcParams() => {
    'p_order_number': orderNumber,
    'p_payment_idempotency_key': paymentIdempotencyKey,
    'p_fulfilment_type': fulfilmentType.databaseValue,
    'p_branch_snapshot': branchSnapshot.toJson(),
    'p_delivery_address_snapshot': deliveryAddressSnapshot?.toJson(),
    'p_subtotal_sen': subtotalSen,
    'p_discount_sen': discountSen,
    'p_delivery_fee_sen': deliveryFeeSen,
    'p_total_sen': totalSen,
    'p_items': items.map((item) => item.toJson()).toList(growable: false),
  };

  Map<String, dynamic> toPaymentRpcParams() {
    if (!hasPaymentDetails) {
      throw const InvalidOrderException('Payment details are required.');
    }
    return {
      ...toRpcParams(),
      'p_payment_type': paymentType,
      'p_payment_status': paymentStatus,
      'p_payment_method_id': paymentMethodId,
    };
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String paymentIdempotencyKey;
  final String? paymentType;
  final String? paymentStatus;
  final String? paymentMethodId;
  final String customerId;
  final String? riderId;
  final FulfilmentType fulfilmentType;
  final OrderStatus status;
  final BranchSnapshot branchSnapshot;
  final DeliveryAddressSnapshot? deliveryAddressSnapshot;
  final int subtotalSen;
  final int discountSen;
  final int deliveryFeeSen;
  final int totalSen;
  final List<OrderItemSnapshot> items;
  final String? proofPhotoPath;
  final String? deliveryComments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.paymentIdempotencyKey,
    this.paymentType,
    this.paymentStatus,
    this.paymentMethodId,
    required this.customerId,
    required this.riderId,
    required this.fulfilmentType,
    required this.status,
    required this.branchSnapshot,
    required this.deliveryAddressSnapshot,
    required this.subtotalSen,
    required this.discountSen,
    required this.deliveryFeeSen,
    required this.totalSen,
    required List<OrderItemSnapshot> items,
    required this.proofPhotoPath,
    required this.deliveryComments,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
  }) : items = List.unmodifiable(items) {
    if (id.trim().isEmpty ||
        orderNumber.trim().isEmpty ||
        customerId.trim().isEmpty) {
      throw const InvalidOrderException('Order identity fields are required.');
    }
    validatePaymentFields(
      paymentType: paymentType,
      paymentStatus: paymentStatus,
      paymentMethodId: paymentMethodId,
    );
    if (subtotalSen < 0 ||
        discountSen < 0 ||
        deliveryFeeSen < 0 ||
        totalSen < 0) {
      throw const InvalidOrderException('Money values cannot be negative.');
    }
    if (totalSen != subtotalSen - discountSen + deliveryFeeSen) {
      throw const InvalidOrderException(
        'Order total does not match its components.',
      );
    }
    if (fulfilmentType == FulfilmentType.delivery &&
        deliveryAddressSnapshot == null) {
      throw const InvalidOrderException(
        'Delivery orders require a delivery address snapshot.',
      );
    }
    if (fulfilmentType == FulfilmentType.pickup &&
        deliveryAddressSnapshot != null) {
      throw const InvalidOrderException(
        'Pickup orders cannot include a delivery address snapshot.',
      );
    }
    if (items.isNotEmpty) {
      final itemTotal = items.fold<int>(
        0,
        (sum, item) => sum + item.lineTotalSen,
      );
      if (itemTotal != subtotalSen) {
        throw const InvalidOrderException(
          'Item totals do not match the subtotal.',
        );
      }
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final branch = json['branch_snapshot'] ?? json['branchSnapshot'];
    if (branch is! Map) {
      throw const InvalidOrderException('Branch snapshot is required.');
    }
    final address =
        json['delivery_address_snapshot'] ?? json['deliveryAddressSnapshot'];
    final rawItems = json['order_items'] ?? json['items'] ?? const <dynamic>[];
    if (rawItems is! List) {
      throw const InvalidOrderException('Order items must be a JSON array.');
    }
    return Order(
      id: _requiredString(json, const ['id'], 'id'),
      orderNumber: _requiredString(json, const [
        'order_number',
        'orderNumber',
      ], 'orderNumber'),
      paymentIdempotencyKey: _requiredString(json, const [
        'payment_idempotency_key',
        'paymentIdempotencyKey',
      ], 'paymentIdempotencyKey'),
      paymentType: _optionalString(json, const ['payment_type', 'paymentType']),
      paymentStatus: _optionalString(json, const [
        'payment_status',
        'paymentStatus',
      ]),
      paymentMethodId: _optionalString(json, const [
        'payment_method_id',
        'paymentMethodId',
      ]),
      customerId: _requiredString(json, const [
        'customer_id',
        'customerId',
      ], 'customerId'),
      riderId: _optionalString(json, const ['rider_id', 'riderId']),
      fulfilmentType: FulfilmentType.fromDatabase(
        json['fulfilment_type'] ?? json['fulfilmentType'],
      ),
      status: OrderStatus.fromDatabase(json['status']),
      branchSnapshot: BranchSnapshot.fromJson(
        Map<String, dynamic>.from(branch),
      ),
      deliveryAddressSnapshot: address is Map
          ? DeliveryAddressSnapshot.fromJson(Map<String, dynamic>.from(address))
          : null,
      subtotalSen: _requiredInt(json, const [
        'subtotal_sen',
        'subtotalSen',
      ], 'subtotalSen'),
      discountSen: _requiredInt(json, const [
        'discount_sen',
        'discountSen',
      ], 'discountSen'),
      deliveryFeeSen: _requiredInt(json, const [
        'delivery_fee_sen',
        'deliveryFeeSen',
      ], 'deliveryFeeSen'),
      totalSen: _requiredInt(json, const ['total_sen', 'totalSen'], 'totalSen'),
      items: rawItems
          .map((item) {
            if (item is! Map) {
              throw const InvalidOrderException(
                'Each order item must be a JSON object.',
              );
            }
            return OrderItemSnapshot.fromJson(Map<String, dynamic>.from(item));
          })
          .toList(growable: false),
      proofPhotoPath: _optionalString(json, const [
        'proof_photo_path',
        'proofPhotoPath',
      ]),
      deliveryComments: _optionalString(json, const [
        'delivery_comments',
        'deliveryComments',
      ]),
      createdAt: _requiredDateTime(json, const [
        'created_at',
        'createdAt',
      ], 'createdAt'),
      updatedAt: _requiredDateTime(json, const [
        'updated_at',
        'updatedAt',
      ], 'updatedAt'),
      completedAt: _optionalDateTime(json, const [
        'completed_at',
        'completedAt',
      ]),
    );
  }

  bool get isDelivery => fulfilmentType == FulfilmentType.delivery;

  bool get isActive => const {
    OrderStatus.placed,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.pickedUp,
    OrderStatus.delivering,
  }.contains(status);

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'payment_idempotency_key': paymentIdempotencyKey,
    'payment_type': paymentType,
    'payment_status': paymentStatus,
    'payment_method_id': paymentMethodId,
    'customer_id': customerId,
    'rider_id': riderId,
    'fulfilment_type': fulfilmentType.databaseValue,
    'status': status.databaseValue,
    'branch_snapshot': branchSnapshot.toJson(),
    'delivery_address_snapshot': deliveryAddressSnapshot?.toJson(),
    'subtotal_sen': subtotalSen,
    'discount_sen': discountSen,
    'delivery_fee_sen': deliveryFeeSen,
    'total_sen': totalSen,
    'order_items': items.map((item) => item.toJson()).toList(growable: false),
    'proof_photo_path': proofPhotoPath,
    'delivery_comments': deliveryComments,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };
}

class OrderTransitionPolicy {
  const OrderTransitionPolicy._();

  static bool isAllowed({
    required OrderStatus current,
    required OrderStatus next,
    required FulfilmentType fulfilmentType,
    required String actorRole,
    required bool isOwner,
    required bool isAssignedRider,
  }) {
    final role = actorRole.trim().toLowerCase();
    if (role == 'customer' && isOwner) {
      if (current == OrderStatus.placed && next == OrderStatus.cancelled) {
        return true;
      }
      if (fulfilmentType == FulfilmentType.pickup &&
          current == OrderStatus.ready &&
          next == OrderStatus.collected) {
        return true;
      }
    }
    if (role == 'rider' &&
        isAssignedRider &&
        fulfilmentType == FulfilmentType.delivery) {
      return (current == OrderStatus.ready && next == OrderStatus.pickedUp) ||
          (current == OrderStatus.pickedUp && next == OrderStatus.delivering);
    }
    if (role == 'admin') {
      if (current == OrderStatus.placed && next == OrderStatus.preparing) {
        return true;
      }
      if (current == OrderStatus.preparing && next == OrderStatus.ready) {
        return true;
      }
      if (fulfilmentType == FulfilmentType.pickup &&
          current == OrderStatus.ready &&
          next == OrderStatus.collected) {
        return true;
      }
    }
    return false;
  }

  static void ensureAllowed({
    required OrderStatus current,
    required OrderStatus next,
    required FulfilmentType fulfilmentType,
    required String actorRole,
    required bool isOwner,
    required bool isAssignedRider,
  }) {
    if (!isAllowed(
      current: current,
      next: next,
      fulfilmentType: fulfilmentType,
      actorRole: actorRole,
      isOwner: isOwner,
      isAssignedRider: isAssignedRider,
    )) {
      throw InvalidOrderTransitionException(
        'Cannot transition ${current.databaseValue} to ${next.databaseValue} for $actorRole.',
      );
    }
  }
}

String _requiredString(
  Map<String, dynamic> json,
  List<String> keys,
  String field,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  throw InvalidOrderException('$field is required.');
}

String? _optionalString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

int _requiredInt(Map<String, dynamic> json, List<String> keys, String field) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num && value == value.roundToDouble()) {
      return value.toInt();
    }
  }
  throw InvalidOrderException('$field must be an integer.');
}

bool _requiredBool(Map<String, dynamic> json, List<String> keys, String field) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
  }
  throw InvalidOrderException('$field must be a boolean.');
}

double? _optionalDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      final result = value.toDouble();
      if (result.isFinite) {
        return result;
      }
    }
  }
  return null;
}

DateTime _requiredDateTime(
  Map<String, dynamic> json,
  List<String> keys,
  String field,
) {
  final result = _optionalDateTime(json, keys);
  if (result == null) {
    throw InvalidOrderException('$field must be a valid timestamp.');
  }
  return result;
}

DateTime? _optionalDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed.toUtc();
      }
    }
  }
  return null;
}

double haversineDistanceKm({
  required double startLatitude,
  required double startLongitude,
  required double endLatitude,
  required double endLongitude,
}) {
  _validateCoordinate(startLatitude, startLongitude);
  _validateCoordinate(endLatitude, endLongitude);
  const earthRadiusKm = 6371.0;
  final latitudeDelta = _radians(endLatitude - startLatitude);
  final longitudeDelta = _radians(endLongitude - startLongitude);
  final startLatitudeRadians = _radians(startLatitude);
  final endLatitudeRadians = _radians(endLatitude);
  final a =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(startLatitudeRadians) *
          math.cos(endLatitudeRadians) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  final clamped = a.clamp(0.0, 1.0).toDouble();
  return earthRadiusKm *
      2 *
      math.atan2(math.sqrt(clamped), math.sqrt(1 - clamped));
}

double _radians(double value) => value * math.pi / 180.0;

void _validateCoordinate(double latitude, double longitude) {
  if (!latitude.isFinite ||
      !longitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    throw const InvalidOrderException('Invalid geographic coordinates.');
  }
}
