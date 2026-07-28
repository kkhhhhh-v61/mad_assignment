import 'package:flutter/material.dart';
import 'header.dart';
import 'food_creation.dart';
import 'food_edit.dart';

class AdminFoodManagement extends StatefulWidget {
  const AdminFoodManagement({super.key});

  @override
  State<AdminFoodManagement> createState() => _AdminFoodManagementState();
}

class _AdminFoodManagementState extends State<AdminFoodManagement> {
  //TODO: Retrieve actual food items from backend
  final List<Map<String, dynamic>> _foodItems = [
    {
      'id': '1',
      'name': 'Classic Beef Burger',
      'price': 15.90,
      'icon': Icons.lunch_dining,
      'rating': '4.8',
      'prepTime': '15-20 min',
    },
    {
      'id': '2',
      'name': 'Pepperoni Feast Pizza',
      'price': 28.90,
      'icon': Icons.local_pizza,
      'rating': '4.5',
      'prepTime': '20-25 min',
    },
    {
      'id': '3',
      'name': 'Spicy Chicken Wings',
      'price': 18.50,
      'icon': Icons.fastfood,
      'rating': '4.7',
      'prepTime': '10-15 min',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 255, 160, 122),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminFoodCreation(),
            ),
          );
        },
      ),
      body: Column(
        children: [
          AdminHeader(
            pageTitle: 'Food Management',
            showSearch: true,
            showFilter: true,
            onFilterTap: _showFilterOverlay,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20.0),
                  _buildFoodList(context, _foodItems),
                  const SizedBox(height: 80.0), // Padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(BuildContext context, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No Food Items',
          style: TextStyle(
            color: Color.fromARGB(255, 117, 117, 117),
            fontSize: 16.0,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildFoodItemCard(context, items[index]);
      },
    );
  }

  Widget _buildFoodItemCard(BuildContext context, Map<String, dynamic> item) {
    final String name = item['name'] as String;
    final String rating = item['rating'] as String;
    final double price = item['price'] as double;
    final String prepTime = item['prepTime'] as String;
    final IconData icon = item['icon'] as IconData;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminFoodEdit(item: item),
          ),
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
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 160, 122),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              height: 30,
              width: 30,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 245, 245, 245),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Color.fromARGB(255, 158, 158, 158),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        String selectedSort = 'Newest Added';
        final List<String> sortOptions = [
          'Newest Added',
          'Alphabetically',
          'Price Low to High',
          'Price High to Low',
          'Most Sold',
        ];

        String selectedCategory = 'All';
        final List<String> categoryOptions = [
          'All',
          'Burgers',
          'Drinks',
          'Sides',
          'Desserts',
          'Specials'
        ];

        String selectedStatus = 'All';
        final List<String> statusOptions = [
          'All',
          'Active',
          'Inactive',
          'Out of Stock',
        ];

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
                                selectedSort = 'Newest Added';
                                selectedCategory = 'All';
                                selectedStatus = 'All';
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
                        'Category',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: categoryOptions.map((String category) {
                          final isSelected = selectedCategory == category;
                          return ChoiceChip(
                            label: Text(
                              category,
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
                            selectedColor: const Color.fromARGB(255, 255, 160, 122),
                            backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                            onSelected: (bool selected) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24.0),

                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: statusOptions.map((String status) {
                          final isSelected = selectedStatus == status;
                          return ChoiceChip(
                            label: Text(
                              status,
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
                            selectedColor: const Color.fromARGB(255, 255, 160, 122),
                            backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                            onSelected: (bool selected) {
                              setState(() {
                                selectedStatus = status;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32.0),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            //TODO: Apply filters to list
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
}
