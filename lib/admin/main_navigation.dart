import 'package:flutter/material.dart';

import '../main.dart';
import '../customer/main_navigation.dart';

import '../shared/account.dart';
import '../shared/profile.dart';
import 'header.dart';
import 'food_management.dart';
import 'rider_management.dart';

import '../models.dart';

class AdminMainNavigation extends StatefulWidget {
  final AppUser? user;
  const AdminMainNavigation({super.key, this.user});
  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int _currentIndex = 0;

  // Generate pages dynamically to pass context for the logout function
  List<Widget> _getPages(BuildContext context) => [
    const AdminFoodManagement(),
    const AdminRiderManagement(),
    _buildAccountScreen(context),
  ];

  // Build the Admin account screen
  Widget _buildAccountScreen(BuildContext context) {
    return SharedAccountScreen(
      header: const AdminHeader(pageTitle: 'Account'),
      name: widget.user?.name ?? 'Admin User',
      subtitle: widget.user?.phone ?? 'Administrator',
      email: widget.user?.email ?? 'No Email',
      profileIcon: Icons.admin_panel_settings,

      showEditIcon: true,

      onEditPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SharedProfileScreen(
              title: 'Admin Profile',
              initialName: widget.user?.name ?? '',
              initialEmail: widget.user?.email ?? '',
              initialPhone: widget.user?.phone ?? '',
              onSave: (name, email, phone) {
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

      onLogout: () async {
        await supabase.auth.signOut();

        if (context.mounted) {
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

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const CustomerMainNavigation()),
                (route) => false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      body: IndexedStack(
        index: _currentIndex,
        children: _getPages(context),
      ),
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
                icon: Icon(Icons.restaurant_menu_outlined),
                activeIcon: Icon(Icons.restaurant_menu),
                label: 'Food',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.electric_moped_outlined),
                activeIcon: Icon(Icons.electric_moped),
                label: 'Riders',
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