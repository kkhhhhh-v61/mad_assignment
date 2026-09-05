import 'dart:async';
import 'package:flutter/material.dart';

import '../main.dart';
import 'food_item_detail.dart';
import 'header.dart';
import 'main_navigation.dart';

class CustomerHome extends StatefulWidget {
  final ValueChanged<String>? onCategorySelected;
  final bool? initialIsLoggedIn;
  final List<Map<String, dynamic>>? initialRecentOrders;
  final List<Map<String, dynamic>>? initialBestSellers;

  const CustomerHome({
    super.key,
    this.onCategorySelected,
    this.initialIsLoggedIn,
    this.initialRecentOrders,
    this.initialBestSellers,
  });

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final PageController _bannerController = PageController();

  bool _isLoggedIn = false;
  List<Map<String, dynamic>> _recentOrderedItems = [];

  List<Map<String, dynamic>> _bestSellerItems = [];

  StreamSubscription? _authSubscription;

  static String? get _currentUserIdSafe {
    try {
      return supabase.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialIsLoggedIn != null) {
      _isLoggedIn = widget.initialIsLoggedIn!;
    } else {
      _checkAuth();
    }
    if (widget.initialRecentOrders != null) {
      _recentOrderedItems = widget.initialRecentOrders!;
    }
    if (widget.initialBestSellers != null) {
      _bestSellerItems = widget.initialBestSellers!;
    }
    if (widget.initialRecentOrders == null && widget.initialBestSellers == null) {
      _loadAllData();
      _setupAuthListener();
    }
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    try {
      _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
        final newUserId = data.session?.user.id;
        final nowLoggedIn = newUserId != null && newUserId.isNotEmpty;
        if (nowLoggedIn != _isLoggedIn && mounted) {
          setState(() {
            _isLoggedIn = nowLoggedIn;
          });
          _fetchRecentOrders();
        }
      });
    } catch (_) {}
  }

  void _checkAuth() {
    final uid = _currentUserIdSafe;
    _isLoggedIn = uid != null && uid.isNotEmpty;
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchRecentOrders(),
      _fetchBestSellers(),
    ]);
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
      return (item['categories'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
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
      return (item['states'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
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
      'id': raw['id']?.toString(),
      'name': raw['name']?.toString() ?? 'Unnamed Item',
      'price': (raw['price'] as num?)?.toDouble() ?? 0.0,
      'prepTime': prepStr,
      'category': categories.isNotEmpty ? categories.join(', ') : 'Special',
      'categories': categories,
      'exclusive_states': states,
      'icon': raw['icon'] as IconData? ?? Icons.fastfood_outlined,
      'image_url': raw['image_url'] as String?,
      'description': raw['description']?.toString() ?? 'Freshly prepared and made to order.',
      'is_available': raw['is_available'] as bool? ?? true,
    };
  }

  Future<void> _fetchRecentOrders() async {
    final userId = _currentUserIdSafe;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _recentOrderedItems = [];
        });
      }
      return;
    }

    try {
      final ordersRes = await supabase
          .from('orders')
          .select('id, created_at, order_items(food_id, name, quantity, unit_price_sen)')
          .eq('customer_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      final List<String> recentFoodIds = [];
      for (final order in ordersRes) {
        final rawItems = order['order_items'] as List<dynamic>? ?? [];
        for (final item in rawItems) {
          final fid = item['food_id']?.toString();
          if (fid != null && fid.isNotEmpty && !recentFoodIds.contains(fid)) {
            recentFoodIds.add(fid);
          }
        }
      }

      if (recentFoodIds.isEmpty) {
        if (mounted) {
          setState(() {
            _recentOrderedItems = [];
          });
        }
        return;
      }

      final foodRes = await supabase
          .from('food_items')
          .select('''
            *,
            food_item_categories(food_categories(id, name)),
            food_item_states(states(id, name))
          ''')
          .inFilter('id', recentFoodIds)
          .eq('is_available', true);

      final Map<String, Map<String, dynamic>> byId = {};
      for (final item in foodRes) {
        final id = item['id']?.toString();
        if (id != null) {
          byId[id] = _normalizeFoodItem(Map<String, dynamic>.from(item));
        }
      }

      final List<Map<String, dynamic>> recentList = [];
      for (final id in recentFoodIds) {
        if (byId.containsKey(id)) {
          recentList.add(byId[id]!);
        }
      }

      if (mounted) {
        setState(() {
          _recentOrderedItems = recentList;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchBestSellers() async {
    try {
      List<Map<String, dynamic>> top3Items = [];

      // 1. Try get_best_sellers RPC if installed
      try {
        final rpcRes = await supabase.rpc('get_best_sellers', params: {'limit_count': 3});
        if (rpcRes is List && rpcRes.isNotEmpty) {
          final topIds = rpcRes.map((e) => e['id']?.toString()).whereType<String>().toList();
          if (topIds.isNotEmpty) {
            final fullRes = await supabase
                .from('food_items')
                .select('''
                  *,
                  food_item_categories(food_categories(id, name)),
                  food_item_states(states(id, name))
                ''')
                .inFilter('id', topIds)
                .eq('is_available', true);

            final Map<String, Map<String, dynamic>> byId = {};
            for (final item in fullRes) {
              final id = item['id']?.toString();
              if (id != null) byId[id] = _normalizeFoodItem(Map<String, dynamic>.from(item));
            }

            for (final id in topIds) {
              if (byId.containsKey(id)) top3Items.add(byId[id]!);
            }
          }
        }
      } catch (_) {}

      // 2. Aggregate order_items if RPC was not available
      if (top3Items.isEmpty) {
        try {
          final orderItemsRes = await supabase
              .from('order_items')
              .select('food_id, quantity, line_total_sen');

          if (orderItemsRes.isNotEmpty) {
            final Map<String, int> qtyMap = {};
            for (final row in orderItemsRes) {
              final fid = row['food_id']?.toString();
              final qty = (row['quantity'] as num?)?.toInt() ?? 1;
              if (fid != null && fid.isNotEmpty) {
                qtyMap[fid] = (qtyMap[fid] ?? 0) + qty;
              }
            }

            final sortedFids = qtyMap.keys.toList()
              ..sort((a, b) => qtyMap[b]!.compareTo(qtyMap[a]!));
            final topIds = sortedFids.take(3).toList();

            if (topIds.isNotEmpty) {
              final fullRes = await supabase
                  .from('food_items')
                  .select('''
                    *,
                    food_item_categories(food_categories(id, name)),
                    food_item_states(states(id, name))
                  ''')
                  .inFilter('id', topIds)
                  .eq('is_available', true);

              final Map<String, Map<String, dynamic>> byId = {};
              for (final item in fullRes) {
                final id = item['id']?.toString();
                if (id != null) byId[id] = _normalizeFoodItem(Map<String, dynamic>.from(item));
              }

              for (final id in topIds) {
                if (byId.containsKey(id)) top3Items.add(byId[id]!);
              }
            }
          }
        } catch (_) {}
      }

      // 3. Fallback to top available food items
      if (top3Items.isEmpty) {
        final fallbackRes = await supabase
            .from('food_items')
            .select('''
              *,
              food_item_categories(food_categories(id, name)),
              food_item_states(states(id, name))
            ''')
            .eq('is_available', true)
            .order('created_at', ascending: false)
            .limit(3);

        top3Items = (fallbackRes as List)
            .map((e) => _normalizeFoodItem(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (mounted) {
        setState(() {
          _bestSellerItems = top3Items.take(3).toList();
        });
      }
    } catch (_) {}
  }





  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CustomerHeader(showBrandTitle: true),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            color: const Color(0xFFFFA07A),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16.0),
                  _buildBannerCarousel(),
                  const SizedBox(height: 20.0),

                  // 1. Recently Ordered Section (Only when logged in AND has items)
                  if (_isLoggedIn && _recentOrderedItems.isNotEmpty) ...[
                    _buildRecentOrdersSection(),
                    const SizedBox(height: 24.0),
                  ],

                  // 2. Best Sellers Section (Up to three items based on order amount)
                  if (_bestSellerItems.isNotEmpty) ...[
                    _buildBestSellersSection(),
                    const SizedBox(height: 24.0),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: 1,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/banner_1.webp'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(25, 0, 0, 0),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- RECENT ORDERS SECTION ---
  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA07A).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFFFFA07A),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Recently Ordered',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xDD000000),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => CustomerMainNavigation.switchToTab(2),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFA07A),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View Orders',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Quickly reorder your past favorites',
            style: TextStyle(
              fontSize: 12.0,
              color: Color(0xFF757575),
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 205,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: _recentOrderedItems.length,
            itemBuilder: (context, index) {
              final item = _recentOrderedItems[index];
              return _buildRecentOrderItemCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrderItemCard(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = item['image_url']?.toString();
    final icon = (item['icon'] as IconData?) ?? Icons.fastfood_outlined;

    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 14.0, bottom: 6.0, top: 2.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FoodItemDetail(item: item)),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 95,
                      width: double.infinity,
                      color: const Color(0xFFFFF5F0),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                icon,
                                size: 36,
                                color: const Color(0xFFFFA07A),
                              ),
                            )
                          : Icon(
                              icon,
                              size: 36,
                              color: const Color(0xFFFFA07A),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: Color(0xFFFFA07A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xDD000000),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Price & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'RM ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFA07A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    height: 28,
                    width: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA07A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BEST SELLERS SECTION ---
  Widget _buildBestSellersSection() {
    final topItems = _bestSellerItems.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF9800),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Best Sellers',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xDD000000),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => CustomerMainNavigation.switchToTab(1),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFA07A),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              for (int i = 0; i < topItems.length; i++)
                _buildBestSellerCard(topItems[i], rank: i + 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBestSellerCard(Map<String, dynamic> item, {required int rank}) {
    final name = item['name']?.toString() ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final prepTime = item['prepTime']?.toString() ?? '15 mins';
    final category = item['category']?.toString() ?? 'Special';
    final imageUrl = item['image_url']?.toString();
    final icon = (item['icon'] as IconData?) ?? Icons.fastfood_outlined;

    // Rank badges styling
    Color rankBadgeBg;
    Color rankTextColor = Colors.white;
    String rankLabel = '#$rank';

    if (rank == 1) {
      rankBadgeBg = const Color(0xFFFFB300); // Gold
    } else if (rank == 2) {
      rankBadgeBg = const Color(0xFF78909C); // Silver
    } else {
      rankBadgeBg = const Color(0xFFB08D57); // Bronze
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rank == 1
              ? const Color(0xFFFFE0B2)
              : const Color(0xFFEEEEEE),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FoodItemDetail(item: item)),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image with Rank badge on top left
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 75,
                      width: 75,
                      color: const Color(0xFFFFF5F0),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                icon,
                                size: 30,
                                color: const Color(0xFFFFA07A),
                              ),
                            )
                          : Icon(
                              icon,
                              size: 30,
                              color: const Color(0xFFFFA07A),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rankBadgeBg,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        rankLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: rankTextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Item Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xDD000000),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.access_time, size: 12, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 2),
                        Text(
                          prepTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'RM ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFA07A),
                      ),
                    ),
                  ],
                ),
              ),
              // '+' Action button
              Container(
                height: 32,
                width: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFA07A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

