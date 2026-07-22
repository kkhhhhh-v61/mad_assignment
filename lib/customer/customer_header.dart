import 'package:flutter/material.dart';

import '../config.dart';
import 'customer_cart.dart';
import 'customer_notifications.dart';

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
    this.pageTitle = appName,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 60.0,
        bottom: spacingXl,
        left: spacingXl,
        right: spacingXl,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radiusXl)),
        boxShadow: [shadowLg],
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
                          fontSize: fontDisplay,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      )
                    : _buildLocationSelector(),
              ),
              _buildActionButtons(context),
            ],
          ),
          // --- Search Bar + Filter ---
          if (showSearch || showFilter) ...[
            const SizedBox(height: spacingLg),
            Row(
              children: [
                Expanded(
                  child: showSearch
                      ? _buildSearchBar()
                      : const SizedBox.shrink(),
                ),
                if (showFilter) const SizedBox(width: spacingMd),
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
              color: textSecondary,
              fontSize: fontCaption,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: spacingXs,
            children: [
              const Flexible(
                child: Text(
                  'Home - 123 Street Name, City',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontBodyLarge,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: brandColor,
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
          icon: Icon(icon, color: textSecondary, size: 28),
          onPressed: onPressed,
        ),
        if (showBadge)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(spacingXs),
              decoration: BoxDecoration(
                color: brandColor,
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
        color: surfaceLight,
        borderRadius: BorderRadius.circular(radiusFull),
      ),
      child: const TextField(
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: spacingMd),
          hintText: 'Search...',
          hintStyle: TextStyle(color: textHint, fontSize: fontSubtitle),
          prefixIcon: Icon(Icons.search, color: textHint, size: 20),
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
        border: Border.all(color: borderLight),
        borderRadius: BorderRadius.circular(radiusFull),
      ),
      child: IconButton(
        icon: const Icon(Icons.tune, color: brandColor, size: 20),
        onPressed: onFilterTap ?? () {},
      ),
    );
  }
}
