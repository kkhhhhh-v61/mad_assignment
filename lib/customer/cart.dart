import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/states.dart';
import 'checkout.dart';
import 'food_item_detail.dart';
import 'header.dart';
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
  final List<String> exclusiveStates;
  final bool isAvailable;

  CartItem({
    this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.icon = Icons.fastfood_outlined,
    this.imageUrl,
    this.customizations = const [],
    this.exclusiveStates = const [],
    this.isAvailable = true,
  });

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    IconData? icon,
    String? imageUrl,
    List<CartItemCustomization>? customizations,
    List<String>? exclusiveStates,
    bool? isAvailable,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      customizations: customizations ?? this.customizations,
      exclusiveStates: exclusiveStates ?? this.exclusiveStates,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

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
        'exclusive_states': exclusiveStates,
        'is_available': isAvailable,
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
        exclusiveStates: (json['exclusive_states'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        isAvailable: json['is_available'] as bool? ?? true,
      );
}

class CartStorage {
  static const String _baseKey = 'customer_cart_items';
  static final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);

  static int calculateItemCount(List<CartItem> items) {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  static String _getKey([String? userId]) {
    try {
      final id = userId ?? supabase.auth.currentUser?.id;
      if (id != null && id.isNotEmpty) {
        return '${_baseKey}_$id';
      }
    } catch (_) {}
    return '${_baseKey}_guest';
  }

  static Future<List<CartItem>> loadCart([String? userId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(userId);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null || jsonStr.isEmpty) {
        cartCountNotifier.value = 0;
        return [];
      }
      final List<dynamic> list = jsonDecode(jsonStr);
      final items = list
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      cartCountNotifier.value = calculateItemCount(items);
      return items;
    } catch (_) {
      cartCountNotifier.value = 0;
      return [];
    }
  }

  static Future<void> saveCart(List<CartItem> items, [String? userId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(userId);
      final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(key, jsonStr);
      cartCountNotifier.value = calculateItemCount(items);
    } catch (_) {}
  }

  static Future<void> addToCart(CartItem newItem, [String? userId]) async {
    final items = await loadCart(userId);
    final index = items.indexWhere((item) => item.isSameItem(newItem));
    if (index != -1) {
      items[index].quantity += newItem.quantity;
    } else {
      items.add(newItem);
    }
    await saveCart(items, userId);
  }

  static Future<void> clearCart([String? userId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(userId);
      await prefs.remove(key);
      cartCountNotifier.value = 0;
    } catch (_) {}
  }

  static Future<int> updateCartCount([String? userId]) async {
    final items = await loadCart(userId);
    final count = calculateItemCount(items);
    cartCountNotifier.value = count;
    return count;
  }
}

class CustomerCart extends StatefulWidget {
  const CustomerCart({super.key});

  @override
  State<CustomerCart> createState() => _CustomerCartState();
}

class _CustomerCartState extends State<CustomerCart> {
  List<CartItem> _cartItems = [];
  AddressOption? _selectedOption;
  String _currentState = '';
  bool _isLoadingLocation = false;

  bool get _isAuthenticated {
    final session = supabase.auth.currentSession;
    if (session == null || session.isExpired) return false;
    return supabase.auth.currentUser != null;
  }

  bool _isItemAvailable(CartItem item) {
    if (!item.isAvailable) return false;
    if (item.exclusiveStates.isEmpty) return true;
    if (_currentState.isEmpty) return true;
    return item.exclusiveStates.any((s) => isSameState(s, _currentState));
  }

  List<CartItem> get _availableItems =>
      _cartItems.where(_isItemAvailable).toList();

  List<CartItem> get _unavailableItems =>
      _cartItems.where((item) => !_isItemAvailable(item)).toList();

  bool get _hasUnavailableItems => _unavailableItems.isNotEmpty;

  double get _totalPrice =>
      _cartItems.fold(0.0, (sum, item) => sum + item.total);

  double get _availableTotalPrice =>
      _availableItems.fold(0.0, (sum, item) => sum + item.total);

  @override
  void initState() {
    super.initState();
    _initLocation();
    if (_isAuthenticated) {
      _loadCart();
    }
  }

  Future<void> _initLocation() async {
    if (CustomerHeader.hasCachedLocation &&
        CustomerHeader.cachedSelectedOption != null) {
      final cached = CustomerHeader.cachedSelectedOption!;
      setState(() {
        _selectedOption = cached;
        _currentState = cached.state.isNotEmpty
            ? cached.state
            : extractStateFromAddress(cached.fullAddress);
      });
    } else {
      setState(() => _isLoadingLocation = true);
      await CustomerHeader.loadAddressesStatic();
      final option = CustomerHeader.cachedSelectedOption;
      if (mounted && option != null) {
        setState(() {
          _selectedOption = option;
          _currentState = option.state.isNotEmpty
              ? option.state
              : extractStateFromAddress(option.fullAddress);
          _isLoadingLocation = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _onAddressSelected(AddressOption option) async {
    if (option.isDetected) {
      setState(() => _isLoadingLocation = true);
      try {
        final fresh = await CustomerHeader.detectLocation();
        if (mounted) {
          setState(() {
            _selectedOption = fresh;
            _currentState = fresh.state.isNotEmpty
                ? fresh.state
                : extractStateFromAddress(fresh.fullAddress);
            _isLoadingLocation = false;
          });
          CustomerHeader.updateSelectedOption(fresh);
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _selectedOption = option;
            _currentState = option.state.isNotEmpty
                ? option.state
                : extractStateFromAddress(option.fullAddress);
            _isLoadingLocation = false;
          });
          CustomerHeader.updateSelectedOption(option);
        }
      }
    } else {
      setState(() {
        _selectedOption = option;
        _currentState = option.state.isNotEmpty
            ? option.state
            : extractStateFromAddress(option.fullAddress);
      });
      CustomerHeader.updateSelectedOption(option);
    }
  }

  Future<void> _showAddressSelectionModal() async {
    if (_isLoadingLocation) return;
    final selected = await CustomerHeader.showAddressPicker(
      context,
      currentOption: _selectedOption,
    );
    if (selected != null && mounted) {
      await _onAddressSelected(selected);
    }
  }

  Future<void> _refreshCartExclusivity() async {
    final ids = _cartItems
        .map((e) => e.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return;

    try {
      final res = await supabase.from('food_items').select('''
        id,
        is_available,
        food_item_states(states(id, name))
      ''').inFilter('id', ids);

      final Map<String, Map<String, dynamic>> freshData = {};
      for (final raw in res) {
        final id = raw['id']?.toString();
        if (id != null) freshData[id] = Map<String, dynamic>.from(raw);
      }

      bool changed = false;
      final updatedItems = _cartItems.map((item) {
        if (item.id != null && freshData.containsKey(item.id)) {
          final data = freshData[item.id]!;
          final isAvail = data['is_available'] as bool? ?? true;
          final rawStates = data['food_item_states'] as List<dynamic>?;
          final states = rawStates
                  ?.whereType<Map<String, dynamic>>()
                  .map((e) =>
                      (e['states'] as Map<String, dynamic>?)?['name']?.toString())
                  .whereType<String>()
                  .toList() ??
              [];

          bool statesEqual = item.exclusiveStates.length == states.length;
          if (statesEqual) {
            for (int i = 0; i < states.length; i++) {
              if (item.exclusiveStates[i] != states[i]) {
                statesEqual = false;
                break;
              }
            }
          }

          if (item.isAvailable != isAvail || !statesEqual) {
            changed = true;
            return item.copyWith(
              isAvailable: isAvail,
              exclusiveStates: states,
            );
          }
        }
        return item;
      }).toList();

      if (changed && mounted) {
        setState(() {
          _cartItems = updatedItems;
        });
        await CartStorage.saveCart(updatedItems);
      }
    } catch (_) {}
  }

  Future<void> _loadCart() async {
    final items = await CartStorage.loadCart();
    if (mounted) {
      setState(() {
        _cartItems = items;
      });
      _refreshCartExclusivity();
    }
  }

  Future<void> _updateQuantity(int index, int newQuantity) async {
    setState(() {
      _cartItems[index].quantity = newQuantity;
    });
    await CartStorage.saveCart(_cartItems);
  }

  Future<void> _removeItem(int index) async {
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
              builder: (_) =>
                  FoodItemDetail(item: Map<String, dynamic>.from(res)),
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
            'exclusive_states': cartItem.exclusiveStates,
            'is_available': cartItem.isAvailable,
          }),
        ),
      );
      _loadCart();
    }
  }

  Future<void> _navigateToCheckout() async {
    if (_isLoadingLocation) return;
    if (_hasUnavailableItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please remove unavailable items before proceeding to checkout.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerCheckout(
          cartItems: _cartItems,
          deliveryAddress: _selectedOption?.fullAddress ??
              (CustomerHeader.cachedAddress.isNotEmpty
                  ? CustomerHeader.cachedAddress
                  : null),
        ),
      ),
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

  void _navigateToMenu() {
    if (CustomerMainNavigation.hasCurrentState) {
      CustomerMainNavigation.switchToTab(1);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerMainNavigation(initialIndex: 1),
        ),
        (route) => false,
      );
    }
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
              'You must be logged in to view your cart.',
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
                Icons.shopping_cart_outlined,
                size: 36,
                color: Color(0xFFFFA07A),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xDD000000),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add some delicious items from our menu to get started!',
              style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToMenu,
              icon: const Icon(Icons.restaurant_menu, size: 18),
              label: const Text(
                'Explore Menu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA07A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    final address = _selectedOption?.fullAddress ??
        (_currentState.isNotEmpty ? _currentState : 'Select Delivery Location');
    final label = _selectedOption?.label ?? 'Delivery Location';
    final state = _currentState;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: _isLoadingLocation ? null : _showAddressSelectionModal,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA07A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xFFFFA07A),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (state.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            state,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFA07A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isLoadingLocation ? 'Getting current location...' : address,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xDD000000),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _isLoadingLocation ? 16 : 10,
                vertical: _isLoadingLocation ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFA07A),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFA07A),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Color(0xFFFFA07A),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableNoticeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD32F2F),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_unavailableItems.length} item(s) are unavailable for delivery to ${_currentState.isNotEmpty ? _currentState : 'your location'}. Remove them or change location to checkout.',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA07A).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFFFFA07A),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Getting current location...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xDD000000),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Checking item availability for your area',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        _buildLocationSection(),
        if (_hasUnavailableItems && !_isLoadingLocation)
          _buildUnavailableNoticeBanner(),
        Expanded(
          child: _isLoadingLocation
              ? _buildCartLoadingState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
    final isAvailable = _isItemAvailable(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.white : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable
              ? const Color(0xFFEEEEEE)
              : const Color(0xFFE0E0E0),
        ),
        boxShadow: [
          BoxShadow(
            color: isAvailable
                ? const Color(0x0A000000)
                : const Color(0x04000000),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                    child: isAvailable
                        ? (item.imageUrl != null && item.imageUrl!.isNotEmpty
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
                              ))
                        : ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            ),
                            child: Opacity(
                              opacity: 0.55,
                              child: item.imageUrl != null &&
                                      item.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      item.imageUrl!,
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, error, stackTrace) =>
                                          Icon(
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isAvailable
                                    ? const Color(0xDD000000)
                                    : const Color(0xFF757575),
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
                      if (!isAvailable)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cancel_outlined,
                                size: 13,
                                color: Color(0xFFD32F2F),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  !item.isAvailable
                                      ? 'Currently out of stock'
                                      : 'Unavailable in ${_currentState.isNotEmpty ? _currentState : 'your location'} (Exclusive to ${item.exclusiveStates.join(', ')})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFD32F2F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? const Color(0xFFFFA07A)
                                  : const Color(0xFF9E9E9E),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: isAvailable
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildQuantityButton(
                                        icon: Icons.remove,
                                        iconColor: item.quantity > 1
                                            ? const Color(0xDD000000)
                                            : const Color(0xFFBDBDBD),
                                        onTap: () {
                                          if (item.quantity > 1) {
                                            _updateQuantity(
                                                index, item.quantity - 1);
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
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildQuantityButton(
                                        icon: Icons.remove,
                                        iconColor: const Color(0xFFE0E0E0),
                                        onTap: () {},
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
                                            color: Color(0xFF9E9E9E),
                                          ),
                                        ),
                                      ),
                                      _buildQuantityButton(
                                        icon: Icons.add,
                                        iconColor: const Color(0xFFE0E0E0),
                                        onTap: () {},
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
    final canCheckout = !_hasUnavailableItems && !_isLoadingLocation;

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
                Text(
                  _hasUnavailableItems
                      ? 'Total (Available items)'
                      : 'Total Price',
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'RM ${(_hasUnavailableItems ? _availableTotalPrice : _totalPrice).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _hasUnavailableItems
                        ? const Color(0xFF757575)
                        : const Color(0xDD000000),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: canCheckout ? _navigateToCheckout : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA07A),
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF9E9E9E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  _isLoadingLocation
                      ? 'Updating Location...'
                      : (canCheckout ? 'Checkout' : 'Unavailable Items in Cart'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
