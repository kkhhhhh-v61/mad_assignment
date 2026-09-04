import 'package:supabase_flutter/supabase_flutter.dart';

import 'order.dart';

class BranchRecord {
  final String id;
  final String branchCode;
  final String name;
  final int stateId;
  final String stateCode;
  final String address;
  final double latitude;
  final double longitude;
  final bool isActive;

  const BranchRecord({
    required this.id,
    required this.branchCode,
    required this.name,
    required this.stateId,
    required this.stateCode,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isActive,
  });

  factory BranchRecord.fromJson(Map<String, dynamic> json) {
    final latitude = _requiredDouble(json, 'latitude');
    final longitude = _requiredDouble(json, 'longitude');
    if (latitude < -90 || latitude > 90) {
      throw const BranchRepositoryException('Branch latitude is invalid.');
    }
    if (longitude < -180 || longitude > 180) {
      throw const BranchRepositoryException('Branch longitude is invalid.');
    }

    return BranchRecord(
      id: _requiredString(json, 'id'),
      branchCode: _requiredString(json, 'branch_code'),
      name: _requiredString(json, 'name'),
      stateId: _requiredInt(json, 'state_id'),
      stateCode: _requiredString(json, 'state_code'),
      address: _requiredString(json, 'address'),
      latitude: latitude,
      longitude: longitude,
      isActive: _requiredBool(json, 'is_active'),
    );
  }

  BranchSnapshot get snapshot => BranchSnapshot(
    branchId: id,
    name: name,
    stateCode: stateCode,
    latitude: latitude,
    longitude: longitude,
  );
}

abstract interface class BranchRepository {
  Future<List<BranchRecord>> fetchActiveBranches();
}

class BranchRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const BranchRepositoryException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class SupabaseBranchRepository implements BranchRepository {
  final SupabaseClient client;

  const SupabaseBranchRepository(this.client);

  @override
  Future<List<BranchRecord>> fetchActiveBranches() async {
    try {
      final response = await client
          .from('branches')
          .select(
            'id,branch_code,name,state_id,state_code,address,'
            'latitude,longitude,is_active',
          )
          .eq('is_active', true)
          .order('state_id')
          .order('name');
      return response
          .map((row) {
            return BranchRecord.fromJson(row);
          })
          .toList(growable: false);
    } on BranchRepositoryException {
      rethrow;
    } catch (error) {
      throw BranchRepositoryException(
        'Unable to load restaurant branches.',
        error,
      );
    }
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw BranchRepositoryException('Branch field "$key" is required.');
  }
  return value.trim();
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num && value == value.toInt()) return value.toInt();
  final parsed = int.tryParse('$value');
  if (parsed == null) {
    throw BranchRepositoryException('Branch field "$key" is invalid.');
  }
  return parsed;
}

double _requiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  if (parsed == null || !parsed.isFinite) {
    throw BranchRepositoryException('Branch field "$key" is invalid.');
  }
  return parsed;
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  throw BranchRepositoryException('Branch field "$key" is invalid.');
}
