import 'package:flutter/material.dart';

import '../global.dart';
import 'delivery_details.dart';
import 'delivery_tracking.dart';
import 'header.dart';
import 'rider_delivery.dart';
import 'rider_delivery_repository.dart';

class RiderDeliveries extends StatefulWidget {
  final RiderDeliveryRepository? repository;

  const RiderDeliveries({super.key, this.repository});

  @override
  State<RiderDeliveries> createState() => _RiderDeliveriesState();
}

class _RiderDeliveriesState extends State<RiderDeliveries> {
  final List<String> _deliveryStatuses = const ['Active', 'Completed'];
  String _selectedStatus = 'Active';
  List<RiderDelivery> _deliveries = const [];
  bool _loading = true;
  String? _error;

  RiderDeliveryRepository? get _repository => widget.repository;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    final repository = _repository;
    if (repository == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Rider delivery data is not configured yet.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deliveries = await repository.list(
        activeOnly: _selectedStatus == 'Active',
      );
      if (!mounted) return;
      setState(() {
        _deliveries = deliveries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load deliveries. Please try again.';
      });
    }
  }

  void _selectStatus(String status) {
    if (status == _selectedStatus) return;
    setState(() {
      _selectedStatus = status;
      _deliveries = const [];
    });
    _loadDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const RiderHeader(pageTitle: 'My Deliveries'),
        const SizedBox(height: 16),
        _StatusSelector(
          statuses: _deliveryStatuses,
          selectedStatus: _selectedStatus,
          onSelected: _selectStatus,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _DeliveryError(message: _error!, onRetry: _loadDeliveries)
              : DeliveryList(
                  deliveries: _deliveries,
                  selectedStatus: _selectedStatus,
                ),
        ),
      ],
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final List<String> statuses;
  final String selectedStatus;
  final ValueChanged<String> onSelected;

  const _StatusSelector({
    required this.statuses,
    required this.selectedStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffeeeeee),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: statuses
            .map((status) {
              final selected = status == selectedStatus;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: '$status deliveries',
                  child: GestureDetector(
                    onTap: () => onSelected(status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: selected
                            ? const [
                                BoxShadow(
                                  color: Color.fromARGB(15, 0, 0, 0),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          status,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xffffa07a)
                                : const Color(0xff757575),
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _DeliveryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DeliveryError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FallbackMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load deliveries',
            description: message,
          ),
          const SizedBox(height: 4),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class DeliveryList extends StatelessWidget {
  final List<RiderDelivery> deliveries;
  final String selectedStatus;

  const DeliveryList({
    super.key,
    required this.deliveries,
    required this.selectedStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (deliveries.isEmpty) {
      return SingleChildScrollView(
        child: FallbackMessage(
          icon: Icons.local_shipping_outlined,
          title: 'No Deliveries Found',
          description:
              'You have no ${selectedStatus.toLowerCase()} deliveries at the moment.',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: deliveries.length,
      itemBuilder: (context, index) =>
          DeliveryCard(delivery: deliveries[index]),
    );
  }
}

class DeliveryCard extends StatelessWidget {
  final RiderDelivery delivery;

  const DeliveryCard({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final active = delivery.status == 'Active';
    final statusColor = active
        ? const Color(0xff2196f3)
        : const Color(0xff4caf50);
    final buttonText = active ? 'Track Delivery' : 'View Details';

    void handleTap() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => active
              ? DeliveryTracking(delivery: delivery)
              : DeliveryDetails(delivery: delivery),
        ),
      );
    }

    return Semantics(
      button: true,
      label: '$buttonText for ${delivery.deliveryId}',
      child: GestureDetector(
        onTap: handleTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(20, 0, 0, 0),
                blurRadius: 8,
                spreadRadius: 1,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.deliveryId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xdd000000),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          delivery.date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      delivery.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xffeeeeee), height: 1),
              ),
              Row(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xfff5f5f5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Color(0xff9e9e9e),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xdd000000),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          delivery.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    delivery.totalPrice,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xffffa07a),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xffeeeeee), height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Icon(
                          active
                              ? Icons.delivery_dining
                              : Icons.check_circle_outline,
                          size: 16,
                          color: const Color(0xff757575),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            delivery.info,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff757575),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: active
                        ? ElevatedButton(
                            onPressed: handleTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffffa07a),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              buttonText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: handleTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xffffa07a),
                              side: const BorderSide(color: Color(0xffffa07a)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              buttonText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
