import 'package:flutter/material.dart';


class FoodItemDetail extends StatefulWidget {
  final Map<String, dynamic> item;

  const FoodItemDetail({super.key, required this.item});

  String get name => item['name'] as String? ?? 'Unknown';
  double get price => item['price'] as double? ?? 0.0;
  IconData get icon => item['icon'] as IconData? ?? Icons.fastfood;
  String get category => item['category'] as String? ?? 'Category';
  String get rating => item['rating'] as String? ?? '0.0';
  String get prepTime => item['prepTime'] as String? ?? '0 min';

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

  late String _description;
  late List<Map<String, dynamic>> _sizes;
  late List<String> _spiceLevels;
  late List<Map<String, dynamic>> _addons;

  @override
  void initState() {
    super.initState();
    _description = widget.item['description'] as String? ?? 'No description available.';
    _sizes = widget.item['sizes'] != null ? List<Map<String, dynamic>>.from(widget.item['sizes']) : [];
    _spiceLevels = widget.item['spiceLevels'] != null ? List<String>.from(widget.item['spiceLevels']) : [];
    _addons = widget.item['addons'] != null ? List<Map<String, dynamic>>.from(widget.item['addons']) : [];

    if (_sizes.isNotEmpty) {
      _selectedSize = _sizes.first['name'];
    }
    if (_spiceLevels.isNotEmpty) {
      _selectedSpice = _spiceLevels.first;
    }
  }

  double get _calculatedTotal {
    double total = widget.price;
    if (_selectedSize != null) {
      final sizeItem = _sizes.firstWhere((s) => s['name'] == _selectedSize, orElse: () => {'price': 0.0});
      total += (sizeItem['price'] as double? ?? 0.0);
    }
    for (final addonName in _selectedAddons) {
      final addonItem = _addons.firstWhere((a) => a['name'] == addonName, orElse: () => {'price': 0.0});
      total += (addonItem['price'] as double? ?? 0.0);
    }
    return total * _quantity;
  }

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    super.dispose();
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
        title: Text(
          widget.name,
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
                    ItemImageHeader(icon: widget.icon),
                    const SizedBox(height: 16.0),
                    ItemInfoSection(
                      name: widget.name,
                      price: widget.price,
                      category: widget.category,
                      rating: widget.rating,
                      prepTime: widget.prepTime,
                      description: _description,
                    ),
                    const SizedBox(height: 20.0),
                    
                    if (_sizes.isNotEmpty) ...[
                      const SectionHeader(title: 'Choice of Size', isRequired: true),
                      const SizedBox(height: 8.0),
                      ..._sizes.map((size) {
                        return SizeOption(
                          label: size['name'],
                          price: size['price'] as double? ?? 0.0,
                          isSelected: _selectedSize == size['name'],
                          onTap: () {
                            setState(() {
                              _selectedSize = size['name'];
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 16.0),
                    ],

                    if (_spiceLevels.isNotEmpty) ...[
                      const SectionHeader(title: 'Spice Level', isRequired: false),
                      const SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Wrap(
                          spacing: 12.0,
                          children: _spiceLevels.map((level) {
                            return SpiceOption(
                              level: level,
                              isSelected: _selectedSpice == level,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedSpice = level;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    if (_addons.isNotEmpty) ...[
                      const SectionHeader(title: 'Add-ons & Extras', isRequired: false),
                      const SizedBox(height: 8.0),
                      ..._addons.map((addon) {
                        return AddonOption(
                          label: addon['name'],
                          price: addon['price'] as double? ?? 0.0,
                          isSelected: _selectedAddons.contains(addon['name']),
                          onTap: () {
                            setState(() {
                              if (_selectedAddons.contains(addon['name'])) {
                                _selectedAddons.remove(addon['name']);
                              } else {
                                _selectedAddons.add(addon['name']);
                              }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 16.0),
                    ],

                    const SectionHeader(title: 'Special Instructions', isRequired: false),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        controller: _specialInstructionsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'e.g., No onions, extra napkins, separate sauce...',
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
                ),
              ),
            ),
            QuantityAndCartBar(
              quantity: _quantity,
              totalPrice: _calculatedTotal,
              onDecrease: _quantity > 1
                  ? () {
                      setState(() {
                        _quantity--;
                      });
                    }
                  : null,
              onIncrease: () {
                setState(() {
                  _quantity++;
                });
              },
              onAddToCart: () {
                //TODO: Submit selected food item and customizations to backend cart API
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${widget.name} added to cart!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ItemImageHeader extends StatelessWidget {
  final IconData icon;
  const ItemImageHeader({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 245),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color.fromARGB(255, 224, 224, 224),
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 96,
          color: const Color.fromARGB(255, 255, 160, 122),
        ),
      ),
    );
  }
}

class ItemInfoSection extends StatelessWidget {
  final String name;
  final double price;
  final String category;
  final String rating;
  final String prepTime;
  final String description;

  const ItemInfoSection({
    super.key,
    required this.name,
    required this.price,
    required this.category,
    required this.rating,
    required this.prepTime,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
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
                  name,
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 0, 0, 0),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                'RM ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    255,
                    160,
                    122,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 160, 122),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              const Icon(
                Icons.star,
                color: Color.fromARGB(255, 255, 193, 7),
                size: 18,
              ),
              const SizedBox(width: 4.0),
              Text(
                rating,
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(221, 0, 0, 0),
                ),
              ),
              const SizedBox(width: 4.0),
              const Text(
                '(120+ reviews)',
                style: TextStyle(
                  fontSize: 13.0,
                  color: Color.fromARGB(255, 117, 117, 117),
                ),
              ),
              const SizedBox(width: 16.0),
              const Icon(
                Icons.access_time,
                color: Color.fromARGB(255, 158, 158, 158),
                size: 18,
              ),
              const SizedBox(width: 4.0),
              Text(
                prepTime,
                style: const TextStyle(
                  fontSize: 13.0,
                  color: Color.fromARGB(255, 117, 117, 117),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Divider(
            height: 1,
            color: Color.fromARGB(255, 224, 224, 224),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(221, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15.0,
              color: Color.fromARGB(255, 117, 117, 117),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isRequired;

  const SectionHeader({super.key, required this.title, required this.isRequired});

  @override
  Widget build(BuildContext context) {
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
                  ? const Color.fromARGB(
                      255,
                      255,
                      160,
                      122,
                    ).withValues(alpha: 0.1)
                  : const Color.fromARGB(255, 245, 245, 245),
              borderRadius: BorderRadius.circular(25.0),
            ),
            child: Text(
              isRequired ? 'Required' : 'Optional',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: isRequired
                    ? const Color.fromARGB(255, 255, 160, 122)
                    : const Color.fromARGB(255, 117, 117, 117),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SizeOption extends StatelessWidget {
  final String label;
  final double price;
  final bool isSelected;
  final VoidCallback onTap;

  const SizeOption({
    super.key,
    required this.label,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.05)
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
                  label,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
  }
}

class SpiceOption extends StatelessWidget {
  final String level;
  final bool isSelected;
  final Function(bool) onSelected;

  const SpiceOption({
    super.key,
    required this.level,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(level),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color.fromARGB(
        255,
        255,
        160,
        122,
      ),
      backgroundColor: const Color.fromARGB(
        255,
        245,
        245,
        245,
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : const Color.fromARGB(221, 0, 0, 0),
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
        side: BorderSide(
          color: isSelected
              ? const Color.fromARGB(
                  255,
                  255,
                  160,
                  122,
                )
              : const Color.fromARGB(
                  255,
                  224,
                  224,
                  224,
                ),
        ),
      ),
    );
  }
}

class AddonOption extends StatelessWidget {
  final String label;
  final double price;
  final bool isSelected;
  final VoidCallback onTap;

  const AddonOption({
    super.key,
    required this.label,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.05)
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
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected
                      ? const Color.fromARGB(255, 255, 160, 122)
                      : const Color.fromARGB(255, 158, 158, 158),
                  size: 20,
                ),
                const SizedBox(width: 12.0),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
  }
}

class QuantityAndCartBar extends StatelessWidget {
  final int quantity;
  final double totalPrice;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onAddToCart;

  const QuantityAndCartBar({
    super.key,
    required this.quantity,
    required this.totalPrice,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
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
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove, size: 20),
                  color: const Color.fromARGB(221, 0, 0, 0),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(221, 0, 0, 0),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add, size: 20),
                  color: const Color.fromARGB(221, 0, 0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: ElevatedButton(
              onPressed: onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                  255,
                  255,
                  160,
                  122,
                ),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              child: Text(
                'Add to Cart - RM ${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
