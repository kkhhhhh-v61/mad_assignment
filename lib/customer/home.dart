import 'package:flutter/material.dart';

import '../global.dart';
import 'header.dart';
import 'menu.dart';

class CustomerHome extends StatelessWidget {
  final ValueChanged<String>? onCategorySelected;

  const CustomerHome({super.key, this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CustomerHeader(showBrandTitle: true),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),
                SizedBox(
                  height: 200,
                  //TODO: Retrieve banner images dynamically from backend
                  child: PageView.builder(
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20.0),
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/images/banner_1.webp'),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(25, 0, 0, 0),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Quick Categories',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Builder(
                  builder: (context) {
                    final List<Map<String, Object>> categories = [];
                    //TODO: Retrieve food categories dynamically from backend
                    return CategoryItems(
                      categories: categories,
                      onSelected: onCategorySelected,
                    );
                  },
                ),
                const SizedBox(height: 16.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Most Popular',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(
                            255,
                            255,
                            160,
                            122,
                          ),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                Builder(
                  builder: (context) {
                    final List<Map<String, dynamic>> popularItems = [];
                    //TODO: Retrieve popular food items dynamically from backend
                    return FoodItems(foodItems: popularItems);
                  },
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CategoryItems extends StatelessWidget {
  final List<Map<String, Object>> categories;
  final ValueChanged<String>? onSelected;

  const CategoryItems({
    super.key,
    required this.categories,
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

    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 4.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final String name = category['name'] as String;
          return CategoryItem(
            icon: category['icon'] as IconData,
            name: name,
            onTap: () {
              if (onSelected != null) {
                onSelected!(name);
              }
            },
          );
        },
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final VoidCallback? onTap;

  const CategoryItem({
    super.key,
    required this.icon,
    required this.name,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(right: 20.0),
        child: Column(
          children: [
            Container(
              height: 65,
              width: 65,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(20, 0, 0, 0),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Color.fromARGB(255, 255, 160, 122),
                size: 28,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(221, 0, 0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
