import 'package:flutter/material.dart';

import 'customer/home.dart';
import 'customer/menu.dart';
import 'customer/orders.dart';
import 'customer/notifications.dart';
import 'customer/cart.dart';
import 'customer/checkout.dart';

// TODELETE
// TODO: Fetch categories from backend API and map them to UI
Widget buildDummyCategories(
  BuildContext context, {
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
    return buildCategoryChipsLayoutUI(
      context,
      categories,
      selectedCategory,
      onSelected,
    );
  } else {
    return buildCategoryItemsLayoutUI(context, categories, onSelected);
  }
}

// TODELETE
// TODO: Fetch menu items from backend API and map them to UI
Widget buildDummyMenuItems(BuildContext context, {bool onlyTrending = false}) {
  const List<Map<String, Object>> menuItems = [
    // --- Burgers (2 items) ---
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
    // --- Pizza (2 items) ---
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
    // --- Noodles (2 items) ---
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
    // --- Sides (2 items) ---
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
    // --- Desserts (2 items) ---
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
    // --- Beverages (2 items) ---
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

  final List<Map<String, dynamic>> displayedItems = onlyTrending
      ? menuItems.where((item) => (item['isTrending'] as bool)).toList()
      : menuItems;

  return buildFoodItemsLayoutUI(context, displayedItems);
}

// TODELETE
// TODO: Fetch customer orders from backend API and map them to UI
Widget buildDummyOrders(BuildContext context, String selectedStatus) {
  const List<Map<String, dynamic>> dummyOrders = [
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

  return buildOrdersListLayoutUI(context, filteredOrders, selectedStatus);
}

// TODELETE
// TODO: Fetch initial dummy notifications to populate state from backend API
List<Map<String, dynamic>> getInitialDummyNotifications() {
  return [
    {
      'id': '1',
      'type': 'Orders',
      'title': 'Order Arriving Soon!',
      'description':
          'Your order #ORD-8488 is on the way and will arrive in 5 minutes.',
      'time': '5 mins ago',
      'isRead': false,
    },
    {
      'id': '2',
      'type': 'Promos',
      'title': '50% Off Your Next Meal 🍔',
      'description':
          'Use code HALFPRICE to get 50% off your next order. Valid until tomorrow!',
      'time': '2 hours ago',
      'isRead': false,
    },
    {
      'id': '3',
      'type': 'Orders',
      'title': 'Order Completed',
      'description':
          'Your order #ORD-8470 has been delivered. Enjoy your meal!',
      'time': '5 hours ago',
      'isRead': false,
    },
    {
      'id': '4',
      'type': 'System',
      'title': 'System Maintenance',
      'description':
          'The app will be down for scheduled maintenance from 2:00 AM to 4:00 AM tonight.',
      'time': '1 day ago',
      'isRead': true,
    },
    {
      'id': '5',
      'type': 'Orders',
      'title': 'Order Cancelled',
      'description':
          'Your order #ORD-8462 has been cancelled by the restaurant.',
      'time': '1 day ago',
      'isRead': true,
    },
    {
      'id': '6',
      'type': 'Promos',
      'title': 'Free Delivery Weekend! 🚚',
      'description':
          'Enjoy free delivery all weekend long on all orders over RM 30.',
      'time': '2 days ago',
      'isRead': true,
    },
  ];
}

// TODELETE
// TODO: Fetch notifications from backend API and map them to UI
Widget buildDummyNotifications(
  BuildContext context,
  List<Map<String, dynamic>> notifications,
  String selectedCategory,
  VoidCallback onUpdate,
) {
  final filteredNotifications = selectedCategory == 'All'
      ? notifications
      : notifications.where((n) => n['type'] == selectedCategory).toList();

  return buildNotificationsListLayoutUI(
    context,
    filteredNotifications,
    onUpdate,
  );
}

List<CartItem> dummyCartItems = [
  CartItem(
    name: 'Classic Beef Burger',
    price: 16.90,
    quantity: 2,
    icon: Icons.lunch_dining,
    customizations: [
      CartItemCustomization(name: 'No onions', price: 0.0),
      CartItemCustomization(name: 'Extra sauce', price: 2.0),
    ],
  ),
  CartItem(
    name: 'Iced Lemon Tea',
    price: 5.00,
    quantity: 1,
    icon: Icons.local_drink,
  ),
];

// TODELETE
// TODO: Fetch user cart items dynamically from database
Widget buildDummyCartView({
  required BuildContext context,
  required VoidCallback onStateChanged,
}) {
  return buildCartLayoutUI(
    context: context,
    cartItems: dummyCartItems,
    onQuantityChanged: (index, newQuantity) {
      dummyCartItems[index].quantity = newQuantity;
      onStateChanged();
    },
    onItemRemoved: (index) {
      dummyCartItems.removeAt(index);
      onStateChanged();
    },
  );
}

// ==================== Dummy Checkout Data ====================

String dummySelectedAddress = 'Home - 123 Street Name, City';
String dummySelectedPaymentMethod = 'Credit Card';
List<String> dummyPaymentMethods = [
  'Credit Card',
  'Cash on Delivery',
  'E-Wallet',
  'Online Banking'
];
Map<String, dynamic>? dummyAppliedVoucher;
double dummyDeliveryFee = 5.00;

List<Map<String, dynamic>> dummyVouchers = [
  {
    'id': 'v1',
    'title': 'Free Delivery',
    'expiryDate': 'Valid until 31 Dec 2026',
    'type': 'free_delivery',
    'minSpend': 30.0,
  },
  {
    'id': 'v2',
    'title': '10% Off',
    'expiryDate': 'Valid until 15 Aug 2026',
    'type': 'percentage',
    'discountValue': 10.0,
    'minSpend': 50.0,
  },
];

// TODELETE
// TODO: Fetch user order details dynamically from database
Widget buildDummyCheckoutView({
  required BuildContext context,
  required VoidCallback onStateChanged,
}) {
  return buildCheckoutLayoutUI(
    context: context,
    cartItems: dummyCartItems,
    selectedAddress: dummySelectedAddress,
    selectedPaymentMethod: dummySelectedPaymentMethod,
    availablePaymentMethods: dummyPaymentMethods,
    onPaymentMethodChanged: (method) {
      dummySelectedPaymentMethod = method;
      onStateChanged();
    },
    appliedVoucher: dummyAppliedVoucher,
    deliveryFee: dummyDeliveryFee,
    availableVouchers: dummyVouchers,
    onVoucherApplied: (voucher) {
      dummyAppliedVoucher = voucher;
      onStateChanged();
    },
  );
}
