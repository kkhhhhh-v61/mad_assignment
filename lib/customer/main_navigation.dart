import 'package:flutter/material.dart';

// Import shared components
import '../shared/account.dart';
import '../shared/profile.dart';

// Import customer pages
import 'auth.dart';
import 'header.dart';
import 'home.dart';
import 'menu.dart';
import 'orders.dart';

class CustomerMainNavigation extends StatefulWidget {
  const CustomerMainNavigation({super.key});

  @override
  State<CustomerMainNavigation> createState() => _CustomerMainNavigationState();
}

class _CustomerMainNavigationState extends State<CustomerMainNavigation> {
  int _currentIndex = 0;
  bool _isLoggedIn = false;
  String _selectedMenuCategory = '';

  List<Widget> get _screens => [
    CustomerHome(
      onCategorySelected: (categoryName) {
        setState(() {
          _selectedMenuCategory = categoryName;
          _currentIndex = 1;
        });
      },
    ),
    CustomerMenu(
      initialCategory: _selectedMenuCategory,
      onCategoryChanged: (categoryName) {
        _selectedMenuCategory = categoryName;
      },
    ),
    const CustomerOrders(),
    _isLoggedIn
        ? _buildAccountScreen() // Build the account screen
        : CustomerAuth(onAuthSuccess: () => setState(() => _isLoggedIn = true)),
  ];

  // Build the customer account screen with custom options
  Widget _buildAccountScreen() {
    return SharedAccountScreen(
      header: const CustomerHeader(
        showTitle: true,
        pageTitle: 'My Account',
        showSearch: false,
      ),
      name: 'Kai Hao',
      subtitle: '+60 16-356 1651',
      email: 'kaihao0303@gmail.com',
      profileIcon: Icons.person,
      onEditPressed: () {
        // Navigate to the shared profile screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SharedProfileScreen(
              title: 'Edit Profile',
              initialName: 'Kai Hao',
              initialEmail: 'kaihao0303@gmail.com',
              initialPhone: '+60 16-356 1651',
              onSave: (name, email, phone) {
                // TODO: Update user profile via backend API
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Profile updated successfully!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Color.fromARGB(255, 255, 160, 122),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
      onLogout: () {
        // Handle logout and show snackbar notification
        setState(() => _isLoggedIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Logged out successfully',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color.fromARGB(255, 239, 83, 80),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      },
      accountOptions: [
        SharedOptionTile(icon: Icons.location_on_outlined, title: 'Saved Addresses', onTap: () {}),
        const Divider(height: 1, indent: 60, endIndent: 20.0),
        SharedOptionTile(icon: Icons.credit_card_outlined, title: 'Payment Methods', onTap: () {}),
        const Divider(height: 1, indent: 60, endIndent: 20.0),
        SharedOptionTile(icon: Icons.local_offer_outlined, title: 'Vouchers & Offers', onTap: () {}),
        const Divider(height: 1, indent: 60, endIndent: 20.0),
        SharedOptionTile(icon: Icons.help_outline, title: 'Help Center', onTap: () {}),
        const Divider(height: 1, indent: 60, endIndent: 20.0),
        SharedOptionTile(icon: Icons.settings_outlined, title: 'Settings', onTap: () {}),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(248, 255, 255, 255),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(15, 0, 0, 0),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        height: 100,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color.fromARGB(255, 255, 160, 122),
            unselectedItemColor: const Color.fromARGB(255, 158, 158, 158),
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fastfood_outlined),
                activeIcon: Icon(Icons.fastfood),
                label: 'Menu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                activeIcon: Icon(Icons.account_circle),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}