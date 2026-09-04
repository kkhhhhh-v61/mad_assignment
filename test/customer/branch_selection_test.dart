import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mad_assignment/Order/branch_repository.dart';
import 'package:mad_assignment/customer/branch_selection.dart';

const _branches = <BranchRecord>[
  BranchRecord(
    id: 'branch-kl-01',
    branchCode: 'WPKL-01',
    name: 'DoorDish Kuala Lumpur',
    stateId: 14,
    stateCode: 'WPKL',
    address: '1 Jalan Test, Kuala Lumpur',
    latitude: 3.1390,
    longitude: 101.6869,
    isActive: true,
  ),
  BranchRecord(
    id: 'branch-kl-02',
    branchCode: 'WPKL-02',
    name: 'DoorDish Sentul',
    stateId: 14,
    stateCode: 'WPKL',
    address: '2 Jalan Example, Kuala Lumpur',
    latitude: 3.1738,
    longitude: 101.6940,
    isActive: true,
  ),
];

void main() {
  testWidgets('shows the selected branch name and address', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BranchSelection(
            selectedBranch: _branches.first,
            branches: _branches,
            isLoading: false,
            error: null,
            onTap: () {},
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text('Restaurant Branch'), findsOneWidget);
    expect(find.text('DoorDish Kuala Lumpur'), findsOneWidget);
    expect(find.text('1 Jalan Test, Kuala Lumpur'), findsOneWidget);
    expect(find.text('Delivery Address'), findsNothing);
  });

  testWidgets('lists branch name and address in the picker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BranchSelectionBottomSheet(
            branches: _branches,
            selectedBranch: _branches.first,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Choose Restaurant Branch'), findsOneWidget);
    expect(find.text('DoorDish Kuala Lumpur'), findsOneWidget);
    expect(find.text('DoorDish Sentul'), findsOneWidget);
    expect(find.text('2 Jalan Example, Kuala Lumpur'), findsOneWidget);
  });
}
