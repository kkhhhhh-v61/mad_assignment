import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../customer/main_navigation.dart';

import '../shared/account.dart';
import '../shared/profile.dart';
import 'header.dart';
import 'food_management.dart';
import 'rider_management.dart';
import 'customer_management.dart';
import 'branch_management.dart';

import '../models.dart';

class AdminMainNavigation extends StatefulWidget {
  final AppUser? user;
  const AdminMainNavigation({super.key, this.user});
  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int _currentIndex = 0;
  AppUser? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  List<Widget> _getPages(BuildContext context) => [
    const AdminFoodManagement(),
    const AdminRiderManagement(),
    const AdminBranchManagement(),
    _buildAccountScreen(context),
  ];

  Widget _buildAccountScreen(BuildContext context) {
    return SharedAccountScreen(
      header: const AdminHeader(pageTitle: 'Account'),
      name: currentUser?.name ?? 'Admin User',
      subtitle: currentUser?.phone ?? 'Administrator',
      email: currentUser?.email ?? 'No Email',
      profileIcon: Icons.admin_panel_settings,
      avatarUrl: currentUser?.avatarUrl,

      showEditIcon: true,

      onEditPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SharedProfileScreen(
              title: 'Admin Profile',
              initialName: currentUser?.name ?? '',
              initialEmail: currentUser?.email ?? '',
              initialPhone: currentUser?.phone ?? '',
              initialAvatarUrl: currentUser?.avatarUrl,
              onSave: (name, email, phone, password) async {
                try {
                  final userId = supabase.auth.currentUser!.id;

                  await supabase
                      .from('profiles')
                      .update({'name': name, 'email': email, 'phone': phone})
                      .eq('id', userId);

                  if (password.isNotEmpty) {
                    if (password.length < 8) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 8 characters long.',
                            ),
                            backgroundColor: Color.fromARGB(255, 239, 83, 80),
                          ),
                        );
                      }
                      return;
                    }
                    await supabase.auth.updateUser(
                      UserAttributes(password: password),
                    );
                  }

                  final updatedProfile = await supabase
                      .from('profiles')
                      .select()
                      .eq('id', currentUser!.id)
                      .single();

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
                        content: Text(
                          'Error updating profile: $e',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
            MaterialPageRoute(
              builder: (context) => const CustomerMainNavigation(),
            ),
            (route) => false,
          );
        }
      },

      accountOptions: [
        SharedOptionTile(
          icon: Icons.store_outlined,
          title: 'Delivery Fees Setting',
          onTap: () {},
        ),
        SharedOptionTile(
          icon: Icons.people_outline,
          title: 'Manage Customers',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminCustomerManagement(),
              ),
            );
          },
        ),
        SharedOptionTile(
          icon: Icons.bar_chart,
          title: 'Assign Rider',
          onTap: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      body: IndexedStack(index: _currentIndex, children: _getPages(context)),
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
                icon: Icon(Icons.store_outlined),
                activeIcon: Icon(Icons.store),
                label: 'Branches',
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
