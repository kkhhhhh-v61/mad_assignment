import 'package:flutter/material.dart';

import '../global.dart';
import 'delivery_details.dart';
import 'delivery_tracking.dart';
import 'header.dart';

class RiderDeliveries extends StatefulWidget {
  const RiderDeliveries({super.key});

  @override
  State<RiderDeliveries> createState() => _RiderDeliveriesState();
}

class _RiderDeliveriesState extends State<RiderDeliveries> {
  final List<String> _deliveryStatuses = const [
    'Active',
    'Completed',
  ];
  String _selectedStatus = 'Active';
  final List<Map<String, dynamic>> _deliveries = [];

  @override
  void initState() {
    super.initState();
    //TODO: Retrieve rider deliveries dynamically from backend based on selected status
  }

  @override
  Widget build(BuildContext context) {
    final filteredDeliveries = _deliveries
        .where((delivery) => delivery['status'] == _selectedStatus)
        .toList();

    return Column(
      children: [
        const RiderHeader(
          pageTitle: 'My Deliveries',
        ),
        const SizedBox(height: 16.0),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 238, 238, 238),
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Row(
            children: _deliveryStatuses.map((status) {
              final isSelected = status == _selectedStatus;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color.fromARGB(15, 0, 0, 0),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isSelected
                              ? const Color.fromARGB(255, 255, 160, 122)
                              : const Color.fromARGB(255, 117, 117, 117),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 13.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: DeliveryList(
            deliveries: filteredDeliveries,
            selectedStatus: _selectedStatus,
          ),
        ),
      ],
    );
  }
}

class DeliveryList extends StatelessWidget {
  final List<Map<String, dynamic>> deliveries;
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
          description: 'You have no ${selectedStatus.toLowerCase()} deliveries at the moment.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        return DeliveryCard(delivery: deliveries[index]);
      },
    );
  }
}

class DeliveryCard extends StatelessWidget {
  final Map<String, dynamic> delivery;

  const DeliveryCard({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final String deliveryId = delivery['deliveryId'] as String? ?? '';
    final String date = delivery['date'] as String? ?? '';
    final String status = delivery['status'] as String? ?? '';
    final String customerName = delivery['customerName'] as String? ?? '';
    final String address = delivery['address'] as String? ?? '';
    final String totalPrice = delivery['totalPrice'] as String? ?? '';
    final String info = delivery['info'] as String? ?? '';

    Color statusColor;
    IconData footerIcon;
    String buttonText;
    Color buttonColor;
    bool isOutlined;

    switch (status) {
      case 'Active':
        statusColor = const Color.fromARGB(255, 33, 150, 243);
        footerIcon = Icons.delivery_dining;
        buttonText = 'Track Delivery';
        buttonColor = const Color.fromARGB(255, 255, 160, 122);
        isOutlined = false;
        break;
      case 'Completed':
      default:
        statusColor = const Color.fromARGB(255, 76, 175, 80);
        footerIcon = Icons.check_circle_outline;
        buttonText = 'View Details';
        buttonColor = const Color.fromARGB(255, 255, 160, 122);
        isOutlined = true;
        break;
    }

    void handleTap() {
      if (status == 'Active') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryTracking(delivery: delivery),
          ),
        );
      } else if (status == 'Completed') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryDetails(delivery: delivery),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: handleTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deliveryId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: Color.fromARGB(221, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Color.fromARGB(255, 117, 117, 117),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(
                color: Color.fromARGB(255, 238, 238, 238),
                height: 1.0,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 245, 245, 245),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color.fromARGB(255, 158, 158, 158),
                    size: 30,
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
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(221, 0, 0, 0),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        address,
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: Color.fromARGB(255, 117, 117, 117),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  totalPrice,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Color.fromARGB(255, 255, 160, 122),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(
                color: Color.fromARGB(255, 238, 238, 238),
                height: 1.0,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      footerIcon,
                      size: 16.0,
                      color: const Color.fromARGB(255, 117, 117, 117),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      info,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Color.fromARGB(255, 117, 117, 117),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 32.0,
                  child: isOutlined
                      ? OutlinedButton(
                          onPressed: handleTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: buttonColor,
                            side: BorderSide(color: buttonColor),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: handleTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 12.0,
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
    );
  }
}
