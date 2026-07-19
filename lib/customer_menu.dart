import 'package:flutter/material.dart';

import 'config.dart';
import 'customer_header.dart';

class CustomerMenu extends StatefulWidget {
  const CustomerMenu({super.key});

  @override
  State<CustomerMenu> createState() => _CustomerMenuState();
}

class _CustomerMenuState extends State<CustomerMenu> {
  String _selectedCategory = categories.first['name'] as String;

  @override
  Widget build(BuildContext context) {
    final filteredItems = menuItems.where((item) => item['category'] == _selectedCategory).toList();

    return Column(
      children: [
        const CustomerHeader(
          showFilter: true,
        ),
        const SizedBox(
          height: 15,
        ),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category['name'] == _selectedCategory;

              return Container(
                margin: const EdgeInsets.only(
                  right: 12.0,
                ),
                child: ChoiceChip(
                  label: Text(
                    category['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  avatar: Icon(
                    category['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : brandColor,
                  ),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedCategory = category['name'] as String;
                    });
                  },
                  selectedColor: brandColor,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? brandColor : Colors.grey[300]!,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return Container(
                margin: const EdgeInsets.only(
                  bottom: 15.0,
                ),
                padding: const EdgeInsets.all(10.0),
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
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon( // TODO: replace with image
                        item['icon'] as IconData,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber[400], size: 16),
                              const SizedBox(
                                width: 4,
                              ),
                              Text(
                                item['rating'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Icon(
                                Icons.access_time,
                                color: Colors.grey[400],
                                size: 16,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Text(
                                item['time'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['price'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: brandColor,
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: brandColor,
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
                                    // TODO
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
              );
            },
          ),
        ),
      ],
    );
  }
}