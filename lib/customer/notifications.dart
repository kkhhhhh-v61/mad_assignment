import 'package:flutter/material.dart';

import '../global.dart';
// TODELETE
import '../data.dart';

class CustomerNotifications extends StatefulWidget {
  const CustomerNotifications({super.key});

  @override
  State<CustomerNotifications> createState() => _CustomerNotificationsState();
}

class _CustomerNotificationsState extends State<CustomerNotifications> {
  String _selectedCategory = 'All';
  final List<String> _categories = const ['All', 'Orders', 'Promos', 'System'];

  // TODELETE
  late List<Map<String, dynamic>> _notifications;

  @override
  void initState() {
    super.initState();
    // TODELETE
    // TODO: Initialize notifications from backend API
    _notifications = getInitialDummyNotifications();
  }

  void _forceUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xDD000000),
            size: 20,
          ),
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
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF2196F3)),
            tooltip: 'Mark all as read',
            onPressed: () {
              setState(() {
                for (var notif in _notifications) {
                  notif['isRead'] = true;
                }
              });
            },
          ),
          const SizedBox(width: 8),
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
                          color: isSelected
                              ? Colors.white
                              : const Color(0xDD000000),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
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
                          color: isSelected
                              ? const Color.fromARGB(255, 255, 160, 122)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          // --- Notifications List ---
          Expanded(
            // TODELETE
            // TODO: Call dynamic layout function with data fetched from backend
            child: buildDummyNotifications(
              context,
              _notifications,
              _selectedCategory,
              _forceUpdate,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Dynamic UI Functions ====================

Widget buildNotificationsListLayoutUI(
  BuildContext context,
  List<Map<String, dynamic>> notifications,
  VoidCallback onUpdate,
) {
  if (notifications.isEmpty) {
    return SingleChildScrollView(
      child: buildDefaultFallbackMessage(
        icon: Icons.notifications_none_outlined,
        title: 'No Notifications Yet',
        description: 'You have no notifications or updates right now.',
      ),
    );
  }

  return ListView.separated(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    itemCount: notifications.length,
    separatorBuilder: (context, index) => const SizedBox(height: 12.0),
    itemBuilder: (context, index) {
      final notif = notifications[index];
      return buildNotificationCardUI(context, notif, onUpdate);
    },
  );
}

Widget buildNotificationCardUI(
  BuildContext context,
  Map<String, dynamic> notif,
  VoidCallback onUpdate,
) {
  final bool isRead = notif['isRead'] as bool;
  final String type = notif['type'] as String;
  final String title = notif['title'] as String;
  final String description = notif['description'] as String;
  final String time = notif['time'] as String;

  IconData icon;
  Color iconColor;

  switch (type) {
    case 'Orders':
      icon = Icons.receipt_long;
      iconColor = const Color.fromARGB(255, 255, 160, 122);
      break;
    case 'Promos':
      icon = Icons.local_offer;
      iconColor = const Color(0xFFE53935);
      break;
    case 'System':
    default:
      icon = Icons.info_outline;
      iconColor = const Color(0xFF2196F3);
      break;
  }

  return InkWell(
    onTap: () {
      if (!isRead) {
        notif['isRead'] = true;
        onUpdate();
      }
    },
    borderRadius: BorderRadius.circular(16.0),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isRead
            ? Colors.white
            : const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: isRead
            ? null
            : Border.all(
                color: const Color.fromARGB(
                  255,
                  255,
                  160,
                  122,
                ).withValues(alpha: 0.3),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24.0),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.w600
                              : FontWeight.bold,
                          fontSize: 16.0,
                          color: const Color(0xDD000000),
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 255, 160, 122),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: isRead
                        ? const Color(0xFF757575)
                        : const Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
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
