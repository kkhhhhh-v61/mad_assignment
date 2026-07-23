import 'package:flutter/material.dart';

import 'cart.dart';
import 'notifications.dart';

class CustomerHeader extends StatefulWidget {
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
  State<CustomerHeader> createState() => _CustomerHeaderState();
}

class _CustomerHeaderState extends State<CustomerHeader> {
  //TODO: Retrieve user addresses dynamically from backend
  // --- TOREMOVE ---
  final List<String> _addresses = [
    'Home - 123 Street Name, City',
    'Work - 456 Office Tower, City',
    'Partner - 789 Apartment Bldg, City',
  ];
  late String _selectedAddress = _addresses[0];
  // --- END TOREMOVE ---

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
          Row(
            children: [
              Expanded(
                child: widget.showTitle
                    ? Text(
                        widget.pageTitle,
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(221, 0, 0, 0),
                        ),
                      )
                    : _buildLocationSelector(),
              ),
              _buildActionButtons(context),
            ],
          ),
          if (widget.showSearch || widget.showFilter) ...[
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: widget.showSearch
                      ? _buildSearchBar()
                      : const SizedBox.shrink(),
                ),
                if (widget.showFilter) const SizedBox(width: 12.0),
                if (widget.showFilter) _buildFilterButton(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return PopupMenuButton<String>(
      initialValue: _selectedAddress,
      onSelected: (String newValue) {
        setState(() {
          _selectedAddress = newValue;
        });
      },
      itemBuilder: (BuildContext context) {
        return _addresses.map((String address) {
          return PopupMenuItem<String>(
            value: address,
            child: Text(
              address,
              style: TextStyle(
                fontWeight: _selectedAddress == address
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: _selectedAddress == address
                    ? const Color.fromARGB(255, 255, 160, 122)
                    : const Color.fromARGB(221, 0, 0, 0),
              ),
            ),
          );
        }).toList();
      },
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your location',
            style: TextStyle(
              color: Color.fromARGB(255, 117, 117, 117),
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4.0,
            children: [
              Flexible(
                child: Text(
                  _selectedAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                  ),
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

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        _buildIconWithBadge(
          icon: Icons.notifications_outlined,
          //TODO: Retrieve unread notifications count dynamically from backend
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
          //TODO: Retrieve cart item count dynamically from backend
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

  Widget _buildIconWithBadge({
    required IconData icon,
    required bool showBadge,
    required VoidCallback onPressed,
  }) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: const Color.fromARGB(255, 117, 117, 117),
            size: 28,
          ),
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

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 245),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: const TextField(
        textAlignVertical: TextAlignVertical.center,
        //TODO: Handle search query submission to backend
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.0),
          hintText: 'Search...',
          hintStyle: TextStyle(
            color: Color.fromARGB(255, 158, 158, 158),
            fontSize: 16.0,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Color.fromARGB(255, 158, 158, 158),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 224, 224, 224)),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: IconButton(
        icon: const Icon(
          Icons.tune,
          color: Color.fromARGB(255, 255, 160, 122),
          size: 20,
        ),
        onPressed: widget.onFilterTap ?? () {},
      ),
    );
  }
}
