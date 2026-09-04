import 'package:flutter/material.dart';

import '../global.dart';
import '../main.dart';
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
    if (widget.initialCategory != oldWidget.initialCategory &&
        widget.initialCategory != null) {
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
      List<dynamic> response;
      try {
        response = await supabase
            .from('food_categories')
            .select()
            .order('display_order', ascending: true);
      } catch (_) {
        response = await supabase
            .from('food_categories')
            .select()
            .order('name', ascending: true);
      }

      if (mounted) {
        setState(() {
          _foodCategories = List<Map<String, dynamic>>.from(response);
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
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
          _isLoadingFoodItems = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingFoodItems = false;
        });
      }
    }
  }

  List<String> _extractCategories(Map<String, dynamic> item) {
    final rawList = item['food_item_categories'] as List<dynamic>?;
    if (rawList != null && rawList.isNotEmpty) {
      final categories = <String>[];
      for (final entry in rawList) {
        if (entry is Map<String, dynamic>) {
          final cat = entry['food_categories'] as Map<String, dynamic>?;
          if (cat != null && cat['name'] != null) {
            categories.add(cat['name'].toString());
          }
        }
      }
      if (categories.isNotEmpty) return categories;
    }
    if (item['category'] != null && item['category'].toString().isNotEmpty) {
      return [item['category'].toString()];
    }
    return [];
  }

  Map<String, dynamic> _normalizeFoodItem(Map<String, dynamic> raw) {
    final categories = _extractCategories(raw);
    final categoryStr =
        categories.isNotEmpty ? categories.join(', ') : 'Special';

    final int? prepMinutes = raw['preparation_time'] as int? ??
        (raw['prepTime'] != null
            ? int.tryParse(raw['prepTime'].toString())
            : null);
    final String prepTimeStr = prepMinutes != null
        ? '$prepMinutes mins'
        : (raw['prepTime']?.toString() ?? '15 mins');

    final double priceVal = (raw['price'] as num?)?.toDouble() ?? 0.0;

    return {
      ...raw,
      'name': raw['name']?.toString() ?? 'Unnamed Item',
      'price': priceVal,
      'prepTime': prepTimeStr,
      'category': categoryStr,
      'categories': categories,
      'icon': raw['icon'] as IconData? ?? Icons.fastfood_outlined,
      'image_url': raw['image_url'] as String?,
      'description': raw['description']?.toString() ??
          'Freshly prepared and made to order.',
    };
  }

  void _showFilterOverlay() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return CustomerMenuFilterSheet(
          initialSort: _selectedSort,
          initialMinPrice: _minPriceController.text,
          initialMaxPrice: _maxPriceController.text,
          sortOptions: _sortOptions,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedSort = result['sort'] ?? 'Popularity';
        _minPriceController.text = result['minPrice'] ?? '';
        _maxPriceController.text = result['maxPrice'] ?? '';
      });
    }
  }

  Widget _buildCategoryChips() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 45,
        child: Center(
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

    final List<String> chipNames = [
      'All',
      ..._foodCategories
          .map((c) => c['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty),
    ];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: chipNames.length,
        itemBuilder: (context, index) {
          final String name = chipNames[index];
          final bool isSelected =
              _selectedCategory == name ||
              (_selectedCategory.isEmpty && name == 'All');

          return Container(
            margin: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(
                name,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : const Color.fromARGB(221, 0, 0, 0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedCategory = name == 'All' ? '' : name;
                  } else if (name != 'All') {
                    _selectedCategory = '';
                  }
                });
                widget.onCategoryChanged?.call(_selectedCategory);
              },
              selectedColor: const Color.fromARGB(255, 255, 160, 122),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedItems = _foodItems.map(_normalizeFoodItem).where((item) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (item['name']?.toString() ?? '').toLowerCase();
        final desc = (item['description']?.toString() ?? '').toLowerCase();
        final cats = (item['categories'] as List<dynamic>?)
                ?.map((e) => e.toString().toLowerCase())
                .toList() ??
            [];
        final cat = (item['category']?.toString() ?? '').toLowerCase();

        final matchesName = name.contains(query);
        final matchesDesc = desc.contains(query);
        final matchesCat =
            cat.contains(query) || cats.any((c) => c.contains(query));

        if (!matchesName && !matchesDesc && !matchesCat) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory.isNotEmpty && _selectedCategory != 'All') {
        final List<String> categories =
            (item['categories'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
        final hasCategory = categories.any(
          (c) =>
              c.trim().toLowerCase() == _selectedCategory.trim().toLowerCase(),
        );
        if (!hasCategory &&
            (item['category']?.toString().toLowerCase() !=
                _selectedCategory.toLowerCase())) {
          return false;
        }
      }

      // Price filter
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final minPrice = double.tryParse(_minPriceController.text.trim());
      if (minPrice != null && price < minPrice) return false;

      final maxPrice = double.tryParse(_maxPriceController.text.trim());
      if (maxPrice != null && price > maxPrice) return false;

      return true;
    }).toList();

    // Sort options
    if (_selectedSort == 'Alphabetically') {
      displayedItems.sort((a, b) => (a['name']?.toString() ?? '')
          .toLowerCase()
          .compareTo((b['name']?.toString() ?? '').toLowerCase()));
    } else if (_selectedSort == 'Price Low to High') {
      displayedItems.sort((a, b) =>
          ((a['price'] as num?) ?? 0).compareTo((b['price'] as num?) ?? 0));
    } else if (_selectedSort == 'Price High to Low') {
      displayedItems.sort((a, b) =>
          ((b['price'] as num?) ?? 0).compareTo((a['price'] as num?) ?? 0));
    } else if (_selectedSort == 'Preparation Time') {
      displayedItems.sort((a, b) {
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
    }

    return Column(
      children: [
        CustomerHeader(
          showFilter: true,
          onFilterTap: _showFilterOverlay,
          searchController: _searchController,
          onSearchChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
          onSearchClear: () {
            setState(() {
              _searchQuery = '';
            });
          },
          searchHint: 'Search menu...',
        ),
        const SizedBox(height: 16.0),
        _buildCategoryChips(),
        const SizedBox(height: 8.0),
        Expanded(
          child: _isLoadingFoodItems
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(255, 255, 160, 122),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color.fromARGB(255, 255, 160, 122),
                  onRefresh: () async {
                    await Future.wait([
                      _fetchCategories(),
                      _fetchFoodItems(),
                    ]);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: FoodItems(
                        foodItems: displayedItems,
                        emptyMessage: _searchQuery.isNotEmpty
                            ? 'No items found matching "$_searchQuery".'
                            : (_selectedCategory.isNotEmpty &&
                                    _selectedCategory != 'All'
                                ? 'No items found in "$_selectedCategory".'
                                : 'There are no menu items to display right now.'),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class FoodItems extends StatelessWidget {
  final List<Map<String, dynamic>> foodItems;
  final String? emptyMessage;

  const FoodItems({
    super.key,
    required this.foodItems,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (foodItems.isEmpty) {
      return FallbackMessage(
        icon: Icons.fastfood_outlined,
        title: 'No Items Found',
        description:
            emptyMessage ?? 'There are no menu items to display right now.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: foodItems.length,
      itemBuilder: (context, index) {
        return FoodItemCard(item: foodItems[index]);
      },
    );
  }
}

class FoodItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const FoodItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String name = item['name'] as String? ?? '';
    final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final String prepTime = item['prepTime'] as String? ?? '';
    final IconData icon =
        (item['icon'] as IconData?) ?? Icons.fastfood_outlined;
    final String? imageUrl = item['image_url'] as String?;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FoodItemDetail(item: item)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
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
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          icon,
                          color: const Color.fromARGB(255, 158, 158, 158),
                          size: 40,
                        ),
                      )
                    : Icon(
                        icon,
                        color: const Color.fromARGB(255, 158, 158, 158),
                        size: 40,
                      ),
              ),
            ),
            const SizedBox(width: 16.0),
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
                        prepTime,
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: Color.fromARGB(255, 117, 117, 117),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RM ${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 160, 122),
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 30,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 255, 160, 122),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FoodItemDetail(item: item),
                              ),
                            );
                          },
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
  State<CustomerMenuFilterSheet> createState() =>
      _CustomerMenuFilterSheetState();
}

class _CustomerMenuFilterSheetState extends State<CustomerMenuFilterSheet> {
  late String _tempSort;
  late final TextEditingController _tempMinPriceCtrl;
  late final TextEditingController _tempMaxPriceCtrl;

  @override
  void initState() {
    super.initState();
    _tempSort = widget.initialSort;
    _tempMinPriceCtrl = TextEditingController(text: widget.initialMinPrice);
    _tempMaxPriceCtrl = TextEditingController(text: widget.initialMaxPrice);
  }

  @override
  void dispose() {
    _tempMinPriceCtrl.dispose();
    _tempMaxPriceCtrl.dispose();
    super.dispose();
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
                        'sort': 'Popularity',
                        'minPrice': '',
                        'maxPrice': '',
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
                        child: Text(value),
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
                'Price Range',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(221, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tempMinPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        hintText: 'Min',
                        filled: true,
                        fillColor:
                            const Color.fromARGB(255, 245, 245, 245),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '-',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _tempMaxPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        hintText: 'Max',
                        filled: true,
                        fillColor:
                            const Color.fromARGB(255, 245, 245, 245),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32.0),
              SizedBox(
                width: double.infinity,
                height: 50.0,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'sort': _tempSort,
                      'minPrice': _tempMinPriceCtrl.text.trim(),
                      'maxPrice': _tempMaxPriceCtrl.text.trim(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(255, 255, 160, 122),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
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
