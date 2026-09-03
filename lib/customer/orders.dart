import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Order/order.dart';
import '../Order/order_repository.dart';
import '../global.dart';
import '../main.dart';
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

  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final customerId = supabase.auth.currentUser?.id;
      if (customerId == null || customerId.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Sign in to view your orders.';
        });
        return;
      }

      final repository = SupabaseOrderRepository(supabase);
      final activeOrders = await repository.listCustomerOrders(
        customerId: customerId,
        activeOnly: true,
      );
      final completedOrders = await repository.listCustomerOrders(
        customerId: customerId,
        activeOnly: false,
      );
      final orders = [...activeOrders, ...completedOrders]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _orders = orders.map(_toCustomerOrderMap).toList(growable: false);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Orders could not be loaded right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _orders
        .where((order) => order['status'] == _selectedStatus)
        .toList();

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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _OrdersError(message: _error!, onRetry: _loadOrders)
              : OrderList(
                  orders: filteredOrders,
                  selectedStatus: _selectedStatus,
                ),
        ),
      ],
    );
  }
}

class _OrdersError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OrdersError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 44,
              color: Color(0xff9e9e9e),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff757575)),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _toCustomerOrderMap(Order order) {
  final displayStatus = _customerDisplayStatus(order.status);
  final items = order.items
      .map(
        (item) => <String, dynamic>{
          'name': item.name,
          'quantity': item.quantity,
          'price': item.unitPriceSen / 100,
        },
      )
      .toList(growable: false);
  final info = switch (order.status) {
    OrderStatus.delivering => 'Rider is on the way',
    OrderStatus.pickedUp => 'Rider picked up your order',
    OrderStatus.delivered || OrderStatus.collected => 'Delivered',
    OrderStatus.cancelled => 'Order cancelled',
    _ => 'Preparing your order',
  };

  return {
    'orderId': order.orderNumber,
    'date': DateFormat('dd MMM yyyy, h:mm a').format(order.createdAt.toLocal()),
    'status': displayStatus,
    'items': items,
    'subtotal': order.subtotalSen / 100,
    'deliveryFee': order.deliveryFeeSen / 100,
    'discount': order.discountSen / 100,
    'totalPrice': 'RM ${(order.totalSen / 100).toStringAsFixed(2)}',
    'info': info,
    'icon':
        order.status == OrderStatus.pickedUp ||
            order.status == OrderStatus.delivering
        ? Icons.delivery_dining
        : Icons.fastfood,
    'typedOrder': order,
  };
}

String _customerDisplayStatus(OrderStatus status) {
  return switch (status) {
    OrderStatus.pickedUp => 'Delivering',
    OrderStatus.delivering => 'Delivering',
    OrderStatus.delivered || OrderStatus.collected => 'Completed',
    OrderStatus.cancelled => 'Cancelled',
    _ => 'Preparing',
  };
}

class OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final String selectedStatus;

  const OrderList({
    super.key,
    required this.orders,
    required this.selectedStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return SingleChildScrollView(
        child: FallbackMessage(
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
        return OrderCard(order: orders[index]);
      },
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final String orderId = order['orderId'] as String? ?? '';
    final String date = order['date'] as String? ?? '';
    final String status = order['status'] as String? ?? '';
    final List<Map<String, dynamic>> itemsList = order['items'] != null
        ? List<Map<String, dynamic>>.from(order['items'])
        : [];
    final String totalPrice = order['totalPrice'] as String? ?? '';
    final String info = order['info'] as String? ?? '';
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
        ? itemsList.first['name'] as String? ?? 'Item'
        : 'Order';
    final int remainingCount = itemsList.length > 1 ? itemsList.length - 1 : 0;
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
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
}
