import 'package:flutter/material.dart';

import '../config.dart';
import 'customer_header.dart';

class CustomerAccount extends StatelessWidget {
  const CustomerAccount({super.key});

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
                const SizedBox(height: spacingXl),
                // --- Profile Card ---
                _buildProfileCard(),
                const SizedBox(height: spacing2xl),
                // --- Account Options ---
                _buildAccountOptions(),
                const SizedBox(height: spacing3xl),
                // --- Logout Button ---
                _buildLogoutButton(),
                const SizedBox(height: spacing3xl),
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
      margin: const EdgeInsets.symmetric(horizontal: spacingXl),
      padding: const EdgeInsets.all(spacingXl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusXl),
        boxShadow: const [shadowMd],
      ),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: brandColor),
          ),
          const SizedBox(width: spacingXl),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kai Hao',
                  style: TextStyle(
                    fontSize: fontHeadline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacingXs),
                Text(
                  '+60 16-356 1651',
                  style: TextStyle(fontSize: fontBody, color: textSecondary),
                ),
                SizedBox(height: 2),
                Text(
                  'kaihao0303@gmail.com',
                  style: TextStyle(fontSize: fontBody, color: textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: textHint),
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
      margin: const EdgeInsets.symmetric(horizontal: spacingXl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusXl),
        boxShadow: const [shadowMd],
      ),
      child: Column(
        children: [
          _buildOptionTile(Icons.location_on_outlined, 'Saved Addresses'),
          const Divider(height: 1, indent: 60, endIndent: spacingXl),
          _buildOptionTile(Icons.credit_card_outlined, 'Payment Methods'),
          const Divider(height: 1, indent: 60, endIndent: spacingXl),
          _buildOptionTile(Icons.local_offer_outlined, 'Vouchers & Offers'),
          const Divider(height: 1, indent: 60, endIndent: spacingXl),
          _buildOptionTile(Icons.help_outline, 'Help Center'),
          const Divider(height: 1, indent: 60, endIndent: spacingXl),
          _buildOptionTile(Icons.settings_outlined, 'Settings'),
        ],
      ),
    );
  }

  // --- Option Tile ---
  Widget _buildOptionTile(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingXl,
        vertical: spacingXs,
      ),
      leading: Container(
        padding: const EdgeInsets.all(spacingSm),
        decoration: const BoxDecoration(
          color: surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: textSecondary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: fontBodyLarge,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: textHint),
      onTap: () {
        // TODO
      },
    );
  }

  // --- Logout Button ---
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: spacingXl),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: () {
            // TODO
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: dangerColor,
            side: const BorderSide(color: dangerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusLg),
            ),
          ),
          child: const Text(
            'Log Out',
            style: TextStyle(
              fontSize: fontSubtitle,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
