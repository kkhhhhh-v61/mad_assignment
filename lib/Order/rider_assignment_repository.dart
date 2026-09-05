import 'package:supabase_flutter/supabase_flutter.dart';

import 'branch_repository.dart';
import 'order.dart';

const _activeAssignmentStatuses = <String>{'ready', 'picked_up', 'delivering'};

class RiderAssignmentRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const RiderAssignmentRepositoryException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class RiderAssignmentCandidate {
  final String riderId;
  final String name;
  final String email;
  final String vehicle;
  final String plate;
  final String status;
  final bool isActive;
  final String? branchId;
  final String? branchName;
  final int activeOrderCount;

  const RiderAssignmentCandidate({
    required this.riderId,
    required this.name,
    required this.email,
    required this.vehicle,
    required this.plate,
    required this.status,
    required this.isActive,
    required this.branchId,
    required this.branchName,
    required this.activeOrderCount,
  });

  bool get isEligible =>
      isActive &&
      status == 'Online' &&
      branchId?.isNotEmpty == true &&
      activeOrderCount == 0;

  RiderAssignmentCandidate copyWith({String? branchId, String? branchName}) {
    return RiderAssignmentCandidate(
      riderId: riderId,
      name: name,
      email: email,
      vehicle: vehicle,
      plate: plate,
      status: status,
      isActive: isActive,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      activeOrderCount: activeOrderCount,
    );
  }
}

abstract interface class RiderAssignmentRepository {
  Future<List<Order>> fetchUnassignedDeliveryOrders();

  Future<List<RiderAssignmentCandidate>> fetchRiders();

  Future<List<BranchRecord>> fetchBranches();

  Future<void> setRiderBranch({
    required String riderId,
    required String branchId,
  });

  Future<Order> assignOrder({required String orderId, String? riderId});
}

class SupabaseRiderAssignmentRepository implements RiderAssignmentRepository {
  final SupabaseClient client;

  const SupabaseRiderAssignmentRepository(this.client);

  @override
  Future<List<Order>> fetchUnassignedDeliveryOrders() async {
    try {
      final response = await client
          .from('orders')
          .select('*, order_items(*)')
          .eq('fulfilment_type', 'delivery')
          .eq('status', 'ready')
          .isFilter('rider_id', null)
          .order('created_at', ascending: false);
      return response
          .map((row) => Order.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } on OrderDataException {
      rethrow;
    } catch (error) {
      throw RiderAssignmentRepositoryException(
        'Unable to load unassigned delivery orders.',
        error,
      );
    }
  }

  @override
  Future<List<RiderAssignmentCandidate>> fetchRiders() async {
    try {
      final riderResponse = await client
          .from('riders')
          .select('id, vehicle, plate, status, is_active')
          .order('id');
      final riderRows = riderResponse
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
      if (riderRows.isEmpty) return const [];

      final riderIds = riderRows
          .map((row) => row['id'].toString())
          .toList(growable: false);
      final mappings = await client
          .from('rider_branch_assignments')
          .select('rider_id, branch_id')
          .inFilter('rider_id', riderIds);
      final branchByRider = <String, String>{
        for (final row in mappings)
          row['rider_id'].toString(): row['branch_id'].toString(),
      };

      final activeOrders = await client
          .from('orders')
          .select('rider_id, status')
          .inFilter('status', _activeAssignmentStatuses.toList());
      final activeCountByRider = <String, int>{};
      for (final row in activeOrders) {
        final riderId = row['rider_id']?.toString();
        if (riderId == null || riderId.isEmpty) continue;
        activeCountByRider[riderId] = (activeCountByRider[riderId] ?? 0) + 1;
      }

      final profiles = await client
          .from('profiles')
          .select('id, name, email')
          .inFilter('id', riderIds);
      final profileById = <String, Map<String, dynamic>>{
        for (final row in profiles)
          row['id'].toString(): Map<String, dynamic>.from(row),
      };

      final branches = await fetchBranches();
      final branchById = <String, BranchRecord>{
        for (final branch in branches) branch.id: branch,
      };

      return riderRows
          .map((row) {
            final riderId = row['id'].toString();
            final profile = profileById[riderId] ?? const <String, dynamic>{};
            final branchId = branchByRider[riderId];
            return RiderAssignmentCandidate(
              riderId: riderId,
              name: profile['name']?.toString() ?? 'Unnamed rider',
              email: profile['email']?.toString() ?? '',
              vehicle: row['vehicle']?.toString() ?? 'Unknown vehicle',
              plate: row['plate']?.toString() ?? 'No plate',
              status: row['status']?.toString() ?? 'Offline',
              isActive: row['is_active'] == true,
              branchId: branchId,
              branchName: branchId == null ? null : branchById[branchId]?.name,
              activeOrderCount: activeCountByRider[riderId] ?? 0,
            );
          })
          .toList(growable: false);
    } on RiderAssignmentRepositoryException {
      rethrow;
    } catch (error) {
      throw RiderAssignmentRepositoryException(
        'Unable to load rider assignment data.',
        error,
      );
    }
  }

  @override
  Future<List<BranchRecord>> fetchBranches() async {
    try {
      final response = await client
          .from('branches')
          .select(branchSelectColumns)
          .eq('is_active', true)
          .order('state_id')
          .order('name');
      return response
          .map((row) => BranchRecord.fromJson(row))
          .toList(growable: false);
    } on BranchRepositoryException {
      rethrow;
    } catch (error) {
      throw RiderAssignmentRepositoryException(
        'Unable to load active branches.',
        error,
      );
    }
  }

  @override
  Future<void> setRiderBranch({
    required String riderId,
    required String branchId,
  }) async {
    if (riderId.trim().isEmpty || branchId.trim().isEmpty) {
      throw const RiderAssignmentRepositoryException(
        'Rider and branch are required.',
      );
    }
    try {
      await client.from('rider_branch_assignments').upsert({
        'rider_id': riderId,
        'branch_id': branchId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'rider_id');
    } catch (error) {
      throw RiderAssignmentRepositoryException(
        'Unable to save the rider branch.',
        error,
      );
    }
  }

  @override
  Future<Order> assignOrder({required String orderId, String? riderId}) async {
    if (orderId.trim().isEmpty) {
      throw const RiderAssignmentRepositoryException('Order ID is required.');
    }
    try {
      final params = <String, dynamic>{'p_order_id': orderId};
      if (riderId != null) params['p_rider_id'] = riderId;
      final response = await client.rpc('assign_order_rider', params: params);
      if (response is Map) {
        return Order.fromJson(Map<String, dynamic>.from(response));
      }
      if (response is List && response.isNotEmpty && response.first is Map) {
        return Order.fromJson(Map<String, dynamic>.from(response.first as Map));
      }
      throw const OrderDataException('The assignment response was malformed.');
    } on OrderDataException {
      rethrow;
    } catch (error) {
      throw RiderAssignmentRepositoryException(
        'Unable to assign the delivery rider.',
        error,
      );
    }
  }
}

class RiderAssignmentPolicy {
  const RiderAssignmentPolicy._();

  /// Mirrors the server's safe fallback: same branch, active, Online, and no
  /// active delivery. Without a general idle-rider location source, ties are
  /// deterministic by rider ID.
  static RiderAssignmentCandidate? choose({
    required String branchId,
    required Iterable<RiderAssignmentCandidate> candidates,
  }) {
    final eligible =
        candidates
            .where(
              (candidate) =>
                  candidate.branchId == branchId && candidate.isEligible,
            )
            .toList(growable: false)
          ..sort((a, b) => a.riderId.compareTo(b.riderId));
    return eligible.isEmpty ? null : eligible.first;
  }
}
