import 'package:flutter/material.dart';

import '../global.dart';
import '../main.dart';
import '../services/states.dart';
import 'food_item_detail.dart';
import 'header.dart';

class CustomerMenu extends StatefulWidget {
  final String? initialCategory;
  final ValueChanged<String>? onCategoryChanged;

  const CustomerMenu({super.key, this.initialCategory, this.onCategoryChanged});

  @override
  State<CustomerMenu> createState() => _CustomerMenuState();
}

class _CustomerMenuState extends State<CustomerMenu> {
  String _selectedCategory = '';
  List<Map<String, dynamic>> _foodCategories = [];
  bool _isLoadingCategories = true;

  List<Map<String, dynamic>> _foodItems = [];
  bool _isLoadingFoodItems = true;

  String _currentState = CustomerHeader.cachedState;
  bool _isLoadingLocation = !CustomerHeader.hasCachedLocation;
  String _selectedSort = 'Popularity';
  final List<String> _sortOptions = [
    'Popularity',
    'Alphabetically',
    'Price Low to High',
    'Price High to Low',
    'Preparation Time',
  ];

  late final TextEditingController _searchController;
  String _searchQuery = '';
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? '';
    _searchController = TextEditingController();
    _minPriceController = TextEditingController();
    _maxPriceController = TextEditingController();
    _fetchCategories();
    _fetchFoodItems();
  }

  @override
  void didUpdateWidget(CustomerMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory && widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      List<dynamic> res;
      try {
        res = await supabase.from('food_categories').select().order('display_order', ascending: true);
      } catch (_) {
        res = await supabase.from('food_categories').select().order('name', ascending: true);
      }

      if (mounted) {
        setState(() {
          _foodCategories = List<Map<String, dynamic>>.from(res);
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchFoodItems() async {
    try {
      List<dynamic> res;
      try {
        res = await supabase.from('food_items').select('''
          *,
          food_item_categories(food_categories(id, name)),
          food_item_states(states(id, name))
        ''').eq('is_available', true).order('created_at', ascending: false);
      } catch (_) {
        res = await supabase.from('food_items').select().eq('is_available', true).order('created_at', ascending: false);
      }

      if (mounted) {
        setState(() {
          _foodItems = List<Map<String, dynamic>>.from(res);
          _isLoadingFoodItems = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFoodItems = false);
    }
  }

  List<String> _extractCategories(Map<String, dynamic> item) {
    final raw = item['food_item_categories'] as List<dynamic>?;
    if (raw != null && raw.isNotEmpty) {
      final cats = raw
          .whereType<Map<String, dynamic>>()
          .map((e) => (e['food_categories'] as Map<String, dynamic>?)?['name']?.toString())
          .whereType<String>()
          .toList();
      if (cats.isNotEmpty) return cats;
    }
    if (item['categories'] is List) {
      return (item['categories'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (item['category'] != null && item['category'].toString().isNotEmpty) {
      return [item['category'].toString()];
    }
    return const [];
  }

  List<String> _extractStates(Map<String, dynamic> item) {
    final raw = item['food_item_states'] as List<dynamic>?;
    if (raw != null && raw.isNotEmpty) {
      final states = raw
          .whereType<Map<String, dynamic>>()
          .map((e) => (e['states'] as Map<String, dynamic>?)?['name']?.toString())
          .whereType<String>()
          .toList();
      if (states.isNotEmpty) return states;
    }
    if (item['states'] is List) {
      return (item['states'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  Map<String, dynamic> _normalizeFoodItem(Map<String, dynamic> raw) {
    final categories = _extractCategories(raw);
    final states = _extractStates(raw);
    final prep = raw['preparation_time'] as int? ??
        (raw['prepTime'] != null ? int.tryParse(raw['prepTime'].toString()) : null);
    final prepStr = prep != null ? '$prep mins' : (raw['prepTime']?.toString() ?? '15 mins');

    return {
      ...raw,
      'name': raw['name']?.toString() ?? 'Unnamed Item',
      'price': (raw['price'] as num?)?.toDouble() ?? 0.0,
      'prepTime': prepStr,
      'category': categories.isNotEmpty ? categories.join(', ') : 'Special',
      'categories': categories,
      'exclusive_states': states,
      'icon': raw['icon'] as IconData? ?? Icons.fastfood_outlined,
      'image_url': raw['image_url'] as String?,
      'description': raw['description']?.toString() ?? 'Freshly prepared and made to order.',
    };
  }

  List<Map<String, dynamic>> _filterAndSortFoodItems() {
    final items = _foodItems.map(_normalizeFoodItem).where((item) {
      final isAvailable = item['is_available'] as bool? ?? true;
      if (!isAvailable) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (item['name']?.toString() ?? '').toLowerCase();
        final desc = (item['description']?.toString() ?? '').toLowerCase();
        final cats = (item['categories'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        final cat = (item['category']?.toString() ?? '').toLowerCase();
        if (!name.contains(q) && !desc.contains(q) && !cat.contains(q) && !cats.any((c) => c.contains(q))) {
          return false;
        }
      }

      if (_selectedCategory.isNotEmpty && _selectedCategory != 'All') {
        final List<String> categories =
            (item['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final hasCategory = categories.any((c) => c.trim().toLowerCase() == _selectedCategory.trim().toLowerCase());
        if (!hasCategory && (item['category']?.toString().toLowerCase() != _selectedCategory.toLowerCase())) {
          return false;
        }
      }

      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final minP = double.tryParse(_minPriceController.text.trim());
      if (minP != null && price < minP) return false;

      final maxP = double.tryParse(_maxPriceController.text.trim());
      if (maxP != null && price > maxP) return false;

      final exclusiveStates =
          (item['exclusive_states'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      if (exclusiveStates.isNotEmpty) {
        if (_currentState.isEmpty) return false;
        final matches = exclusiveStates.any(
          (s) => isSameState(s, _currentState),
        );
        if (!matches) return false;
      }

      return true;
    }).toList();

    if (_selectedSort == 'Alphabetically') {
      items.sort((a, b) => (a['name']?.toString() ?? '').toLowerCase().compareTo((b['name']?.toString() ?? '').toLowerCase()));
    } else if (_selectedSort == 'Price Low to High') {
      items.sort((a, b) => ((a['price'] as num?) ?? 0).compareTo((b['price'] as num?) ?? 0));
    } else if (_selectedSort == 'Price High to Low') {
      items.sort((a, b) => ((b['price'] as num?) ?? 0).compareTo((a['price'] as num?) ?? 0));
    } else if (_selectedSort == 'Preparation Time') {
      items.sort((a, b) {
        final pA = (a['preparation_time'] as num?)?.toInt() ?? int.tryParse(a['prepTime']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
        final pB = (b['preparation_time'] as num?)?.toInt() ?? int.tryParse(b['prepTime']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
        return pA.compareTo(pB);
      });
    }

    return items;
  }

  void _showFilterSheet() async {
    final res = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerMenuFilterSheet(
        initialSort: _selectedSort,
        initialMinPrice: _minPriceController.text,
        initialMaxPrice: _maxPriceController.text,
        sortOptions: _sortOptions,
      ),
    );

    if (res != null && mounted) {
      setState(() {
        _selectedSort = res['sort'] ?? 'Popularity';
        _minPriceController.text = res['minPrice'] ?? '';
        _maxPriceController.text = res['maxPrice'] ?? '';
      });
    }
  }

  void _onCategoryChipSelected(String name, bool selected) {
    setState(() {
      if (selected) {
        _selectedCategory = name == 'All' ? '' : name;
      } else if (name != 'All') {
        _selectedCategory = '';
      }
    });
    widget.onCategoryChanged?.call(_selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filterAndSortFoodItems();
    final bool isContentLoading = _isLoadingFoodItems || _isLoadingLocation;

    return Column(
      children: [
        CustomerHeader(
          showFilter: true,
          onFilterTap: _showFilterSheet,
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _searchQuery = v.trim()),
          onSearchClear: () => setState(() => _searchQuery = ''),
          searchHint: 'Search menu...',
          onLocationLoadingChanged: (loading) {
            if (_isLoadingLocation != loading) {
              setState(() {
                _isLoadingLocation = loading;
              });
            }
          },
          onLocationChanged: (address, state) {
            setState(() {
              _currentState = state;
              _isLoadingLocation = false;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildCategoryChips(),
        const SizedBox(height: 8),
        Expanded(
          child: isContentLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFA07A)))
              : RefreshIndicator(
                  color: const Color(0xFFFFA07A),
                  onRefresh: () async {
                    await Future.wait([_fetchCategories(), _fetchFoodItems()]);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: FoodItems(
                        foodItems: items,
                        emptyMessage: _searchQuery.isNotEmpty
                            ? 'No items found matching "$_searchQuery".'
                            : (_selectedCategory.isNotEmpty && _selectedCategory != 'All'
                                ? 'No items found in "$_selectedCategory".'
                                : 'There are no menu items available for your location right now.'),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 45,
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFA07A)),
          ),
        ),
      );
    }

    if (_foodCategories.isEmpty) {
      return const FallbackMessage(
        icon: Icons.category_outlined,
        title: 'No Categories',
        description: 'Categories are currently unavailable.',
      );
    }

    final chipNames = [
      'All',
      ..._foodCategories.map((c) => c['name']?.toString() ?? '').where((name) => name.isNotEmpty),
    ];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chipNames.length,
        itemBuilder: (_, i) {
          final name = chipNames[i];
          final isSelected = _selectedCategory == name || (_selectedCategory.isEmpty && name == 'All');

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xDD000000),
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (sel) => _onCategoryChipSelected(name, sel),
              selectedColor: const Color(0xFFFFA07A),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? const Color(0xFFFFA07A) : const Color(0xFFE0E0E0)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FoodItems extends StatelessWidget {
  final List<Map<String, dynamic>> foodItems;
  final String? emptyMessage;

  const FoodItems({super.key, required this.foodItems, this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (foodItems.isEmpty) {
      return FallbackMessage(
        icon: Icons.fastfood_outlined,
        title: 'No Items Found',
        description: emptyMessage ?? 'There are no menu items to display right now.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: foodItems.length,
      itemBuilder: (_, i) => FoodItemCard(item: foodItems[i]),
    );
  }
}

class FoodItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const FoodItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['name'] as String? ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final prepTime = item['prepTime'] as String? ?? '';
    final icon = (item['icon'] as IconData?) ?? Icons.fastfood_outlined;
    final imageUrl = item['image_url'] as String?;
    final exclusiveStates =
        (item['exclusive_states'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    void openDetail() => Navigator.push(context, MaterialPageRoute(builder: (_) => FoodItemDetail(item: item)));

    return GestureDetector(
      onTap: openDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, spreadRadius: 1, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(icon, color: const Color(0xFF9E9E9E), size: 40),
                      )
                    : Icon(icon, color: const Color(0xFF9E9E9E), size: 40),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xDD000000)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, color: Color(0xFF9E9E9E), size: 16),
                                const SizedBox(width: 4),
                                Text(prepTime, style: const TextStyle(fontSize: 13, color: Color(0xFF757575))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (exclusiveStates.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'State Exclusive: ${exclusiveStates.join(", ")}',
                          child: InkWell(
                            onTap: () => _showExclusiveStatesDialog(context, name, exclusiveStates),
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA07A).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFFA07A).withValues(alpha: 0.4)),
                              ),
                              child: const Center(
                                child: Icon(Icons.location_on, size: 17, color: Color(0xFFFFA07A)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RM ${price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFFA07A))),
                      Container(
                        height: 30,
                        width: 30,
                        decoration: const BoxDecoration(color: Color(0xFFFFA07A), shape: BoxShape.circle),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.add, color: Colors.white, size: 20),
                          onPressed: openDetail,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExclusiveStatesDialog(BuildContext context, String foodName, List<String> states) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA07A).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, color: Color(0xFFFFA07A), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'State Exclusive',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xDD000000),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              foodName.isNotEmpty
                  ? '$foodName is exclusively available in:'
                  : 'This item is exclusively available in:',
              style: const TextStyle(fontSize: 14, color: Color(0xFF616161), height: 1.4),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: states.map((state) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFC8B4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFFFFA07A)),
                      const SizedBox(width: 4),
                      Text(
                        state,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFA07A),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA07A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerMenuFilterSheet extends StatefulWidget {
  final String initialSort;
  final String initialMinPrice;
  final String initialMaxPrice;
  final List<String> sortOptions;

  const CustomerMenuFilterSheet({
    super.key,
    required this.initialSort,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.sortOptions,
  });

  @override
  State<CustomerMenuFilterSheet> createState() => _CustomerMenuFilterSheetState();
}

class _CustomerMenuFilterSheetState extends State<CustomerMenuFilterSheet> {
  late String _tempSort;
  late final TextEditingController _tempMinPriceController;
  late final TextEditingController _tempMaxPriceController;

  @override
  void initState() {
    super.initState();
    _tempSort = widget.initialSort;
    _tempMinPriceController = TextEditingController(text: widget.initialMinPrice);
    _tempMaxPriceController = TextEditingController(text: widget.initialMaxPrice);
  }

  @override
  void dispose() {
    _tempMinPriceController.dispose();
    _tempMaxPriceController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    Navigator.pop(context, {'sort': 'Popularity', 'minPrice': '', 'maxPrice': ''});
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'sort': _tempSort,
      'minPrice': _tempMinPriceController.text.trim(),
      'maxPrice': _tempMaxPriceController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              _buildPriceRangeSection(),
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
      decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Filter & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xDD000000))),
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Clear', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xDD000000))),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _tempSort,
              isExpanded: true,
              items: widget.sortOptions
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
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

  Widget _buildPriceInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixText: 'RM ',
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xDD000000))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPriceInput(_tempMinPriceController, 'Min')),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('-', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: _buildPriceInput(_tempMaxPriceController, 'Max')),
          ],
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
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
