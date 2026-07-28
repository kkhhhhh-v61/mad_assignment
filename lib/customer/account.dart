import 'package:flutter/material.dart';

import 'header.dart';
import 'profile.dart';

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
                _buildProfileCard(context),
                const SizedBox(height: 24.0),
                _buildAccountOptions(context),
                const SizedBox(height: 32.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
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
              color: const Color.fromARGB(
                255,
                255,
                160,
                122,
              ).withValues(alpha: 0.2),
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
                //TODO: Retrieve user profile details dynamically from backend
                Text(
                  'Kai Hao',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.0),
                Text(
                  '+60 16-356 1651',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'kaihao0303@gmail.com',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Color.fromARGB(255, 158, 158, 158),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerProfile(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOptions(BuildContext context) {
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
          const Divider(height: 1, indent: 60, endIndent: 20.0),
          _buildLogoutTile(context),
        ],
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 4.0,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 229, 57, 53).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.logout,
          color: Color.fromARGB(255, 229, 57, 53),
          size: 22,
        ),
      ),
      title: const Text(
        'Log Out',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15.0,
          color: Color.fromARGB(255, 229, 57, 53),
        ),
      ),
      onTap: () {
        onLogout?.call();
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
    );
  }

  Widget _buildOptionTile(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 4.0,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 245, 245, 245),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color.fromARGB(255, 117, 117, 117),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color.fromARGB(255, 158, 158, 158),
      ),
      onTap: () {},
    );
  }

}
