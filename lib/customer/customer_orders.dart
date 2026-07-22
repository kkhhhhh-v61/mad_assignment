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
                    padding: const EdgeInsets.symmetric(vertical: spacingSm),
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
                          fontSize: fontDetail,
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
        border: Border.all(color: borderLight),
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
                  color: surfaceLight,
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
                child: Icon(order.icon, color: brandColor, size: 26),
              ),
              const SizedBox(width: spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.displayTitle,
                      style: const TextStyle(
                        fontSize: fontSubtitle,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: spacingXs),
                    Row(
                      children: [
                        Text(
                          order.orderId,
                          style: const TextStyle(
                            fontSize: fontDetail,
                            color: brandColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: fontDetail,
                            color: textHint,
                          ),
                        ),
                        Text(
                          order.date,
                          style: const TextStyle(
                            fontSize: fontCaption,
                            color: textSecondary,
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
          const SizedBox(height: spacingLg),
          // --- Total & Action Buttons ---
          Container(
            padding: const EdgeInsets.only(top: spacingMd),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: borderLight)),
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
                        fontSize: fontCaption,
                        color: textHint,
                      ),
                    ),
                    Text(
                      formatPrice(order.total),
                      style: const TextStyle(
                        fontSize: fontTitle,
                        fontWeight: FontWeight.bold,
                        color: brandColor,
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
                          foregroundColor: const Color(0xFFC62828),
                          side: const BorderSide(color: Color(0xFFC62828)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(radiusFull),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: spacingLg,
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
                          backgroundColor: brandColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(radiusFull),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: spacingLg,
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
                          backgroundColor: surfaceLight,
                          foregroundColor: textPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(radiusFull),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: spacingLg,
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
