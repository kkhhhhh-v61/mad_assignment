import 'package:flutter/material.dart';

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
        const SizedBox(height: 16.0),
        // --- Category Chips ---
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.name == _selectedCategory;

              return Container(
                margin: const EdgeInsets.only(right: 12.0),
                child: ChoiceChip(
                  label: Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xDD000000),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  avatar: Icon(
                    category.icon,
                    size: 18,
                    color: isSelected ? Colors.white : const Color.fromARGB(255, 255, 160, 122),
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
                  selectedColor: const Color.fromARGB(255, 255, 160, 122),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide(
                      color: isSelected ? const Color.fromARGB(255, 255, 160, 122) : const Color(0xFFE0E0E0),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8.0),
        // --- Menu Items ---
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
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
