import 'package:flutter/material.dart';

import '../global.dart';

import 'order_details.dart';

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
            child: buildDummyOrders(_selectedStatus),
          ),
        ),
      ],
    );
  }
}

// ==================== Order Card UI ====================
Widget buildOrderCard(BuildContext context, Map<String, Object> order) {
  final String orderId = order['orderId'] as String;
  final String date = order['date'] as String;
  final String status = order['status'] as String;
  final List<Map<String, Object>> itemsList = (order['items'] as List).cast<Map<String, Object>>();
  final String totalPrice = order['totalPrice'] as String;
  final String info = order['info'] as String;
  final IconData? icon = order['icon'] as IconData?;

  Color statusColor;
  IconData footerIcon;
  String buttonText;
  Color buttonColor;
  bool isOutlined;

  switch (status) {
    case 'Preparing':
      statusColor = const Color.fromARGB(255, 255, 160, 122);
      footerIcon = Icons.access_time;
      buttonText = 'Cancel Order';
      buttonColor = const Color(0xFFE53935);
      isOutlined = true;
      break;
    case 'Delivering':
      statusColor = const Color(0xFF2196F3);
      footerIcon = Icons.delivery_dining;
      buttonText = 'Track Order';
      buttonColor = const Color.fromARGB(255, 255, 160, 122);
      isOutlined = false;
      break;
    case 'Cancelled':
      statusColor = const Color(0xFFE53935);
      footerIcon = Icons.cancel_outlined;
      buttonText = 'Reorder';
      buttonColor = const Color.fromARGB(255, 255, 160, 122);
      isOutlined = false;
      break;
    case 'Completed':
    default:
      statusColor = const Color(0xFF4CAF50);
      footerIcon = Icons.check_circle_outline;
      buttonText = 'Reorder';
      buttonColor = const Color.fromARGB(255, 255, 160, 122);
      isOutlined = false;
      break;
  }

  // Parse items
  String firstItemName = itemsList.isNotEmpty ? itemsList.first['name'] as String : '';
  final int remainingCount = itemsList.length - 1;
  final String displayItems = remainingCount > 0
      ? '$firstItemName & $remainingCount item(s)'
      : firstItemName;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetails(order: order),
        ),
      );
    },
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
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF9E9E9E),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16.0),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayItems,
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xDD000000),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
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
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Divider(color: Color(0xFFEEEEEE), height: 1.0),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  footerIcon,
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
            SizedBox(
              height: 32,
              child: isOutlined
                  ? OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: buttonColor,
                        side: BorderSide(color: buttonColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
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
