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
  test('next branch code uses the next sequence for the selected state', () {
    final branches = [
      const BranchRecord(
        id: 'branch-1',
        branchCode: 'DD-07-01',
        name: 'DoorDish George Town',
        stateId: 7,
        stateCode: '07',
        address: '1 Jalan Test, George Town',
        latitude: 5.4141,
        longitude: 100.3288,
        isActive: true,
      ),
      const BranchRecord(
        id: 'branch-2',
        branchCode: 'DD-07-02',
        name: 'DoorDish Bukit Mertajam',
        stateId: 7,
        stateCode: '07',
        address: '2 Jalan Test, Bukit Mertajam',
        latitude: 5.3639,
        longitude: 100.4667,
        isActive: true,
      ),
      const BranchRecord(
        id: 'branch-3',
        branchCode: 'DD-14-09',
        name: 'DoorDish Kuala Lumpur',
        stateId: 14,
        stateCode: '14',
        address: '3 Jalan Test, Kuala Lumpur',
        latitude: 3.139,
        longitude: 101.6869,
        isActive: true,
      ),
    ];

    expect(
      nextBranchCode(stateCode: '07', existingBranches: branches),
      'DD-07-03',
    );
    expect(
      nextBranchCode(stateCode: '14', existingBranches: branches),
      'DD-14-10',
    );
  });

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

  testWidgets('create form auto assigns a code after state selection', (
    tester,
  ) async {
    final repository = _FakeBranchAdminRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminBranchForm(
          repository: repository,
          existingBranches: repository.branches,
        ),
      ),
    );

    expect(
      find.text('Automatically assigned after selecting a state.'),
      findsOneWidget,
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pulau Pinang (07)').last);
    await tester.pumpAndSettle();

    final codeField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(codeField.controller?.text, 'DD-07-01');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).readOnly,
      isTrue,
    );
  });
}
