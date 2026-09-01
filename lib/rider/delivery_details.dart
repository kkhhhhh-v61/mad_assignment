import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../global.dart';
import '../Order/order.dart';
import 'data_gov_my_fuel_price_repository.dart';
import 'rider_delivery.dart';
import 'rider_fuel_estimate.dart';
import 'rider_fuel_estimator.dart';

class DeliveryDetails extends StatefulWidget {
  final RiderDelivery delivery;
  final RiderFuelEstimateService? fuelEstimateService;

  const DeliveryDetails({
    super.key,
    required this.delivery,
    this.fuelEstimateService,
  });

  @override
  State<DeliveryDetails> createState() => _DeliveryDetailsState();
}

class _DeliveryDetailsState extends State<DeliveryDetails> {
  RiderFuelEstimate? _fuelEstimate;
  String? _fuelError;
  bool _fuelLoading = true;
  DataGovMyFuelPriceRepository? _ownedFuelRepository;

  @override
  void initState() {
    super.initState();
    _loadFuelEstimate();
  }

  Future<void> _loadFuelEstimate() async {
    try {
      final service = widget.fuelEstimateService ?? await _defaultFuelService();
      final estimate = await service.forOrder(widget.delivery.order);
      if (!mounted) return;
      setState(() {
        _fuelEstimate = estimate;
        _fuelLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fuelLoading = false;
        _fuelError = 'Fuel estimate is unavailable right now.';
      });
    }
  }

  Future<RiderFuelEstimateService> _defaultFuelService() async {
    final preferences = await SharedPreferences.getInstance();
    _ownedFuelRepository = DataGovMyFuelPriceRepository(
      preferences: preferences,
    );
    return RiderFuelEstimateService(repository: _ownedFuelRepository!);
  }

  @override
  void dispose() {
    _ownedFuelRepository?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;
    return Scaffold(
      backgroundColor: const Color(0xfff9fafb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xdd000000),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          delivery.deliveryId,
          style: const TextStyle(
            color: Color(0xdd000000),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusHero(delivery: delivery),
              const SizedBox(height: 32),
              CustomerInfoCard(delivery: delivery),
              const SizedBox(height: 20),
              RiderFuelEstimateCard(
                estimate: _fuelEstimate,
                loading: _fuelLoading,
                error: _fuelError,
              ),
              const SizedBox(height: 20),
              EvidenceCard(delivery: delivery),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  final RiderDelivery delivery;

  const _StatusHero({required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: const Color(0xff4caf50).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt,
              size: 40,
              color: Color(0xff4caf50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            delivery.order.status == OrderStatus.cancelled
                ? 'Cancelled'
                : 'Completed',
            style: const TextStyle(
              color: Color(0xff4caf50),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Completed on ${delivery.date}',
            style: const TextStyle(color: Color(0xff9e9e9e), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class CustomerInfoCard extends StatelessWidget {
  final RiderDelivery delivery;

  const CustomerInfoCard({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(8, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xdd000000),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xfffff3e0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Color(0xffffa07a)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xdd000000),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      delivery.address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xff757575),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xffeeeeee)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Total',
                style: TextStyle(fontSize: 15, color: Color(0xff757575)),
              ),
              Text(
                delivery.totalPrice,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xffffa07a),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RiderFuelEstimateCard extends StatelessWidget {
  final RiderFuelEstimate? estimate;
  final bool loading;
  final String? error;

  const RiderFuelEstimateCard({
    super.key,
    required this.estimate,
    this.loading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(8, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: loading
          ? const Row(
              children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(width: 12),
                Text('Loading fuel estimate...'),
              ],
            )
          : estimate == null || !estimate!.isAvailable
          ? _UnavailableFuel(error: error ?? estimate?.unavailableReason)
          : _AvailableFuel(estimate: estimate!),
    );
  }
}

class _UnavailableFuel extends StatelessWidget {
  final String? error;

  const _UnavailableFuel({this.error});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.local_gas_station_outlined, color: Color(0xffffa07a)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fuel Estimate',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xdd000000),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error ?? 'Fuel estimate unavailable.',
                style: const TextStyle(fontSize: 13, color: Color(0xff757575)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Estimate only; it never changes the order total.',
                style: TextStyle(fontSize: 11, color: Color(0xff9e9e9e)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailableFuel extends StatelessWidget {
  final RiderFuelEstimate estimate;

  const _AvailableFuel({required this.estimate});

  @override
  Widget build(BuildContext context) {
    final price = estimate.fuelPrice!;
    final effectiveDate = DateFormat(
      'dd MMM yyyy',
    ).format(price.effectiveDate.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_gas_station_outlined,
              color: Color(0xffffa07a),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Fuel Estimate',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xdd000000),
                ),
              ),
            ),
            if (estimate.isFromCache)
              const Chip(
                label: Text('Cached', style: TextStyle(fontSize: 10)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _FuelRow(
          label: 'Distance (one way)',
          value: '${estimate.distanceKm!.toStringAsFixed(2)} km',
        ),
        _FuelRow(
          label: 'Assumed efficiency',
          value:
              '${RiderFuelEstimator.motorcycleEfficiencyKmPerLitre.toStringAsFixed(1)} km/L',
        ),
        _FuelRow(
          label: 'Estimated fuel',
          value: '${estimate.fuelLitres!.toStringAsFixed(2)} L',
        ),
        _FuelRow(
          label: 'General-market RON95',
          value: 'RM ${price.ron95RinggitPerLitre.toStringAsFixed(2)}/L',
        ),
        _FuelRow(
          label: 'Estimated cost',
          value: 'RM ${(estimate.estimatedCostSen! / 100).toStringAsFixed(2)}',
          emphasize: true,
        ),
        const SizedBox(height: 8),
        Text(
          'Effective $effectiveDate${estimate.isFromCache ? ' • using cached data' : ''}',
          style: const TextStyle(fontSize: 11, color: Color(0xff9e9e9e)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Estimate only; one-way straight-line distance. It never changes customer billing.',
          style: TextStyle(fontSize: 11, color: Color(0xff9e9e9e)),
        ),
      ],
    );
  }
}

class _FuelRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _FuelRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xff757575)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
              color: emphasize
                  ? const Color(0xffffa07a)
                  : const Color(0xdd000000),
            ),
          ),
        ],
      ),
    );
  }
}

class EvidenceCard extends StatelessWidget {
  final RiderDelivery delivery;

  const EvidenceCard({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final hasProof = delivery.order.proofPhotoPath != null;
    final comments = delivery.order.deliveryComments;
    if (!hasProof && (comments == null || comments.trim().isEmpty)) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: const FallbackMessage(
          icon: Icons.hide_image_outlined,
          title: 'No Evidence',
          description: 'No delivery evidence was provided.',
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(8, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Evidence',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xdd000000),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xfff5f5f5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                hasProof ? 'Proof photo stored securely' : 'No Photo Provided',
                style: const TextStyle(color: Color(0xff9e9e9e), fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Comments',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xdd000000),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comments?.trim().isNotEmpty == true ? comments! : 'No comments.',
            style: const TextStyle(fontSize: 14, color: Color(0xff757575)),
          ),
        ],
      ),
    );
  }
}
