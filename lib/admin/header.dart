import 'package:flutter/material.dart';

class AdminHeader extends StatelessWidget {
  final String pageTitle;
  final bool showSearch;
  final bool showFilter;
  final VoidCallback? onFilterTap;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final String? searchHint;

  const AdminHeader({
    super.key,
    required this.pageTitle,
    this.showSearch = false,
    this.showFilter = false,
    this.onFilterTap,
    this.searchController,
    this.onSearchChanged,
    this.onSearchClear,
    this.searchHint,
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
                if (showSearch)
                  Expanded(
                    child: AdminSearchBar(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      onClear: onSearchClear,
                      hintText: searchHint ?? 'Search food items...',
                    ),
                  ),
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
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const AdminSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 245),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller ?? ValueNotifier(const TextEditingValue()),
        builder: (context, value, child) {
          final hasText = value.text.isNotEmpty;
          return TextField(
            controller: controller,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color.fromARGB(255, 158, 158, 158),
                fontSize: 16.0,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color.fromARGB(255, 158, 158, 158),
                size: 20,
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Color.fromARGB(255, 158, 158, 158),
                        size: 18,
                      ),
                      onPressed: () {
                        controller?.clear();
                        onChanged?.call('');
                        onClear?.call();
                      },
                    )
                  : null,
            ),
          );
        },
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
