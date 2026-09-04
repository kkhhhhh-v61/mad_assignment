import 'package:flutter/material.dart';
import 'package:mad_assignment/customer/payment_methods.dart';
import 'package:mad_assignment/customer/saved_addresses.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/account.dart';
import '../shared/profile.dart';
import '../main.dart';

import '../shared/auth.dart';
import 'header.dart';
import 'home.dart';
import 'menu.dart';
import 'orders.dart';

import '../models.dart';


class CustomerMainNavigation extends StatefulWidget {
  const CustomerMainNavigation({super.key});

  @override
  State<CustomerMainNavigation> createState() => _CustomerMainNavigationState();
}

class _CustomerMainNavigationState extends State<CustomerMainNavigation> {
  int _currentIndex = 0;
  bool _isLoggedIn = false;
  String _selectedMenuCategory = '';
  AppUser? currentUser;

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
        ? _buildAccountScreen()
        : SharedAuthScreen(
      onAuthSuccess: (user) {
        setState(() {
          _isLoggedIn = true;
          currentUser = user;
        });
      },
    ),
  ];

  Widget _buildAccountScreen() {
    return SharedAccountScreen(
      header: const CustomerHeader(
        showTitle: true,
        pageTitle: 'My Account',
        showSearch: false,
      ),
      name: currentUser?.name ?? 'No Name',
      subtitle: currentUser?.phone ?? 'No Phone',
      email: currentUser?.email ?? 'No Email',
      profileIcon: Icons.person,
      avatarUrl: currentUser?.avatarUrl,
      onEditPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SharedProfileScreen(
              title: 'Edit Profile',
              initialName: currentUser?.name ?? '',
              initialEmail: currentUser?.email ?? '',
              initialPhone: currentUser?.phone ?? '',
              initialAvatarUrl: currentUser?.avatarUrl,
              onSave: (name, email, phone, password) async {
                try {
                  final userId = supabase.auth.currentUser!.id;

                  await supabase.from('profiles').update({
                    'name': name,
                    'email': email,
                    'phone': phone,
                  }).eq('id', userId);

                  if (password.isNotEmpty) {
                    if (password.length < 8) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password must be at least 8 characters long.'),
                            backgroundColor: Color.fromARGB(255, 239, 83, 80),
                          ),
                        );
                      }
                      return;
                    }
                    await supabase.auth.updateUser(UserAttributes(password: password));
                  }

                  final updatedProfile = await supabase.from('profiles').select().eq('id', currentUser!.id).single();

                  setState(() {
                    currentUser = AppUser(
                      id: currentUser!.id,
                      role: currentUser!.role,
                      name: name,
                      email: email,
                      phone: phone,
                      address: currentUser!.address,
                      avatarUrl: updatedProfile['avatar_url'],
                    );
                  });

                  if (context.mounted) {
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
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating profile: $e', style: const TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: const Color.fromARGB(255, 239, 83, 80),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
      onLogout: () async {
        await supabase.auth.signOut();
        setState(() {
          _isLoggedIn = false;
          currentUser = null;
        });
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
        }
      },
      accountOptions: [
        SharedOptionTile(
          icon: Icons.location_on_outlined,
          title: 'Saved Addresses',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SavedAddressesScreen(),
              ),
            );
          },
        ),
        const Divider(height: 1, indent: 60, endIndent: 20.0),
        SharedOptionTile(
            icon: Icons.credit_card_outlined,
            title: 'Payment Methods',
            onTap: () {
              Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
              );
            }
            ),

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