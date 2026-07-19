import 'package:flutter/material.dart';

import '../config.dart';
import '../data.dart';

class CustomerCart extends StatefulWidget {
  const CustomerCart({super.key});

  @override
  State<CustomerCart> createState() => _CustomerCartState();
}

class _CustomerCartState extends State<CustomerCart> {
  List<CartItem> _localCartItems = [];
  bool _isVoucherApplied = false;

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
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: fontTitle,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: surfaceMuted, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Cart Items ---
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _localCartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(_localCartItems[index]);
                    },
                  ),
                  const SizedBox(height: spacingSm),
                  // --- Special Instructions ---
                  const Text(
                    'Special Instructions',
                    style: TextStyle(
                      fontSize: fontSubtitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: spacingSm),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'E.g. No onions, extra spicy...',
                      hintStyle: const TextStyle(
                        color: textHint,
                        fontSize: fontBody,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(spacingLg),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(radiusLg),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: spacing2xl),
                  // --- Voucher ---
                  _buildVoucherTile(),
                  const SizedBox(height: spacingLg),
                  // --- Payment Method ---
                  _buildPaymentTile(),
                  const SizedBox(height: spacing2xl),
                  // --- Order Summary ---
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: fontSubtitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: spacingLg),
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
  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: spacingLg),
      padding: const EdgeInsets.all(spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: const [shadowMd],
      ),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            child: Icon(item.icon, color: textHint, size: 35),
          ),
          const SizedBox(width: spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: fontBodyLarge,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: spacingSm),
                Text(
                  formatPrice(item.price),
                  style: const TextStyle(
                    fontSize: fontBodyLarge,
                    fontWeight: FontWeight.bold,
                    color: brandColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.circular(radiusXl),
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
                      fontSize: fontBody,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  iconColor: brandColor,
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
    Color iconColor = textPrimary,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(radiusXl),
      child: Padding(
        padding: const EdgeInsets.all(spacingSm),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }

  // --- Voucher Tile ---
  Widget _buildVoucherTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: const [shadowSm],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: 2.0,
        ),
        leading: Container(
          padding: const EdgeInsets.all(spacingSm),
          decoration: BoxDecoration(
            color: brandColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_offer, color: brandColor, size: 20),
        ),
        title: Text(
          _isVoucherApplied ? 'DISCOUNT30 Applied' : 'Add Voucher / Promo Code',
          style: TextStyle(
            fontSize: fontBody,
            fontWeight: FontWeight.bold,
            color: _isVoucherApplied ? brandColor : textPrimary,
          ),
        ),
        trailing: _isVoucherApplied
            ? IconButton(
                icon: const Icon(Icons.close, size: 20, color: textHint),
                onPressed: () => setState(() => _isVoucherApplied = false),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16, color: textHint),
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
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: const [shadowSm],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: 2.0,
        ),
        leading: Container(
          padding: const EdgeInsets.all(spacingSm),
          decoration: BoxDecoration(
            color: infoColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.credit_card, color: infoColor, size: 20),
        ),
        title: const Text(
          'Payment Method',
          style: TextStyle(fontSize: fontBody, color: textHint),
        ),
        subtitle: const Text(
          'Credit Card ending in 1234',
          style: TextStyle(
            fontSize: fontBody,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: textHint,
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
      padding: const EdgeInsets.all(spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: const [shadowMd],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', formatPrice(subtotal)),
          const SizedBox(height: spacingSm),
          _buildSummaryRow('Delivery Fee', formatPrice(deliveryFee)),
          if (_isVoucherApplied) ...[
            const SizedBox(height: spacingSm),
            _buildSummaryRow(
              'Discount',
              '-${formatPrice(discount)}',
              textColor: brandColor,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: spacingSm),
            child: Divider(height: 1),
          ),
          _buildSummaryRow('Total', formatPrice(total), isTotal: true),
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
            fontSize: isTotal ? fontSubtitle : fontBody,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? textPrimary : textSecondary,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? fontSubtitle : fontBody,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: textColor ?? (isTotal ? brandColor : textPrimary),
          ),
        ),
      ],
    );
  }

  // --- Checkout Bar ---
  Widget _buildCheckoutBar(double total) {
    return Container(
      padding: const EdgeInsets.all(spacingXl),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusFull)),
        boxShadow: [shadowBottomBar],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Price',
                  style: TextStyle(color: textSecondary, fontSize: fontDetail),
                ),
                const SizedBox(height: 2),
                Text(
                  formatPrice(total),
                  style: const TextStyle(
                    fontSize: fontDisplay,
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
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusFull),
                  ),
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(
                    fontSize: fontSubtitle,
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
