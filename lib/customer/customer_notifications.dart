import 'package:flutter/material.dart';

import '../config.dart';
import '../data.dart';

class CustomerNotifications extends StatefulWidget {
  const CustomerNotifications({super.key});

  @override
  State<CustomerNotifications> createState() => _CustomerNotificationsState();
}

class _CustomerNotificationsState extends State<CustomerNotifications> {
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Orders',
    'Promos',
    'System',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _selectedCategory == 'All'
        ? notificationItems
        : notificationItems
            .where((item) => item.category == _selectedCategory)
            .toList();

    final hasUnread = notificationItems.any((item) => item.isUnread);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: fontTitle,
          ),
        ),
        actions: [
          if (hasUnread)
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all, color: brandColor, size: 24),
              onPressed: () {
                setState(() {
                  for (var item in notificationItems) {
                    item.isUnread = false;
                  }
                });
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: surfaceMuted, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // --- Category Filter Tabs ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: spacingXl,
              vertical: spacingMd,
            ),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return Container(
                    margin: const EdgeInsets.only(right: spacingSm),
                    child: ChoiceChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: fontBody,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                        }
                      },
                      selectedColor: brandColor,
                      backgroundColor: surfaceLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusFull),
                        side: BorderSide(
                          color: isSelected ? brandColor : borderLight,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // --- Notifications List ---
          Expanded(
            child: filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(spacingXl),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(filteredNotifications[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Notification Card ---
  Widget _buildNotificationCard(NotificationItem item) {
    Color iconBgColor;

    switch (item.category) {
      case 'Orders':
        iconBgColor = brandColor;
        break;
      case 'Promos':
        iconBgColor = starColor;
        break;
      case 'System':
      default:
        iconBgColor = infoColor;
        break;
    }

    return GestureDetector(
      onTap: () {
        if (item.isUnread) {
          setState(() {
            item.isUnread = false;
          });
        }
        // TODO: navigate to relevant order/promo screen if applicable
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: spacingLg),
        padding: const EdgeInsets.all(spacingLg),
        decoration: BoxDecoration(
          color: item.isUnread ? surfaceLight : Colors.white,
          borderRadius: BorderRadius.circular(radiusLg),
          border: Border.all(
            color: item.isUnread
                ? brandColor.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: const [shadowMd],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Icon Container ---
            Stack(
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(radiusMd),
                  ),
                  child: Icon(item.icon, color: iconBgColor, size: 28),
                ),
                if (item.isUnread)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      height: 10,
                      width: 10,
                      decoration: const BoxDecoration(
                        color: brandColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: spacingLg),
            // --- Content ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: fontSubtitle,
                            fontWeight: item.isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: spacingSm),
                      Text(
                        item.time,
                        style: const TextStyle(
                          fontSize: fontCaption,
                          color: textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacingXs),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: fontBody,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 90,
            width: 90,
            decoration: const BoxDecoration(
              color: surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: textHint,
              size: 45,
            ),
          ),
          const SizedBox(height: spacingLg),
          const Text(
            'No notifications here',
            style: TextStyle(
              fontSize: fontTitle,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: spacingXs),
          const Text(
            'You are all caught up for this category.',
            style: TextStyle(
              fontSize: fontBody,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
