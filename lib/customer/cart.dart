import 'package:flutter/material.dart';

import '../global.dart';
import 'checkout.dart';

class CartItemCustomization {
  final String name;
  final double price;

  CartItemCustomization({required this.name, this.price = 0.0});
}

class CartItem {
  final String name;
  final double price;
  int quantity;
  final IconData icon;
  final List<CartItemCustomization> customizations;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.icon,
    this.customizations = const [],
  });
}

class CustomerCart extends StatefulWidget {
  const CustomerCart({super.key});

  @override
  State<CustomerCart> createState() => _CustomerCartState();
}

class _CustomerCartState extends State<CustomerCart> {
  late List<CartItem> _cartItems;

  @override
  void initState() {
    super.initState();
    _cartItems = [];
    // --- TOREMOVE ---
    _cartItems = [
      CartItem(
        name: 'Classic Beef Burger',
        price: 16.90,
        quantity: 2,
        icon: Icons.lunch_dining,
        customizations: [
          CartItemCustomization(name: 'Extra Cheese', price: 2.00),
          CartItemCustomization(name: 'No Onions', price: 0.00),
        ],
      ),
      CartItem(
        name: 'Golden French Fries',
        price: 8.90,
        quantity: 1,
        icon: Icons.tapas,
        customizations: [
          CartItemCustomization(name: 'Large Size', price: 3.00),
        ],
      ),
    ];
    // --- END TOREMOVE ---
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(248, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(221, 0, 0, 0),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: Color.fromARGB(221, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color.fromARGB(255, 214, 214, 214),
            height: 1.0,
          ),
        ),
      ),
      body: buildCartLayout(
        context: context,
        cartItems: _cartItems,
        onQuantityChanged: (index, newQty) {
          setState(() {
            _cartItems[index].quantity = newQty;
          });
        },
        onItemRemoved: (index) {
          setState(() {
            _cartItems.removeAt(index);
          });
        },
      ),
    );
  }
}

// ==================== Dynamic UI Functions ====================

Widget buildCartLayout({
  required BuildContext context,
  required List<CartItem> cartItems,
  required Function(int, int) onQuantityChanged,
  required Function(int) onItemRemoved,
}) {
  if (cartItems.isEmpty) {
    return Center(
      child: buildFallbackMessage(
        icon: Icons.shopping_cart_outlined,
        title: 'Your Cart is Empty',
        description: 'Add some delicious items from our menu to get started!',
      ),
    );
  }

  double total = 0;
  for (var item in cartItems) {
    double customTotal = item.customizations.fold(
      0.0,
      (sum, c) => sum + c.price,
    );
    total += (item.price + customTotal) * item.quantity;
  }

  return Column(
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
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  return buildCartItemCard(
                    item: cartItems[index],
                    index: index,
                    onQuantityChanged: onQuantityChanged,
                    onItemRemoved: onItemRemoved,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      // --- Bottom Checkout Bar ---
      buildCartCheckoutBar(context, total),
    ],
  );
}

Widget buildCartItemCard({
  required CartItem item,
  required int index,
  required Function(int, int) onQuantityChanged,
  required Function(int) onItemRemoved,
}) {
  final baseTotal = item.price * item.quantity;
  final customTotal =
      item.customizations.fold(0.0, (sum, c) => sum + c.price) * item.quantity;
  final itemTotal = baseTotal + customTotal;

  return Container(
    margin: const EdgeInsets.only(bottom: 16.0),
    padding: const EdgeInsets.all(16.0),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 245, 245, 245),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Icon(
                item.icon,
                color: const Color.fromARGB(255, 189, 189, 189),
                size: 40,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(221, 0, 0, 0),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'RM ${baseTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (item.customizations.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    ...item.customizations.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 158, 158, 158),
                                      fontSize: 13.0,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontSize: 13.0,
                                        color: Color.fromARGB(
                                          255,
                                          117,
                                          117,
                                          117,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (c.price > 0) ...[
                              const SizedBox(width: 8.0),
                              Text(
                                '+ RM ${(c.price * item.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 117, 117, 117),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12.0),
                  const Divider(
                    height: 1,
                    color: Color.fromARGB(255, 214, 214, 214),
                  ),
                  const SizedBox(height: 8.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'RM ${itemTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 160, 122),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => onItemRemoved(index),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              label: const Text(
                'Remove',
                style: TextStyle(color: Colors.redAccent),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 245, 245, 245),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildCartQuantityButton(
                    icon: Icons.remove,
                    onPressed: () {
                      if (item.quantity > 1) {
                        onQuantityChanged(index, item.quantity - 1);
                      }
                    },
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 28),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  buildCartQuantityButton(
                    icon: Icons.add,
                    iconColor: const Color.fromARGB(255, 255, 160, 122),
                    onPressed: () {
                      onQuantityChanged(index, item.quantity + 1);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildCartQuantityButton({
  required IconData icon,
  required VoidCallback onPressed,
  Color iconColor = const Color.fromARGB(221, 0, 0, 0),
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

Widget buildCartCheckoutBar(BuildContext context, double total) {
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
                style: TextStyle(
                  color: Color.fromARGB(255, 117, 117, 117),
                  fontSize: 13.0,
                ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerCheckout(),
                  ),
                );
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
                'Checkout',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
