import 'package:flutter/material.dart';

// ==================== Model Classes ====================

class Category {
  final String name;
  final IconData icon;

  const Category({required this.name, required this.icon});
}

class MenuItem {
  final String name;
  final String category;
  final String rating;
  final double price;
  final String time;
  final IconData icon;
  final bool isTrending;

  const MenuItem({
    required this.name,
    required this.category,
    required this.rating,
    required this.price,
    required this.time,
    required this.icon,
    this.isTrending = false,
  });
}

class CartItem {
  final String name;
  final double price;
  int quantity;
  final IconData icon;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.icon,
  });
}

class OrderItem {
  final String orderId;
  final String status;
  final String date;
  final String items;
  final double total;
  final String restaurant;
  final IconData icon;

  const OrderItem({
    required this.orderId,
    required this.status,
    required this.date,
    required this.items,
    required this.total,
    required this.restaurant,
    required this.icon,
  });
}

// ==================== Dummy Data ====================
// TODO: replace all dummy data with dynamic data from DB

const List<Category> categories = [
  Category(name: 'Mains', icon: Icons.lunch_dining),
  Category(name: 'Sides', icon: Icons.tapas),
  Category(name: 'Drinks', icon: Icons.local_cafe),
  Category(name: 'Desserts', icon: Icons.icecream),
  Category(name: 'Healthy', icon: Icons.eco),
];

const List<MenuItem> menuItems = [
  MenuItem(
    name: 'Spicy Chicken Burger',
    category: 'Mains',
    rating: '4.8',
    price: 15.90,
    time: '15-20 min',
    icon: Icons.lunch_dining,
    isTrending: true,
  ),
  MenuItem(
    name: 'Beef Pepperoni Pizza',
    category: 'Mains',
    rating: '4.5',
    price: 22.50,
    time: '25-30 min',
    icon: Icons.local_pizza,
    isTrending: true,
  ),
  MenuItem(
    name: 'Grilled Salmon Set',
    category: 'Mains',
    rating: '4.7',
    price: 28.00,
    time: '20-25 min',
    icon: Icons.set_meal,
  ),
  MenuItem(
    name: 'Cheesy Fries',
    category: 'Sides',
    rating: '4.6',
    price: 8.50,
    time: '10-15 min',
    icon: Icons.fastfood,
  ),
  MenuItem(
    name: 'Garlic Bread',
    category: 'Sides',
    rating: '4.3',
    price: 6.00,
    time: '5-10 min',
    icon: Icons.bakery_dining,
  ),
  MenuItem(
    name: 'Iced Caramel Macchiato',
    category: 'Drinks',
    rating: '4.9',
    price: 12.00,
    time: '5-10 min',
    icon: Icons.local_cafe,
    isTrending: true,
  ),
  MenuItem(
    name: 'Mango Smoothie',
    category: 'Drinks',
    rating: '4.7',
    price: 10.50,
    time: '5-10 min',
    icon: Icons.local_drink,
  ),
  MenuItem(
    name: 'Chocolate Lava Cake',
    category: 'Desserts',
    rating: '4.9',
    price: 14.00,
    time: '10-15 min',
    icon: Icons.cake,
  ),
  MenuItem(
    name: 'Vanilla Ice Cream',
    category: 'Desserts',
    rating: '4.5',
    price: 5.50,
    time: '5 min',
    icon: Icons.icecream,
  ),
  MenuItem(
    name: 'Avocado Salad',
    category: 'Healthy',
    rating: '4.8',
    price: 16.00,
    time: '10-15 min',
    icon: Icons.eco,
  ),
  MenuItem(
    name: 'Quinoa Bowl',
    category: 'Healthy',
    rating: '4.6',
    price: 18.50,
    time: '15-20 min',
    icon: Icons.rice_bowl,
  ),
];

final List<MenuItem> trendingItems = menuItems
    .where((item) => item.isTrending)
    .toList();

const List<String> orderStatuses = ['Active', 'Completed', 'Cancelled'];

const List<OrderItem> orderItems = [
  OrderItem(
    orderId: '#ORD-1001',
    status: 'Active',
    date: '19 Jul 2026, 12:30 PM',
    items: '2x Spicy Chicken Burger, 1x Iced Caramel Macchiato',
    total: 43.80,
    restaurant: 'Burger Joint',
    icon: Icons.lunch_dining,
  ),
  OrderItem(
    orderId: '#ORD-0998',
    status: 'Completed',
    date: '18 Jul 2026, 07:15 PM',
    items: '1x Beef Pepperoni Pizza, 2x Garlic Bread',
    total: 34.50,
    restaurant: 'Pizza Palace',
    icon: Icons.local_pizza,
  ),
  OrderItem(
    orderId: '#ORD-0985',
    status: 'Completed',
    date: '15 Jul 2026, 01:00 PM',
    items: '1x Grilled Salmon Set',
    total: 28.00,
    restaurant: 'Healthy Bites',
    icon: Icons.set_meal,
  ),
  OrderItem(
    orderId: '#ORD-0970',
    status: 'Cancelled',
    date: '10 Jul 2026, 08:45 PM',
    items: '1x Chocolate Lava Cake, 1x Vanilla Ice Cream',
    total: 19.50,
    restaurant: 'Sweet Treats',
    icon: Icons.cake,
  ),
];

List<CartItem> cartItems = [
  CartItem(
    name: 'Spicy Chicken Burger',
    price: 15.90,
    quantity: 2,
    icon: Icons.lunch_dining,
  ),
  CartItem(
    name: 'Iced Caramel Macchiato',
    price: 12.00,
    quantity: 1,
    icon: Icons.local_cafe,
  ),
];

const double deliveryFee = 5.00;
const double activeDiscount = 3.00;
