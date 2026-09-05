import 'package:flutter/material.dart';

import '../main.dart';
import 'cart.dart';
import 'main_navigation.dart';

class FoodItemDetail extends StatefulWidget {
  final Map<String, dynamic> item;

  const FoodItemDetail({super.key, required this.item});

  @override
  State<FoodItemDetail> createState() => _FoodItemDetailState();
}

class _FoodItemDetailState extends State<FoodItemDetail> {
  int _quantity = 1;
  String? _selectedSize;
  String? _selectedSpice;
  final Set<String> _selectedAddons = {};
  final TextEditingController _specialInstructionsController = TextEditingController();

  late List<Map<String, dynamic>> _sizes;
  late List<String> _spiceLevels;
  late List<Map<String, dynamic>> _addons;

  bool get _isAuthenticated {
    final session = supabase.auth.currentSession;
    if (session == null || session.isExpired) return false;
    return supabase.auth.currentUser != null;
  }

  String get _name => widget.item['name']?.toString() ?? 'Food Item';
  double get _basePrice => (widget.item['price'] as num?)?.toDouble() ?? 0.0;
  String? get _imageUrl => widget.item['image_url'] as String?;
  IconData get _icon => widget.item['icon'] as IconData? ?? Icons.fastfood_outlined;
  bool get _isAvailable => widget.item['is_available'] as bool? ?? true;

  String get _prepTime {
    final int? prepMinutes = widget.item['preparation_time'] as int? ??
        (widget.item['prepTime'] != null ? int.tryParse(widget.item['prepTime'].toString()) : null);
    if (prepMinutes != null) return '$prepMinutes mins';
    final str = widget.item['prepTime']?.toString();
    return (str != null && str.isNotEmpty) ? str : '15 mins';
  }

  List<String> get _categories {
    final raw = widget.item['food_item_categories'] as List<dynamic>?;
    if (raw != null && raw.isNotEmpty) {
      final cats = raw
          .whereType<Map<String, dynamic>>()
          .map((e) => (e['food_categories'] as Map<String, dynamic>?)?['name']?.toString())
          .whereType<String>()
          .toList();
      if (cats.isNotEmpty) return cats;
    }
    if (widget.item['categories'] is List) {
      return (widget.item['categories'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (widget.item['category'] != null && widget.item['category'].toString().isNotEmpty) {
      return [widget.item['category'].toString()];
    }
    return const [];
  }

  double get _totalPrice {
    double total = _basePrice;
    if (_selectedSize != null) {
      final size = _sizes.firstWhere((s) => s['name'] == _selectedSize, orElse: () => {'price': 0.0});
      total += ((size['price'] as num?)?.toDouble() ?? 0.0);
    }
    for (final addon in _selectedAddons) {
      final item = _addons.firstWhere((a) => a['name'] == addon, orElse: () => {'price': 0.0});
      total += ((item['price'] as num?)?.toDouble() ?? 0.0);
    }
    return total * _quantity;
  }

  @override
  void initState() {
    super.initState();
    _sizes = widget.item['sizes'] != null ? List<Map<String, dynamic>>.from(widget.item['sizes']) : [];
    _spiceLevels = widget.item['spiceLevels'] != null ? List<String>.from(widget.item['spiceLevels']) : [];
    _addons = widget.item['addons'] != null ? List<Map<String, dynamic>>.from(widget.item['addons']) : [];

    if (_sizes.isNotEmpty) _selectedSize = _sizes.first['name'];
    if (_spiceLevels.isNotEmpty) _selectedSpice = _spiceLevels.first;
  }

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _incrementQuantity() => setState(() => _quantity++);

  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _selectSize(String sizeName) => setState(() => _selectedSize = sizeName);

  void _selectSpice(String spiceLevel) => setState(() => _selectedSpice = spiceLevel);

  void _toggleAddon(String addonName) {
    setState(() {
      _selectedAddons.contains(addonName) ? _selectedAddons.remove(addonName) : _selectedAddons.add(addonName);
    });
  }

  Future<void> _addToCart() async {
    final List<CartItemCustomization> customizations = [];

    if (_selectedSize != null) {
      final sizeMap = _sizes.firstWhere(
        (s) => s['name'] == _selectedSize,
        orElse: () => {'price': 0.0},
      );
      final sizePrice = (sizeMap['price'] as num?)?.toDouble() ?? 0.0;
      customizations.add(CartItemCustomization(
        name: 'Size: $_selectedSize',
        price: sizePrice,
      ));
    }

    if (_selectedSpice != null && _selectedSpice!.isNotEmpty) {
      customizations.add(CartItemCustomization(
        name: 'Spice: $_selectedSpice',
        price: 0.0,
      ));
    }

    for (final addonName in _selectedAddons) {
      final addonMap = _addons.firstWhere(
        (a) => a['name'] == addonName,
        orElse: () => {'price': 0.0},
      );
      final addonPrice = (addonMap['price'] as num?)?.toDouble() ?? 0.0;
      customizations.add(CartItemCustomization(
        name: addonName,
        price: addonPrice,
      ));
    }

    final instructions = _specialInstructionsController.text.trim();
    if (instructions.isNotEmpty) {
      customizations.add(CartItemCustomization(
        name: 'Note: $instructions',
        price: 0.0,
      ));
    }

    final cartItem = CartItem(
      id: widget.item['id']?.toString(),
      name: _name,
      price: _basePrice,
      quantity: _quantity,
      icon: _icon,
      imageUrl: _imageUrl,
      customizations: customizations,
    );

    await CartStorage.addToCart(cartItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_name added to cart!', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFFFA07A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xDD000000), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _name,
          style: const TextStyle(color: Color(0xDD000000), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageHeader(),
                    const SizedBox(height: 16),
                    _buildItemInfo(),
                    const SizedBox(height: 20),
                    _buildSizeSelector(),
                    _buildSpiceLevelSelector(),
                    _buildAddonSelector(),
                    _buildSpecialInstructionsSection(),
                  ],
                ),
              ),
            ),
            _buildBottomCartBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return Container(
      height: 240,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: (_imageUrl != null && _imageUrl!.isNotEmpty)
            ? Image.network(
                _imageUrl!,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : const Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFFA07A)),
                        ),
                      ),
                errorBuilder: (context, error, stackTrace) => Center(child: Icon(_icon, size: 80, color: const Color(0xFFFFA07A))),
              )
            : Center(child: Icon(_icon, size: 80, color: const Color(0xFFFFA07A))),
      ),
    );
  }

  Widget _buildItemInfo() {
    final categories = _categories;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xDD000000)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'RM ${_basePrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFA07A)),
              ),
            ],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFC8B4)),
                  ),
                  child: Text(cat, style: const TextStyle(color: Color(0xFFFF7F50), fontWeight: FontWeight.bold, fontSize: 12)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF9E9E9E), size: 16),
              const SizedBox(width: 6),
              Text(_prepTime, style: const TextStyle(fontSize: 13, color: Color(0xFF757575), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector() {
    if (_sizes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Choice of Size', isRequired: true),
        const SizedBox(height: 8),
        ..._sizes.map((size) {
          final isSelected = _selectedSize == size['name'];
          final price = (size['price'] as num?)?.toDouble() ?? 0.0;
          return _buildOptionTile(
            title: size['name']?.toString() ?? '',
            price: price,
            isSelected: isSelected,
            isRadio: true,
            onTap: () => _selectSize(size['name']?.toString() ?? ''),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSpiceLevelSelector() {
    if (_spiceLevels.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Spice Level', isRequired: false),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 12,
            children: _spiceLevels.map((level) {
              final isSelected = _selectedSpice == level;
              return ChoiceChip(
                label: Text(level),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) _selectSpice(level);
                },
                selectedColor: const Color(0xFFFFA07A),
                backgroundColor: const Color(0xFFF5F5F5),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xDD000000),
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? const Color(0xFFFFA07A) : const Color(0xFFE0E0E0)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAddonSelector() {
    if (_addons.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Add-ons & Extras', isRequired: false),
        const SizedBox(height: 8),
        ..._addons.map((addon) {
          final addonName = addon['name']?.toString() ?? '';
          final isSelected = _selectedAddons.contains(addonName);
          final price = (addon['price'] as num?)?.toDouble() ?? 0.0;
          return _buildOptionTile(
            title: addonName,
            price: price,
            isSelected: isSelected,
            isRadio: false,
            onTap: () => _toggleAddon(addonName),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required double price,
    required bool isSelected,
    required bool isRadio,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5F0) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFA07A) : const Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isRadio
                      ? (isSelected ? Icons.radio_button_checked : Icons.radio_button_off)
                      : (isSelected ? Icons.check_box : Icons.check_box_outline_blank),
                  color: isSelected ? const Color(0xFFFFA07A) : const Color(0xFF9E9E9E),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: const Color(0xDD000000),
                  ),
                ),
              ],
            ),
            Text(
              '+ RM ${price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFFFFA07A) : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Special Instructions', isRequired: false),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _specialInstructionsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g., No onions, extra napkins, separate sauce...',
              hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFFFA07A))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCartBar() {
    if (!_isAuthenticated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, -4))],
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _navigateToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA07A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text(
              'Log In Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    final isAvailable = _isAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, -4))],
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: isAvailable && _quantity > 1 ? _decrementQuantity : null,
                  icon: const Icon(Icons.remove, size: 20),
                  color: const Color(0xDD000000),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xDD000000)),
                  ),
                ),
                IconButton(
                  onPressed: isAvailable ? _incrementQuantity : null,
                  icon: const Icon(Icons.add, size: 20),
                  color: const Color(0xDD000000),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isAvailable ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA07A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Text(
                  isAvailable ? 'Add to Cart - RM ${_totalPrice.toStringAsFixed(2)}' : 'Currently Unavailable',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xDD000000)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: isRequired ? const Color(0xFFFFF5F0) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: isRequired ? const Color(0xFFFFC8B4) : const Color(0xFFE0E0E0)),
            ),
            child: Text(
              isRequired ? 'Required' : 'Optional',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isRequired ? const Color(0xFFFF7F50) : const Color(0xFF757575),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
