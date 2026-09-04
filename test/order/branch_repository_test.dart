import 'package:flutter_test/flutter_test.dart';

import 'package:mad_assignment/Order/branch_repository.dart';

Map<String, dynamic> _branchJson({
  double latitude = 3.1390,
  double longitude = 101.6869,
}) => <String, dynamic>{
  'id': 'branch-kl-01',
  'branch_code': 'WPKL-01',
  'name': 'DoorDish Kuala Lumpur',
  'state_id': 14,
  'state_code': 'WPKL',
  'address': '1 Jalan Test, Kuala Lumpur',
  'latitude': latitude,
  'longitude': longitude,
  'is_active': true,
};

void main() {
  test('maps a valid active branch and exposes route snapshot', () {
    final branch = BranchRecord.fromJson(_branchJson());

    expect(branch.id, 'branch-kl-01');
    expect(branch.branchCode, 'WPKL-01');
    expect(branch.stateId, 14);
    expect(branch.address, '1 Jalan Test, Kuala Lumpur');
    expect(branch.isActive, isTrue);
    expect(branch.snapshot.branchId, branch.id);
    expect(branch.snapshot.latitude, branch.latitude);
    expect(branch.snapshot.longitude, branch.longitude);
  });

  test('rejects a branch with invalid coordinates', () {
    expect(
      () => BranchRecord.fromJson(_branchJson(latitude: 91.0)),
      throwsA(isA<BranchRepositoryException>()),
    );
    expect(
      () => BranchRecord.fromJson(_branchJson(longitude: -181.0)),
      throwsA(isA<BranchRepositoryException>()),
    );
  });

  test('rejects a branch with a missing required field', () {
    final json = _branchJson()..remove('address');

    expect(
      () => BranchRecord.fromJson(json),
      throwsA(isA<BranchRepositoryException>()),
    );
  });
}
