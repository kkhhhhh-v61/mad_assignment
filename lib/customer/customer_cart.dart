import 'package:flutter/material.dart';

import '../data.dart';

class CustomerCart extends StatefulWidget {
  const CustomerCart({super.key});

  @override
  State<CustomerCart> createState() => _CustomerCartState();
}

class _CustomerCartState extends State<CustomerCart> {
  List<CartItem> _localCartItems = [];
  bool _isVoucherApplied = false;
  final Set<int> _expandedCartIndices = {};

  @override
  void initState() {
    super.initState();
    _localCartItems = cartItems
        .map(
          (item) => CartItem(
            name: item.name,
            price: item.price,
            quantity: item.quantity,
            icon: item.icon,
            customizations: item.customizations,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    for (var item in _localCartItems) {
      subtotal += item.price * item.quantity;
    }

    double discount = _isVoucherApplied ? activeDiscount : 0.0;
    double total = subtotal + deliveryFee - discount;
    if (total < 0) total = 0;

    return Scaffold(
      backgroundColor: const Color(0xF8FFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xDD000000), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: Color(0xDD000000),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFEEEEEE), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Cart Items ---
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _localCartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(_localCartItems[index], index);
                    },
                  ),
                  const SizedBox(height: 8.0),
                  // --- Special Instructions ---
                  const Text(
                    'Special Instructions',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'E.g. No onions, extra spicy...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14.0,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  // --- Voucher ---
                  _buildVoucherTile(),
                  const SizedBox(height: 16.0),
                  // --- Payment Method ---
                  _buildPaymentTile(),
                  const SizedBox(height: 24.0),
                  // --- Order Summary ---
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _buildOrderSummary(subtotal, discount, total),
                ],
              ),
            ),
          ),
          // --- Bottom Checkout Bar ---
          _buildCheckoutBar(total),
        ],
      ),
    );
  }

  // --- Cart Item Card ---
  Widget _buildCartItem(CartItem item, int index) {
    final isExpanded = _expandedCartIndices.contains(index);
    final customList = item.customizations.isEmpty
        ? <String>[]
        : item.customizations.split(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(item.icon, color: const Color(0xFF9E9E9E), size: 35),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (customList.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCartIndices.remove(index);
                        } else {
                          _expandedCartIndices.add(index);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: const Color.fromARGB(255, 255, 160, 122),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '${customList.length} ${customList.length == 1 ? 'Customization' : 'Customizations'}',
                            style: const TextStyle(
                              fontSize: 13.0,
                              color: Color.fromARGB(255, 255, 160, 122),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 4.0),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: customList.map((custom) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    color: Color(0xFF757575),
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    custom,
                                    style: const TextStyle(
                                      fontSize: 13.0,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 8.0),
                Text(
                  'RM ${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 160, 122),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onPressed: () {
                    if (item.quantity > 1) {
                      setState(() => item.quantity--);
                    }
                  },
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  iconColor: const Color.fromARGB(255, 255, 160, 122),
                  onPressed: () {
                    setState(() => item.quantity++);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Quantity Button ---
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = const Color(0xDD000000),
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }

  // --- Voucher Tile ---
  Widget _buildVoucherTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(15, 0, 0, 0),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 2.0,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_offer, color: Color.fromARGB(255, 255, 160, 122), size: 20),
        ),
        title: Text(
          _isVoucherApplied ? 'DISCOUNT30 Applied' : 'Add Voucher / Promo Code',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: _isVoucherApplied ? const Color.fromARGB(255, 255, 160, 122) : const Color(0xDD000000),
          ),
        ),
        trailing: _isVoucherApplied
            ? IconButton(
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF9E9E9E)),
                onPressed: () => setState(() => _isVoucherApplied = false),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9E9E9E)),
        onTap: () {
          if (!_isVoucherApplied) {
            setState(() => _isVoucherApplied = true);
          }
        },
      ),
    );
  }

  // --- Payment Method Tile ---
  Widget _buildPaymentTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(15, 0, 0, 0),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 2.0,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.credit_card, color: Color(0xFF2196F3), size: 20),
        ),
        title: const Text(
          'Payment Method',
          style: TextStyle(fontSize: 14.0, color: Color(0xFF9E9E9E)),
        ),
        subtitle: const Text(
          'Credit Card ending in 1234',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Color(0xDD000000),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF9E9E9E),
        ),
        onTap: () {
          // TODO
        },
      ),
    );
  }

  // --- Order Summary ---
  Widget _buildOrderSummary(double subtotal, double discount, double total) {
    return Container(
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
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', 'RM ${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8.0),
          _buildSummaryRow('Delivery Fee', 'RM ${deliveryFee.toStringAsFixed(2)}'),
          if (_isVoucherApplied) ...[
            const SizedBox(height: 8.0),
            _buildSummaryRow(
              'Discount',
              '-RM ${discount.toStringAsFixed(2)}',
              textColor: const Color.fromARGB(255, 255, 160, 122),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          _buildSummaryRow('Total', 'RM ${total.toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  // --- Summary Row ---
  Widget _buildSummaryRow(
    String title,
    String amount, {
    bool isTotal = false,
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 16.0 : 14.0,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xDD000000) : const Color(0xFF757575),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 16.0 : 14.0,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: textColor ?? (isTotal ? const Color.fromARGB(255, 255, 160, 122) : const Color(0xDD000000)),
          ),
        ),
      ],
    );
  }

  // --- Checkout Bar ---
  Widget _buildCheckoutBar(double total) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(15, 0, 0, 0),
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Price',
                  style: TextStyle(color: Color(0xFF757575), fontSize: 13.0),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'RM ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // TODO
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
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
          ),
        ],
      ),
    );
  }
}
