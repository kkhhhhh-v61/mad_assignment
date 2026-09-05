import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../services/states.dart';
import 'cart.dart';
import 'main_navigation.dart';
import 'notifications.dart';
import 'saved_addresses.dart';

class AddressOption {
  final String label;
  final String fullAddress;
  final String state;
  final double? latitude;
  final double? longitude;
  final bool isDetected;
  final bool isDefault;

  const AddressOption({
    required this.label,
    required this.fullAddress,
    required this.state,
    this.latitude,
    this.longitude,
    this.isDetected = false,
    this.isDefault = false,
  });
}

class CustomerHeader extends StatefulWidget {
  final bool showFilter;
  final bool showSearch;
  final bool showTitle;
  final String pageTitle;
  final bool showBrandTitle;
  final bool showActions;
  final VoidCallback? onFilterTap;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final String? searchHint;
  final void Function(String address, String state)? onLocationChanged;
  final ValueChanged<bool>? onLocationLoadingChanged;

  static String? get _currentUserIdSafe {
    try {
      return supabase.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  static bool get hasCachedLocation =>
      _CustomerHeaderState._hasLoaded &&
      _CustomerHeaderState._cachedSelectedOption != null &&
      _CustomerHeaderState._cachedUserId == _currentUserIdSafe;

  static String get cachedState =>
      _CustomerHeaderState._cachedSelectedOption?.state ?? '';

  static String get cachedAddress =>
      _CustomerHeaderState._cachedSelectedOption?.fullAddress ?? '';

  static List<String> get cachedSavedAddressStrings =>
      _CustomerHeaderState._cachedSavedAddresses
          ?.map((a) => a.fullAddress)
          .where((s) => s.isNotEmpty)
          .toList() ??
      [];

  static AddressOption? get cachedDetectedLocation =>
      _CustomerHeaderState._cachedDetectedLocation;

  static AddressOption? get cachedSelectedOption =>
      _CustomerHeaderState._cachedSelectedOption;

  static List<AddressOption>? get cachedSavedAddresses =>
      _CustomerHeaderState._cachedSavedAddresses;

  static void clearLocationCache() => _CustomerHeaderState.clearLocationCache();

  static void setPreloadedAddress(AddressOption option) =>
      _CustomerHeaderState.setPreloadedAddress(option);

  static void updateSelectedOption(AddressOption option) {
    _CustomerHeaderState._cachedSelectedOption = option;
    _CustomerHeaderState._cachedUserId = _currentUserIdSafe;
    _CustomerHeaderState._hasLoaded = true;
  }

  static Future<AddressOption> detectLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
          final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json&addressdetails=1',
          );
          final res = await http
              .get(url, headers: {'User-Agent': 'DoorDishApp/1.0'})
              .timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            final addr = data['address'] as Map<String, dynamic>?;
            final road =
                addr?['road'] ??
                addr?['suburb'] ??
                addr?['neighbourhood'] ??
                addr?['city'] ??
                'Current Location';
            final state = addr?['state']?.toString() ?? 'Penang';
            final resolvedState = extractStateFromAddress(state);
            return AddressOption(
              label: 'Current Location',
              fullAddress: '$road, $resolvedState',
              state: resolvedState,
              latitude: pos.latitude,
              longitude: pos.longitude,
              isDetected: true,
            );
          }
        }
      }
    } catch (_) {}

    return const AddressOption(
      label: 'Current Location',
      fullAddress: 'George Town, Penang',
      state: 'Pulau Pinang',
      isDetected: true,
    );
  }

  static Future<void> loadAddressesStatic() async {
    final userId = _currentUserIdSafe;
    if (userId == null) {
      final detected = await detectLocation();
      _CustomerHeaderState._cachedSelectedOption = detected;
      _CustomerHeaderState._cachedDetectedLocation = detected;
      _CustomerHeaderState._cachedSavedAddresses = const [];
      _CustomerHeaderState._cachedUserId = null;
      _CustomerHeaderState._hasLoaded = true;
      return;
    }

    AddressOption? defaultOption;
    final List<AddressOption> saved = [];

    final detectFuture = detectLocation();
    final profileFuture = supabase
        .from('profiles')
        .select('address, role')
        .eq('id', userId)
        .maybeSingle();
    final addressesFuture = supabase
        .from('user_addresses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final detected = await detectFuture;
    _CustomerHeaderState._cachedDetectedLocation = detected;

    try {
      final profileRes = await profileFuture;
      final profileAddr = profileRes?['address']?.toString();
      if (profileAddr != null && profileAddr.trim().isNotEmpty) {
        defaultOption = AddressOption(
          label: 'Default Address',
          fullAddress: profileAddr.trim(),
          state: extractStateFromAddress(profileAddr),
          isDefault: true,
        );
      }

      final otherRes = await addressesFuture;
      for (final row in otherRes) {
        final fullAddr = row['full_address']?.toString() ?? '';
        final lbl = row['label']?.toString() ?? 'Saved Address';
        if (fullAddr.isNotEmpty) {
          saved.add(
            AddressOption(
              label: lbl,
              fullAddress: fullAddr,
              state: extractStateFromAddress(fullAddr),
            ),
          );
        }
      }
    } catch (_) {}

    final initial =
        defaultOption ?? (saved.isNotEmpty ? saved.first : detected);
    final allSaved = [?defaultOption, ...saved];

    _CustomerHeaderState._cachedSelectedOption = initial;
    _CustomerHeaderState._cachedSavedAddresses = List<AddressOption>.from(allSaved);
    _CustomerHeaderState._cachedUserId = userId;
    _CustomerHeaderState._hasLoaded = true;
  }

  static Future<AddressOption?> showAddressPicker(
    BuildContext context, {
    AddressOption? currentOption,
  }) async {
    if (!_CustomerHeaderState._hasLoaded ||
        _CustomerHeaderState._cachedUserId != _currentUserIdSafe) {
      await loadAddressesStatic();
    }

    final detected = _CustomerHeaderState._cachedDetectedLocation;
    final savedAddresses = _CustomerHeaderState._cachedSavedAddresses ?? [];
    final activeOption = currentOption ?? _CustomerHeaderState._cachedSelectedOption;
    final isAuthenticated = _currentUserIdSafe != null;

    if (!context.mounted) return null;

    return await showModalBottomSheet<AddressOption>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Delivery Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xDD000000),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAddressOptionTile(
                  sheetContext,
                  detected ??
                      const AddressOption(
                        label: 'Current Location',
                        fullAddress: 'Current Location',
                        state: '',
                        isDetected: true,
                      ),
                  isSelected: activeOption?.isDetected == true ||
                      (detected != null &&
                          activeOption?.fullAddress == detected.fullAddress),
                  icon: Icons.my_location,
                ),
                if (!isAuthenticated) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFC8B4)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: Color(0xFFFFA07A),
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Log in to see your saved addresses',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xDD000000),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Save your favorite delivery addresses for faster ordering.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              CustomerMainNavigation.switchToTab(3);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA07A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Log In Now',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  if (savedAddresses.isNotEmpty) const Divider(height: 24),
                  ...savedAddresses.map(
                    (addr) => _buildAddressOptionTile(
                      sheetContext,
                      addr,
                      isSelected: activeOption?.fullAddress == addr.fullAddress,
                      icon: addr.isDefault
                          ? Icons.home_outlined
                          : Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await Navigator.push(
                        sheetContext,
                        MaterialPageRoute(
                          builder: (_) => const SavedAddressesScreen(),
                        ),
                      );
                      clearLocationCache();
                      await loadAddressesStatic();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_location_alt_outlined,
                            size: 18,
                            color: Color(0xFFFFA07A),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Manage Saved Addresses',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFA07A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildAddressOptionTile(
    BuildContext sheetContext,
    AddressOption option, {
    required bool isSelected,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        updateSelectedOption(option);
        Navigator.pop(sheetContext, option);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFC8B4)
                : const Color(0xFFEEEEEE),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? const Color(0xFFFFA07A)
                  : const Color(0xFF9E9E9E),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFFFFA07A)
                              : const Color(0xDD000000),
                        ),
                      ),
                      if (option.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFA07A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.fullAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                size: 18,
                color: Color(0xFFFFA07A),
              ),
          ],
        ),
      ),
    );
  }

  const CustomerHeader({
    super.key,
    this.showFilter = false,
    this.showSearch = true,
    this.showTitle = false,
    this.pageTitle = 'DoorDish',
    this.showBrandTitle = false,
    this.showActions = true,
    this.onFilterTap,
    this.searchController,
    this.onSearchChanged,
    this.onSearchClear,
    this.searchHint,
    this.onLocationChanged,
    this.onLocationLoadingChanged,
  });

  @override
  State<CustomerHeader> createState() => _CustomerHeaderState();
}

class _CustomerHeaderState extends State<CustomerHeader> {
  static AddressOption? _cachedSelectedOption;
  static AddressOption? _cachedDetectedLocation;
  static List<AddressOption>? _cachedSavedAddresses;
  static String? _cachedUserId;
  static bool _hasLoaded = false;

  static void clearLocationCache() {
    _cachedSelectedOption = null;
    _cachedDetectedLocation = null;
    _cachedSavedAddresses = null;
    _cachedUserId = null;
    _hasLoaded = false;
  }

  static void setPreloadedAddress(AddressOption option) {
    _cachedSelectedOption = option;
    _cachedDetectedLocation = option;
    _cachedSavedAddresses = [option];
    _cachedUserId = null;
    _hasLoaded = true;
  }

  AddressOption _selectedOption = const AddressOption(
    label: 'Current Location',
    fullAddress: 'George Town, Penang',
    state: 'Pulau Pinang',
    isDetected: true,
  );
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    final currentUserId = CustomerHeader._currentUserIdSafe;
    final bool authChanged = currentUserId != _cachedUserId;

    if (_hasLoaded && !authChanged && _cachedSelectedOption != null) {
      _selectedOption = _cachedSelectedOption!;
      _isLoadingLocation = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onLocationChanged?.call(
            _selectedOption.fullAddress,
            _selectedOption.state,
          );
          widget.onLocationLoadingChanged?.call(false);
        }
      });
    } else {
      _loadAddresses();
    }
  }

  Future<void> _loadAddresses() async {
    widget.onLocationLoadingChanged?.call(true);

    try {
      await _loadAddressesInternal().timeout(const Duration(seconds: 5));
    } catch (_) {
      const fallback = AddressOption(
        label: 'Current Location',
        fullAddress: 'George Town, Penang',
        state: 'Pulau Pinang',
        isDetected: true,
      );
      _cachedSelectedOption = fallback;
      _cachedDetectedLocation = fallback;
      _cachedSavedAddresses = const [];
      _cachedUserId = CustomerHeader._currentUserIdSafe;
      _hasLoaded = true;
      if (mounted) {
        setState(() {
          _selectedOption = fallback;
          _isLoadingLocation = false;
        });
        widget.onLocationChanged?.call(fallback.fullAddress, fallback.state);
        widget.onLocationLoadingChanged?.call(false);
      }
    }
  }

  Future<void> _loadAddressesInternal() async {
    await CustomerHeader.loadAddressesStatic();
    final initial = CustomerHeader.cachedSelectedOption ??
        const AddressOption(
          label: 'Current Location',
          fullAddress: 'George Town, Penang',
          state: 'Pulau Pinang',
          isDetected: true,
        );

    if (mounted) {
      setState(() {
        _selectedOption = initial;
        _isLoadingLocation = false;
      });
      widget.onLocationChanged?.call(initial.fullAddress, initial.state);
      widget.onLocationLoadingChanged?.call(false);
    }
  }

  void _selectAddress(AddressOption option) {
    setState(() {
      _selectedOption = option;
      _cachedSelectedOption = option;
    });
    widget.onLocationChanged?.call(option.fullAddress, option.state);
  }


  Future<void> _showAddressSheet() async {
    if (_isLoadingLocation) return;
    final selected = await CustomerHeader.showAddressPicker(
      context,
      currentOption: _selectedOption,
    );
    if (selected != null && mounted) {
      _selectAddress(selected);
    }
  }

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
                child: widget.showBrandTitle
                    ? Row(
                        children: [
                          const Text(
                            'Door',
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: Colors.black,
                            ),
                          ),
                          const Text(
                            'Dish',
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: Color(0xFFFFA07A),
                            ),
                          ),
                        ],
                       )
                     : (widget.showTitle
                           ? Text(
                               widget.pageTitle,
                               style: const TextStyle(
                                 fontSize: 22.0,
                                 fontWeight: FontWeight.bold,
                                 color: Color.fromARGB(221, 0, 0, 0),
                               ),
                             )
                           : _buildLocationSelector()),
              ),
              if (widget.showActions) const HeaderActionButtons(),
            ],
          ),
          if (widget.showSearch || widget.showFilter) ...[
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: widget.showSearch
                      ? HeaderSearchBar(
                    controller: widget.searchController,
                    onChanged: widget.onSearchChanged,
                    onClear: widget.onSearchClear,
                    hintText: widget.searchHint ?? 'Search...',
                  )
                      : const SizedBox.shrink(),
                ),
                if (widget.showFilter) const SizedBox(width: 12.0),
                if (widget.showFilter)
                  HeaderFilterButton(onFilterTap: widget.onFilterTap),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return InkWell(
      onTap: _isLoadingLocation ? null : _showAddressSheet,
      borderRadius: BorderRadius.circular(10),
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
            children: [
              Flexible(
                child: Text(
                  _isLoadingLocation
                      ? 'Detecting location...'
                      : _selectedOption.fullAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                    color: Color(0xDD000000),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _isLoadingLocation
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
              )
                  : const Icon(
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
}

class HeaderActionButtons extends StatefulWidget {
  const HeaderActionButtons({super.key});

  @override
  State<HeaderActionButtons> createState() => _HeaderActionButtonsState();
}

class _HeaderActionButtonsState extends State<HeaderActionButtons> {
  bool _hasUnreadNotifications = false;
  RealtimeChannel? _notificationChannel;
  @override
  void initState() {
    super.initState();
    _checkUnreadNotifications();
    _setupRealtimeSubscription();
    CartStorage.updateCartCount();
  }

  Future<void> _checkUnreadNotifications() async {
    final userId = CustomerHeader._currentUserIdSafe;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          _hasUnreadNotifications = (response as List).isNotEmpty;
        });
      }
    } catch (e) {
      // Ignored
    }
  }

  void _setupRealtimeSubscription() {
    final userId = CustomerHeader._currentUserIdSafe;
    if (userId == null) return;

    try {
      _notificationChannel = supabase
          .channel('public:notifications')
          .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          if (mounted) {
            setState(() {
              _hasUnreadNotifications = true;
            });
          }
        },
      )
          .subscribe();
    } catch (_) {}
  }

  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeaderIconWithBadge(
          icon: Icons.notifications_outlined,
          showBadge: _hasUnreadNotifications,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomerNotifications(),
              ),
            );
            _checkUnreadNotifications();
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: CartStorage.cartCountNotifier,
          builder: (context, cartCount, _) {
            return HeaderIconWithBadge(
              icon: Icons.shopping_cart_outlined,
              showBadge: cartCount > 0,
              badgeCount: cartCount,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerCart()),
                );
                CartStorage.updateCartCount();
              },
            );
          },
        ),
      ],
    );
  }
}

class HeaderIconWithBadge extends StatelessWidget {
  final IconData icon;
  final bool showBadge;
  final int? badgeCount;
  final VoidCallback onPressed;

  const HeaderIconWithBadge({
    super.key,
    required this.icon,
    required this.showBadge,
    this.badgeCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasCount = badgeCount != null;
    final count = badgeCount ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: const Color.fromARGB(255, 117, 117, 117),
            size: 28,
          ),
          onPressed: onPressed,
        ),
        if (showBadge && (!hasCount || count > 0))
          Positioned(
            top: hasCount ? 4 : 8,
            right: hasCount ? 4 : 8,
            child: Container(
              padding: hasCount
                  ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
                  : const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 160, 122),
                borderRadius: hasCount ? BorderRadius.circular(10) : null,
                shape: hasCount ? BoxShape.rectangle : BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: BoxConstraints(
                minHeight: hasCount ? 18 : 10,
                minWidth: hasCount ? 18 : 10,
              ),
              child: hasCount
                  ? Center(
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

class HeaderSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const HeaderSearchBar({
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

class HeaderFilterButton extends StatelessWidget {
  final VoidCallback? onFilterTap;

  const HeaderFilterButton({super.key, this.onFilterTap});

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
