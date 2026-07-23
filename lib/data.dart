import 'package:flutter/material.dart';

import 'customer/home.dart';
import 'customer/menu.dart';
import 'customer/orders.dart';

// ==================== Dummy Categories Function ====================
Widget buildDummyCategories({
  bool isChoiceChip = false,
  String selectedCategory = '',
  ValueChanged<String>? onSelected,
}) {
  const List<Map<String, Object>> categories = [
    {'name': 'Burgers', 'icon': Icons.lunch_dining},
    {'name': 'Pizza', 'icon': Icons.local_pizza},
    {'name': 'Noodles', 'icon': Icons.ramen_dining},
    {'name': 'Sides', 'icon': Icons.tapas},
    {'name': 'Desserts', 'icon': Icons.icecream},
    {'name': 'Beverages', 'icon': Icons.local_drink},
  ];

  if (isChoiceChip) {
    final List<Map<String, Object>> chipCategories = [
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

// ==================== Dummy Menu Items Function ====================
Widget buildDummyMenuItems({bool onlyTrending = false}) {
  const List<Map<String, Object>> menuItems = [
    // Burgers (2 items)
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
    // Pizza (2 items)
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
    // Noodles (2 items)
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
    // Sides (2 items)
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
    // Desserts (2 items)
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
    // Beverages (2 items)
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

  final List<Map<String, Object>> displayedItems = onlyTrending
      ? menuItems.where((item) => (item['isTrending'] as bool)).toList()
      : menuItems;

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    itemCount: displayedItems.length,
    itemBuilder: (context, index) {
      return buildFoodItemCard(context, displayedItems[index]);
    },
  );
}

// ==================== Dummy Orders Function ====================
Widget buildDummyOrders(String selectedStatus) {
  const List<Map<String, Object>> dummyOrders = [
    {
      'orderId': '#ORD-8492',
      'date': 'Today, 12:45 PM',
      'status': 'Preparing',
      'items': [
        {'name': 'Classic Beef Burger', 'quantity': 2, 'price': 16.90},
        {'name': 'Golden French Fries', 'quantity': 1, 'price': 5.80},
        {'name': 'Iced Lemon Tea', 'quantity': 2, 'price': 5.00},
      ],
      'subtotal': 49.60,
      'deliveryFee': 5.00,
      'discount': 0.00,
      'totalPrice': 'RM 54.60',
      'info': 'Estimated Delivery: 15-20 mins',
      'icon': Icons.lunch_dining,
    },
    {
      'orderId': '#ORD-8488',
      'date': 'Today, 12:15 PM',
      'status': 'Delivering',
      'items': [
        {'name': 'Classic Beef Burger', 'quantity': 2, 'price': 16.90},
        {'name': 'Iced Lemon Tea', 'quantity': 1, 'price': 5.00},
      ],
      'subtotal': 38.80,
      'deliveryFee': 3.00,
      'discount': 5.00,
      'totalPrice': 'RM 36.80',
      'info': 'Estimated Arrival: 5 mins',
      'icon': Icons.lunch_dining,
    },
    {
      'orderId': '#ORD-8485',
      'date': 'Today, 11:30 AM',
      'status': 'Preparing',
      'items': [
        {'name': 'Pepperoni Feast Pizza', 'quantity': 1, 'price': 28.90},
        {'name': 'Crispy Mozzarella Sticks', 'quantity': 1, 'price': 12.90},
      ],
      'subtotal': 41.80,
      'deliveryFee': 4.00,
      'discount': 0.00,
      'totalPrice': 'RM 45.80',
      'info': 'Estimated Delivery: 25-30 mins',
      'icon': Icons.local_pizza,
    },
    {
      'orderId': '#ORD-8470',
      'date': 'Yesterday, 7:15 PM',
      'status': 'Completed',
      'items': [
        {'name': 'Spicy Beef Ramen', 'quantity': 1, 'price': 22.90},
        {'name': 'Belgian Chocolate Sundae', 'quantity': 1, 'price': 6.90},
      ],
      'subtotal': 29.80,
      'deliveryFee': 4.00,
      'discount': 2.00,
      'totalPrice': 'RM 31.80',
      'info': 'Delivered in 18 mins',
      'icon': Icons.ramen_dining,
    },
    {
      'orderId': '#ORD-8462',
      'date': 'Yesterday, 1:30 PM',
      'status': 'Cancelled',
      'items': [
        {'name': 'Pepperoni Feast Pizza', 'quantity': 1, 'price': 28.90},
      ],
      'subtotal': 28.90,
      'deliveryFee': 4.00,
      'discount': 0.00,
      'totalPrice': 'RM 32.90',
      'info': 'Cancelled by restaurant',
      'icon': Icons.local_pizza,
    },
  ];

  final filteredOrders = dummyOrders
      .where((order) => order['status'] == selectedStatus)
      .toList();

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
    itemCount: filteredOrders.length,
    itemBuilder: (context, index) {
      return buildOrderCard(context, filteredOrders[index]);
    },
  );
}
