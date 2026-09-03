import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../rider/rider_location_service.dart';

abstract interface class CustomerRiderLocationRepository {
  Future<RiderLocation?> fetchLatest(String orderId);

  Stream<RiderLocation> watchLocation(String orderId);
}

class CustomerRiderLocationRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const CustomerRiderLocationRepositoryException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class SupabaseCustomerRiderLocationRepository
    implements CustomerRiderLocationRepository {
  final SupabaseClient client;

  const SupabaseCustomerRiderLocationRepository(this.client);

  @override
  Future<RiderLocation?> fetchLatest(String orderId) async {
    if (orderId.trim().isEmpty) {
      throw const CustomerRiderLocationRepositoryException(
        'Order ID is required.',
      );
    }
    try {
      final response = await client
          .from('rider_locations')
          .select(
            'order_id,rider_id,latitude,longitude,accuracy_metres,recorded_at',
          )
          .eq('order_id', orderId)
          .maybeSingle();
      if (response == null) {
        return null;
      }
      return RiderLocation.fromJson(response);
    } on CustomerRiderLocationRepositoryException {
      rethrow;
    } catch (error) {
      throw CustomerRiderLocationRepositoryException(
        'Unable to load the rider location.',
        error,
      );
    }
  }

  @override
  Stream<RiderLocation> watchLocation(String orderId) {
    if (orderId.trim().isEmpty) {
      return Stream<RiderLocation>.error(
        const CustomerRiderLocationRepositoryException('Order ID is required.'),
      );
    }

    final controller = StreamController<RiderLocation>();
    final channel = client
        .channel(
          'customer-rider-location-$orderId-${DateTime.now().microsecondsSinceEpoch}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rider_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isEmpty || controller.isClosed) {
              return;
            }
            try {
              controller.add(RiderLocation.fromJson(row));
            } catch (error, stackTrace) {
              if (!controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            }
          },
        )
        .subscribe();

    controller.onCancel = () async {
      await channel.unsubscribe();
      await controller.close();
    };
    return controller.stream;
  }
}
