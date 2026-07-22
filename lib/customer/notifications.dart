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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF8FFFFFF),
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
          // TODO: Replace with dynamic customer notifications fetched from database
          Expanded(
            child: SingleChildScrollView(
              child: buildDefaultFallbackMessage(
                icon: Icons.notifications_none_outlined,
                title: 'No Notifications Yet',
                description: 'You have no notifications or updates right now.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
