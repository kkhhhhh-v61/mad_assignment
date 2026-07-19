import 'package:flutter/material.dart';
import 'package:mad_assignment/config.dart';
import 'package:mad_assignment/customer_home.dart';

class CustomerMainNavigation extends StatefulWidget {
  const CustomerMainNavigation({super.key});

  @override
  State<CustomerMainNavigation> createState() => _CustomerMainNavigationState();
}

class _CustomerMainNavigationState extends State<CustomerMainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CustomerHome(),
    const Center(
      child: Text('Menu Page', style: TextStyle(fontSize: 24),),
    ),
    const Center(
      child: Text('Orders Page', style: TextStyle(fontSize: 24),),
    ),
    const Center(
      child: Text('Favorites Page', style: TextStyle(fontSize: 24),),
    ),
    const Center(
      child: Text('Account Page', style: TextStyle(fontSize: 24),),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(248, 255, 255, 255),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(15.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(64, 0, 0, 0),
              blurRadius: 15,
              spreadRadius: 1,
              offset: Offset(0, -2),
            )
          ],
        ),
        height: 100,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(15.0),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: brandColor,
            unselectedItemColor: Colors.grey,
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
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Favorites',
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
