import 'package:flutter/material.dart';

import '../global.dart';
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

  void _showFilterOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return const _FilterBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomerHeader(showFilter: true, onFilterTap: _showFilterOverlay),
        const SizedBox(height: 16.0),
        Builder(
          builder: (context) {
            final List<Map<String, dynamic>> categories = [];
            //TODO: Retrieve food categories dynamically from backend
            return CategoryChips(
              categories: categories,
              selectedCategory: _selectedCategory,
              onSelected: (val) {
                setState(() => _selectedCategory = val);
                widget.onCategoryChanged?.call(val);
              },
            );
          },
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: Builder(
                builder: (context) {
                  final List<Map<String, dynamic>> menuItems = [];
                  //TODO: Retrieve food items dynamically from backend based on category and filters

                  final displayedItems =
                      _selectedCategory.isEmpty || _selectedCategory == 'All'
                      ? menuItems
                      : menuItems
                            .where(
                              (item) => item['category'] == _selectedCategory,
                            )
                            .toList();

                  return FoodItems(foodItems: displayedItems);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet();

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String selectedSort = 'Popularity';
  final List<String> sortOptions = [
    'Alphabetically',
    'Popularity',
    'Highest Rating',
    'Price Low to High',
    'Price High to Low',
  ];

  late final TextEditingController minPriceController;
  late final TextEditingController maxPriceController;

  String selectedRating = 'Any';
  final List<String> ratingOptions = ['Any', '4.5+', '4.0+', '3.0+'];

  @override
  void initState() {
    super.initState();
    minPriceController = TextEditingController();
    maxPriceController = TextEditingController();
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.0),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 224, 224, 224),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedSort = 'Popularity';
                        minPriceController.clear();
                        maxPriceController.clear();
                        selectedRating = 'Any';
                      });
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: Color.fromARGB(255, 229, 57, 53),
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 245, 245, 245),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSort,
                    isExpanded: true,
                    items: sortOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedSort = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              const Text(
                'Price Range',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        hintText: 'Min',
                        filled: true,
                        fillColor: const Color.fromARGB(
                          255,
                          245,
                          245,
                          245,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '-',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        hintText: 'Max',
                        filled: true,
                        fillColor: const Color.fromARGB(
                          255,
                          245,
                          245,
                          245,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              const Text(
                'Rating',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                children: ratingOptions.map((String rating) {
                  final isSelected = selectedRating == rating;
                  return ChoiceChip(
                    label: Text(
                      rating,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color.fromARGB(221, 0, 0, 0),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() {
                          selectedRating = rating;
                        });
                      }
                    },
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
              const SizedBox(height: 32.0),

              SizedBox(
                width: double.infinity,
                height: 50.0,
                child: ElevatedButton(
                  onPressed: () {
                    //TODO: Fetch filtered and sorted menu items dynamically from backend
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedCategory;
  final ValueChanged<String>? onSelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const FallbackMessage(
        icon: Icons.category_outlined,
        title: 'No Categories',
        description: 'Categories are currently unavailable.',
      );
    }

    final List<Map<String, dynamic>> chipCategories = [
      {'name': 'All', 'icon': Icons.restaurant_menu},
      ...categories,
    ];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: chipCategories.length,
        itemBuilder: (context, index) {
          final category = chipCategories[index];
          final String name = category['name'] as String;
          final IconData icon = category['icon'] as IconData;
          final bool isSelected =
              selectedCategory == name ||
              (selectedCategory.isEmpty && name == 'All');

          return CategoryChip(
            name: name,
            icon: icon,
            isSelected: isSelected,
            onSelected: (bool selected) {
              if (onSelected != null) {
                if (selected) {
                  onSelected!(name == 'All' ? '' : name);
                } else if (name != 'All') {
                  onSelected!('');
                }
              }
            },
          );
        },
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;

  const CategoryChip({
    super.key,
    required this.name,
    required this.icon,
    required this.isSelected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12.0),
      child: ChoiceChip(
        label: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color.fromARGB(221, 0, 0, 0),
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
                : const Color.fromARGB(255, 224, 224, 224),
          ),
        ),
      ),
    );
  }
}

class FoodItems extends StatelessWidget {
  final List<Map<String, dynamic>> foodItems;

  const FoodItems({super.key, required this.foodItems});

  @override
  Widget build(BuildContext context) {
    if (foodItems.isEmpty) {
      return const FallbackMessage(
        icon: Icons.fastfood_outlined,
        title: 'No Items Found',
        description: 'There are no menu items to display right now.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: foodItems.length,
      itemBuilder: (context, index) {
        return FoodItemCard(item: foodItems[index]);
      },
    );
  }
}

class FoodItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const FoodItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
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
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 245, 245, 245),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                icon,
                color: const Color.fromARGB(255, 158, 158, 158),
                size: 40,
              ),
            ),
            const SizedBox(width: 16.0),
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
                      const Icon(
                        Icons.star,
                        color: Color.fromARGB(255, 255, 193, 7),
                        size: 16,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: Color.fromARGB(255, 117, 117, 117),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      const Icon(
                        Icons.access_time,
                        color: Color.fromARGB(255, 158, 158, 158),
                        size: 16,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        prepTime,
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: Color.fromARGB(255, 117, 117, 117),
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
}
