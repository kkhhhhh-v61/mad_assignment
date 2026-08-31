import 'package:flutter/material.dart';

import '../main.dart';
import '../customer/main_navigation.dart';

import '../shared/account.dart';
import '../shared/profile.dart';

import 'deliveries.dart';
import 'header.dart';

import '../models.dart';

class RiderMainNavigation extends StatefulWidget {
  final AppUser? user;
  const RiderMainNavigation({super.key, this.user});

  @override
  State<RiderMainNavigation> createState() => _RiderMainNavigationState();
}

class _RiderMainNavigationState extends State<RiderMainNavigation> {
  int _currentIndex = 0;

  // Generate screens dynamically to pass context for navigation and snackbars
  List<Widget> _getScreens(BuildContext context) => [
    const RiderDeliveries(),
    _buildAccountScreen(context),
  ];

  // Build the Rider account screen
  Widget _buildAccountScreen(BuildContext context) {
    return SharedAccountScreen(
      header: const RiderHeader(pageTitle: 'My Account'),
      name: widget.user?.name ?? 'Rider',
      subtitle: widget.user?.phone ?? 'No Phone',
      email: widget.user?.email ?? 'No Email',
      profileIcon: Icons.person,
      showEditIcon: true,
      onEditPressed: () {
        // Navigate to the shared profile screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SharedProfileScreen(
              title: 'Rider Profile',
              initialName: widget.user?.name ?? '',
              initialEmail: widget.user?.email ?? '',
              initialPhone: widget.user?.phone ?? '',
              onSave: (name, email, phone) {
                // TODO: Update rider profile via backend API
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
      backgroundColor: const Color.fromARGB(248, 255, 255, 255),
      body: _getScreens(context)[_currentIndex],
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
                icon: Icon(Icons.delivery_dining_outlined),
                activeIcon: Icon(Icons.delivery_dining),
                label: 'Deliveries',
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