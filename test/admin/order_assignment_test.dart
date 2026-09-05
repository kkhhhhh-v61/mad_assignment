import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mad_assignment/Order/branch_repository.dart';
import 'package:mad_assignment/Order/order.dart';
import 'package:mad_assignment/Order/rider_assignment_repository.dart';
import 'package:mad_assignment/admin/order_assignment.dart';

RiderAssignmentCandidate _rider({
  required String id,
  String branchId = 'branch-penang',
  String status = 'Online',
  bool isActive = true,
  int activeOrders = 0,
}) {
  return RiderAssignmentCandidate(
    riderId: id,
    name: id,
    email: '$id@example.com',
    vehicle: 'Motorcycle',
    plate: 'ABC 1234',
    status: status,
    isActive: isActive,
    branchId: branchId,
    branchName: 'DoorDish Penang',
    activeOrderCount: activeOrders,
  );
}

void main() {
  test('chooses an eligible same-branch rider deterministically', () {
    final selected = RiderAssignmentPolicy.choose(
      branchId: 'branch-penang',
      candidates: [
        _rider(id: 'rider-z'),
        _rider(id: 'rider-a'),
        _rider(id: 'rider-other', branchId: 'branch-kl'),
      ],
    );

    expect(selected?.riderId, 'rider-a');
  });

  test('rejects offline, inactive, busy, and unassigned riders', () {
    final candidates = [
      _rider(id: 'offline', status: 'Offline'),
      _rider(id: 'inactive', isActive: false),
      _rider(id: 'busy', activeOrders: 1),
      _rider(id: 'unassigned', branchId: ''),
    ];

    expect(
      RiderAssignmentPolicy.choose(
        branchId: 'branch-penang',
        candidates: candidates,
      ),
      isNull,
    );
  });

  test('queues when no same-branch rider is eligible', () {
    final selected = RiderAssignmentPolicy.choose(
      branchId: 'branch-penang',
      candidates: [_rider(id: 'busy', activeOrders: 1)],
    );

    expect(selected, isNull);
  });

  testWidgets('assignment page shows branch mapping controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminOrderAssignment(repository: _FakeAssignmentRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assign Rider'), findsOneWidget);
    expect(find.text('Rider branch assignments'), findsOneWidget);
    expect(find.text('DoorDish Penang'), findsOneWidget);
  });
}

class _FakeAssignmentRepository implements RiderAssignmentRepository {
  final rider = _rider(id: 'rider-a');

  @override
  Future<List<Order>> fetchUnassignedDeliveryOrders() async => const [];

  @override
  Future<List<RiderAssignmentCandidate>> fetchRiders() async => [rider];

  @override
  Future<List<BranchRecord>> fetchBranches() async => [
    const BranchRecord(
      id: 'branch-penang',
      branchCode: 'DD-07-01',
      name: 'DoorDish Penang',
      stateId: 7,
      stateCode: '07',
      address: '1 Jalan Test, Penang',
      latitude: 5.4,
      longitude: 100.3,
      isActive: true,
    ),
  ];

  @override
  Future<void> setRiderBranch({
    required String riderId,
    required String branchId,
  }) async {}

  @override
  Future<Order> assignOrder({required String orderId, String? riderId}) {
    throw UnimplementedError();
  }
}
