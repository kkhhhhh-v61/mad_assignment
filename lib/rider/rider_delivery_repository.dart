import '../Order/order_repository.dart';
import 'rider_delivery.dart';

abstract interface class RiderDeliveryRepository {
  Future<List<RiderDelivery>> list({required bool activeOnly});
}

class SupabaseRiderDeliveryRepository implements RiderDeliveryRepository {
  final OrderRepository orderRepository;
  final String riderId;

  const SupabaseRiderDeliveryRepository({
    required this.orderRepository,
    required this.riderId,
  });

  @override
  Future<List<RiderDelivery>> list({required bool activeOnly}) async {
    final orders = await orderRepository.listRiderOrders(
      riderId: riderId,
      activeOnly: activeOnly,
    );
    return orders
        .map((order) => RiderDelivery(order: order))
        .toList(growable: false);
  }
}

class FakeRiderDeliveryRepository implements RiderDeliveryRepository {
  final List<RiderDelivery> deliveries;

  const FakeRiderDeliveryRepository(this.deliveries);

  @override
  Future<List<RiderDelivery>> list({required bool activeOnly}) async {
    return deliveries
        .where(
          (delivery) => activeOnly
              ? delivery.status == 'Active'
              : delivery.status == 'Completed',
        )
        .toList(growable: false);
  }
}

class FailingRiderDeliveryRepository implements RiderDeliveryRepository {
  final Object error;

  const FailingRiderDeliveryRepository(this.error);

  @override
  Future<List<RiderDelivery>> list({required bool activeOnly}) {
    return Future<List<RiderDelivery>>.error(error);
  }
}
