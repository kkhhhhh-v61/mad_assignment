import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_assignment/Order/branch_repository.dart';
import 'package:mad_assignment/admin/branch_management.dart';

class _FakeBranchAdminRepository implements BranchAdminRepository {
  List<BranchRecord> branches = [
    const BranchRecord(
      id: 'branch-1',
      branchCode: 'DD-14-01',
      name: 'DoorDish Kuala Lumpur',
      stateId: 14,
      stateCode: '14',
      address: '1 Jalan Test, Kuala Lumpur',
      latitude: 3.139,
      longitude: 101.6869,
      isActive: true,
    ),
  ];

  @override
  Future<List<BranchRecord>> fetchAllBranches() async => branches;

  @override
  Future<BranchRecord> createBranch(BranchDraft draft) async {
    final branch = BranchRecord(
      id: 'branch-2',
      branchCode: draft.branchCode,
      name: draft.name,
      stateId: draft.stateId,
      stateCode: draft.stateCode,
      address: draft.address,
      latitude: draft.latitude,
      longitude: draft.longitude,
      isActive: draft.isActive,
    );
    branches = [...branches, branch];
    return branch;
  }

  @override
  Future<BranchRecord> updateBranch({
    required String branchId,
    required BranchDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteBranch(String branchId) async {
    branches = branches.where((branch) => branch.id != branchId).toList();
  }
}

void main() {
  testWidgets('admin branch page lists branches and opens create form', (
    tester,
  ) async {
    final repository = _FakeBranchAdminRepository();
    await tester.pumpWidget(
      MaterialApp(home: AdminBranchManagement(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Branch Management'), findsOneWidget);
    expect(find.text('DoorDish Kuala Lumpur'), findsOneWidget);
    expect(find.text('DD-14-01  •  State 14'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Create Branch'), findsNWidgets(2));
    expect(find.text('Branch Code'), findsOneWidget);
  });
}
