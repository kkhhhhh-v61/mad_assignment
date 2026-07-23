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
        const CustomerHeader(),
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
                    List<Map<String, Object>> categories = [];
                    //TODO: Retrieve food categories dynamically from backend
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
                    return buildCategoryItems(
                      context,
                      categories,
                      onCategorySelected,
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
                    List<Map<String, dynamic>> popularItems = [];
                    //TODO: Retrieve popular food items dynamically from backend
                    // --- TOREMOVE ---
                    popularItems = [
                      {
                        'name': 'Classic Beef Burger',
                        'category': 'Burgers',
                        'rating': '4.8 (120+)',
                        'price': 16.90,
                        'prepTime': '15-20 min',
                        'icon': Icons.lunch_dining,
                      },
                      {
                        'name': 'Pepperoni Feast Pizza',
                        'category': 'Pizza',
                        'rating': '4.9 (210+)',
                        'price': 28.90,
                        'prepTime': '20-25 min',
                        'icon': Icons.local_pizza,
                      },
                      {
                        'name': 'Spicy Beef Ramen',
                        'category': 'Noodles',
                        'rating': '4.8 (150+)',
                        'price': 18.90,
                        'prepTime': '15-20 min',
                        'icon': Icons.ramen_dining,
                      },
                    ];
                    // --- END TOREMOVE ---
                    return buildFoodItems(context, popularItems);
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

Widget buildCategoryItems(
  BuildContext context,
  List<Map<String, Object>> categories,
  ValueChanged<String>? onSelected,
) {
  if (categories.isEmpty) {
    return buildFallbackMessage(
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
        return buildCategoryItem(
          icon: category['icon'] as IconData,
          name: name,
          onTap: () {
            if (onSelected != null) {
              onSelected(name);
            }
          },
        );
      },
    ),
  );
}

Widget buildCategoryItem({
  required IconData icon,
  required String name,
  VoidCallback? onTap,
}) {
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
