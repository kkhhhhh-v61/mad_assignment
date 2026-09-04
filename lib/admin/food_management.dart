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
  List<Map<String, dynamic>> _foodItems = [];
  final Set<String> _expandedItemIds = {};
  bool _isLoading = true;

  String _selectedSort = 'Newest Added';
  final List<String> _sortOptions = [
    'Newest Added',
    'Alphabetically',
    'Price Low to High',
    'Price High to Low',
    'Preparation Time',
  ];

  late final TextEditingController _searchController;
  String _searchQuery = '';

  String _selectedCategory = 'All';
  List<String> get _categoryOptions {
    final set = <String>{'All'};
    for (final item in _foodItems) {
      set.addAll(_extractCategories(item));
    }
    return set.toList();
  }

  String _selectedStatus = 'All';
  final List<String> _statusOptions = [
    'All',
    'Available',
    'Unavailable',
  ];

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
      List<dynamic> response;
      try {
        response = await supabase.from('food_items').select('''
          *,
          food_item_categories(food_categories(id, name)),
          food_item_states(states(id, name))
        ''').order('created_at', ascending: false);
      } catch (_) {
        response = await supabase
            .from('food_items')
            .select()
            .order('created_at', ascending: false);
      }

      if (mounted) {
        setState(() {
          _foodItems = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> _extractCategories(Map<String, dynamic> item) {
    final rawList = item['food_item_categories'] as List<dynamic>?;
    if (rawList == null) return [];
    final categories = <String>[];
    for (final entry in rawList) {
      if (entry is Map<String, dynamic>) {
        final cat = entry['food_categories'] as Map<String, dynamic>?;
        if (cat != null && cat['name'] != null) {
          categories.add(cat['name'].toString());
        }
      }
    }
    return categories;
  }

  List<String> _extractStates(Map<String, dynamic> item) {
    final rawList = item['food_item_states'] as List<dynamic>?;
    if (rawList == null) return [];
    final states = <String>[];
    for (final entry in rawList) {
      if (entry is Map<String, dynamic>) {
        final state = entry['states'] as Map<String, dynamic>?;
        if (state != null && state['name'] != null) {
          states.add(state['name'].toString());
        }
      }
    }
    return states;
  }

  Future<void> _navigateToAddFood() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FoodCreation(),
      ),
    );

    if (result == true) {
      _fetchFoodItems();
    }
  }

  Future<void> _navigateToEditFood(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminFoodEdit(item: item),
      ),
    );

    if (result == true) {
      _fetchFoodItems();
    }
  }

  Future<void> _deleteFoodItem(Map<String, dynamic> item) async {
    Navigator.pop(context); // Close confirmation modal

    setState(() {
      _isLoading = true;
    });

    try {
      final foodId = item['id'];
      final foodName = item['name']?.toString() ?? 'Food item';

      // Delete storage image if present
      final imageUrl = item['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(imageUrl);
          final segments = uri.pathSegments;
          final bucketIndex = segments.indexOf('food-images');
          if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
            final pathInBucket = segments.sublist(bucketIndex + 1).join('/');
            await supabase.storage.from('food-images').remove([pathInBucket]);
          }
        } catch (_) {}
      }

      // Delete junction and related child records
      await supabase
          .from('food_item_categories')
          .delete()
          .eq('food_id', foodId);
      await supabase
          .from('food_item_states')
          .delete()
          .eq('food_id', foodId);

      // Delete the food item
      await supabase.from('food_items').delete().eq('id', foodId);

      _expandedItemIds.remove(foodId.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$foodName deleted successfully!'),
            backgroundColor: const Color.fromARGB(255, 76, 175, 80),
          ),
        );
      }

      await _fetchFoodItems();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete food item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmModal(Map<String, dynamic> item) {
    final foodName = item['name']?.toString() ?? 'this food item';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(),
                const SizedBox(height: 20.0),
                Container(
                  height: 56,
                  width: 56,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 255, 235, 238),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color.fromARGB(255, 229, 57, 53),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Delete Food Item?',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 0, 0, 0),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Are you sure you want to delete "$foodName"? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
                const SizedBox(height: 24.0),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(modalContext),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color.fromARGB(255, 224, 224, 224),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(221, 0, 0, 0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _deleteFoodItem(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 229, 57, 53),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query.trim();
              });
            },
            onSearchClear: () {
              setState(() {
                _searchQuery = '';
              });
            },
            searchHint: 'Search food items...',
            onFilterTap: _showFilterModal,
          ),
          Expanded(
            child: RefreshIndicator(
              color: const Color.fromARGB(255, 255, 160, 122),
              onRefresh: _fetchFoodItems,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20.0),
                    _buildFoodList(),
                    const SizedBox(height: 80.0), // Padding for FAB
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
      backgroundColor: const Color.fromARGB(255, 255, 160, 122),
      elevation: 3,
      onPressed: _navigateToAddFood,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  Widget _buildFoodList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60.0),
        child: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 255, 160, 122),
          ),
        ),
      );
    }

    if (_foodItems.isEmpty) {
      return _buildEmptyFallback();
    }

    final filteredItems = _foodItems.where((item) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (item['name']?.toString() ?? '').toLowerCase();
        final categories = _extractCategories(item)
            .map((c) => c.toLowerCase())
            .toList();
        final states = _extractStates(item)
            .map((s) => s.toLowerCase())
            .toList();

        final matchesName = name.contains(query);
        final matchesCat = categories.any((c) => c.contains(query));
        final matchesState = states.any((s) => s.contains(query));

        if (!matchesName && !matchesCat && !matchesState) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'All') {
        final categories = _extractCategories(item);
        final hasCat = categories.any(
          (c) => c.trim().toLowerCase() == _selectedCategory.trim().toLowerCase(),
        );
        if (!hasCat) return false;
      }

      // Status filter
      if (_selectedStatus != 'All') {
        final isAvailable = item['is_available'] as bool? ?? true;
        if (_selectedStatus == 'Available' && !isAvailable) {
          return false;
        }
        if (_selectedStatus == 'Unavailable' && isAvailable) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort options
    if (_selectedSort == 'Alphabetically') {
      filteredItems.sort((a, b) => (a['name']?.toString() ?? '')
          .toLowerCase()
          .compareTo((b['name']?.toString() ?? '').toLowerCase()));
    } else if (_selectedSort == 'Price Low to High') {
      filteredItems.sort((a, b) =>
          ((a['price'] as num?) ?? 0).compareTo((b['price'] as num?) ?? 0));
    } else if (_selectedSort == 'Price High to Low') {
      filteredItems.sort((a, b) =>
          ((b['price'] as num?) ?? 0).compareTo((a['price'] as num?) ?? 0));
    } else if (_selectedSort == 'Preparation Time') {
      filteredItems.sort((a, b) {
        final prepA = (a['preparation_time'] as num?)?.toInt() ??
            int.tryParse(a['prepTime']
                    ?.toString()
                    .replaceAll(RegExp(r'[^0-9]'), '') ??
                '') ??
            0;
        final prepB = (b['preparation_time'] as num?)?.toInt() ??
            int.tryParse(b['prepTime']
                    ?.toString()
                    .replaceAll(RegExp(r'[^0-9]'), '') ??
                '') ??
            0;
        return prepA.compareTo(prepB);
      });
    } else {
      // 'Newest Added' or default
      filteredItems.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(1970);
        final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(1970);
        return dateB.compareTo(dateA);
      });
    }

    if (filteredItems.isEmpty) {
      final isSearchingOrFiltering = _searchQuery.isNotEmpty ||
          _selectedCategory != 'All' ||
          _selectedStatus != 'All';
      return Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: FallbackMessage(
          icon: isSearchingOrFiltering
              ? Icons.search_off
              : Icons.fastfood_outlined,
          title: isSearchingOrFiltering
              ? 'No Matching Food Items'
              : 'No Food Items',
          description: isSearchingOrFiltering
              ? 'No food items match your current search or filter criteria.'
              : 'You haven\'t added any food items yet.',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return _buildFoodItemCard(filteredItems[index]);
      },
    );
  }

  Widget _buildEmptyFallback() {
    return const Padding(
      padding: EdgeInsets.only(top: 40.0),
      child: FallbackMessage(
        icon: Icons.fastfood_outlined,
        title: 'No Food Items',
        description: 'You haven\'t added any food items yet.',
      ),
    );
  }

  Widget _buildFoodItemCard(Map<String, dynamic> item) {
    final String id = item['id']?.toString() ?? '';
    final bool isExpanded = _expandedItemIds.contains(id);

    final String name = item['name'] as String? ?? 'Unnamed Item';
    final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final int? prepTime = item['preparation_time'] as int? ??
        (item['prepTime'] != null
            ? int.tryParse(item['prepTime'].toString())
            : null);
    final String prepTimeStr =
        prepTime != null ? '$prepTime mins' : (item['prepTime']?.toString() ?? 'N/A');
    final String? imageUrl = item['image_url'] as String?;
    final bool isAvailable = item['is_available'] as bool? ?? true;
    final IconData icon = item['icon'] as IconData? ?? Icons.fastfood_outlined;

    final categories = _extractCategories(item);
    final states = _extractStates(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(15, 0, 0, 0),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedItemIds.remove(id);
            } else {
              _expandedItemIds.add(id);
            }
          });
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 245, 245, 245),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  icon,
                                  color: const Color.fromARGB(255, 158, 158, 158),
                                  size: 40,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(255, 255, 160, 122),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Icon(
                              icon,
                              color: const Color.fromARGB(255, 158, 158, 158),
                              size: 40,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(221, 0, 0, 0),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Color.fromARGB(255, 158, 158, 158),
                              size: 16,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              prepTimeStr,
                              style: const TextStyle(
                                fontSize: 13.0,
                                color: Color.fromARGB(255, 117, 117, 117),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            Text(
                              'RM ${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 255, 160, 122),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? const Color.fromARGB(255, 237, 247, 237)
                                    : const Color.fromARGB(255, 245, 245, 245),
                                borderRadius: BorderRadius.circular(6.0),
                                border: Border.all(
                                  color: isAvailable
                                      ? const Color.fromARGB(255, 200, 230, 201)
                                      : const Color.fromARGB(255, 224, 224, 224),
                                ),
                              ),
                              child: Text(
                                isAvailable ? 'Available' : 'Unavailable',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  color: isAvailable
                                      ? const Color.fromARGB(255, 46, 125, 50)
                                      : const Color.fromARGB(255, 158, 158, 158),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (categories.isNotEmpty) ...[
                          const SizedBox(height: 6.0),
                          Wrap(
                            spacing: 4.0,
                            runSpacing: 4.0,
                            children: categories.map((cat) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 255, 245, 240),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Text(
                                  cat,
                                  style: const TextStyle(
                                    fontSize: 11.0,
                                    color: Color.fromARGB(255, 255, 127, 80),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        height: 32,
                        width: 32,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 245, 245, 245),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color.fromARGB(255, 117, 117, 117),
                            size: 16,
                          ),
                          onPressed: () => _navigateToEditFood(item),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        height: 32,
                        width: 32,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 255, 235, 238),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color.fromARGB(255, 229, 57, 53),
                            size: 16,
                          ),
                          onPressed: () => _showDeleteConfirmModal(item),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? const Color.fromARGB(255, 255, 245, 240)
                              : const Color.fromARGB(255, 245, 245, 245),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: isExpanded
                              ? const Color.fromARGB(255, 255, 160, 122)
                              : const Color.fromARGB(255, 158, 158, 158),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 14.0),
                const Divider(
                  height: 1.0,
                  color: Color.fromARGB(255, 240, 240, 240),
                ),
                const SizedBox(height: 12.0),
                _buildAccordionContent(
                  states: states,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccordionContent({
    required List<String> states,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 15.0,
              color: Color.fromARGB(255, 255, 160, 122),
            ),
            const SizedBox(width: 6.0),
            const Text(
              'Exclusive States',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(221, 0, 0, 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Padding(
          padding: const EdgeInsets.only(left: 21.0),
          child: states.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 237, 247, 237),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: const Color.fromARGB(255, 200, 230, 201),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public,
                        size: 13.0,
                        color: Color.fromARGB(255, 46, 125, 50),
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        'All States (Nationwide)',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Color.fromARGB(255, 46, 125, 50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: states.map((state) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 245, 245, 245),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: const Color.fromARGB(255, 230, 230, 230),
                        ),
                      ),
                      child: Text(
                        state,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Color.fromARGB(221, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 224, 224, 224),
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }

  void _showFilterModal() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext sheetContext) {
        return FoodFilterSheet(
          initialSort: _selectedSort,
          initialCategory: _selectedCategory,
          initialStatus: _selectedStatus,
          sortOptions: _sortOptions,
          categoryOptions: _categoryOptions,
          statusOptions: _statusOptions,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedSort = result['sort'] ?? 'Newest Added';
        _selectedCategory = result['category'] ?? 'All';
        _selectedStatus = result['status'] ?? 'All';
      });
    }
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

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 224, 224, 224),
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.0),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildDragHandle()),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(221, 0, 0, 0),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'sort': 'Newest Added',
                        'category': 'All',
                        'status': 'All',
                      });
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: Color.fromARGB(255, 229, 57, 53),
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(221, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 245, 245, 245),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _tempSort,
                    isExpanded: true,
                    items: widget.sortOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 15.0,
                            color: Color.fromARGB(221, 0, 0, 0),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _tempSort = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(221, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: widget.categoryOptions.map((String category) {
                  final isSelected = _tempCategory == category;
                  return ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color.fromARGB(221, 0, 0, 0),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor:
                        const Color.fromARGB(255, 255, 160, 122),
                    backgroundColor:
                        const Color.fromARGB(255, 245, 245, 245),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(
                        color: isSelected
                            ? const Color.fromARGB(255, 255, 160, 122)
                            : Colors.transparent,
                      ),
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _tempCategory = category;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(221, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: widget.statusOptions.map((String status) {
                  final isSelected = _tempStatus == status;
                  return ChoiceChip(
                    label: Text(
                      status,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color.fromARGB(221, 0, 0, 0),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor:
                        const Color.fromARGB(255, 255, 160, 122),
                    backgroundColor:
                        const Color.fromARGB(255, 245, 245, 245),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(
                        color: isSelected
                            ? const Color.fromARGB(255, 255, 160, 122)
                            : Colors.transparent,
                      ),
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _tempStatus = status;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32.0),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'sort': _tempSort,
                      'category': _tempCategory,
                      'status': _tempStatus,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(255, 255, 160, 122),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
