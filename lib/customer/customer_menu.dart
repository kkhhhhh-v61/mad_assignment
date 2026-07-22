import 'package:flutter/material.dart';

import '../config.dart';
import '../data.dart';
import 'customer_header.dart';
import 'filter_overlay.dart';
import 'food_item_card.dart';

class CustomerMenu extends StatefulWidget {
  const CustomerMenu({super.key});

  @override
  State<CustomerMenu> createState() => _CustomerMenuState();
}

class _CustomerMenuState extends State<CustomerMenu> {
  String _selectedCategory = '';

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedCategory.isEmpty
        ? menuItems
        : menuItems.where((item) => item.category == _selectedCategory).toList();

    return Column(
      children: [
        CustomerHeader(
          showFilter: true,
          onFilterTap: () => showFilterOverlay(context),
        ),
        const SizedBox(height: spacingLg),
        // --- Category Chips ---
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: spacingXl),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.name == _selectedCategory;

              return Container(
                margin: const EdgeInsets.only(right: spacingMd),
                child: ChoiceChip(
                  label: Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  avatar: Icon(
                    category.icon,
                    size: 18,
                    color: isSelected ? Colors.white : brandColor,
                  ),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategory = category.name;
                      } else {
                        _selectedCategory = '';
                      }
                    });
                  },
                  selectedColor: brandColor,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusXl),
                    side: BorderSide(
                      color: isSelected ? brandColor : borderLight,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: spacingSm),
        // --- Menu Items ---
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: spacingXl,
              vertical: spacingSm,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              return FoodItemCard(item: filteredItems[index]);
            },
          ),
        ),
      ],
    );
  }
}
