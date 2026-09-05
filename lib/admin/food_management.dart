import 'package:flutter/material.dart';

import '../global.dart';
import '../main.dart';
import 'food_creation.dart';
import 'food_edit.dart';
import 'header.dart';

class AdminFoodManagement extends StatefulWidget {
  const AdminFoodManagement({super.key});

  @override
  State<AdminFoodManagement> createState() => _AdminFoodManagementState();
}

class _AdminFoodManagementState extends State<AdminFoodManagement> {
  late final TextEditingController _searchController;
  List<Map<String, dynamic>> _foodItems = [];
  bool _isLoading = true;
  String _searchQuery = '';

  String _selectedSort = 'Newest Added';
  final List<String> _sortOptions = [
    'Newest Added',
    'Alphabetically',
    'Price Low to High',
    'Price High to Low',
    'Preparation Time',
  ];

  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  final List<String> _statusOptions = ['All', 'Active', 'Inactive'];

  List<String> get _categoryOptions {
    final set = <String>{'All'};
    for (final item in _foodItems) {
      set.addAll(_extractCategories(item));
    }
    return set.toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchFoodItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFoodItems() async {
    try {
      List<dynamic> res;
      try {
        res = await supabase
            .from('food_items')
            .select('''
          *,
          food_item_categories(food_categories(id, name)),
          food_item_states(states(id, name))
        ''')
            .order('created_at', ascending: false);
      } catch (_) {
        res = await supabase
            .from('food_items')
            .select()
            .order('created_at', ascending: false);
      }

      if (mounted) {
        setState(() {
          _foodItems = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _extractFromRelation(
    Map<String, dynamic> item,
    String relKey,
    String subKey,
  ) {
    final raw = item[relKey] as List<dynamic>?;
    if (raw == null) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => (e[subKey] as Map<String, dynamic>?)?['name']?.toString())
        .whereType<String>()
        .toList();
  }

  List<String> _extractCategories(Map<String, dynamic> item) =>
      _extractFromRelation(item, 'food_item_categories', 'food_categories');

  List<String> _extractStates(Map<String, dynamic> item) =>
      _extractFromRelation(item, 'food_item_states', 'states');

  List<Map<String, dynamic>> _filterAndSortFoodItems() {
    final filtered = _foodItems.where((item) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (item['name']?.toString() ?? '').toLowerCase();
        final cats = _extractCategories(item).map((c) => c.toLowerCase());
        final states = _extractStates(item).map((s) => s.toLowerCase());
        if (!name.contains(q) &&
            !cats.any((c) => c.contains(q)) &&
            !states.any((s) => s.contains(q))) {
          return false;
        }
      }

      if (_selectedCategory != 'All') {
        final match = _extractCategories(item).any(
          (c) =>
              c.trim().toLowerCase() == _selectedCategory.trim().toLowerCase(),
        );
        if (!match) return false;
      }

      if (_selectedStatus != 'All') {
        final isAvail = item['is_available'] as bool? ?? true;
        if (_selectedStatus == 'Active' && !isAvail) return false;
        if (_selectedStatus == 'Inactive' && isAvail) return false;
      }

      return true;
    }).toList();

    if (_selectedSort == 'Alphabetically') {
      filtered.sort(
        (a, b) => (a['name']?.toString() ?? '').toLowerCase().compareTo(
          (b['name']?.toString() ?? '').toLowerCase(),
        ),
      );
    } else if (_selectedSort == 'Price Low to High') {
      filtered.sort(
        (a, b) =>
            ((a['price'] as num?) ?? 0).compareTo((b['price'] as num?) ?? 0),
      );
    } else if (_selectedSort == 'Price High to Low') {
      filtered.sort(
        (a, b) =>
            ((b['price'] as num?) ?? 0).compareTo((a['price'] as num?) ?? 0),
      );
    } else if (_selectedSort == 'Preparation Time') {
      filtered.sort((a, b) {
        final pA =
            (a['preparation_time'] as num?)?.toInt() ??
            int.tryParse(
              a['prepTime']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '',
            ) ??
            0;
        final pB =
            (b['preparation_time'] as num?)?.toInt() ??
            int.tryParse(
              b['prepTime']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '',
            ) ??
            0;
        return pA.compareTo(pB);
      });
    } else {
      filtered.sort((a, b) {
        final dA =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(1970);
        final dB =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(1970);
        return dB.compareTo(dA);
      });
    }

    return filtered;
  }

  Future<void> _toggleFoodAvailability(
    Map<String, dynamic> item,
    bool newValue,
  ) async {
    final foodId = item['id'];
    final previousValue = item['is_available'] as bool? ?? true;

    setState(() {
      item['is_available'] = newValue;
    });

    try {
      await supabase
          .from('food_items')
          .update({'is_available': newValue})
          .eq('id', foodId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item['name'] ?? 'Item'} is now ${newValue ? 'Active' : 'Inactive'}',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: newValue
                ? const Color(0xFF10B981)
                : const Color(0xFF6B7280),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          item['is_available'] = previousValue;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddFood() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FoodCreation()),
    );
    if (res == true) _fetchFoodItems();
  }

  Future<void> _navigateToEditFood(Map<String, dynamic> item) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminFoodEdit(item: item)),
    );
    if (res == true) _fetchFoodItems();
  }

  void _showAllItemsSheet(String title, List<String> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildDragHandle()),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xDD000000),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF757575),
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map(
                      (val) => _buildTagChip(
                        label: val,
                        bgColor: const Color(0xFFF3F4F6),
                        textColor: const Color(0xFF374151),
                        borderColor: const Color(0xFFE5E7EB),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterModal() async {
    final res = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FoodFilterSheet(
        initialSort: _selectedSort,
        initialCategory: _selectedCategory,
        initialStatus: _selectedStatus,
        sortOptions: _sortOptions,
        categoryOptions: _categoryOptions,
        statusOptions: _statusOptions,
      ),
    );

    if (res != null && mounted) {
      setState(() {
        _selectedSort = res['sort'] ?? 'Newest Added';
        _selectedCategory = res['category'] ?? 'All';
        _selectedStatus = res['status'] ?? 'All';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildFloatingActionButton(),
      body: Column(
        children: [
          AdminHeader(
            pageTitle: 'Food Management',
            showSearch: true,
            showFilter: true,
            searchController: _searchController,
            onSearchChanged: (q) => setState(() => _searchQuery = q.trim()),
            onSearchClear: () => setState(() => _searchQuery = ''),
            searchHint: 'Search food items...',
            onFilterTap: _showFilterModal,
          ),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFFFA07A),
              onRefresh: _fetchFoodItems,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildFoodList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFFFA07A),
      elevation: 3,
      onPressed: _navigateToAddFood,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  Widget _buildFoodList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFA07A)),
        ),
      );
    }

    if (_foodItems.isEmpty) return _buildEmptyFallback(isFiltering: false);

    final items = _filterAndSortFoodItems();
    if (items.isEmpty) {
      final isFiltering =
          _searchQuery.isNotEmpty ||
          _selectedCategory != 'All' ||
          _selectedStatus != 'All';
      return _buildEmptyFallback(isFiltering: isFiltering);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildFoodItemCard(items[i]),
    );
  }

  Widget _buildEmptyFallback({required bool isFiltering}) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: FallbackMessage(
        icon: isFiltering ? Icons.search_off : Icons.fastfood_outlined,
        title: isFiltering ? 'No Matching Food Items' : 'No Food Items',
        description: isFiltering
            ? 'No food items match your current search or filter criteria.'
            : 'You haven\'t added any food items yet.',
      ),
    );
  }

  Widget _buildFoodItemCard(Map<String, dynamic> item) {
    final name = item['name'] as String? ?? 'Unnamed Item';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final prep =
        item['preparation_time'] as int? ??
        (item['prepTime'] != null
            ? int.tryParse(item['prepTime'].toString())
            : null);
    final prepStr = prep != null
        ? '$prep mins'
        : (item['prepTime']?.toString() ?? 'N/A');
    final imageUrl = item['image_url'] as String?;
    final isAvailable = item['is_available'] as bool? ?? true;
    final icon = item['icon'] as IconData? ?? Icons.fastfood_outlined;
    final categories = _extractCategories(item);
    final states = _extractStates(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToEditFood(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFEEEEEE),
                          width: 0.8,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13.2),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                height: 72,
                                width: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      icon,
                                      color: const Color(0xFFFFA07A),
                                      size: 32,
                                    ),
                                loadingBuilder: (_, child, p) => p == null
                                    ? child
                                    : const Center(
                                        child: SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFFFA07A),
                                          ),
                                        ),
                                      ),
                              )
                            : Icon(
                                icon,
                                color: const Color(0xFFFFA07A),
                                size: 32,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xDD000000),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Transform.scale(
                                scale: 0.75,
                                alignment: Alignment.centerRight,
                                child: Switch(
                                  value: isAvailable,
                                  activeThumbColor: const Color(0xFF10B981),
                                  activeTrackColor: const Color(0xFFA7F3D0),
                                  inactiveThumbColor: const Color(0xFF9CA3AF),
                                  inactiveTrackColor: const Color(0xFFE5E7EB),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (val) =>
                                      _toggleFoodAvailability(item, val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'RM ${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFA07A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '•',
                                style: TextStyle(color: Color(0xFFBDBDBD)),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.schedule,
                                size: 13,
                                color: Color(0xFF9E9E9E),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                prepStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF757575),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 10),
                if (categories.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        size: 14,
                        color: Color(0xFF9E9E9E),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Category: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF757575),
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            ...categories
                                .take(2)
                                .map(
                                  (cat) => _buildTagChip(
                                    label: cat,
                                    bgColor: const Color(0xFFFFF1EB),
                                    textColor: const Color(0xFFE05638),
                                    borderColor: const Color(0xFFFFD8CC),
                                  ),
                                ),
                            if (categories.length > 2)
                              _buildMoreBadge(
                                '+${categories.length - 2} more',
                                onTap: () => _showAllItemsSheet(
                                  'Categories',
                                  categories,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF9E9E9E),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'States: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF757575),
                      ),
                    ),
                    Expanded(
                      child: states.isEmpty
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: _buildTagChip(
                                label: 'All States',
                                icon: Icons.public,
                                bgColor: const Color(0xFFEDF7ED),
                                textColor: const Color(0xFF16A34A),
                                borderColor: const Color(0xFFBBF7D0),
                              ),
                            )
                          : Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                ...states
                                    .take(2)
                                    .map(
                                      (state) => _buildTagChip(
                                        label: state,
                                        bgColor: const Color(0xFFF3F4F6),
                                        textColor: const Color(0xFF374151),
                                        borderColor: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                if (states.length > 2)
                                  _buildMoreBadge(
                                    '+${states.length - 2} more',
                                    onTap: () => _showAllItemsSheet(
                                      'Exclusive States',
                                      states,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip({
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreBadge(String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 0.8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class FoodFilterSheet extends StatefulWidget {
  final String initialSort;
  final String initialCategory;
  final String initialStatus;
  final List<String> sortOptions;
  final List<String> categoryOptions;
  final List<String> statusOptions;

  const FoodFilterSheet({
    super.key,
    required this.initialSort,
    required this.initialCategory,
    required this.initialStatus,
    required this.sortOptions,
    required this.categoryOptions,
    required this.statusOptions,
  });

  @override
  State<FoodFilterSheet> createState() => _FoodFilterSheetState();
}

class _FoodFilterSheetState extends State<FoodFilterSheet> {
  late String _tempSort;
  late String _tempCategory;
  late String _tempStatus;

  @override
  void initState() {
    super.initState();
    _tempSort = widget.initialSort;
    _tempCategory = widget.initialCategory;
    _tempStatus = widget.initialStatus;
  }

  void _clearFilters() {
    Navigator.pop(context, {
      'sort': 'Newest Added',
      'category': 'All',
      'status': 'All',
    });
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'sort': _tempSort,
      'category': _tempCategory,
      'status': _tempStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildDragHandle()),
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSortSection(),
              const SizedBox(height: 24),
              _buildChipSection(
                title: 'Category',
                options: widget.categoryOptions,
                selectedOption: _tempCategory,
                onSelected: (val) => setState(() => _tempCategory = val),
              ),
              const SizedBox(height: 24),
              _buildChipSection(
                title: 'Status',
                options: widget.statusOptions,
                selectedOption: _tempStatus,
                onSelected: (val) => setState(() => _tempStatus = val),
              ),
              const SizedBox(height: 32),
              _buildApplyButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Filter & Sort',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xDD000000),
          ),
        ),
        TextButton(
          onPressed: _clearFilters,
          child: const Text(
            'Clear',
            style: TextStyle(
              color: Color(0xFFE53935),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xDD000000),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _tempSort,
              isExpanded: true,
              items: widget.sortOptions
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        v,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xDD000000),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (nv) {
                if (nv != null) setState(() => _tempSort = nv);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipSection({
    required String title,
    required List<String> options,
    required String selectedOption,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xDD000000),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSel = selectedOption == opt;
            return ChoiceChip(
              label: Text(
                opt,
                style: TextStyle(
                  color: isSel ? Colors.white : const Color(0xDD000000),
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              selected: isSel,
              selectedColor: const Color(0xFFFFA07A),
              backgroundColor: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSel ? const Color(0xFFFFA07A) : Colors.transparent,
                ),
              ),
              onSelected: (_) => onSelected(opt),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _applyFilters,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFA07A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Apply Filters',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
