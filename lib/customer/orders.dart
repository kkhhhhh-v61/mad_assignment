import 'package:flutter/material.dart';

// ignore: unused_import
import '../global.dart';
// TODELETE
import '../data.dart';
import 'header.dart';

class CustomerOrders extends StatefulWidget {
  const CustomerOrders({super.key});

  @override
  State<CustomerOrders> createState() => _CustomerOrdersState();
}

class _CustomerOrdersState extends State<CustomerOrders> {
  final List<String> _orderStatuses = const [
    'Preparing',
    'Delivering',
    'Completed',
    'Cancelled',
  ];
  String _selectedStatus = 'Preparing';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CustomerHeader(
          showSearch: false,
          showTitle: true,
          pageTitle: 'My Orders',
        ),
        const SizedBox(height: 16.0),
        // --- Status Tabs ---
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Row(
            children: _orderStatuses.map((status) {
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
                              : const Color(0xFF757575),
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
        // TODO: Replace with dynamic customer orders fetched from database
        Expanded(
          child: SingleChildScrollView(
            // TODELETE
            child: buildDummyOrders(),
          ),
        ),
      ],
    );
  }
}

// ==================== Order Card UI ====================
Widget buildOrderCard(Map<String, Object> order) {
  final String orderId = order['orderId'] as String;
  final String date = order['date'] as String;
  final String status = order['status'] as String;
  final String items = order['items'] as String;
  final String totalPrice = order['totalPrice'] as String;
  final String info = order['info'] as String;

  final bool isPreparing = status == 'Preparing';
  final Color statusColor = isPreparing
      ? const Color.fromARGB(255, 255, 160, 122)
      : const Color(0xFF4CAF50);

  return Container(
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
                  orderId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Color(0xDD000000),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Color(0xFF757575),
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
          child: Divider(color: Color(0xFFEEEEEE), height: 1.0),
        ),
        Text(
          items,
          style: const TextStyle(
            fontSize: 14.0,
            color: Color(0xDD000000),
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isPreparing ? Icons.access_time : Icons.check_circle_outline,
                  size: 16.0,
                  color: const Color(0xFF757575),
                ),
                const SizedBox(width: 4.0),
                Text(
                  info,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
      ],
    ),
  );
}
