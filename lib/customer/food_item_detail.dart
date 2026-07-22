import 'package:flutter/material.dart';

import '../config.dart';
import '../data.dart';

class FoodItemDetail extends StatefulWidget {
  final MenuItem item;

  const FoodItemDetail({super.key, required this.item});

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
    double total = widget.item.price;
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
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.item.name,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: fontTitle,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- Scrollable Details & Customization ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: spacingLg,
                  bottom: spacingXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Hero Banner ---
                    Container(
                      height: 230,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: spacingXl),
                      decoration: BoxDecoration(
                        color: surfaceLight,
                        borderRadius: BorderRadius.circular(radiusXl),
                        border: Border.all(color: borderLight),
                      ),
                      child: Center(
                        // TODO: replace with high-resolution image
                        child: Icon(
                          widget.item.icon,
                          size: 96,
                          color: brandColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: spacingLg),
                    // --- Title & Metadata Section ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: spacingXl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.item.name,
                                  style: const TextStyle(
                                    fontSize: fontHeadline,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: spacingMd),
                              Text(
                                formatPrice(widget.item.price),
                                style: const TextStyle(
                                  fontSize: fontHeadline,
                                  fontWeight: FontWeight.bold,
                                  color: brandColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: spacingMd),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: spacingMd,
                                  vertical: spacingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: brandColor.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(radiusFull),
                                ),
                                child: Text(
                                  widget.item.category,
                                  style: const TextStyle(
                                    color: brandColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontDetail,
                                  ),
                                ),
                              ),
                              const SizedBox(width: spacingMd),
                              const Icon(
                                Icons.star,
                                color: starColor,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.item.rating,
                                style: const TextStyle(
                                  fontSize: fontBodyLarge,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '(120+ reviews)',
                                style: TextStyle(
                                  fontSize: fontDetail,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(width: spacingLg),
                              const Icon(
                                Icons.access_time,
                                color: textHint,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.item.prepTime,
                                style: const TextStyle(
                                  fontSize: fontDetail,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: spacingLg),
                          const Divider(height: 1, color: borderLight),
                          const SizedBox(height: spacingLg),
                          // --- Description Section ---
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: fontSubtitle,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: spacingXs),
                          const Text(
                            'Prepared fresh daily using authentic recipes and signature ingredients. Carefully crafted to provide a delightful balance of rich flavors and perfect textures with every serving.',
                            style: TextStyle(
                              fontSize: fontBodyLarge,
                              color: textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: spacingXl),
                    // --- Size Section ---
                    _buildSectionHeader('Choice of Size', true),
                    const SizedBox(height: spacingSm),
                    _buildSizeOption('Regular', '+ RM 0.00'),
                    _buildSizeOption('Large', '+ RM 3.50'),
                    _buildSizeOption('Extra Large', '+ RM 6.00'),
                    const SizedBox(height: spacingLg),
                    // --- Spice Level Section ---
                    _buildSectionHeader('Spice Level', false),
                    const SizedBox(height: spacingSm),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: spacingXl),
                      child: Wrap(
                        spacing: spacingMd,
                        children: [
                          'No Spice',
                          'Mild',
                          'Normal',
                          'Extra Spicy',
                        ].map((level) {
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
                            selectedColor: brandColor,
                            backgroundColor: surfaceLight,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radiusFull),
                              side: BorderSide(
                                color: isSelected ? brandColor : borderLight,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: spacingLg),
                    // --- Add-ons Section ---
                    _buildSectionHeader('Add-ons & Extras', false),
                    const SizedBox(height: spacingSm),
                    _buildAddonOption('Extra Cheese', '+ RM 2.50'),
                    _buildAddonOption('Add Egg', '+ RM 2.00'),
                    _buildAddonOption('Extra Sauce', '+ RM 1.50'),
                    const SizedBox(height: spacingLg),
                    // --- Special Instructions Section ---
                    _buildSectionHeader('Special Instructions', false),
                    const SizedBox(height: spacingSm),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: spacingXl),
                      child: TextField(
                        controller: _specialInstructionsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'e.g., No onions, extra napkins, separate sauce...',
                          hintStyle: const TextStyle(color: textHint),
                          filled: true,
                          fillColor: surfaceLight,
                          contentPadding: const EdgeInsets.all(spacingMd),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radiusLg),
                            borderSide: const BorderSide(color: borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radiusLg),
                            borderSide: const BorderSide(color: borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radiusLg),
                            borderSide: const BorderSide(color: brandColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // --- Bottom Action Bar ---
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: spacingXl,
                vertical: spacingLg,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [shadowBottomBar],
                border: Border(top: BorderSide(color: borderLight)),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceLight,
                      borderRadius: BorderRadius.circular(radiusFull),
                      border: Border.all(color: borderLight),
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
                          color: textPrimary,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: spacingSm,
                          ),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: fontTitle,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
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
                          color: textPrimary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: spacingLg),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: replace with dynamic state management
                        final List<String> customParts = [
                          'Size: $_selectedSize',
                          'Spice: $_selectedSpice',
                        ];
                        if (_selectedAddons.isNotEmpty) {
                          customParts.add(
                            'Add-ons: ${_selectedAddons.join(', ')}',
                          );
                        }
                        if (_specialInstructionsController.text.trim().isNotEmpty) {
                          customParts.add(
                            'Note: ${_specialInstructionsController.text.trim()}',
                          );
                        }
                        final customString = customParts.join(' • ');

                        cartItems.add(
                          CartItem(
                            name: widget.item.name,
                            price: _calculatedTotal / _quantity,
                            quantity: _quantity,
                            icon: widget.item.icon,
                            customizations: customString,
                          ),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${widget.item.name} added to cart!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: brandColor,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: spacingLg),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radiusFull),
                        ),
                      ),
                      child: Text(
                        'Add to Cart - ${formatPrice(_calculatedTotal)}',
                        style: const TextStyle(
                          fontSize: fontSubtitle,
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

  // --- Helper Widgets ---
  Widget _buildSectionHeader(String title, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: spacingXl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: fontSubtitle,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: spacingMd,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isRequired ? brandColor.withValues(alpha: 0.1) : surfaceLight,
              borderRadius: BorderRadius.circular(radiusFull),
            ),
            child: Text(
              isRequired ? 'Required' : 'Optional',
              style: TextStyle(
                fontSize: fontDetail,
                fontWeight: FontWeight.bold,
                color: isRequired ? brandColor : textSecondary,
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
        margin: const EdgeInsets.only(
          left: spacingXl,
          right: spacingXl,
          bottom: spacingSm,
        ),
        padding: const EdgeInsets.all(spacingMd),
        decoration: BoxDecoration(
          color: isSelected ? brandColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(radiusLg),
          border: Border.all(
            color: isSelected ? brandColor : borderLight,
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
                  color: isSelected ? brandColor : textHint,
                  size: 20,
                ),
                const SizedBox(width: spacingMd),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontBodyLarge,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              priceText,
              style: TextStyle(
                fontSize: fontBodyLarge,
                fontWeight: FontWeight.w600,
                color: isSelected ? brandColor : textSecondary,
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
        margin: const EdgeInsets.only(
          left: spacingXl,
          right: spacingXl,
          bottom: spacingSm,
        ),
        padding: const EdgeInsets.all(spacingMd),
        decoration: BoxDecoration(
          color: isSelected ? brandColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(radiusLg),
          border: Border.all(
            color: isSelected ? brandColor : borderLight,
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
                  color: isSelected ? brandColor : textHint,
                  size: 20,
                ),
                const SizedBox(width: spacingMd),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontBodyLarge,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              priceText,
              style: TextStyle(
                fontSize: fontBodyLarge,
                fontWeight: FontWeight.w600,
                color: isSelected ? brandColor : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
