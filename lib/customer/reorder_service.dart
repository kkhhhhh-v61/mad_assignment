import '../Order/order.dart';
import 'address_coordinate_cache.dart';
import 'cart.dart';
import 'header.dart';

class ReorderException implements Exception {
  final String message;

  const ReorderException(this.message);

  @override
  String toString() => message;
}

class ReorderResult {
  final int itemCount;
  final double? branchDistanceKm;

  const ReorderResult({required this.itemCount, this.branchDistanceKm});
}

class CustomerReorderService {
  const CustomerReorderService._();

  static Future<ReorderResult> addOrderToCart({
    required Order order,
    AddressOption? currentAddress,
  }) async {
    _validateOrderStatus(order);

    double? branchDistanceKm;
    if (order.isDelivery) {
      final resolvedAddress = await resolveCurrentAddress(
        selectedAddress: currentAddress,
      );
      final destination = _destinationForReorder(
        order: order,
        currentAddress: resolvedAddress,
      );
      branchDistanceKm = _validateBranchCoverage(
        order: order,
        destination: destination,
      );
    }

    final reorderItems = cartItemsFromOrder(order);
    if (reorderItems.isEmpty) {
      throw const ReorderException('This order has no food items to reorder.');
    }

    final cartItems = await CartStorage.loadCart(order.customerId);
    for (final item in reorderItems) {
      final existingIndex = cartItems.indexWhere(
        (existing) => existing.isSameItem(item),
      );
      if (existingIndex == -1) {
        cartItems.add(item);
      } else {
        cartItems[existingIndex].quantity += item.quantity;
      }
    }
    await CartStorage.saveCart(cartItems, order.customerId);

    final itemCount = reorderItems.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );
    return ReorderResult(
      itemCount: itemCount,
      branchDistanceKm: branchDistanceKm,
    );
  }

  static List<CartItem> cartItemsFromOrder(Order order) {
    return order.items
        .map((item) {
          final customizations = _customizationsFromSnapshot(item);
          final snapshotPrice = item.unitPriceSen / 100.0;
          final customizationTotal = customizations.fold<double>(
            0.0,
            (total, customization) => total + customization.price,
          );
          final basePrice = customizationTotal <= snapshotPrice
              ? snapshotPrice - customizationTotal
              : snapshotPrice;

          return CartItem(
            id: item.foodId,
            name: item.name,
            price: basePrice,
            quantity: item.quantity,
            customizations: customizationTotal <= snapshotPrice
                ? customizations
                : const [],
          );
        })
        .toList(growable: false);
  }

  static Future<AddressOption?> resolveCurrentAddress({
    AddressOption? selectedAddress,
  }) async {
    var option = selectedAddress ?? CustomerHeader.cachedSelectedOption;
    if (option == null && CustomerHeader.cachedAddress.trim().isNotEmpty) {
      option = AddressOption(
        label: 'Current Address',
        fullAddress: CustomerHeader.cachedAddress,
        state: CustomerHeader.cachedState,
      );
    }
    if (option == null || option.fullAddress.trim().isEmpty) return null;
    if (_hasValidCoordinates(option.latitude, option.longitude)) {
      return option;
    }

    final cachedCoordinates =
        (await AddressCoordinateCache.loadAll())[option.fullAddress.trim()];
    if (cachedCoordinates == null) return option;
    return AddressOption(
      label: option.label,
      fullAddress: option.fullAddress,
      state: option.state,
      latitude: cachedCoordinates.latitude,
      longitude: cachedCoordinates.longitude,
      isDetected: option.isDetected,
      isDefault: option.isDefault,
    );
  }

  static DeliveryAddressSnapshot _destinationForReorder({
    required Order order,
    required AddressOption? currentAddress,
  }) {
    final original = order.deliveryAddressSnapshot;
    if (original == null) {
      throw const ReorderException(
        'This delivery order has no saved delivery address.',
      );
    }
    if (currentAddress == null) {
      throw const ReorderException(
        'Select or confirm a map-ready delivery address before reordering.',
      );
    }

    var latitude = currentAddress.latitude;
    var longitude = currentAddress.longitude;
    if (!_hasValidCoordinates(latitude, longitude) &&
        _sameAddress(currentAddress.fullAddress, original.formattedAddress) &&
        _hasValidCoordinates(original.latitude, original.longitude)) {
      latitude = original.latitude;
      longitude = original.longitude;
    }
    if (!_hasValidCoordinates(latitude, longitude)) {
      throw const ReorderException(
        'Confirm the delivery address on the map before reordering.',
      );
    }

    return DeliveryAddressSnapshot(
      label: currentAddress.label.trim().isEmpty
          ? original.label
          : currentAddress.label,
      formattedAddress: currentAddress.fullAddress,
      stateCode: original.stateCode,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static double _validateBranchCoverage({
    required Order order,
    required DeliveryAddressSnapshot destination,
  }) {
    final distanceKm = DeliveryDistancePolicy.estimateKm(
      branch: order.branchSnapshot,
      destination: destination,
    );
    if (distanceKm == null) {
      throw const ReorderException(
        'The previous branch or current address has no valid coordinates.',
      );
    }
    if (distanceKm > DeliveryDistancePolicy.maximumDistanceKm) {
      throw ReorderException(
        'Reorder rejected: the previous branch does not cover your current '
        'address (${distanceKm.toStringAsFixed(1)} km away; maximum is '
        '${DeliveryDistancePolicy.maximumDistanceKm.toStringAsFixed(0)} km).',
      );
    }
    return distanceKm;
  }

  static void _validateOrderStatus(Order order) {
    const reorderableStatuses = {
      OrderStatus.delivered,
      OrderStatus.collected,
      OrderStatus.cancelled,
    };
    if (!reorderableStatuses.contains(order.status)) {
      throw const ReorderException(
        'Only completed or cancelled orders can be reordered.',
      );
    }
  }

  static List<CartItemCustomization> _customizationsFromSnapshot(
    OrderItemSnapshot item,
  ) {
    final raw = item.selectedOptions['customizations'];
    if (raw is! List) return const [];

    final customizations = <CartItemCustomization>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final name = entry['name']?.toString().trim() ?? '';
      final price = (entry['price'] as num?)?.toDouble();
      if (name.isEmpty || price == null || !price.isFinite || price < 0) {
        continue;
      }
      customizations.add(CartItemCustomization(name: name, price: price));
    }
    return customizations;
  }

  static bool _sameAddress(String first, String second) {
    return first.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase() ==
        second.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  static bool _hasValidCoordinates(double? latitude, double? longitude) {
    return latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}
