import 'package:flutter/material.dart';

import '../global.dart';
import 'header.dart';
import 'order_details.dart';
import 'order_tracking.dart';

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
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 238, 238, 238),
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
          child: Builder(
            builder: (context) {
              List<Map<String, dynamic>> dummyOrders = [];
              //TODO: Retrieve user orders dynamically from backend based on selected status
              // --- TOREMOVE ---
              dummyOrders = [
                {
                  'orderId': '#ORD-8492',
                  'date': 'Today, 12:45 PM',
                  'status': 'Preparing',
                  'items': [
                    {
                      'name': 'Classic Beef Burger',
                      'quantity': 2,
                      'price': 16.90,
                    },
                    {
                      'name': 'Golden French Fries',
                      'quantity': 1,
                      'price': 5.80,
                    },
                    {'name': 'Iced Lemon Tea', 'quantity': 2, 'price': 5.00},
                  ],
                  'subtotal': 49.60,
                  'deliveryFee': 5.00,
                  'discount': 0.00,
                  'totalPrice': 'RM 54.60',
                  'info': 'Estimated Delivery: 15-20 mins',
                  'icon': Icons.lunch_dining,
                },
                {
                  'orderId': '#ORD-8488',
                  'date': 'Today, 12:15 PM',
                  'status': 'Delivering',
                  'items': [
                    {
                      'name': 'Classic Beef Burger',
                      'quantity': 2,
                      'price': 16.90,
                    },
                    {'name': 'Iced Lemon Tea', 'quantity': 1, 'price': 5.00},
                  ],
                  'subtotal': 38.80,
                  'deliveryFee': 3.00,
                  'discount': 5.00,
                  'totalPrice': 'RM 36.80',
                  'info': 'Estimated Arrival: 5 mins',
                  'icon': Icons.lunch_dining,
                },
                {
                  'orderId': '#ORD-8485',
                  'date': 'Today, 11:30 AM',
                  'status': 'Preparing',
                  'items': [
                    {
                      'name': 'Pepperoni Feast Pizza',
                      'quantity': 1,
                      'price': 28.90,
                    },
                    {
                      'name': 'Crispy Mozzarella Sticks',
                      'quantity': 1,
                      'price': 12.90,
                    },
                  ],
                  'subtotal': 41.80,
                  'deliveryFee': 4.00,
                  'discount': 0.00,
                  'totalPrice': 'RM 45.80',
                  'info': 'Estimated Delivery: 25-30 mins',
                  'icon': Icons.local_pizza,
                },
                {
                  'orderId': '#ORD-8470',
                  'date': 'Yesterday, 7:15 PM',
                  'status': 'Completed',
                  'items': [
                    {'name': 'Spicy Beef Ramen', 'quantity': 1, 'price': 22.90},
                    {
                      'name': 'Belgian Chocolate Sundae',
                      'quantity': 1,
                      'price': 6.90,
                    },
                  ],
                  'subtotal': 29.80,
                  'deliveryFee': 4.00,
                  'discount': 2.00,
                  'totalPrice': 'RM 31.80',
                  'info': 'Delivered in 18 mins',
                  'icon': Icons.ramen_dining,
                },
                {
                  'orderId': '#ORD-8462',
                  'date': 'Yesterday, 1:30 PM',
                  'status': 'Cancelled',
                  'items': [
                    {
                      'name': 'Pepperoni Feast Pizza',
                      'quantity': 1,
                      'price': 28.90,
                    },
                  ],
                  'subtotal': 28.90,
                  'deliveryFee': 4.00,
                  'discount': 0.00,
                  'totalPrice': 'RM 32.90',
                  'info': 'Cancelled by restaurant',
                  'icon': Icons.local_pizza,
                },
              ];
              // --- END TOREMOVE ---

              final filteredOrders = dummyOrders
                  .where((order) => order['status'] == _selectedStatus)
                  .toList();

              return buildOrderList(context, filteredOrders, _selectedStatus);
            },
          ),
        ),
      ],
    );
  }
}

Widget buildOrderList(
  BuildContext context,
  List<Map<String, dynamic>> orders,
  String selectedStatus,
) {
  if (orders.isEmpty) {
    return SingleChildScrollView(
      child: buildFallbackMessage(
        icon: Icons.receipt_long_outlined,
        title: 'No Orders Found',
        description: 'You have no $selectedStatus orders at the moment.',
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
    itemCount: orders.length,
    itemBuilder: (context, index) {
      return buildOrderCard(context, orders[index]);
    },
  );
}

Widget buildOrderCard(BuildContext context, Map<String, dynamic> order) {
  final String orderId = order['orderId'] as String;
  final String date = order['date'] as String;
  final String status = order['status'] as String;
  final List<Map<String, dynamic>> itemsList = (order['items'] as List)
      .cast<Map<String, dynamic>>();
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
      buttonColor = const Color.fromARGB(255, 229, 57, 53);
      isOutlined = true;
      break;
    case 'Delivering':
      statusColor = const Color.fromARGB(255, 33, 150, 243);
      footerIcon = Icons.delivery_dining;
      buttonText = 'Track Order';
      buttonColor = const Color.fromARGB(255, 255, 160, 122);
      isOutlined = false;
      break;
    case 'Cancelled':
      statusColor = const Color.fromARGB(255, 229, 57, 53);
      footerIcon = Icons.cancel_outlined;
      buttonText = 'Reorder';
      buttonColor = const Color.fromARGB(255, 255, 160, 122);
      isOutlined = true;
      break;
    case 'Completed':
    default:
      statusColor = const Color.fromARGB(255, 76, 175, 80);
      footerIcon = Icons.check_circle_outline;
      buttonText = 'Reorder';
      buttonColor = const Color.fromARGB(255, 255, 160, 122);
      isOutlined = true;
      break;
  }

  String firstItemName = itemsList.isNotEmpty
      ? itemsList.first['name'] as String
      : '';
  final int remainingCount = itemsList.length - 1;
  final String displayItems = remainingCount > 0
      ? '$firstItemName & $remainingCount item(s)'
      : firstItemName;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderDetails(order: order)),
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
              if (icon != null) ...[
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 245, 245, 245),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    icon,
                    color: const Color.fromARGB(255, 158, 158, 158),
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
                        color: Color.fromARGB(221, 0, 0, 0),
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
                  const SizedBox(width: 4.0),
                  Text(
                    info,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Color.fromARGB(255, 117, 117, 117),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: buttonText == 'Track Order'
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderTracking(order: order),
                                  ),
                                );
                              }
                            : () {},
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
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
