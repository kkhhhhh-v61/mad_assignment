import 'package:flutter/material.dart';

import '../config.dart';
import '../data.dart';
import 'customer_header.dart';

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
        const SizedBox(height: spacingLg),
        // --- Status Tabs ---
        Container(
          margin: const EdgeInsets.symmetric(horizontal: spacingXl),
          padding: const EdgeInsets.all(spacingXs),
          decoration: BoxDecoration(
            color: surfaceMuted,
            borderRadius: BorderRadius.circular(radiusFull),
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
                    padding: const EdgeInsets.symmetric(vertical: spacingMd),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(radiusXl),
                      boxShadow: isSelected ? const [shadowSm] : [],
                    ),
                    child: Center(
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isSelected ? brandColor : textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: fontBody,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: spacingSm),
        // --- Order List ---
        Expanded(
          child: filteredOrders.isEmpty
              ? const Center(
                  child: Text(
                    'No orders found.',
                    style: TextStyle(color: textHint, fontSize: fontSubtitle),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: spacingXl,
                    vertical: spacingSm,
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
      margin: const EdgeInsets.only(bottom: spacingLg),
      padding: const EdgeInsets.all(spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: const [shadowMd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Restaurant + Order ID ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.restaurant,
                style: const TextStyle(
                  fontSize: fontSubtitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                order.orderId,
                style: const TextStyle(
                  color: brandColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: spacingSm),
          // --- Order Details ---
          Row(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: surfaceLight,
                  borderRadius: BorderRadius.circular(radiusSm),
                ),
                child: Icon(order.icon, color: textHint, size: 30),
              ),
              const SizedBox(width: spacingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.items,
                      style: const TextStyle(color: textPrimary, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: spacingXs),
                    Text(
                      order.date,
                      style: const TextStyle(
                        fontSize: fontCaption,
                        color: textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: spacingLg),
          const Divider(height: 1),
          const SizedBox(height: spacingLg),
          // --- Total + Action Button ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${formatPrice(order.total)}',
                style: const TextStyle(
                  fontSize: fontBodyLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  // TODO
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandColor,
                  side: const BorderSide(color: brandColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusXl),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: spacingXl),
                ),
                child: Text(
                  _selectedStatus == 'Active' ? 'Track Order' : 'Reorder',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
