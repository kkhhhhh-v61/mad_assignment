import 'package:flutter/material.dart';

import '../data.dart';
import 'header.dart';

class CustomerOrders extends StatefulWidget {
  const CustomerOrders({super.key});

  @override
  State<CustomerOrders> createState() => _CustomerOrdersState();
}

class _CustomerOrdersState extends State<CustomerOrders> {
  String _selectedStatus = orderStatuses.first;

  @override
  Widget build(BuildContext context) {
    final filteredOrders =
        orderItems.where((order) => order.status == _selectedStatus).toList();

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
            children: orderStatuses.map((status) {
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
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
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
        // --- Order List ---
        Expanded(
          child: filteredOrders.isEmpty
              ? const Center(
                  child: Text(
                    'No orders found.',
                    style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16.0),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(filteredOrders[index]);
                  },
                ),
        ),
      ],
    );
  }

  // --- Order Card ---
  Widget _buildOrderCard(OrderItem order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(20, 0, 0, 0),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Order Title & Date/ID ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(order.icon, color: const Color.fromARGB(255, 255, 160, 122), size: 26),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.displayTitle,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xDD000000),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Text(
                          order.orderId,
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: Color.fromARGB(255, 255, 160, 122),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 13.0,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        Text(
                          order.date,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          // --- Total & Action Buttons ---
          Container(
            padding: const EdgeInsets.only(top: 12.0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    Text(
                      'RM ${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 160, 122),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (order.status == 'Preparing')
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            order.status = 'Cancelled';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF5350),
                          side: const BorderSide(color: Color(0xFFEF5350)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ),
                        ),
                        child: const Text(
                          'Cancel Order',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (order.status == 'Delivering')
                      ElevatedButton(
                        onPressed: () {
                          // TODO: handle tracking order
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ),
                        ),
                        child: const Text(
                          'Track Order',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          // TODO: handle reordering action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5F5F5),
                          foregroundColor: const Color(0xDD000000),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ),
                        ),
                        child: const Text(
                          'Reorder',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
