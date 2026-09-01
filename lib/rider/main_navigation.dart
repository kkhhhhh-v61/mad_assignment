import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../customer/main_navigation.dart';

import '../shared/account.dart';
import '../shared/profile.dart';

import 'deliveries.dart';
import 'header.dart';
import 'rider_delivery_repository.dart';

import '../models.dart';
import '../Order/order_repository.dart';

class RiderMainNavigation extends StatefulWidget {
  final AppUser? user;
  const RiderMainNavigation({super.key, this.user});

  @override
  State<RiderMainNavigation> createState() => _RiderMainNavigationState();
}

class _RiderMainNavigationState extends State<RiderMainNavigation> {
  int _currentIndex = 0;
  AppUser? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  RiderDeliveryRepository? _buildDeliveryRepository() {
    final riderId = currentUser?.id ?? supabase.auth.currentUser?.id;
    if (riderId == null || riderId.trim().isEmpty) {
      return null;
    }
    return SupabaseRiderDeliveryRepository(
      orderRepository: SupabaseOrderRepository(supabase),
      riderId: riderId,
    );
  }

  // Generate screens dynamically to pass context for navigation and snackbars
  List<Widget> _getScreens(BuildContext context) => [
    RiderDeliveries(repository: _buildDeliveryRepository()),
    _buildAccountScreen(context),
  ];

  // Build the Rider account screen
  Widget _buildAccountScreen(BuildContext context) {
    return SharedAccountScreen(
      header: const RiderHeader(pageTitle: 'My Account'),
      name: currentUser?.name ?? 'Rider',
      subtitle: currentUser?.phone ?? 'No Phone',
      email: currentUser?.email ?? 'No Email',
      profileIcon: Icons.person,
      showEditIcon: true,
      onEditPressed: () {
        // Navigate to the shared profile screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SharedProfileScreen(
              title: 'Rider Profile',
              initialName: currentUser?.name ?? '',
              initialEmail: currentUser?.email ?? '',
              initialPhone: currentUser?.phone ?? '',
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

                  setState(() {
                    currentUser = AppUser(
                      id: currentUser!.id,
                      role: currentUser!.role,
                      name: name,
                      email: email,
                      phone: phone,
                      address: currentUser!.address,
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
