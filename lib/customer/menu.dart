import 'package:flutter/material.dart';

import '../global.dart';

// TODELETE
import '../data.dart';
import 'filter_overlay.dart';
import 'food_item_detail.dart';
import 'header.dart';

class CustomerMenu extends StatefulWidget {
  final String? initialCategory;
  final ValueChanged<String>? onCategoryChanged;

  const CustomerMenu({super.key, this.initialCategory, this.onCategoryChanged});

  @override
  State<CustomerMenu> createState() => _CustomerMenuState();
}

class _CustomerMenuState extends State<CustomerMenu> {
  // TODELETE
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? '';
  }

  @override
  void didUpdateWidget(CustomerMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory &&
        widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomerHeader(
          showFilter: true,
          onFilterTap: () => showFilterOverlay(context),
        ),
        const SizedBox(height: 16.0),
        // TODO: Replace with dynamic category filter chips fetched from database
        // TODELETE
        buildDummyCategories(
          isChoiceChip: true,
          selectedCategory: _selectedCategory,
          onSelected: (val) {
            setState(() => _selectedCategory = val);
            widget.onCategoryChanged?.call(val);
          },
        ),
        const SizedBox(height: 8.0),
        // TODO: Replace with dynamic menu items fetched from database
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              // TODELETE
              child: buildDummyMenuItems(),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== Category Chip UI ====================
Widget buildCategoryChip({
  required String name,
  required IconData icon,
  required bool isSelected,
  ValueChanged<bool>? onSelected,
}) {
  return Container(
    margin: const EdgeInsets.only(right: 12.0),
    child: ChoiceChip(
      label: Text(
        name,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xDD000000),
          fontWeight: FontWeight.w600,
        ),
      ),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected
            ? Colors.white
            : const Color.fromARGB(255, 255, 160, 122),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color.fromARGB(255, 255, 160, 122),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: isSelected
              ? const Color.fromARGB(255, 255, 160, 122)
              : const Color(0xFFE0E0E0),
        ),
      ),
    ),
  );
}

// ==================== Food Item Card UI ====================
Widget buildFoodItemCard(BuildContext context, Map<String, Object> item) {
  final String name = item['name'] as String;
  final String rating = item['rating'] as String;
  final double price = item['price'] as double;
  final String prepTime = item['prepTime'] as String;
  final IconData icon = item['icon'] as IconData;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FoodItemDetail(item: item)),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(20, 0, 0, 0),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // --- Item Icon ---
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              // TODO: replace with image
              icon,
              color: const Color(0xFF9E9E9E),
              size: 40,
            ),
          ),
          const SizedBox(width: 16.0),
          // --- Item Details ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                    const SizedBox(width: 4.0),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFF9E9E9E),
                      size: 16,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      prepTime,
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RM ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 160, 122),
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 30,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 255, 160, 122),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FoodItemDetail(item: item),
                            ),
                          );
                        },
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
  );
}
