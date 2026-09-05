import 'package:flutter/material.dart';
import 'package:mad_assignment/customer/payment_methods.dart';
import 'package:mad_assignment/customer/saved_addresses.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

import '../shared/account.dart';
import '../shared/profile.dart';
import '../main.dart';
import '../admin/main_navigation.dart';
import '../rider/main_navigation.dart';

import '../shared/auth.dart';
import 'header.dart';
import 'home.dart';
import 'menu.dart';
import 'orders.dart';

import '../models.dart';


class CustomerMainNavigation extends StatefulWidget {
  final int initialIndex;

  const CustomerMainNavigation({super.key, this.initialIndex = 0});

  @override
  State<CustomerMainNavigation> createState() => _CustomerMainNavigationState();
}

class _CustomerMainNavigationState extends State<CustomerMainNavigation> {
  late int _currentIndex;
  bool _isLoggedIn = false;
  String _selectedMenuCategory = '';
  AppUser? currentUser;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
    _currentIndex = widget.initialIndex;
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      final savedEmail = prefs.getString('saved_email') ?? '';
      final savedPassword = prefs.getString('saved_password') ?? '';

      if (savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
        AppUser? user = await loginUser(savedEmail, savedPassword);

        if (user != null && mounted) {
          if (user.role == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminMainNavigation(user: user)));
            return;
          } else if (user.role == 'rider') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RiderMainNavigation(user: user)));
            return;
          } else {
            setState(() {
              _isLoggedIn = true;
              currentUser = user;
              _isCheckingAuth = false;
            });
            return;
          }
        }
      }
    } else {
      await supabase.auth.signOut();
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          currentUser = null;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isCheckingAuth = false;
      });
    }
  }


  @override
  void didUpdateWidget(covariant CustomerMainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
    }
  }



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
            header: const CustomerHeader(
              showTitle: true,
              pageTitle: 'My Account',
              showSearch: false,
            ),
            onAuthSuccess: (user) {
              CustomerHeader.clearLocationCache();
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', false);

        await supabase.auth.signOut();
        CustomerHeader.clearLocationCache();
        setState(() {
          _isLoggedIn = false;
          currentUser = null;
        });
        if (mounted) {
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
    if (_isCheckingAuth) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 255, 160, 122),
            strokeWidth: 3.0,
          ),
        ),
      );
    }
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