import 'package:flutter/material.dart';

import '../global.dart';

class CustomerNotifications extends StatefulWidget {
  const CustomerNotifications({super.key});

  @override
  State<CustomerNotifications> createState() => _CustomerNotificationsState();
}

class _CustomerNotificationsState extends State<CustomerNotifications> {
  String _selectedCategory = 'All';
  final List<String> _categories = const ['All', 'Orders', 'Promos', 'System'];

  late List<Map<String, dynamic>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [];
    //TODO: Retrieve user's notifications dynamically from backend
  }

  void _forceUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(221, 0, 0, 0),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color.fromARGB(221, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.done_all,
              color: Color.fromARGB(255, 255, 160, 122),
            ),
            tooltip: 'Mark all as read',
            onPressed: () {
              //TODO: Mark all notifications as read via backend API
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
          child: Container(
            color: const Color.fromARGB(255, 238, 238, 238),
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
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
                              : const Color.fromARGB(221, 0, 0, 0),
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
                      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        side: BorderSide(
                          color: isSelected
                              ? const Color.fromARGB(255, 255, 160, 122)
                              : const Color.fromARGB(255, 224, 224, 224),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: Builder(
              builder: (context) {
                final displayedNotifs = _selectedCategory == 'All'
                    ? _notifications
                    : _notifications
                          .where((notif) => notif['type'] == _selectedCategory)
                          .toList();
                return NotificationsList(
                  notifications: displayedNotifs,
                  onUpdate: _forceUpdate,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsList extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final VoidCallback onUpdate;

  const NotificationsList({
    super.key,
    required this.notifications,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const SingleChildScrollView(
        child: FallbackMessage(
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
        return NotificationCard(notif: notif, onUpdate: onUpdate);
      },
    );
  }
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onUpdate;

  const NotificationCard({
    super.key,
    required this.notif,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRead = notif['isRead'] as bool? ?? false;
    final String type = notif['type'] as String? ?? 'System';
    final String title = notif['title'] as String? ?? '';
    final String description = notif['description'] as String? ?? '';
    final String time = notif['time'] as String? ?? '';

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'Orders':
        icon = Icons.receipt_long;
        iconColor = const Color.fromARGB(255, 255, 160, 122);
        break;
      case 'Promos':
        icon = Icons.local_offer;
        iconColor = const Color.fromARGB(255, 229, 57, 53);
        break;
      case 'System':
      default:
        icon = Icons.info_outline;
        iconColor = const Color.fromARGB(255, 33, 150, 243);
        break;
    }

    return InkWell(
      onTap: () {
        if (!isRead) {
          //TODO: Mark single notification as read via backend API
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
              color: Color.fromARGB(8, 0, 0, 0),
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
                            color: const Color.fromARGB(221, 0, 0, 0),
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
                          ? const Color.fromARGB(255, 117, 117, 117)
                          : const Color.fromARGB(255, 66, 66, 66),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Color.fromARGB(255, 158, 158, 158),
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
}
