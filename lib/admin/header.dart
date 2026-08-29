import 'package:flutter/material.dart';

class AdminHeader extends StatelessWidget {
  final String pageTitle;
  final bool showSearch;
  final bool showFilter;
  final VoidCallback? onFilterTap;

  const AdminHeader({
    super.key,
    required this.pageTitle,
    this.showSearch = false,
    this.showFilter = false,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pageTitle,
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 0, 0, 0),
                  ),
                ),
              ),
            ],
          ),
          if (showSearch || showFilter) ...[
            const SizedBox(height: 16.0),
            Row(
              children: [
                if (showSearch) const Expanded(child: AdminSearchBar()),
                if (showSearch && showFilter) const SizedBox(width: 12.0),
                if (showFilter) AdminFilterButton(onFilterTap: onFilterTap),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AdminSearchBar extends StatelessWidget {
  const AdminSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 245),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: const TextField(
        textAlignVertical: TextAlignVertical.center,
        //TODO: Handle search query submission to backend for admin
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
}

class AdminFilterButton extends StatelessWidget {
  final VoidCallback? onFilterTap;

  const AdminFilterButton({super.key, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
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
        onPressed: onFilterTap ?? () {},
      ),
    );
  }
}
