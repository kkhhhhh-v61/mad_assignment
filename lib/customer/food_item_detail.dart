import 'package:flutter/material.dart';

class FoodItemDetail extends StatefulWidget {
  final Map<String, dynamic> item;

  const FoodItemDetail({super.key, required this.item});

  String get name => item['name'] as String;
  double get price => item['price'] as double;
  IconData get icon => item['icon'] as IconData;
  String get category => item['category'] as String;
  String get rating => item['rating'] as String;
  String get prepTime => item['prepTime'] as String;

  @override
  State<FoodItemDetail> createState() => _FoodItemDetailState();
}

class _FoodItemDetailState extends State<FoodItemDetail> {
  int _quantity = 1;
  String _selectedSize = 'Regular';
  String _selectedSpice = 'Normal';
  final Set<String> _selectedAddons = {};
  final TextEditingController _specialInstructionsController =
      TextEditingController();

  double get _calculatedTotal {
    double total = widget.price;
    if (_selectedSize == 'Large') total += 3.50;
    if (_selectedSize == 'Extra Large') total += 6.00;
    for (final addon in _selectedAddons) {
      if (addon == 'Extra Cheese') total += 2.50;
      if (addon == 'Add Egg') total += 2.00;
      if (addon == 'Extra Sauce') total += 1.50;
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
        title: Text(
          widget.name,
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
                padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 230,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          size: 96,
                          color: const Color.fromARGB(255, 255, 160, 122),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Padding(
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
                                  widget.name,
                                  style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xDD000000),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Text(
                                'RM ${widget.price.toStringAsFixed(2)}',
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
                                  widget.category,
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
                                color: Color(0xFFFFC107),
                                size: 18,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                widget.rating,
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xDD000000),
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              const Text(
                                '(120+ reviews)',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: Color(0xFF757575),
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFF9E9E9E),
                                size: 18,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                widget.prepTime,
                                style: const TextStyle(
                                  fontSize: 13.0,
                                  color: Color(0xFF757575),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          const Divider(height: 1, color: Color(0xFFE0E0E0)),
                          const SizedBox(height: 16.0),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xDD000000),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          const Text(
                            'Prepared fresh daily using authentic recipes and signature ingredients. Carefully crafted to provide a delightful balance of rich flavors and perfect textures with every serving.',
                            style: TextStyle(
                              fontSize: 15.0,
                              color: Color(0xFF757575),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    _buildSectionHeader('Choice of Size', true),
                    const SizedBox(height: 8.0),
                    _buildSizeOption('Regular', '+ RM 0.00'),
                    _buildSizeOption('Large', '+ RM 3.50'),
                    _buildSizeOption('Extra Large', '+ RM 6.00'),
                    const SizedBox(height: 16.0),
                    _buildSectionHeader('Spice Level', false),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Wrap(
                        spacing: 12.0,
                        children: ['No Spice', 'Mild', 'Normal', 'Extra Spicy']
                            .map((level) {
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
                                selectedColor: const Color.fromARGB(
                                  255,
                                  255,
                                  160,
                                  122,
                                ),
                                backgroundColor: const Color(0xFFF5F5F5),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xDD000000),
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
                                        : const Color(0xFFE0E0E0),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    _buildSectionHeader('Add-ons & Extras', false),
                    const SizedBox(height: 8.0),
                    _buildAddonOption('Extra Cheese', '+ RM 2.50'),
                    _buildAddonOption('Add Egg', '+ RM 2.00'),
                    _buildAddonOption('Extra Sauce', '+ RM 1.50'),
                    const SizedBox(height: 16.0),
                    _buildSectionHeader('Special Instructions', false),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        controller: _specialInstructionsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'e.g., No onions, extra napkins, separate sauce...',
                          hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          contentPadding: const EdgeInsets.all(12.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
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
            Container(
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
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(25.0),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove, size: 20),
                          color: const Color(0xDD000000),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xDD000000),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _quantity++;
                            });
                          },
                          icon: const Icon(Icons.add, size: 20),
                          color: const Color(0xDD000000),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final List<String> customParts = [
                          'Size: $_selectedSize',
                          'Spice: $_selectedSpice',
                        ];
                        if (_selectedAddons.isNotEmpty) {
                          customParts.add(
                            'Add-ons: ${_selectedAddons.join(', ')}',
                          );
                        }
                        if (_specialInstructionsController.text
                            .trim()
                            .isNotEmpty) {
                          customParts.add(
                            'Note: ${_specialInstructionsController.text.trim()}',
                          );
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${widget.name} added to cart!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              160,
                              122,
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
                      },
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
                        'Add to Cart - RM ${_calculatedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isRequired) {
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
              color: Color(0xDD000000),
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
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(25.0),
            ),
            child: Text(
              isRequired ? 'Required' : 'Optional',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: isRequired
                    ? const Color.fromARGB(255, 255, 160, 122)
                    : const Color(0xFF757575),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeOption(String label, String priceText) {
    final isSelected = _selectedSize == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSize = label;
        });
      },
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
                : const Color(0xFFE0E0E0),
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
                      : const Color(0xFF9E9E9E),
                  size: 20,
                ),
                const SizedBox(width: 12.0),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: const Color(0xDD000000),
                  ),
                ),
              ],
            ),
            Text(
              priceText,
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color.fromARGB(255, 255, 160, 122)
                    : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonOption(String label, String priceText) {
    final isSelected = _selectedAddons.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedAddons.remove(label);
          } else {
            _selectedAddons.add(label);
          }
        });
      },
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
                : const Color(0xFFE0E0E0),
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
                      : const Color(0xFF9E9E9E),
                  size: 20,
                ),
                const SizedBox(width: 12.0),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: const Color(0xDD000000),
                  ),
                ),
              ],
            ),
            Text(
              priceText,
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color.fromARGB(255, 255, 160, 122)
                    : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
