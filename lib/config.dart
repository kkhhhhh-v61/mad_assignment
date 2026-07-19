import 'package:flutter/material.dart';

// Global Configs
final appLogo = 'assets/images/logo.webp';
final brandColor = Color.fromARGB(255, 255, 160, 122);

// TODO: replace with dynamic data from DB
final List<Map<String, dynamic>> categories = const [
  {'name': 'Mains', 'icon': Icons.lunch_dining},
  {'name': 'Sides', 'icon': Icons.tapas},
  {'name': 'Drinks', 'icon': Icons.local_cafe},
  {'name': 'Desserts', 'icon': Icons.icecream},
  {'name': 'Healthy', 'icon': Icons.eco},
];

// TODO: replace with dynamic data from DB
final List<Map<String, dynamic>> trendingItems = const [
  {
    'name': 'Spicy Chicken Burger',
    'rating': '4.8',
    'price': 'RM 15.90',
    'time': '15-20 min',
    'icon': Icons.lunch_dining,
  },
  {
    'name': 'Beef Pepperoni Pizza',
    'rating': '4.5',
    'price': 'RM 22.50',
    'time': '25-30 min',
    'icon': Icons.local_pizza,
  },
  {
    'name': 'Iced Caramel Macchiato',
    'rating': '4.9',
    'price': 'RM 12.00',
    'time': '5-10 min',
    'icon': Icons.local_cafe,
  },
];

final List<Map<String, dynamic>> menuItems = const [
  // Mains
  {'name': 'Spicy Chicken Burger', 'category': 'Mains', 'rating': '4.8', 'price': 'RM 15.90', 'time': '15-20 min', 'icon': Icons.lunch_dining},
  {'name': 'Beef Pepperoni Pizza', 'category': 'Mains', 'rating': '4.5', 'price': 'RM 22.50', 'time': '25-30 min', 'icon': Icons.local_pizza},
  {'name': 'Grilled Salmon Set', 'category': 'Mains', 'rating': '4.7', 'price': 'RM 28.00', 'time': '20-25 min', 'icon': Icons.set_meal},

  // Sides
  {'name': 'Cheesy Fries', 'category': 'Sides', 'rating': '4.6', 'price': 'RM 8.50', 'time': '10-15 min', 'icon': Icons.fastfood},
  {'name': 'Garlic Bread', 'category': 'Sides', 'rating': '4.3', 'price': 'RM 6.00', 'time': '5-10 min', 'icon': Icons.bakery_dining},

  // Drinks
  {'name': 'Iced Caramel Macchiato', 'category': 'Drinks', 'rating': '4.9', 'price': 'RM 12.00', 'time': '5-10 min', 'icon': Icons.local_cafe},
  {'name': 'Mango Smoothie', 'category': 'Drinks', 'rating': '4.7', 'price': 'RM 10.50', 'time': '5-10 min', 'icon': Icons.local_drink},

  // Desserts
  {'name': 'Chocolate Lava Cake', 'category': 'Desserts', 'rating': '4.9', 'price': 'RM 14.00', 'time': '10-15 min', 'icon': Icons.cake},
  {'name': 'Vanilla Ice Cream', 'category': 'Desserts', 'rating': '4.5', 'price': 'RM 5.50', 'time': '5 min', 'icon': Icons.icecream},

  // Healthy
  {'name': 'Avocado Salad', 'category': 'Healthy', 'rating': '4.8', 'price': 'RM 16.00', 'time': '10-15 min', 'icon': Icons.eco},
  {'name': 'Quinoa Bowl', 'category': 'Healthy', 'rating': '4.6', 'price': 'RM 18.50', 'time': '15-20 min', 'icon': Icons.rice_bowl},
];