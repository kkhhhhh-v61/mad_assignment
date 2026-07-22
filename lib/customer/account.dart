import 'package:flutter/material.dart';

import '../data.dart';
import 'header.dart';

class CustomerAccount extends StatelessWidget {
  final VoidCallback? onLogout;

  const CustomerAccount({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CustomerHeader(
          showTitle: true,
          pageTitle: 'My Account',
          showSearch: false,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20.0),
                // --- Profile Card ---
                _buildProfileCard(),
                const SizedBox(height: 24.0),
                // --- Account Options ---
                _buildAccountOptions(),
                const SizedBox(height: 32.0),
                // --- Logout Button ---
                _buildLogoutButton(context),
                const SizedBox(height: 32.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Profile Card ---
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(20, 0, 0, 0),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Color.fromARGB(255, 255, 160, 122),
            ),
          ),
          const SizedBox(width: 20.0),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kai Hao',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  '+60 16-356 1651',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Color(0xFF757575),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'kaihao0303@gmail.com',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF9E9E9E)),
            onPressed: () {
              // TODO
            },
          ),
        ],
      ),
    );
  }

  // --- Account Options ---
  Widget _buildAccountOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(20, 0, 0, 0),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildOptionTile(Icons.location_on_outlined, 'Saved Addresses'),
          const Divider(height: 1, indent: 60, endIndent: 20.0),
          _buildOptionTile(Icons.credit_card_outlined, 'Payment Methods'),
          const Divider(height: 1, indent: 60, endIndent: 20.0),
          _buildOptionTile(Icons.local_offer_outlined, 'Vouchers & Offers'),
          const Divider(height: 1, indent: 60, endIndent: 20.0),
          _buildOptionTile(Icons.help_outline, 'Help Center'),
          const Divider(height: 1, indent: 60, endIndent: 20.0),
          _buildOptionTile(Icons.settings_outlined, 'Settings'),
        ],
      ),
    );
  }

  // --- Option Tile ---
  Widget _buildOptionTile(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 4.0,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF757575), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15.0,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF9E9E9E),
      ),
      onTap: () {
        // TODO
      },
    );
  }

  // --- Logout Button ---
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: () {
            isLoggedIn = false;
            onLogout?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Logged out successfully',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Color(0xFFEF5350),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEF5350),
            side: const BorderSide(color: Color(0xFFEF5350)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: const Text(
            'Log Out',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
