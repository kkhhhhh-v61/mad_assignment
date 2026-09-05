import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'order.dart';

abstract interface class OrderRepository {
  Future<Order> createOrder(OrderSubmission submission);

  Future<Order?> findOrder(String orderId);

  Future<List<Order>> listRiderOrders({
    required String riderId,
    required bool activeOnly,
  });

  Future<List<Order>> listCustomerOrders({
    required String customerId,
    required bool activeOnly,
  });

  Future<Order> transitionStatus({
    required String orderId,
    required OrderStatus expectedStatus,
    required OrderStatus nextStatus,
  });

  Future<Order> completeDelivery({
    required String orderId,
    required String proofPhotoPath,
    String? deliveryComments,
  });

  Stream<Order> watchOrder(String orderId);
}

class OrderRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const OrderRepositoryException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class OrderNotFoundException extends OrderRepositoryException {
  const OrderNotFoundException(super.message);
}

class SupabaseOrderRepository implements OrderRepository {
  static const _completionTimeout = Duration(seconds: 30);

  final SupabaseClient client;
  final Duration completionTimeout;

  const SupabaseOrderRepository(
    this.client, {
    this.completionTimeout = _completionTimeout,
  });

  @override
  Future<Order> createOrder(OrderSubmission submission) async {
    try {
      final usesPaymentRpc = submission.hasPaymentDetails;
      final response = await client.rpc(
        usesPaymentRpc
            ? 'create_order_with_payment'
            : 'create_order_with_items',
        params: usesPaymentRpc
            ? submission.toPaymentRpcParams()
            : submission.toRpcParams(),
      );
      return Order.fromJson(_asOrderMap(response));
    } on OrderDataException {
      rethrow;
    } catch (error) {
      throw OrderRepositoryException('Unable to create the order.', error);
    }
  }

  @override
  Future<Order?> findOrder(String orderId) async {
    if (orderId.trim().isEmpty) {
      throw const OrderRepositoryException('Order ID is required.');
    }
    try {
      final response = await client
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .maybeSingle();
      if (response == null) {
        return null;
      }
      return Order.fromJson(Map<String, dynamic>.from(response));
    } on OrderDataException {
      rethrow;
    } catch (error) {
      throw OrderRepositoryException('Unable to load the order.', error);
    }
  }

  @override
  Future<List<Order>> listRiderOrders({
    required String riderId,
    required bool activeOnly,
  }) async {
    final statuses = activeOnly
        ? const ['placed', 'preparing', 'ready', 'picked_up', 'delivering']
        : const ['delivered', 'collected', 'cancelled'];
    try {
      final response = await client
          .from('orders')
          .select('*, order_items(*)')
          .eq('rider_id', riderId)
          .inFilter('status', statuses)
          .order('created_at', ascending: false);
      return _asOrderList(response);
    } on OrderDataException {
      rethrow;
    } catch (error) {
      throw OrderRepositoryException('Unable to load rider deliveries.', error);
    }
  }

  @override
  Future<List<Order>> listCustomerOrders({
    required String customerId,
    required bool activeOnly,
  }) async {
    final statuses = activeOnly
        ? const ['placed', 'preparing', 'ready', 'picked_up', 'delivering']
        : const ['delivered', 'collected', 'cancelled'];
    try {
      final response = await client
          .from('orders')
          .select('*, order_items(*)')
          .eq('customer_id', customerId)
          .inFilter('status', statuses)
          .order('created_at', ascending: false);
      // Keep history readable for legacy Card rows missing a method ID;
      // new submissions remain strict through OrderSubmission validation.
      return _asOrderList(response, allowMissingCardMethodId: true);
    } on OrderDataException {
      rethrow;
    } catch (error) {
      throw OrderRepositoryException('Unable to load customer orders.', error);
    }
  }

  @override
  Future<Order> transitionStatus({
    required String orderId,
    required OrderStatus expectedStatus,
    required OrderStatus nextStatus,
  }) async {
    try {
      final response = await client.rpc(
        'transition_order_status',
        params: {
          'p_order_id': orderId,
          'p_expected_status': expectedStatus.databaseValue,
          'p_next_status': nextStatus.databaseValue,
        },
      );
      return Order.fromJson(_asOrderMap(response));
    } on OrderDataException {
      rethrow;
    } catch (error) {
      throw OrderRepositoryException('Unable to update order status.', error);
    }
  }

  @override
  Future<Order> completeDelivery({
    required String orderId,
    required String proofPhotoPath,
    String? deliveryComments,
  }) async {
    try {
      final response = await client
          .rpc(
            'complete_delivery',
            params: {
              'p_order_id': orderId,
              'p_proof_photo_path': proofPhotoPath,
              'p_delivery_comments': deliveryComments,
            },
          )
          .timeout(
            completionTimeout,
            onTimeout: () =>
                throw TimeoutException('Delivery completion timed out.'),
          );
      return Order.fromJson(_asOrderMap(response));
    } on OrderDataException {
      rethrow;
    } on TimeoutException catch (error) {
      throw OrderRepositoryException(
        'Delivery completion timed out. Check the connection and try again.',
        error,
      );
    } catch (error) {
      throw OrderRepositoryException('Unable to complete delivery.', error);
    }
  }

  @override
  Stream<Order> watchOrder(String orderId) {
    final controller = StreamController<Order>();
    final channelName =
        'order-$orderId-${DateTime.now().microsecondsSinceEpoch}';
    final channel = client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (_) async {
            try {
              final order = await findOrder(orderId);
              if (order != null && !controller.isClosed) {
                controller.add(order);
              }
            } catch (error, stackTrace) {
              if (!controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            }
          },
        )
        .subscribe();

    controller.onListen = () async {
      try {
        final order = await findOrder(orderId);
        if (order != null && !controller.isClosed) {
          controller.add(order);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    };
    controller.onCancel = () async {
      await channel.unsubscribe();
      await controller.close();
    };
    return controller.stream;
  }

  String? get currentUserId => client.auth.currentUser?.id;
}

Map<String, dynamic> _asOrderMap(dynamic response) {
  if (response is Map) {
    return Map<String, dynamic>.from(response);
  }
  if (response is List && response.isNotEmpty && response.first is Map) {
    return Map<String, dynamic>.from(response.first as Map);
  }
  throw const OrderDataException('The order response was empty or malformed.');
}

List<Order> _asOrderList(
  dynamic response, {
  bool allowMissingCardMethodId = false,
}) {
  if (response is! List) {
    throw const OrderDataException('The order list response was malformed.');
  }
  return response
      .map((row) {
        if (row is! Map) {
          throw const OrderDataException('An order row was malformed.');
        }
        return Order.fromJson(
          Map<String, dynamic>.from(row),
          allowMissingCardMethodId: allowMissingCardMethodId,
        );
      })
      .toList(growable: false);
}
