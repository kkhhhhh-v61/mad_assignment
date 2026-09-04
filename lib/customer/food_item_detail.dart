import 'package:flutter/material.dart';

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
  final TextEditingController _specialInstructionsController =
      TextEditingController();

  late List<Map<String, dynamic>> _sizes;
  late List<String> _spiceLevels;
  late List<Map<String, dynamic>> _addons;

  String get _name => widget.item['name']?.toString() ?? 'Food Item';
  double get _basePrice => (widget.item['price'] as num?)?.toDouble() ?? 0.0;
  String? get _imageUrl => widget.item['image_url'] as String?;
  IconData get _icon =>
      widget.item['icon'] as IconData? ?? Icons.fastfood_outlined;
  bool get _isAvailable => widget.item['is_available'] as bool? ?? true;

  String get _prepTime {
    final int? prepMinutes = widget.item['preparation_time'] as int? ??
        (widget.item['prepTime'] != null
            ? int.tryParse(widget.item['prepTime'].toString())
            : null);
    if (prepMinutes != null) return '$prepMinutes mins';
    final str = widget.item['prepTime']?.toString();
    if (str != null && str.isNotEmpty) return str;
    return '15 mins';
  }

  List<String> get _categories {
    final rawList = widget.item['food_item_categories'] as List<dynamic>?;
    if (rawList != null && rawList.isNotEmpty) {
      final cats = <String>[];
      for (final entry in rawList) {
        if (entry is Map<String, dynamic>) {
          final cat = entry['food_categories'] as Map<String, dynamic>?;
          if (cat != null && cat['name'] != null) {
            cats.add(cat['name'].toString());
          }
        }
      }
      if (cats.isNotEmpty) return cats;
    }
    if (widget.item['categories'] is List) {
      return (widget.item['categories'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (widget.item['category'] != null &&
        widget.item['category'].toString().isNotEmpty) {
      return [widget.item['category'].toString()];
    }
    return [];
  }


  double get _calculatedTotal {
    double total = _basePrice;
    if (_selectedSize != null) {
      final sizeItem = _sizes.firstWhere(
        (s) => s['name'] == _selectedSize,
        orElse: () => {'price': 0.0},
      );
      total += ((sizeItem['price'] as num?)?.toDouble() ?? 0.0);
    }
    for (final addonName in _selectedAddons) {
      final addonItem = _addons.firstWhere(
        (a) => a['name'] == addonName,
        orElse: () => {'price': 0.0},
      );
      total += ((addonItem['price'] as num?)?.toDouble() ?? 0.0);
    }
    return total * _quantity;
  }

  @override
  void initState() {
    super.initState();
    _sizes = widget.item['sizes'] != null
        ? List<Map<String, dynamic>>.from(widget.item['sizes'])
        : [];
    _spiceLevels = widget.item['spiceLevels'] != null
        ? List<String>.from(widget.item['spiceLevels'])
        : [];
    _addons = widget.item['addons'] != null
        ? List<Map<String, dynamic>>.from(widget.item['addons'])
        : [];

    if (_sizes.isNotEmpty) {
      _selectedSize = _sizes.first['name'];
    }
    if (_spiceLevels.isNotEmpty) {
      _selectedSpice = _spiceLevels.first;
    }
  }

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    super.dispose();
  }

  Widget _buildImageHeader() {
    return Container(
      height: 240,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 245),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color.fromARGB(255, 224, 224, 224),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: (_imageUrl != null && _imageUrl!.isNotEmpty)
            ? Image.network(
                _imageUrl!,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.fromARGB(255, 255, 160, 122),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    _icon,
                    size: 80,
                    color: const Color.fromARGB(255, 255, 160, 122),
                  ),
                ),
              )
            : Center(
                child: Icon(
                  _icon,
                  size: 80,
                  color: const Color.fromARGB(255, 255, 160, 122),
                ),
              ),
      ),
    );
  }

  Widget _buildItemInfo() {
    final categories = _categories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 0, 0, 0),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                'RM ${_basePrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
              ),
            ],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: categories.map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 245, 240),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: const Color.fromARGB(255, 255, 200, 180),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 127, 80),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12.0),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Color.fromARGB(255, 158, 158, 158),
                size: 16,
              ),
              const SizedBox(width: 6.0),
              Text(
                _prepTime,
                style: const TextStyle(
                  fontSize: 13.0,
                  color: Color.fromARGB(255, 117, 117, 117),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(221, 0, 0, 0),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2),
            decoration: BoxDecoration(
              color: isRequired
                  ? const Color.fromARGB(255, 255, 245, 240)
                  : const Color.fromARGB(255, 245, 245, 245),
              borderRadius: BorderRadius.circular(25.0),
              border: Border.all(
                color: isRequired
                    ? const Color.fromARGB(255, 255, 200, 180)
                    : const Color.fromARGB(255, 224, 224, 224),
              ),
            ),
            child: Text(
              isRequired ? 'Required' : 'Optional',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: isRequired
                    ? const Color.fromARGB(255, 255, 127, 80)
                    : const Color.fromARGB(255, 117, 117, 117),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacySizesSection() {
    if (_sizes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Choice of Size', isRequired: true),
        const SizedBox(height: 8.0),
        ..._sizes.map((size) {
          final isSelected = _selectedSize == size['name'];
          final price = (size['price'] as num?)?.toDouble() ?? 0.0;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSize = size['name'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 8.0,
              ),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color.fromARGB(255, 255, 245, 240)
                    : Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(
                  color: isSelected
                      ? const Color.fromARGB(255, 255, 160, 122)
                      : const Color.fromARGB(255, 224, 224, 224),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? const Color.fromARGB(255, 255, 160, 122)
                            : const Color.fromARGB(255, 158, 158, 158),
                        size: 20,
                      ),
                      const SizedBox(width: 12.0),
                      Text(
                        size['name']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: const Color.fromARGB(221, 0, 0, 0),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '+ RM ${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color.fromARGB(255, 255, 160, 122)
                          : const Color.fromARGB(255, 117, 117, 117),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildLegacySpiceSection() {
    if (_spiceLevels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Spice Level', isRequired: false),
        const SizedBox(height: 8.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Wrap(
            spacing: 12.0,
            children: _spiceLevels.map((level) {
              final isSelected = _selectedSpice == level;

              return ChoiceChip(
                label: Text(level),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSpice = level;
                    });
                  }
                },
                selectedColor: const Color.fromARGB(255, 255, 160, 122),
                backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : const Color.fromARGB(221, 0, 0, 0),
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: BorderSide(
                    color: isSelected
                        ? const Color.fromARGB(255, 255, 160, 122)
                        : const Color.fromARGB(255, 224, 224, 224),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildLegacyAddonsSection() {
    if (_addons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Add-ons & Extras', isRequired: false),
        const SizedBox(height: 8.0),
        ..._addons.map((addon) {
          final isSelected = _selectedAddons.contains(addon['name']);
          final price = (addon['price'] as num?)?.toDouble() ?? 0.0;

          return GestureDetector(
            onTap: () {
              setState(() {
                if (_selectedAddons.contains(addon['name'])) {
                  _selectedAddons.remove(addon['name']);
                } else {
                  _selectedAddons.add(addon['name']);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 8.0,
              ),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color.fromARGB(255, 255, 245, 240)
                    : Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(
                  color: isSelected
                      ? const Color.fromARGB(255, 255, 160, 122)
                      : const Color.fromARGB(255, 224, 224, 224),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: isSelected
                            ? const Color.fromARGB(255, 255, 160, 122)
                            : const Color.fromARGB(255, 158, 158, 158),
                        size: 20,
                      ),
                      const SizedBox(width: 12.0),
                      Text(
                        addon['name']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: const Color.fromARGB(221, 0, 0, 0),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '+ RM ${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color.fromARGB(255, 255, 160, 122)
                          : const Color.fromARGB(255, 117, 117, 117),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildSpecialInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Special Instructions', isRequired: false),
        const SizedBox(height: 8.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: TextField(
            controller: _specialInstructionsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g., No onions, extra napkins, separate sauce...',
              hintStyle: const TextStyle(
                color: Color.fromARGB(255, 158, 158, 158),
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 245, 245, 245),
              contentPadding: const EdgeInsets.all(12.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 224, 224, 224),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 224, 224, 224),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCartBar() {
    final isAvailable = _isAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 16.0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(15, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: Color.fromARGB(255, 224, 224, 224)),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 245, 245, 245),
              borderRadius: BorderRadius.circular(25.0),
              border: Border.all(
                color: const Color.fromARGB(255, 224, 224, 224),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: isAvailable && _quantity > 1
                      ? () {
                          setState(() {
                            _quantity--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove, size: 20),
                  color: const Color.fromARGB(221, 0, 0, 0),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(221, 0, 0, 0),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isAvailable
                      ? () {
                          setState(() {
                            _quantity++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add, size: 20),
                  color: const Color.fromARGB(221, 0, 0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isAvailable
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$_name added to cart!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor:
                                const Color.fromARGB(255, 255, 160, 122),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(
                    255,
                    255,
                    160,
                    122,
                  ),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color.fromARGB(255, 224, 224, 224),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: Text(
                  isAvailable
                      ? 'Add to Cart - RM ${_calculatedTotal.toStringAsFixed(2)}'
                      : 'Currently Unavailable',
                  style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
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
        title: Text(
          _name,
          style: const TextStyle(
            color: Color.fromARGB(221, 0, 0, 0),
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
                padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageHeader(),
                    const SizedBox(height: 16.0),
                    _buildItemInfo(),
                    const SizedBox(height: 20.0),
                    _buildLegacySizesSection(),
                    _buildLegacySpiceSection(),
                    _buildLegacyAddonsSection(),
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
}
