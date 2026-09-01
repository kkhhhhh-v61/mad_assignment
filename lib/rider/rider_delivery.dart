import 'package:intl/intl.dart';

import '../Order/order.dart';

class RiderDelivery {
  final Order order;
  final String customerName;
  final String customerPhone;

  const RiderDelivery({
    required this.order,
    this.customerName = 'Customer',
    this.customerPhone = '',
  });

  String get deliveryId => order.orderNumber;

  String get date =>
      DateFormat('dd MMM yyyy, h:mm a').format(order.createdAt.toLocal());

  String get status =>
      order.status == OrderStatus.delivered ||
          order.status == OrderStatus.collected ||
          order.status == OrderStatus.cancelled
      ? 'Completed'
      : 'Active';

  String get statusValue => order.status.databaseValue;

  String get address =>
      order.deliveryAddressSnapshot?.formattedAddress ??
      'Pickup at ${order.branchSnapshot.name}';

  String get totalPrice => 'RM ${(order.totalSen / 100).toStringAsFixed(2)}';

  String get info => order.status == OrderStatus.delivering
      ? 'Delivery in progress'
      : order.status == OrderStatus.delivered ||
            order.status == OrderStatus.collected
      ? 'Completed ${order.completedAt == null ? '' : DateFormat('dd MMM, h:mm a').format(order.completedAt!.toLocal())}'
      : 'Delivery pending';

  double? get destinationLatitude => order.deliveryAddressSnapshot?.latitude;

  double? get destinationLongitude => order.deliveryAddressSnapshot?.longitude;

  double? get branchLatitude => order.branchSnapshot.latitude;

  double? get branchLongitude => order.branchSnapshot.longitude;

  Map<String, dynamic> toLegacyMap() => {
    'deliveryId': deliveryId,
    'date': date,
    'status': status,
    'statusValue': statusValue,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'address': address,
    'totalPrice': totalPrice,
    'info': info,
    'order': order.toJson(),
  };
}
