import 'package:flutter/material.dart';

import 'cart.dart';
import 'notifications.dart';

class CustomerHeader extends StatelessWidget {
  final bool showFilter;
  final bool showSearch;
  final bool showTitle;
  final String pageTitle;
  final VoidCallback? onFilterTap;

  const CustomerHeader({
    super.key,
    this.showFilter = false,
    this.showSearch = true,
    this.showTitle = false,
    this.pageTitle = 'DoorDish',
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 60.0,
        bottom: 20.0,
        left: 20.0,
        right: 20.0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(25, 0, 0, 0),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Location / Title + Actions ---
          Row(
            children: [
              Expanded(
                child: showTitle
                    ? Text(
                        pageTitle,
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xDD000000),
                        ),
                      )
                    : _buildLocationSelector(),
              ),
              _buildActionButtons(context),
            ],
          ),
          // --- Search Bar + Filter ---
          if (showSearch || showFilter) ...[
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: showSearch
                      ? _buildSearchBar()
                      : const SizedBox.shrink(),
                ),
                if (showFilter) const SizedBox(width: 12.0),
                if (showFilter) _buildFilterButton(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- Location Selector ---
  Widget _buildLocationSelector() {
    return InkWell(
      onTap: () {
        // TODO
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your location',
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4.0,
            children: [
              const Flexible(
                child: Text(
                  'Home - 123 Street Name, City',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color.fromARGB(255, 255, 160, 122),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Action Buttons ---
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        _buildIconWithBadge(
          icon: Icons.notifications_outlined,
          showBadge: true,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomerNotifications(),
              ),
            );
          },
        ),
        _buildIconWithBadge(
          icon: Icons.shopping_cart_outlined,
          showBadge: true,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomerCart()),
            );
          },
        ),
      ],
    );
  }

  // --- Icon with Badge Dot ---
  Widget _buildIconWithBadge({
    required IconData icon,
    required bool showBadge,
    required VoidCallback onPressed,
  }) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: const Color(0xFF757575), size: 28),
          onPressed: onPressed,
        ),
        if (showBadge)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 160, 122),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minHeight: 10, minWidth: 10),
            ),
          ),
      ],
    );
  }

  // --- Search Bar ---
  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: const TextField(
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.0),
          hintText: 'Search...',
          hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16.0),
          prefixIcon: Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
        ),
      ),
    );
  }

  // --- Filter Button ---
  Widget _buildFilterButton() {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: IconButton(
        icon: const Icon(
          Icons.tune,
          color: Color.fromARGB(255, 255, 160, 122),
          size: 20,
        ),
        onPressed: onFilterTap ?? () {},
      ),
    );
  }
}
