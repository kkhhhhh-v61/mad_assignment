import 'package:flutter/material.dart';

import 'account.dart';
import 'auth.dart';
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
        ? CustomerAccount(onLogout: () => setState(() => _isLoggedIn = false))
        : CustomerAuth(onAuthSuccess: () => setState(() => _isLoggedIn = true)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF8FFFFFF),
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
            unselectedItemColor: const Color(0xFF9E9E9E),
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
