import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../global.dart';
import '../main.dart';
import 'checkout.dart';
import 'food_item_detail.dart';
import 'main_navigation.dart';

class CartItemCustomization {
  final String name;
  final double price;

  CartItemCustomization({required this.name, this.price = 0.0});

  Map<String, dynamic> toJson() => {'name': name, 'price': price};

  factory CartItemCustomization.fromJson(Map<String, dynamic> json) =>
      CartItemCustomization(
        name: json['name']?.toString() ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      );
}

class CartItem {
  final String? id;
  final String name;
  final double price;
  int quantity;
  final IconData icon;
  final String? imageUrl;
  final List<CartItemCustomization> customizations;

  CartItem({
    this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.icon = Icons.fastfood_outlined,
    this.imageUrl,
    this.customizations = const [],
  });

  double get customizationTotal =>
      customizations.fold(0.0, (sum, c) => sum + c.price);
  double get total => (price + customizationTotal) * quantity;

  bool hasSameCustomizations(List<CartItemCustomization> other) {
    if (customizations.length != other.length) return false;
    for (int i = 0; i < customizations.length; i++) {
      if (customizations[i].name != other[i].name ||
          customizations[i].price != other[i].price) {
        return false;
      }
    }
    return true;
  }

  bool isSameItem(CartItem other) {
    if (id != null && other.id != null) {
      if (id != other.id) return false;
    } else if (name != other.name) {
      return false;
    }
    return hasSameCustomizations(other.customizations);
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'icon': icon.codePoint,
        if (imageUrl != null) 'image_url': imageUrl,
        'customizations': customizations.map((c) => c.toJson()).toList(),
      };

  static const Map<int, IconData> _knownIcons = {
    0xe25a: Icons.fastfood,
    0xf0289: Icons.fastfood_outlined,
    0xe532: Icons.restaurant,
    0xe533: Icons.restaurant_menu,
    0xe395: Icons.local_pizza,
  };

  static IconData _resolveIcon(int? code) {
    if (code == null) return Icons.fastfood_outlined;
    return _knownIcons[code] ?? Icons.fastfood_outlined;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? 'Food Item',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        icon: _resolveIcon(json['icon'] as int?),
        imageUrl: json['image_url']?.toString(),
        customizations: (json['customizations'] as List<dynamic>?)
                ?.map((c) => CartItemCustomization.fromJson(
                    Map<String, dynamic>.from(c as Map)))
                .toList() ??
            [],
      );
}

class CartStorage {
  static const String _key = 'customer_cart_items';

  static Future<List<CartItem>> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCart(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_key, jsonStr);
    } catch (_) {}
  }

  static Future<void> addToCart(CartItem newItem) async {
    final items = await loadCart();
    final index = items.indexWhere((item) => item.isSameItem(newItem));
    if (index != -1) {
      items[index].quantity += newItem.quantity;
    } else {
      items.add(newItem);
    }
    await saveCart(items);
  }

  static Future<void> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}

class CustomerCart extends StatefulWidget {
  const CustomerCart({super.key});

  @override
  State<CustomerCart> createState() => _CustomerCartState();
}

class _CustomerCartState extends State<CustomerCart> {
  List<CartItem> _cartItems = [];

  bool get _isAuthenticated {
    final session = supabase.auth.currentSession;
    if (session == null || session.isExpired) return false;
    return supabase.auth.currentUser != null;
  }
  double get _totalPrice =>
      _cartItems.fold(0.0, (sum, item) => sum + item.total);

  @override
  void initState() {
    super.initState();
    if (_isAuthenticated) {
      _loadCart();
    }
    //TODO: Retrieve user's cart items dynamically from backend
  }

  Future<void> _loadCart() async {
    final items = await CartStorage.loadCart();
    if (mounted) {
      setState(() {
        _cartItems = items;
      });
    }
  }

  Future<void> _updateQuantity(int index, int newQuantity) async {
    //TODO: Update item quantity in cart via backend API
    setState(() {
      _cartItems[index].quantity = newQuantity;
    });
    await CartStorage.saveCart(_cartItems);
  }

  Future<void> _removeItem(int index) async {
    //TODO: Remove item from cart via backend API
    setState(() {
      _cartItems.removeAt(index);
    });
    await CartStorage.saveCart(_cartItems);
  }

  Future<void> _openItemDetail(CartItem cartItem) async {
    if (cartItem.id != null && cartItem.id!.isNotEmpty) {
      try {
        final res = await supabase.from('food_items').select('''
          *,
          food_item_categories(food_categories(id, name)),
          food_item_states(states(id, name))
        ''').eq('id', cartItem.id!).maybeSingle();
        if (res != null && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodItemDetail(item: Map<String, dynamic>.from(res)),
            ),
          );
          _loadCart();
          return;
        }
      } catch (_) {}
    }
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FoodItemDetail(item: {
            if (cartItem.id != null) 'id': cartItem.id,
            'name': cartItem.name,
            'price': cartItem.price,
            if (cartItem.imageUrl != null) 'image_url': cartItem.imageUrl,
            'icon': cartItem.icon,
          }),
        ),
      );
      _loadCart();
    }
  }

  Future<void> _navigateToCheckout() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerCheckout()),
    );
    _loadCart();
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerMainNavigation(initialIndex: 3),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
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
          'My Cart',
          style: TextStyle(
            color: Color(0xDD000000),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFD6D6D6), height: 1),
        ),
      ),
      body: !_isAuthenticated
          ? _buildUnauthenticatedView()
          : (_cartItems.isEmpty ? _buildEmptyCart() : _buildCartContent()),
    );
  }

  Widget _buildUnauthenticatedView() {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA07A).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 36,
                color: Color(0xFFFFA07A),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please Log In',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xDD000000),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You must be logged in to view your cart and proceed with orders.',
              style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _navigateToLogin,
              child: const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA07A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: FallbackMessage(
        icon: Icons.shopping_cart_outlined,
        title: 'Your Cart is Empty',
        description: 'Add some delicious items from our menu to get started!',
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _cartItems.length,
            itemBuilder: (_, index) =>
                _buildCartItemCard(_cartItems[index], index),
          ),
        ),
        _buildCheckoutBar(),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openItemDetail(item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stackTrace) => Icon(
                              item.icon,
                              color: const Color(0xFFBDBDBD),
                              size: 36,
                            ),
                          )
                        : Icon(
                            item.icon,
                            color: const Color(0xFFBDBDBD),
                            size: 36,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xDD000000),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _removeItem(index),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline,
                                color: Color(0xFFEF5350),
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.customizations.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            item.customizations.map((c) {
                              return c.price > 0
                                  ? '${c.name} (+RM ${c.price.toStringAsFixed(2)})'
                                  : c.name;
                            }).join(' • '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'RM ${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFA07A),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildQuantityButton(
                                  icon: Icons.remove,
                                  iconColor: item.quantity > 1
                                      ? const Color(0xDD000000)
                                      : const Color(0xFFBDBDBD),
                                  onTap: () {
                                    if (item.quantity > 1) {
                                      _updateQuantity(index, item.quantity - 1);
                                    }
                                  },
                                ),
                                Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 24),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _buildQuantityButton(
                                  icon: Icons.add,
                                  iconColor: const Color(0xFFFFA07A),
                                  onTap: () => _updateQuantity(
                                      index, item.quantity + 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = const Color(0xDD000000),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
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
                    color: Color(0xFF757575),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'RM ${_totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
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
                onPressed: _navigateToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA07A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
