import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
  final bool isDetected;
  final bool isDefault;

  const AddressOption({
    required this.label,
    required this.fullAddress,
    required this.state,
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

  static bool get hasCachedLocation =>
      _CustomerHeaderState._hasLoaded &&
      _CustomerHeaderState._cachedSelectedOption != null &&
      _CustomerHeaderState._cachedUserId == supabase.auth.currentUser?.id;

  static String get cachedState =>
      _CustomerHeaderState._cachedSelectedOption?.state ?? '';

  static String get cachedAddress =>
      _CustomerHeaderState._cachedSelectedOption?.fullAddress ?? '';

  static void clearLocationCache() => _CustomerHeaderState.clearLocationCache();

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

  AddressOption _selectedOption = const AddressOption(
    label: 'Current Location',
    fullAddress: 'George Town, Penang',
    state: 'Pulau Pinang',
    isDetected: true,
  );
  List<AddressOption> _savedAddresses = [];
  AddressOption? _detectedLocation;
  bool _isLoadingLocation = true;

  bool get _isAuthenticated {
    final session = supabase.auth.currentSession;
    if (session == null || session.isExpired) return false;
    return supabase.auth.currentUser != null;
  }

  @override
  void initState() {
    super.initState();
    final currentUserId = supabase.auth.currentUser?.id;
    final bool authChanged = currentUserId != _cachedUserId;

    if (_hasLoaded && !authChanged && _cachedSelectedOption != null) {
      _selectedOption = _cachedSelectedOption!;
      _detectedLocation = _cachedDetectedLocation;
      _savedAddresses = List<AddressOption>.from(_cachedSavedAddresses ?? []);
      _isLoadingLocation = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onLocationChanged?.call(_selectedOption.fullAddress, _selectedOption.state);
          widget.onLocationLoadingChanged?.call(false);
        }
      });
    } else {
      _loadAddresses();
    }
  }

  Future<AddressOption> _detectLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied && perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
          final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json&addressdetails=1',
          );
          final res = await http.get(url, headers: {'User-Agent': 'DoorDishApp/1.0'}).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            final addr = data['address'] as Map<String, dynamic>?;
            final road = addr?['road'] ?? addr?['suburb'] ?? addr?['neighbourhood'] ?? addr?['city'] ?? 'Current Location';
            final state = addr?['state']?.toString() ?? 'Penang';
            final resolvedState = extractStateFromAddress(state);
            return AddressOption(
              label: 'Current Location',
              fullAddress: '$road, $resolvedState',
              state: resolvedState,
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

  Future<void> _loadAddresses() async {
    //TODO: Retrieve user addresses dynamically from backend
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
      _cachedUserId = supabase.auth.currentUser?.id;
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
    if (!_isAuthenticated) {
      final detected = await _detectLocation();
      _detectedLocation = detected;
      _cachedSelectedOption = detected;
      _cachedDetectedLocation = detected;
      _cachedSavedAddresses = const [];
      _cachedUserId = null;
      _hasLoaded = true;
      if (mounted) {
        setState(() {
          _selectedOption = detected;
          _isLoadingLocation = false;
        });
        widget.onLocationChanged?.call(detected.fullAddress, detected.state);
        widget.onLocationLoadingChanged?.call(false);
      }
      return;
    }

    final userId = supabase.auth.currentUser!.id;
    AddressOption? defaultOption;
    final List<AddressOption> saved = [];

    final detectFuture = _detectLocation();
    final profileFuture = supabase.from('profiles').select('address, role').eq('id', userId).maybeSingle();
    final addressesFuture = supabase.from('user_addresses').select().eq('user_id', userId).order('created_at', ascending: false);

    final detected = await detectFuture;
    _detectedLocation = detected;

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
        saved.add(AddressOption(
          label: lbl,
          fullAddress: fullAddr,
          state: extractStateFromAddress(fullAddr),
        ));
      }
    }

    final initial = defaultOption ?? (saved.isNotEmpty ? saved.first : detected);
    final allSaved = [
      ?defaultOption,
      ...saved,
    ];

    _cachedSelectedOption = initial;
    _cachedDetectedLocation = detected;
    _cachedSavedAddresses = List<AddressOption>.from(allSaved);
    _cachedUserId = userId;
    _hasLoaded = true;

    if (mounted) {
      setState(() {
        _selectedOption = initial;
        _savedAddresses = allSaved;
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

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerMainNavigation(initialIndex: 3),
      ),
      (route) => false,
    );
  }

  Future<void> _openManageAddresses() async {
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
    );
    clearLocationCache();
    _loadAddresses();
  }

  void _showAddressSheet() {
    if (_isLoadingLocation) return;
    showModalBottomSheet(
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xDD000000)),
                ),
                const SizedBox(height: 16),
                if (_detectedLocation != null)
                  _buildAddressTile(_detectedLocation!, icon: Icons.my_location),
                if (!_isAuthenticated) ...[
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
                        const Icon(Icons.lock_outline, color: Color(0xFFFFA07A), size: 28),
                        const SizedBox(height: 8),
                        const Text(
                          'Log in to see your saved addresses',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xDD000000)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Save your favorite delivery addresses for faster ordering.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _navigateToLogin();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA07A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Log In Now', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  if (_savedAddresses.isNotEmpty) const Divider(height: 24),
                  ..._savedAddresses.map((addr) => _buildAddressTile(
                        addr,
                        icon: addr.isDefault ? Icons.home_outlined : Icons.location_on_outlined,
                      )),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _openManageAddresses,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_location_alt_outlined, size: 18, color: Color(0xFFFFA07A)),
                          SizedBox(width: 8),
                          Text(
                            'Manage Saved Addresses',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFA07A)),
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
                    ? const Text(
                        'DoorDish',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Color(0xFFFFA07A),
                        ),
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
                if (widget.showFilter) HeaderFilterButton(onFilterTap: widget.onFilterTap),
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
                  _isLoadingLocation ? 'Detecting location...' : _selectedOption.fullAddress,
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

  Widget _buildAddressTile(AddressOption option, {required IconData icon}) {
    final isSelected = _selectedOption.fullAddress == option.fullAddress;
    return InkWell(
      onTap: () {
        _selectAddress(option);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFFFC8B4) : const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFFFA07A) : const Color(0xFF9E9E9E), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFFFFA07A) : const Color(0xDD000000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.fullAddress,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFFA07A), size: 20),
          ],
        ),
      ),
    );
  }
}

class HeaderActionButtons extends StatelessWidget {
  const HeaderActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeaderIconWithBadge(
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
        HeaderIconWithBadge(
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
}

class HeaderIconWithBadge extends StatelessWidget {
  final IconData icon;
  final bool showBadge;
  final VoidCallback onPressed;

  const HeaderIconWithBadge({
    super.key,
    required this.icon,
    required this.showBadge,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
