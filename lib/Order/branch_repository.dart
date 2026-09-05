import 'package:supabase_flutter/supabase_flutter.dart';

import 'order.dart';

const branchSelectColumns =
    'id,branch_code,name,state_id,state_code,address,latitude,longitude,is_active';

class BranchStateOption {
  final int id;
  final String name;

  const BranchStateOption({required this.id, required this.name});

  String get code => id.toString().padLeft(2, '0');
}

const branchStateOptions = <BranchStateOption>[
  BranchStateOption(id: 1, name: 'Johor'),
  BranchStateOption(id: 2, name: 'Kedah'),
  BranchStateOption(id: 3, name: 'Kelantan'),
  BranchStateOption(id: 4, name: 'Melaka'),
  BranchStateOption(id: 5, name: 'Negeri Sembilan'),
  BranchStateOption(id: 6, name: 'Pahang'),
  BranchStateOption(id: 7, name: 'Pulau Pinang'),
  BranchStateOption(id: 8, name: 'Perak'),
  BranchStateOption(id: 9, name: 'Perlis'),
  BranchStateOption(id: 10, name: 'Sabah'),
  BranchStateOption(id: 11, name: 'Sarawak'),
  BranchStateOption(id: 12, name: 'Selangor'),
  BranchStateOption(id: 13, name: 'Terengganu'),
  BranchStateOption(id: 14, name: 'Kuala Lumpur'),
  BranchStateOption(id: 15, name: 'Labuan'),
  BranchStateOption(id: 16, name: 'Putrajaya'),
];

String nextBranchCode({
  required String stateCode,
  required Iterable<BranchRecord> existingBranches,
}) {
  final trimmedStateCode = stateCode.trim();
  if (trimmedStateCode.isEmpty) {
    throw const BranchRepositoryException('Branch state code is required.');
  }
  final normalizedStateCode = trimmedStateCode.padLeft(2, '0');

  final prefix = 'DD-$normalizedStateCode-';
  var highestSequence = 0;
  for (final branch in existingBranches) {
    final code = branch.branchCode.trim().toUpperCase();
    if (!code.startsWith(prefix)) continue;
    final sequenceText = code.substring(prefix.length);
    final sequence = int.tryParse(sequenceText);
    if (sequence != null && sequence > highestSequence) {
      highestSequence = sequence;
    }
  }

  return '$prefix${(highestSequence + 1).toString().padLeft(2, '0')}';
}

class BranchDraft {
  final String branchCode;
  final String name;
  final int stateId;
  final String stateCode;
  final String address;
  final double latitude;
  final double longitude;
  final bool isActive;

  BranchDraft({
    required this.branchCode,
    required this.name,
    required this.stateId,
    required this.stateCode,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isActive,
  }) {
    if (branchCode.trim().isEmpty ||
        name.trim().isEmpty ||
        stateCode.trim().isEmpty ||
        address.trim().isEmpty) {
      throw const BranchRepositoryException(
        'Branch code, name, state code, and address are required.',
      );
    }
    if (stateId <= 0) {
      throw const BranchRepositoryException('Branch state is invalid.');
    }
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw const BranchRepositoryException('Branch latitude is invalid.');
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw const BranchRepositoryException('Branch longitude is invalid.');
    }
  }

  Map<String, dynamic> toJson() => {
    'branch_code': branchCode.trim(),
    'name': name.trim(),
    'state_id': stateId,
    'state_code': stateCode.trim(),
    'address': address.trim(),
    'latitude': latitude,
    'longitude': longitude,
    'is_active': isActive,
  };
}

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

abstract interface class BranchAdminRepository {
  Future<List<BranchRecord>> fetchAllBranches();

  Future<BranchRecord> createBranch(BranchDraft draft);

  Future<BranchRecord> updateBranch({
    required String branchId,
    required BranchDraft draft,
  });

  Future<void> deleteBranch(String branchId);
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
          .select(branchSelectColumns)
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

class SupabaseBranchAdminRepository implements BranchAdminRepository {
  final SupabaseClient client;

  const SupabaseBranchAdminRepository(this.client);

  @override
  Future<List<BranchRecord>> fetchAllBranches() async {
    try {
      final response = await client
          .from('branches')
          .select(branchSelectColumns)
          .order('state_id')
          .order('name');
      return response
          .map((row) => BranchRecord.fromJson(row))
          .toList(growable: false);
    } on BranchRepositoryException {
      rethrow;
    } catch (error) {
      throw BranchRepositoryException(
        'Unable to load all restaurant branches.',
        error,
      );
    }
  }

  @override
  Future<BranchRecord> createBranch(BranchDraft draft) async {
    try {
      final response = await client
          .from('branches')
          .insert(draft.toJson())
          .select(branchSelectColumns)
          .single();
      return BranchRecord.fromJson(response);
    } on BranchRepositoryException {
      rethrow;
    } catch (error) {
      throw BranchRepositoryException('Unable to create the branch.', error);
    }
  }

  @override
  Future<BranchRecord> updateBranch({
    required String branchId,
    required BranchDraft draft,
  }) async {
    if (branchId.trim().isEmpty) {
      throw const BranchRepositoryException('Branch ID is required.');
    }
    try {
      final response = await client
          .from('branches')
          .update(draft.toJson())
          .eq('id', branchId)
          .select(branchSelectColumns)
          .single();
      return BranchRecord.fromJson(response);
    } on BranchRepositoryException {
      rethrow;
    } catch (error) {
      throw BranchRepositoryException('Unable to update the branch.', error);
    }
  }

  @override
  Future<void> deleteBranch(String branchId) async {
    if (branchId.trim().isEmpty) {
      throw const BranchRepositoryException('Branch ID is required.');
    }
    try {
      await client.from('branches').delete().eq('id', branchId);
    } catch (error) {
      throw BranchRepositoryException('Unable to delete the branch.', error);
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
