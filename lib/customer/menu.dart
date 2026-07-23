import 'package:flutter/material.dart';

import 'food_item_detail.dart';
import 'header.dart';
import '../global.dart';

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
        String selectedSort = 'Popularity';
        final List<String> sortOptions = [
          'Alphabetically',
          'Popularity',
          'Highest Rating',
          'Price Low to High',
          'Price High to Low'
        ];
        
        TextEditingController minPriceController = TextEditingController();
        TextEditingController maxPriceController = TextEditingController();
        
        String selectedRating = 'Any';
        final List<String> ratingOptions = ['Any', '4.5+', '4.0+', '3.0+'];

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
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
                            color: const Color(0xFFE0E0E0),
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
                        color: Color(0xFFE53935),
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
                          color: const Color(0xFFF5F5F5),
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
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text('-', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: maxPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: 'RM ',
                                hintText: 'Max',
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                                color: isSelected ? Colors.white : const Color(0xDD000000),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                            selectedColor: const Color.fromARGB(255, 255, 160, 122),
                            backgroundColor: const Color(0xFFF5F5F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color.fromARGB(255, 255, 160, 122)
                                    : const Color(0xFFE0E0E0),
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
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 255, 160, 122),
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomerHeader(
          showFilter: true,
          onFilterTap: _showFilterOverlay,
        ),
        const SizedBox(height: 16.0),
        Builder(
          builder: (context) {
            List<Map<String, dynamic>> categories = [];
            // --- TOREMOVE ---
            categories = [
              {'name': 'Burgers', 'icon': Icons.lunch_dining},
              {'name': 'Pizza', 'icon': Icons.local_pizza},
              {'name': 'Noodles', 'icon': Icons.ramen_dining},
              {'name': 'Sides', 'icon': Icons.tapas},
              {'name': 'Desserts', 'icon': Icons.icecream},
              {'name': 'Beverages', 'icon': Icons.local_drink},
            ];
            // --- END TOREMOVE ---
            return buildCategoryChips(
              context,
              categories,
              _selectedCategory,
              (val) {
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
                  List<Map<String, dynamic>> menuItems = [];
                  // --- TOREMOVE ---
                  menuItems = [
                    {
                      'name': 'Classic Beef Burger',
                      'category': 'Burgers',
                      'rating': '4.8 (120+)',
                      'price': 16.90,
                      'prepTime': '15-20 min',
                      'icon': Icons.lunch_dining,
                      'isTrending': true,
                    },
                    {
                      'name': 'Crispy Chicken Burger',
                      'category': 'Burgers',
                      'rating': '4.7 (95+)',
                      'price': 14.90,
                      'prepTime': '12-18 min',
                      'icon': Icons.lunch_dining,
                      'isTrending': false,
                    },
                    {
                      'name': 'Pepperoni Feast Pizza',
                      'category': 'Pizza',
                      'rating': '4.9 (210+)',
                      'price': 28.90,
                      'prepTime': '20-25 min',
                      'icon': Icons.local_pizza,
                      'isTrending': true,
                    },
                    {
                      'name': 'Margherita Cheese Pizza',
                      'category': 'Pizza',
                      'rating': '4.6 (80+)',
                      'price': 24.90,
                      'prepTime': '18-22 min',
                      'icon': Icons.local_pizza,
                      'isTrending': false,
                    },
                    {
                      'name': 'Spicy Beef Ramen',
                      'category': 'Noodles',
                      'rating': '4.8 (150+)',
                      'price': 18.90,
                      'prepTime': '15-20 min',
                      'icon': Icons.ramen_dining,
                      'isTrending': true,
                    },
                    {
                      'name': 'Seafood Fried Noodles',
                      'category': 'Noodles',
                      'rating': '4.5 (60+)',
                      'price': 17.90,
                      'prepTime': '15-20 min',
                      'icon': Icons.ramen_dining,
                      'isTrending': false,
                    },
                    {
                      'name': 'Golden French Fries',
                      'category': 'Sides',
                      'rating': '4.7 (180+)',
                      'price': 8.90,
                      'prepTime': '8-12 min',
                      'icon': Icons.tapas,
                      'isTrending': false,
                    },
                    {
                      'name': 'Crispy Mozzarella Sticks',
                      'category': 'Sides',
                      'rating': '4.8 (110+)',
                      'price': 12.90,
                      'prepTime': '10-15 min',
                      'icon': Icons.tapas,
                      'isTrending': false,
                    },
                    {
                      'name': 'Belgian Chocolate Sundae',
                      'category': 'Desserts',
                      'rating': '4.9 (140+)',
                      'price': 10.90,
                      'prepTime': '5-8 min',
                      'icon': Icons.icecream,
                      'isTrending': true,
                    },
                    {
                      'name': 'Strawberry Cheesecake',
                      'category': 'Desserts',
                      'rating': '4.7 (75+)',
                      'price': 13.90,
                      'prepTime': '5-10 min',
                      'icon': Icons.icecream,
                      'isTrending': false,
                    },
                    {
                      'name': 'Iced Lemon Tea',
                      'category': 'Beverages',
                      'rating': '4.6 (130+)',
                      'price': 6.90,
                      'prepTime': '3-5 min',
                      'icon': Icons.local_drink,
                      'isTrending': false,
                    },
                    {
                      'name': 'Matcha Green Tea Latte',
                      'category': 'Beverages',
                      'rating': '4.8 (90+)',
                      'price': 11.90,
                      'prepTime': '5-8 min',
                      'icon': Icons.local_drink,
                      'isTrending': false,
                    },
                  ];
                  // --- END TOREMOVE ---
                  
                  final displayedItems = _selectedCategory.isEmpty || _selectedCategory == 'All'
                    ? menuItems
                    : menuItems.where((item) => item['category'] == _selectedCategory).toList();

                  return buildFoodItems(context, displayedItems);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget buildCategoryChips(
  BuildContext context,
  List<Map<String, dynamic>> categories,
  String selectedCategory,
  ValueChanged<String>? onSelected,
) {
  if (categories.isEmpty) {
    return buildFallbackMessage(
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

        return buildCategoryChip(
          name: name,
          icon: icon,
          isSelected: isSelected,
          onSelected: (bool selected) {
            if (onSelected != null) {
              if (selected) {
                onSelected(name == 'All' ? '' : name);
              } else if (name != 'All') {
                onSelected('');
              }
            }
          },
        );
      },
    ),
  );
}

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

Widget buildFoodItems(
  BuildContext context,
  List<Map<String, dynamic>> items,
) {
  if (items.isEmpty) {
    return buildFallbackMessage(
      icon: Icons.fastfood_outlined,
      title: 'No Items Found',
      description: 'There are no menu items to display right now.',
    );
  }

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    itemCount: items.length,
    itemBuilder: (context, index) {
      return buildFoodItemCard(context, items[index]);
    },
  );
}

Widget buildFoodItemCard(BuildContext context, Map<String, dynamic> item) {
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
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF9E9E9E),
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
