import 'package:flutter/material.dart';

import 'order_tracking.dart';

class OrderDetails extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetails({super.key, required this.order});

  String get orderId => order['orderId'] as String;
  String get date => order['date'] as String;
  String get status => order['status'] as String;
  List<Map<String, Object>> get itemsList =>
      (order['items'] as List).cast<Map<String, Object>>();
  double get subtotal => (order['subtotal'] as num).toDouble();
  double get deliveryFee => (order['deliveryFee'] as num).toDouble();
  double get discount => (order['discount'] as num).toDouble();
  String get totalPrice => order['totalPrice'] as String;
  String get info => order['info'] as String;
  IconData? get icon => order['icon'] as IconData?;

  @override
  Widget build(BuildContext context) {
    // Colors and Buttons Logic
    Color statusColor;
    IconData heroIcon;
    String buttonText;
    Color buttonColor;
    bool isOutlined;

    switch (status) {
      case 'Preparing':
        statusColor = const Color.fromARGB(255, 255, 160, 122);
        heroIcon = Icons.outdoor_grill;
        buttonText = 'Cancel Order';
        buttonColor = const Color(0xFFE53935);
        isOutlined = true;
        break;
      case 'Delivering':
        statusColor = const Color(0xFF2196F3);
        heroIcon = Icons.electric_moped;
        buttonText = 'Track Order';
        buttonColor = const Color.fromARGB(255, 255, 160, 122);
        isOutlined = false;
        break;
      case 'Cancelled':
        statusColor = const Color(0xFFE53935);
        heroIcon = Icons.cancel_presentation;
        buttonText = 'Reorder';
        buttonColor = const Color.fromARGB(255, 255, 160, 122);
        isOutlined = false;
        break;
      case 'Completed':
      default:
        statusColor = const Color(0xFF4CAF50);
        heroIcon = Icons.task_alt;
        buttonText = 'Reorder';
        buttonColor = const Color.fromARGB(255, 255, 160, 122);
        isOutlined = false;
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xDD000000),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          orderId,
          style: const TextStyle(
            color: Color(0xDD000000),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20.0, bottom: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Status Hero Banner ---
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
                            'Placed on $date',
                            style: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // --- Info Card ---
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20.0),
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color.fromARGB(255, 255, 160, 122),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delivery Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                    color: Color(0xDD000000),
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  info,
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // --- Receipt Card ---
                    buildOrderReceiptCardUI(
                      itemsList: itemsList,
                      subtotal: subtotal,
                      deliveryFee: deliveryFee,
                      discount: discount,
                      totalPrice: totalPrice,
                    ),
                  ],
                ),
              ),
            ),

            // --- Bottom Action Bar ---
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: isOutlined
                    ? OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: buttonColor,
                          side: BorderSide(color: buttonColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
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
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Dynamic UI Functions ====================

Widget buildOrderReceiptCardUI({
  required List<Map<String, Object>> itemsList,
  required double subtotal,
  required double deliveryFee,
  required double discount,
  required String totalPrice,
}) {
  return Container(
    padding: const EdgeInsets.all(20.0),
    margin: const EdgeInsets.symmetric(horizontal: 20.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.0),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Receipt',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: Color(0xDD000000),
          ),
        ),
        const SizedBox(height: 20.0),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemsList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16.0),
          itemBuilder: (context, index) {
            final item = itemsList[index];
            final String name = item['name'] as String;
            final int qty = item['quantity'] as int;
            final double price = (item['price'] as num).toDouble();
            final double itemTotal = price * qty;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Center(
                    child: Text(
                      '${qty}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.0,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '@ RM ${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'RM ${itemTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.0,
                  ),
                ),
              ],
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Divider(color: Color(0xFFEEEEEE), height: 1.0, thickness: 1.0),
        ),
        buildOrderReceiptRowUI('Subtotal', 'RM ${subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 12.0),
        buildOrderReceiptRowUI(
          'Delivery Fee',
          'RM ${deliveryFee.toStringAsFixed(2)}',
        ),
        if (discount > 0) ...[
          const SizedBox(height: 12.0),
          buildOrderReceiptRowUI(
            'Voucher Discount',
            '-RM ${discount.toStringAsFixed(2)}',
            isDiscount: true,
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Divider(color: Color(0xFFEEEEEE), height: 1.0, thickness: 1.0),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Payment',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: Color(0xDD000000),
              ),
            ),
            Text(
              totalPrice,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22.0,
                color: Color.fromARGB(255, 255, 160, 122),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildOrderReceiptRowUI(
  String title,
  String value, {
  bool isDiscount = false,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 15.0, color: Color(0xFF757575)),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w600,
          color: isDiscount ? const Color(0xFF4CAF50) : const Color(0xDD000000),
        ),
      ),
    ],
  );
}
