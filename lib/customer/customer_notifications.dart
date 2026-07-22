import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xF8FFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xDD000000), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xDD000000),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        actions: [
          if (hasUnread)
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all, color: Color.fromARGB(255, 255, 160, 122), size: 24),
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
          child: Container(color: const Color(0xFFEEEEEE), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // --- Category Filter Tabs ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
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
                    margin: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xDD000000),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14.0,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                        }
                      },
                      selectedColor: const Color.fromARGB(255, 255, 160, 122),
                      backgroundColor: const Color(0xFFF5F5F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        side: BorderSide(
                          color: isSelected ? const Color.fromARGB(255, 255, 160, 122) : const Color(0xFFE0E0E0),
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
                    padding: const EdgeInsets.all(20.0),
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
        iconBgColor = const Color.fromARGB(255, 255, 160, 122);
        break;
      case 'Promos':
        iconBgColor = const Color(0xFFFFC107);
        break;
      case 'System':
      default:
        iconBgColor = const Color(0xFF2196F3);
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
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: item.isUnread ? const Color(0xFFF5F5F5) : Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(
            color: item.isUnread
                ? const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1.5,
          ),
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
                    borderRadius: BorderRadius.circular(12.0),
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
                        color: Color.fromARGB(255, 255, 160, 122),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16.0),
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
                            fontSize: 16.0,
                            fontWeight: item.isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: const Color(0xDD000000),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        item.time,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Color(0xFF757575),
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
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: Color(0xFF9E9E9E),
              size: 45,
            ),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'No notifications here',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Color(0xDD000000),
            ),
          ),
          const SizedBox(height: 4.0),
          const Text(
            'You are all caught up for this category.',
            style: TextStyle(
              fontSize: 14.0,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}
