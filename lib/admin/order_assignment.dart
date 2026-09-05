import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Order/branch_repository.dart';
import '../Order/order.dart';
import '../Order/rider_assignment_repository.dart';
import 'header.dart';

const _assignmentAccent = Color.fromARGB(255, 255, 160, 122);
const _assignmentBackground = Color.fromARGB(255, 249, 250, 251);

class AdminOrderAssignment extends StatefulWidget {
  final RiderAssignmentRepository? repository;

  const AdminOrderAssignment({super.key, this.repository});

  @override
  State<AdminOrderAssignment> createState() => _AdminOrderAssignmentState();
}

class _AdminOrderAssignmentState extends State<AdminOrderAssignment> {
  late final RiderAssignmentRepository _repository;
  List<Order> _orders = const [];
  List<RiderAssignmentCandidate> _riders = const [];
  List<BranchRecord> _branches = const [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _busyOrderIds = <String>{};
  final Set<String> _busyRiderIds = <String>{};

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        SupabaseRiderAssignmentRepository(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<Object>([
        _repository.fetchUnassignedDeliveryOrders(),
        _repository.fetchRiders(),
        _repository.fetchBranches(),
      ]);
      if (!mounted) return;
      setState(() {
        _orders = results[0] as List<Order>;
        _riders = results[1] as List<RiderAssignmentCandidate>;
        _branches = results[2] as List<BranchRecord>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _assignmentErrorMessage(error);
      });
    }
  }

  Future<void> _assignOrder(Order order) async {
    if (_busyOrderIds.contains(order.id)) return;
    setState(() => _busyOrderIds.add(order.id));
    try {
      final assigned = await _repository.assignOrder(orderId: order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Assigned ${assigned.orderNumber} to an eligible rider.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_assignmentErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _busyOrderIds.remove(order.id));
    }
  }

  Future<void> _saveBranch(
    RiderAssignmentCandidate rider,
    String? branchId,
  ) async {
    if (branchId == null || _busyRiderIds.contains(rider.riderId)) return;
    setState(() => _busyRiderIds.add(rider.riderId));
    try {
      await _repository.setRiderBranch(
        riderId: rider.riderId,
        branchId: branchId,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_assignmentErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _busyRiderIds.remove(rider.riderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _assignmentBackground,
      body: Column(
        children: [
          const AdminHeader(pageTitle: 'Assign Rider'),
          Expanded(
            child: RefreshIndicator(
              color: _assignmentAccent,
              onRefresh: _load,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        children: [
          const SizedBox(height: 80.0),
          const Icon(
            Icons.assignment_late_outlined,
            size: 52,
            color: Colors.grey,
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Unable to load assignment data',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 20.0),
          Center(
            child: OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16.0, 18.0, 16.0, 40.0),
      children: [
        _SectionHeading(
          title: 'Ready deliveries',
          subtitle: 'Only unassigned delivery orders are shown.',
        ),
        if (_orders.isEmpty)
          const _EmptyCard(
            message: 'No ready delivery orders are waiting for a rider.',
          )
        else
          ..._orders.map(_buildOrderCard),
        const SizedBox(height: 24.0),
        _SectionHeading(
          title: 'Rider branch assignments',
          subtitle:
              'Each rider belongs to one branch. Online and idle riders are eligible for auto-assignment.',
        ),
        if (_riders.isEmpty)
          const _EmptyCard(message: 'No riders found.')
        else
          ..._riders.map(_buildRiderCard),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    final isBusy = _busyOrderIds.contains(order.id);
    final branchIsKnown = _branches.any(
      (branch) => branch.id == order.branchSnapshot.branchId,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(
                  label: order.status.databaseValue,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text('Branch: ${order.branchSnapshot.name}'),
            if (!branchIsKnown)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'This order has a legacy branch snapshot and needs a new branch UUID before assignment.',
                  style: TextStyle(color: Colors.deepOrange, fontSize: 12.0),
                ),
              ),
            const SizedBox(height: 12.0),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isBusy || !branchIsKnown
                    ? null
                    : () => _assignOrder(order),
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.electric_moped_outlined),
                label: Text(
                  isBusy ? 'Assigning...' : 'Auto-assign eligible rider',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _assignmentAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderCard(RiderAssignmentCandidate rider) {
    final isBusy = _busyRiderIds.contains(rider.riderId);
    final branchIds = _branches.map((branch) => branch.id).toSet();
    final selectedBranch = branchIds.contains(rider.branchId)
        ? rider.branchId
        : null;
    final availability = rider.activeOrderCount > 0
        ? 'On Delivery'
        : rider.status;
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rider.name,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(
                  label: availability,
                  color: availability == 'Online' ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text('${rider.vehicle} • ${rider.plate}'),
            if (rider.activeOrderCount > 0)
              Text(
                '${rider.activeOrderCount} active delivery',
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 12.0,
                ),
              ),
            const SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              initialValue: selectedBranch,
              decoration: const InputDecoration(
                labelText: 'Assigned branch',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _branches
                  .map(
                    (branch) => DropdownMenuItem<String>(
                      value: branch.id,
                      child: Text(branch.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: isBusy ? null : (value) => _saveBranch(rider, value),
            ),
            if (isBusy)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(color: _assignmentAccent),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3.0),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 12.0),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _assignmentErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('NO_ELIGIBLE_RIDER')) {
    return 'No online, idle rider is assigned to this branch. The order remains queued.';
  }
  if (text.contains('ORDER_NOT_READY')) {
    return 'The order must be Ready before a rider can be assigned.';
  }
  if (text.contains('BRANCH_ASSIGNMENT_REQUIRED')) {
    return 'This order has no valid branch UUID and cannot be assigned safely.';
  }
  if (text.contains('RIDER_ALREADY_ON_DELIVERY')) {
    return 'That rider already has an active delivery.';
  }
  if (text.contains('ADMIN_ROLE_REQUIRED')) {
    return 'An admin account is required for rider assignment.';
  }
  if (error is RiderAssignmentRepositoryException) return error.message;
  return 'Assignment failed. Please refresh and try again.';
}
