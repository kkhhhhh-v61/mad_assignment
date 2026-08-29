import 'package:flutter/material.dart';

import '../global.dart';

class DeliveryDetails extends StatelessWidget {
  final Map<String, dynamic> delivery;

  const DeliveryDetails({super.key, required this.delivery});

  String get deliveryId => delivery['deliveryId'] as String;
  String get date => delivery['date'] as String;
  String get status => delivery['status'] as String;
  String get customerName => delivery['customerName'] as String;
  String get address => delivery['address'] as String;
  String get totalPrice => delivery['totalPrice'] as String;

  @override
  Widget build(BuildContext context) {
    Color statusColor = const Color.fromARGB(255, 76, 175, 80);
    IconData heroIcon = Icons.task_alt;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(221, 0, 0, 0),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          deliveryId,
          style: const TextStyle(
            color: Color.fromARGB(221, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20.0, bottom: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(heroIcon, size: 40, color: statusColor),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Completed on $date',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 158, 158, 158),
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),
              CustomerInfoCard(
                customerName: customerName,
                address: address,
                totalPrice: totalPrice,
              ),
              const SizedBox(height: 20.0),
              EvidenceCard(delivery: delivery),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerInfoCard extends StatelessWidget {
  final String customerName;
  final String address;
  final String totalPrice;

  const CustomerInfoCard({
    super.key,
    required this.customerName,
    required this.address,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
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
              fontSize: 16.0,
              color: Color.fromARGB(221, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 243, 224),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.0,
                        color: Color.fromARGB(221, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Color.fromARGB(255, 117, 117, 117),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Color.fromARGB(255, 238, 238, 238)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Total',
                style: TextStyle(
                  fontSize: 15.0,
                  color: Color.fromARGB(255, 117, 117, 117),
                ),
              ),
              Text(
                totalPrice,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EvidenceCard extends StatelessWidget {
  final Map<String, dynamic> delivery;

  const EvidenceCard({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final String? evidencePhotoUrl = delivery['evidencePhotoUrl'] as String?;
    final String? comments = delivery['evidenceComments'] as String?;

    if (evidencePhotoUrl == null && comments == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const FallbackMessage(
          icon: Icons.hide_image_outlined,
          title: 'No Evidence',
          description: 'No delivery evidence was provided.',
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
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
              fontSize: 16.0,
              color: Color.fromARGB(221, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 16.0),
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 245, 245, 245),
              borderRadius: BorderRadius.circular(12.0),
              image: evidencePhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(evidencePhotoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: evidencePhotoUrl == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 48,
                          color: Color.fromARGB(255, 200, 200, 200),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'No Photo Provided',
                          style: TextStyle(
                            color: Color.fromARGB(255, 158, 158, 158),
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Comments',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
              color: Color.fromARGB(221, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            comments ?? 'No comments.',
            style: const TextStyle(
              fontSize: 14.0,
              color: Color.fromARGB(255, 117, 117, 117),
            ),
          ),
        ],
      ),
    );
  }
}
