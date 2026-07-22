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
  final String prepTime;
  final IconData icon;
  final bool isTrending;

  const MenuItem({
    required this.name,
    required this.category,
    required this.rating,
    required this.price,
    required this.prepTime,
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

class NotificationItem {
  final String title;
  final String description;
  final String time;
  final String category;
  final IconData icon;
  bool isUnread;

  NotificationItem({
    required this.title,
    required this.description,
    required this.time,
    required this.category,
    required this.icon,
    this.isUnread = false,
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
    prepTime: '15-20 min',
    icon: Icons.lunch_dining,
    isTrending: true,
  ),
  MenuItem(
    name: 'Beef Pepperoni Pizza',
    category: 'Mains',
    rating: '4.5',
    price: 22.50,
    prepTime: '25-30 min',
    icon: Icons.local_pizza,
    isTrending: true,
  ),
  MenuItem(
    name: 'Grilled Salmon Set',
    category: 'Mains',
    rating: '4.7',
    price: 28.00,
    prepTime: '20-25 min',
    icon: Icons.set_meal,
  ),
  MenuItem(
    name: 'Cheesy Fries',
    category: 'Sides',
    rating: '4.6',
    price: 8.50,
    prepTime: '10-15 min',
    icon: Icons.fastfood,
  ),
  MenuItem(
    name: 'Garlic Bread',
    category: 'Sides',
    rating: '4.3',
    price: 6.00,
    prepTime: '5-10 min',
    icon: Icons.bakery_dining,
  ),
  MenuItem(
    name: 'Iced Caramel Macchiato',
    category: 'Drinks',
    rating: '4.9',
    price: 12.00,
    prepTime: '5-10 min',
    icon: Icons.local_cafe,
    isTrending: true,
  ),
  MenuItem(
    name: 'Mango Smoothie',
    category: 'Drinks',
    rating: '4.7',
    price: 10.50,
    prepTime: '5-10 min',
    icon: Icons.local_drink,
  ),
  MenuItem(
    name: 'Chocolate Lava Cake',
    category: 'Desserts',
    rating: '4.9',
    price: 14.00,
    prepTime: '10-15 min',
    icon: Icons.cake,
  ),
  MenuItem(
    name: 'Vanilla Ice Cream',
    category: 'Desserts',
    rating: '4.5',
    price: 5.50,
    prepTime: '5 min',
    icon: Icons.icecream,
  ),
  MenuItem(
    name: 'Avocado Salad',
    category: 'Healthy',
    rating: '4.8',
    price: 16.00,
    prepTime: '10-15 min',
    icon: Icons.eco,
  ),
  MenuItem(
    name: 'Quinoa Bowl',
    category: 'Healthy',
    rating: '4.6',
    price: 18.50,
    prepTime: '15-20 min',
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

List<NotificationItem> notificationItems = [
  NotificationItem(
    title: 'Order #ORD-1001 is on the way!',
    description:
        'Your delivery driver is heading to your location. Estimated arrival in 12 mins.',
    time: '2 mins ago',
    category: 'Orders',
    icon: Icons.delivery_dining,
    isUnread: true,
  ),
  NotificationItem(
    title: '30% OFF Your Next Meal!',
    description:
        'Use code DISH30 at checkout to save up to RM 15 on selected restaurants today.',
    time: '1 hour ago',
    category: 'Promos',
    icon: Icons.local_offer,
    isUnread: true,
  ),
  NotificationItem(
    title: 'Payment Method Verified',
    description:
        'Your credit card ending in 1234 has been successfully added to your account.',
    time: '3 hours ago',
    category: 'System',
    icon: Icons.credit_card,
    isUnread: false,
  ),
  NotificationItem(
    title: 'Order #ORD-0998 Delivered',
    description:
        'Enjoy your Beef Pepperoni Pizza! Let us know how it was by rating your meal.',
    time: 'Yesterday, 07:45 PM',
    category: 'Orders',
    icon: Icons.check_circle_outline,
    isUnread: false,
  ),
  NotificationItem(
    title: 'Account Security Update',
    description:
        'Your account password was successfully updated from a new device.',
    time: '5 days ago',
    category: 'System',
    icon: Icons.security,
    isUnread: false,
  ),
];
