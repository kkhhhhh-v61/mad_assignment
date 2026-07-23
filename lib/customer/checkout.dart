import 'package:flutter/material.dart';

import '../global.dart';
import '../data.dart';
import 'cart.dart'; // For CartItem

class CustomerCheckout extends StatefulWidget {
  const CustomerCheckout({super.key});

  @override
  State<CustomerCheckout> createState() => _CustomerCheckoutState();
}

class _CustomerCheckoutState extends State<CustomerCheckout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF8FFFFFF),
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
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xDD000000),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFD6D6D6), height: 1.0),
        ),
      ),
      body: buildDummyCheckoutView(
        context: context,
        onStateChanged: () {
          setState(() {});
        },
      ),
    );
  }
}

// ==================== Dynamic UI Functions ====================

Widget buildCheckoutLayoutUI({
  required BuildContext context,
  required List<CartItem> cartItems,
  required String selectedAddress,
  required String selectedPaymentMethod,
  required List<String> availablePaymentMethods,
  required Function(String) onPaymentMethodChanged,
  required Map<String, dynamic>? appliedVoucher,
  required double deliveryFee,
  required List<Map<String, dynamic>> availableVouchers,
  required Function(Map<String, dynamic>?) onVoucherApplied,
}) {
  if (cartItems.isEmpty) {
    return Center(
      child: buildDefaultFallbackMessage(
        icon: Icons.shopping_bag_outlined,
        title: 'No Items to Checkout',
        description: 'Please add items to your cart first.',
      ),
    );
  }

  double subtotal = 0;
  for (var item in cartItems) {
    double customTotal = item.customizations.fold(0.0, (sum, c) => sum + c.price);
    subtotal += (item.price + customTotal) * item.quantity;
  }

  double discount = 0.0;
  if (appliedVoucher != null) {
    if (appliedVoucher['type'] == 'free_delivery') {
      discount = deliveryFee;
    } else if (appliedVoucher['type'] == 'percentage') {
      discount = subtotal * (appliedVoucher['discountValue'] as double) / 100;
    }
  }

  double total = subtotal + deliveryFee - discount;
  if (total < 0) total = 0;

  return Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildAddressSelectionUI(selectedAddress),
              const SizedBox(height: 20.0),
              buildCheckoutOrderItemsUI(cartItems),
              const SizedBox(height: 20.0),
              buildCheckoutVoucherUI(
                context: context,
                appliedVoucher: appliedVoucher,
                availableVouchers: availableVouchers,
                subtotal: subtotal,
                onVoucherApplied: onVoucherApplied,
              ),
              const SizedBox(height: 20.0),
              buildCheckoutPaymentUI(
                context: context,
                selectedPaymentMethod: selectedPaymentMethod,
                availablePaymentMethods: availablePaymentMethods,
                onPaymentMethodChanged: onPaymentMethodChanged,
              ),
              const SizedBox(height: 20.0),
              buildCheckoutSummaryUI(
                subtotal: subtotal,
                deliveryFee: deliveryFee,
                discount: discount,
                total: total,
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
      buildCheckoutBottomBarUI(total),
    ],
  );
}

Widget buildAddressSelectionUI(String address) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Delivery Address',
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Color(0xDD000000),
        ),
      ),
      const SizedBox(height: 12.0),
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(Icons.location_on, color: Color.fromARGB(255, 255, 160, 122)),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                address,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
          ],
        ),
      ),
    ],
  );
}

Widget buildCheckoutOrderItemsUI(List<CartItem> cartItems) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Order Summary',
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Color(0xDD000000),
        ),
      ),
      const SizedBox(height: 12.0),
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          children: cartItems.asMap().entries.map((entry) {
            int idx = entry.key;
            CartItem item = entry.value;
            double customTotal = item.customizations.fold(0.0, (sum, c) => sum + c.price);
            double itemTotal = (item.price + customTotal) * item.quantity;
            
            return Padding(
              padding: EdgeInsets.only(bottom: idx == cartItems.length - 1 ? 0 : 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 160, 122),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                        if (item.customizations.isNotEmpty) ...[
                          const SizedBox(height: 4.0),
                          ...item.customizations.map((c) => Text(
                            '• ${c.name}',
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Color(0xFF757575),
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    'RM ${itemTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

Widget buildCheckoutVoucherUI({
  required BuildContext context,
  required Map<String, dynamic>? appliedVoucher,
  required List<Map<String, dynamic>> availableVouchers,
  required double subtotal,
  required Function(Map<String, dynamic>?) onVoucherApplied,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Voucher',
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Color(0xDD000000),
        ),
      ),
      const SizedBox(height: 12.0),
      InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => buildVoucherSelectionBottomSheetUI(
              availableVouchers: availableVouchers,
              subtotal: subtotal,
              appliedVoucher: appliedVoucher,
              onVoucherApplied: (v) {
                onVoucherApplied(v);
                Navigator.pop(context);
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: Color.fromARGB(255, 255, 160, 122)),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  appliedVoucher != null ? appliedVoucher['title'] : 'No voucher applied',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: appliedVoucher != null ? const Color(0xDD000000) : const Color(0xFF9E9E9E),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget buildVoucherSelectionBottomSheetUI({
  required List<Map<String, dynamic>> availableVouchers,
  required double subtotal,
  required Map<String, dynamic>? appliedVoucher,
  required Function(Map<String, dynamic>?) onVoucherApplied,
}) {
  return Container(
    padding: const EdgeInsets.all(20.0),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
    ),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Vouchers',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (appliedVoucher != null)
                TextButton(
                  onPressed: () => onVoucherApplied(null),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 20.0),
          if (availableVouchers.isEmpty)
            const Text('No vouchers available.', style: TextStyle(color: Color(0xFF757575)))
          else
            ...availableVouchers.map((voucher) {
              bool isUsable = subtotal >= (voucher['minSpend'] as double);
              bool isSelected = appliedVoucher?['id'] == voucher['id'];

              return Opacity(
                opacity: isUsable ? 1.0 : 0.5,
                child: InkWell(
                  onTap: isUsable ? () => onVoucherApplied(voucher) : null,
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.1) : Colors.white,
                      border: Border.all(
                        color: isSelected ? const Color.fromARGB(255, 255, 160, 122) : const Color(0xFFEEEEEE),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_offer, color: Color.fromARGB(255, 255, 160, 122), size: 24),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                voucher['title'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Min. spend RM ${voucher['minSpend'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isUsable ? const Color(0xFF757575) : Colors.redAccent, 
                                  fontSize: 13.0,
                                  fontWeight: isUsable ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                              if (voucher.containsKey('expiryDate')) ...[
                                const SizedBox(height: 4.0),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Color(0xFF9E9E9E)),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      voucher['expiryDate'],
                                      style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12.0),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    ),
  );
}

Widget buildCheckoutPaymentUI({
  required BuildContext context,
  required String selectedPaymentMethod,
  required List<String> availablePaymentMethods,
  required Function(String) onPaymentMethodChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Payment Method',
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Color(0xDD000000),
        ),
      ),
      const SizedBox(height: 12.0),
      InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => buildPaymentSelectionBottomSheetUI(
              availablePaymentMethods: availablePaymentMethods,
              selectedPaymentMethod: selectedPaymentMethod,
              onPaymentMethodChanged: (method) {
                onPaymentMethodChanged(method);
                Navigator.pop(context);
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card, color: Color.fromARGB(255, 255, 160, 122)),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  selectedPaymentMethod,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget buildPaymentSelectionBottomSheetUI({
  required List<String> availablePaymentMethods,
  required String selectedPaymentMethod,
  required Function(String) onPaymentMethodChanged,
}) {
  return Container(
    padding: const EdgeInsets.all(20.0),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
    ),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20.0),
          ...availablePaymentMethods.map((method) {
            bool isSelected = method == selectedPaymentMethod;
            return InkWell(
              onTap: () => onPaymentMethodChanged(method),
              borderRadius: BorderRadius.circular(16.0),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isSelected ? const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color.fromARGB(255, 255, 160, 122) : const Color(0xFFEEEEEE),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      method == 'Credit Card' ? Icons.credit_card :
                      method == 'Cash on Delivery' ? Icons.money :
                      method == 'E-Wallet' ? Icons.account_balance_wallet :
                      Icons.account_balance,
                      color: const Color.fromARGB(255, 255, 160, 122),
                      size: 24,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Text(
                        method,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Color.fromARGB(255, 255, 160, 122)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}

Widget buildCheckoutSummaryUI({
  required double subtotal,
  required double deliveryFee,
  required double discount,
  required double total,
}) {
  return Container(
    padding: const EdgeInsets.all(20.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.0),
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(15, 0, 0, 0),
          blurRadius: 10,
          spreadRadius: 0,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal', style: TextStyle(color: Color(0xFF757575))),
            Text('RM ${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Delivery Fee', style: TextStyle(color: Color(0xFF757575))),
            Text('RM ${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        if (discount > 0) ...[
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount', style: TextStyle(color: Color(0xFF757575))),
              Text('- RM ${discount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(height: 1, color: Color(0xFFD6D6D6)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'RM ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 160, 122),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildCheckoutBottomBarUI(double total) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      boxShadow: [
        BoxShadow(
          color: Color.fromARGB(15, 0, 0, 0),
          blurRadius: 10,
          spreadRadius: 0,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 160, 122),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        child: const Text(
          'Place Order',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
