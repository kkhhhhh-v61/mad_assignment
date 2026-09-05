import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../Order/branch_repository.dart';
import '../Order/delivery_fee.dart';
import '../Order/order.dart';
import '../Order/order_repository.dart';
import '../global.dart';
import '../rider/data_gov_my_fuel_price_repository.dart';
import '../services/states.dart';
import '../services/stripe_service.dart';
import 'branch_selection.dart';
import 'cart.dart';
import 'address_coordinate_cache.dart';
import 'header.dart';
import 'order_confirmation.dart';
import 'payment_methods.dart';
import 'saved_addresses.dart';

/// Returns the closest active branch to the supplied coordinates.
///
/// This is deliberately a pure helper so the nearest-first rule can be
/// verified without a Supabase session or a widget test.
BranchRecord? nearestActiveBranchForCoordinates({
  required double? latitude,
  required double? longitude,
  required Iterable<BranchRecord> branches,
}) {
  if (latitude == null ||
      longitude == null ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    return null;
  }

  BranchRecord? nearest;
  var nearestDistance = double.infinity;
  for (final branch in branches) {
    if (!branch.isActive ||
        !branch.latitude.isFinite ||
        !branch.longitude.isFinite ||
        branch.latitude < -90 ||
        branch.latitude > 90 ||
        branch.longitude < -180 ||
        branch.longitude > 180) {
      continue;
    }
    final distance = haversineDistanceKm(
      startLatitude: latitude,
      startLongitude: longitude,
      endLatitude: branch.latitude,
      endLongitude: branch.longitude,
    );
    if (distance < nearestDistance) {
      nearest = branch;
      nearestDistance = distance;
    }
  }
  return nearest;
}

class CustomerCheckout extends StatefulWidget {
  final List<CartItem>? cartItems;
  final String? deliveryAddress;
  final BranchSnapshot? branchSnapshot;
  final DeliveryAddressSnapshot? deliveryAddressSnapshot;
  final RoadDeliveryFeeService? deliveryFeeService;
  final BranchRepository? branchRepository;
  final OrderRepository? orderRepository;
  final bool enableBranchSelection;
  final bool returnRequired;

  const CustomerCheckout({
    super.key,
    this.cartItems,
    this.deliveryAddress,
    this.branchSnapshot,
    this.deliveryAddressSnapshot,
    this.deliveryFeeService,
    this.branchRepository,
    this.orderRepository,
    this.enableBranchSelection = true,
    this.returnRequired = false,
  });

  @override
  State<CustomerCheckout> createState() => _CustomerCheckoutState();
}

class _CustomerCheckoutState extends State<CustomerCheckout> {
  late List<CartItem> _cartItems;
  bool _isSelfPickup = false;
  late String _selectedAddress;
  AddressOption? _selectedAddressOption;
  AddressOption? _detectedLocation;
  List<AddressOption> _addressOptions = [];
  late String _selectedPaymentMethod;
  final List<String> _availablePaymentMethods = const [
    'Cash on Delivery',
    'Credit / Debit Card',
  ];
  List<Map<String, dynamic>> _savedCards = [];
  Map<String, dynamic>? _selectedSavedCard;
  bool _savedCardsLoading = false;
  Map<String, dynamic>? _appliedVoucher;
  late double _deliveryFee;
  late List<Map<String, dynamic>> _availableVouchers;
  DeliveryFeeQuote? _deliveryFeeQuote;
  bool _deliveryFeeLoading = false;
  String? _deliveryFeeError;
  RoadDeliveryFeeService? _ownedDeliveryFeeService;
  OsrmDeliveryRoadRouteProvider? _ownedRouteProvider;
  DataGovMyFuelPriceRepository? _ownedFuelPriceRepository;
  BranchRepository? _ownedBranchRepository;
  OrderRepository? _ownedOrderRepository;
  List<BranchRecord> _branches = [];
  BranchRecord? _selectedBranch;
  bool _branchesLoading = false;
  String? _branchesError;
  int _deliveryFeeRequestGeneration = 0;
  int _addressResolutionGeneration = 0;
  final Map<String, AddressOption> _geocodedAddresses = {};
  DeliveryAddressSnapshot? _resolvedDeliveryAddressSnapshot;
  bool _isSubmitting = false;

  BranchSnapshot? get _effectiveBranchSnapshot =>
      _selectedBranch?.snapshot ?? widget.branchSnapshot;

  /// Delivery must have a successful road quote before it can be submitted.
  /// Pickup does not need a route or delivery fee.
  bool get _routedFeeEnabled => !_isSelfPickup;

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cartItems != null
        ? List<CartItem>.from(widget.cartItems!)
        : [];
    _isSelfPickup = false;
    final initialAddress =
        (widget.deliveryAddress != null &&
            widget.deliveryAddress!.trim().isNotEmpty)
        ? widget.deliveryAddress!.trim()
        : (widget.deliveryAddressSnapshot?.formattedAddress ??
              (CustomerHeader.cachedAddress.isNotEmpty
                  ? CustomerHeader.cachedAddress
                  : ''));
    _selectedAddress = initialAddress;
    if (CustomerHeader.cachedSelectedOption != null &&
        CustomerHeader.cachedSelectedOption!.fullAddress == _selectedAddress) {
      _selectedAddressOption = CustomerHeader.cachedSelectedOption;
    }
    _selectedPaymentMethod = 'Cash on Delivery';
    _appliedVoucher = null;
    _deliveryFee = 0.0;
    _availableVouchers = [];
    _resolvedDeliveryAddressSnapshot = widget.deliveryAddressSnapshot;

    if (_cartItems.isEmpty) {
      _loadCartItems();
    }
    _loadAddresses();
    _loadPaymentMethods();
    _loadVouchers();

    if (widget.enableBranchSelection) {
      _loadBranches();
    }
    if (widget.branchSnapshot != null ||
        widget.deliveryAddressSnapshot != null ||
        widget.deliveryFeeService != null) {
      _loadRoutedDeliveryFee();
    }
  }

  Future<void> _loadVouchers() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final response = await Supabase.instance.client
          .from('vouchers')
          .select()
          .eq('is_active', true)
          .gte('expiry_date', todayStr)
          .or('customer_id.is.null, customer_id.eq.$userId')
          .order('expiry_date', ascending: true);

      if (mounted) {
        setState(() {
          _availableVouchers = List<Map<String, dynamic>>.from(response);
          if (_appliedVoucher != null) {
            final stillValid = _availableVouchers.any((v) => v['id'] == _appliedVoucher!['id']);
            if (!stillValid) _appliedVoucher = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching checkout vouchers: $e');
    }
  }

  void _setFulfillmentType(bool isSelfPickup) {
    if (_isSelfPickup == isSelfPickup) return;
    _addressResolutionGeneration++;
    _deliveryFeeRequestGeneration++;
    setState(() {
      _isSelfPickup = isSelfPickup;
      _deliveryFeeQuote = null;
      _deliveryFeeError = null;
      _deliveryFeeLoading = false;
      _deliveryFee = 0.0;
      if (isSelfPickup) {
        _resolvedDeliveryAddressSnapshot = null;
      }
      if (!_isSelfPickup && _selectedAddress.isEmpty) {
        _selectedAddress = CustomerHeader.cachedAddress;
      }

      if (_isSelfPickup && _appliedVoucher?['is_free_delivery'] == true) {
        _appliedVoucher = null;
      }
    });
    if (!isSelfPickup) {
      unawaited(_resolveDeliveryContext());
    }
  }

  Future<void> _loadAddresses() async {
    final cachedCoordinates = await AddressCoordinateCache.loadAll();

    AddressOption withCachedCoordinates(AddressOption option) {
      if (option.latitude != null && option.longitude != null) {
        return option;
      }
      final coordinates = cachedCoordinates[option.fullAddress.trim()];
      if (coordinates == null) return option;
      return AddressOption(
        label: option.label,
        fullAddress: option.fullAddress,
        state: option.state,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        isDetected: option.isDetected,
        isDefault: option.isDefault,
      );
    }

    final AddressOption detected = withCachedCoordinates(
      CustomerHeader.cachedDetectedLocation ??
          (CustomerHeader.cachedAddress.isNotEmpty
              ? AddressOption(
                  label: 'Current Location',
                  fullAddress: CustomerHeader.cachedAddress,
                  state: CustomerHeader.cachedState.isNotEmpty
                      ? CustomerHeader.cachedState
                      : extractStateFromAddress(CustomerHeader.cachedAddress),
                  isDetected: true,
                )
              : const AddressOption(
                  label: 'Current Location',
                  fullAddress: 'George Town, Penang',
                  state: 'Pulau Pinang',
                  isDetected: true,
                )),
    );

    final List<AddressOption> options = [];

    void addCachedHeaderAddresses() {
      final headerSaved = CustomerHeader.cachedSavedAddresses;
      if (headerSaved == null) return;
      for (final rawOption in headerSaved) {
        final option = withCachedCoordinates(rawOption);
        if (!options.any((o) => o.fullAddress == option.fullAddress)) {
          options.add(option);
        }
      }
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('address')
            .eq('id', user.id)
            .maybeSingle();
        final profileAddress = profileRes?['address']?.toString().trim();
        if (profileAddress != null && profileAddress.isNotEmpty) {
          final defaultOption = withCachedCoordinates(
            AddressOption(
              label: 'Default Address',
              fullAddress: profileAddress,
              state: extractStateFromAddress(profileAddress),
              isDefault: true,
            ),
          );
          if (!options.any((o) => o.fullAddress == profileAddress)) {
            options.insert(0, defaultOption);
          }
        }
      } catch (_) {
        // The saved-address query below remains authoritative when available.
      }

      try {
        final savedRes = await Supabase.instance.client
            .from('user_addresses')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        for (final row in savedRes) {
          final address = row['full_address']?.toString().trim();
          final label = row['label']?.toString().trim();
          if (address == null || address.isEmpty) continue;

          final existingIndex = options.indexWhere(
            (option) => option.fullAddress == address,
          );
          final option = withCachedCoordinates(
            AddressOption(
              label: label != null && label.isNotEmpty
                  ? label
                  : 'Saved Address',
              fullAddress: address,
              state: extractStateFromAddress(address),
              isDefault: existingIndex >= 0
                  ? options[existingIndex].isDefault
                  : false,
            ),
          );

          if (existingIndex >= 0) {
            options[existingIndex] = option;
          } else {
            options.add(option);
          }
        }
      } catch (_) {
        // Header cache is only a fallback when the backend list is unavailable.
        addCachedHeaderAddresses();
      }
    } else {
      addCachedHeaderAddresses();
    }

    AddressOption? selectedOption = _selectedAddressOption;
    if (_selectedAddress.isNotEmpty) {
      selectedOption = options
          .where((option) => option.fullAddress == _selectedAddress)
          .firstOrNull;
      if (selectedOption == null && detected.fullAddress == _selectedAddress) {
        selectedOption = detected;
      }
    }
    if (selectedOption == null) {
      selectedOption = options.isNotEmpty ? options.first : detected;
      _selectedAddress = selectedOption.fullAddress;
    }

    if (mounted) {
      setState(() {
        _detectedLocation = detected;
        _addressOptions = options;
        _selectedAddressOption = selectedOption;
      });
      if (!_isSelfPickup) {
        unawaited(_resolveDeliveryContext());
      }
    }
  }

  Future<AddressOption?> _geocodeAddressOption(AddressOption option) async {
    final latitude = option.latitude;
    final longitude = option.longitude;
    if (latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite) {
      return option;
    }

    final query = option.fullAddress.trim();
    if (query.isEmpty) return null;
    final cached = _geocodedAddresses[query];
    if (cached != null) return cached;

    try {
      final response = await http
          .get(
            Uri.https(
              'nominatim.openstreetmap.org',
              '/search',
              <String, String>{
                'q': '$query, Malaysia',
                'format': 'jsonv2',
                'limit': '1',
                'countrycodes': 'my',
              },
            ),
            headers: const {'User-Agent': 'DoorDishApp/1.0'},
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty || decoded.first is! Map) {
        return null;
      }
      final result = Map<String, dynamic>.from(decoded.first as Map);
      final resolvedLatitude = double.tryParse('${result['lat']}');
      final resolvedLongitude = double.tryParse('${result['lon']}');
      if (resolvedLatitude == null ||
          resolvedLongitude == null ||
          !resolvedLatitude.isFinite ||
          !resolvedLongitude.isFinite) {
        return null;
      }
      final resolved = AddressOption(
        label: option.label,
        fullAddress: option.fullAddress,
        state: option.state,
        latitude: resolvedLatitude,
        longitude: resolvedLongitude,
        isDetected: option.isDetected,
        isDefault: option.isDefault,
      );
      _geocodedAddresses[query] = resolved;
      await AddressCoordinateCache.save(
        address: option.fullAddress,
        latitude: resolvedLatitude,
        longitude: resolvedLongitude,
      );
      return resolved;
    } catch (_) {
      return null;
    }
  }

  BranchRecord? _fallbackBranchForAddress(String state) {
    if (_branches.isEmpty) return null;
    if (state.trim().isNotEmpty) {
      for (final branch in _branches) {
        if (isSameState(branch.stateCode, state) ||
            branch.address.toLowerCase().contains(state.toLowerCase()) ||
            branch.name.toLowerCase().contains(state.toLowerCase())) {
          return branch;
        }
      }
    }
    return _branches.first;
  }

  Future<void> _resolveDeliveryContext() async {
    if (_isSelfPickup) return;
    if (_branches.isEmpty && widget.branchSnapshot == null) {
      // Branch loading will call this again when it completes. Keeping the
      // context unresolved prevents a delivery order from being submitted
      // with a zero fee or an arbitrary branch.
      return;
    }

    final generation = ++_addressResolutionGeneration;
    var option = _selectedAddressOption;
    if (option == null && _selectedAddress.trim().isNotEmpty) {
      option = AddressOption(
        label: 'Delivery Address',
        fullAddress: _selectedAddress.trim(),
        state: extractStateFromAddress(_selectedAddress),
      );
    }
    if (option == null) return;

    final resolvedOption = await _geocodeAddressOption(option);
    if (!mounted ||
        _isSelfPickup ||
        generation != _addressResolutionGeneration) {
      return;
    }
    option = resolvedOption ?? option;

    final nearest = nearestActiveBranchForCoordinates(
      latitude: option.latitude,
      longitude: option.longitude,
      branches: _branches,
    );
    final branch =
        nearest ?? _fallbackBranchForAddress(option.state) ?? _selectedBranch;
    final branchSnapshot = branch?.snapshot ?? widget.branchSnapshot;
    final stateCode = branchSnapshot?.stateCode.trim().isNotEmpty == true
        ? branchSnapshot!.stateCode
        : (option.state.isNotEmpty
              ? option.state
              : extractStateFromAddress(option.fullAddress));
    final destination = DeliveryAddressSnapshot(
      label: option.label,
      formattedAddress: option.fullAddress,
      stateCode: stateCode,
      latitude: option.latitude,
      longitude: option.longitude,
    );

    setState(() {
      _selectedAddressOption = option;
      _selectedAddress = option!.fullAddress;
      if (branch != null) _selectedBranch = branch;
      _resolvedDeliveryAddressSnapshot = destination;
      _deliveryFeeQuote = null;
      _deliveryFeeError = null;
      _deliveryFee = 0.0;
    });

    if (branchSnapshot != null) {
      unawaited(_loadRoutedDeliveryFee());
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _savedCardsLoading = true;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('payment_methods')
            .select()
            .eq('user_id', user.id)
            .order('is_default', ascending: false)
            .order('created_at', ascending: false);
        if (mounted) {
          final cards = List<Map<String, dynamic>>.from(response);
          setState(() {
            _savedCards = cards;
            _savedCardsLoading = false;
            if (_selectedSavedCard != null &&
                !cards.any((c) => c['id'] == _selectedSavedCard?['id'])) {
              _selectedSavedCard = null;
            }
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _savedCardsLoading = false;
      });
    }
  }

  Future<void> _openAddCardModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (modalContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalContext).viewInsets.bottom,
        ),
        child: AddCardForm(
          onSave: () async {
            await _loadPaymentMethods();
            if (mounted) {
              setState(() {
                _selectedPaymentMethod = 'Credit / Debit Card';
              });
            }
          },
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CustomerCheckout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cartItems != null && widget.cartItems != oldWidget.cartItems) {
      _cartItems = List<CartItem>.from(widget.cartItems!);
    }
    if (oldWidget.branchSnapshot != widget.branchSnapshot ||
        oldWidget.deliveryAddressSnapshot != widget.deliveryAddressSnapshot ||
        oldWidget.deliveryFeeService != widget.deliveryFeeService ||
        oldWidget.branchRepository != widget.branchRepository ||
        oldWidget.orderRepository != widget.orderRepository ||
        oldWidget.enableBranchSelection != widget.enableBranchSelection ||
        oldWidget.returnRequired != widget.returnRequired) {
      if (oldWidget.branchSnapshot?.branchId !=
          widget.branchSnapshot?.branchId) {
        _selectedBranch = null;
      }
      if (widget.enableBranchSelection) {
        _loadBranches();
      }
      if (widget.deliveryAddressSnapshot != null) {
        _resolvedDeliveryAddressSnapshot = widget.deliveryAddressSnapshot;
        _selectedAddress = widget.deliveryAddressSnapshot!.formattedAddress;
      }
      if (_isSelfPickup) {
        _deliveryFeeQuote = null;
        _deliveryFeeLoading = false;
        _deliveryFeeError = null;
        _deliveryFee = 0.0;
      } else {
        unawaited(_resolveDeliveryContext());
      }
    }
  }

  Future<void> _loadCartItems() async {
    final items = await CartStorage.loadCart();
    if (mounted && items.isNotEmpty) {
      setState(() {
        _cartItems = items;
      });
    }
  }

  BranchRepository? _resolveBranchRepository() {
    final supplied = widget.branchRepository;
    if (supplied != null) return supplied;
    final existing = _ownedBranchRepository;
    if (existing != null) return existing;

    try {
      final repository = SupabaseBranchRepository(Supabase.instance.client);
      _ownedBranchRepository = repository;
      return repository;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadBranches() async {
    if (!widget.enableBranchSelection) return;

    final repository = _resolveBranchRepository();
    if (!mounted) return;
    if (repository == null) {
      setState(() {
        _branchesLoading = false;
        _branchesError = 'Supabase is not ready. Branches could not be loaded.';
      });
      return;
    }

    setState(() {
      _branchesLoading = true;
      _branchesError = null;
    });

    try {
      final branches = await repository.fetchActiveBranches();
      if (!mounted) return;
      BranchRecord? selected = _selectedBranch;
      final fallbackId = widget.branchSnapshot?.branchId;
      if (selected == null && fallbackId != null) {
        for (final branch in branches) {
          if (branch.id == fallbackId) {
            selected = branch;
            break;
          }
        }
      }
      if (selected == null && branches.isNotEmpty) {
        final addressState = extractStateFromAddress(_selectedAddress);
        final candidateState = addressState.isNotEmpty
            ? addressState
            : CustomerHeader.cachedState;
        if (candidateState.isNotEmpty) {
          for (final branch in branches) {
            if (isSameState(branch.stateCode, candidateState) ||
                branch.address.toLowerCase().contains(
                  candidateState.toLowerCase(),
                ) ||
                branch.name.toLowerCase().contains(
                  candidateState.toLowerCase(),
                )) {
              selected = branch;
              break;
            }
          }
        }
        selected ??= branches.first;
      }
      setState(() {
        _branches = branches;
        _selectedBranch = selected;
        _branchesLoading = false;
        _branchesError = null;
      });
      if (!_isSelfPickup) {
        unawaited(_resolveDeliveryContext());
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _branchesLoading = false;
        _branchesError = error is BranchRepositoryException
            ? error.message
            : 'Unable to load restaurant branches.';
      });
    }
  }

  Future<void> _showBranchSelectionDialog(BuildContext context) async {
    final selected = await showModalBottomSheet<BranchRecord>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => BranchSelectionBottomSheet(
        branches: _branches,
        selectedBranch: _selectedBranch,
        onSelected: (branch) => Navigator.pop(context, branch),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _selectedBranch = selected;
    });
    // Branch selection is intentionally available only for pickup. Delivery
    // always re-evaluates the nearest active branch from the address.
  }

  Future<RoadDeliveryFeeService?> _resolveDeliveryFeeService() async {
    final supplied = widget.deliveryFeeService;
    if (supplied != null) {
      return supplied;
    }
    final existing = _ownedDeliveryFeeService;
    if (existing != null) {
      return existing;
    }

    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return null;
    final routeProvider = OsrmDeliveryRoadRouteProvider();
    final fuelRepository = DataGovMyFuelPriceRepository(
      preferences: preferences,
    );
    _ownedRouteProvider = routeProvider;
    _ownedFuelPriceRepository = fuelRepository;
    final service = RoadDeliveryFeeService(
      routeProvider: routeProvider,
      fuelPriceRepository: fuelRepository,
    );
    _ownedDeliveryFeeService = service;
    return service;
  }

  Future<void> _loadRoutedDeliveryFee() async {
    if (_isSelfPickup) return;
    final generation = ++_deliveryFeeRequestGeneration;
    setState(() {
      _deliveryFeeLoading = true;
      _deliveryFeeError = null;
      _deliveryFeeQuote = null;
      _deliveryFee = 0.0;
    });

    final branch = _effectiveBranchSnapshot;
    final destination =
        _resolvedDeliveryAddressSnapshot ?? widget.deliveryAddressSnapshot;
    if (branch == null || destination == null) {
      if (!mounted || generation != _deliveryFeeRequestGeneration) return;
      setState(() {
        _deliveryFeeLoading = false;
        _deliveryFeeError =
        'A branch and delivery address are required to calculate the road fee.';
      });
      return;
    }

    try {
      final service = await _resolveDeliveryFeeService();
      if (!mounted || generation != _deliveryFeeRequestGeneration) return;
      if (service == null) return;
      final quote = await service.quote(
        branch: branch,
        destination: destination,
        returnRequired: widget.returnRequired,
      );
      if (!mounted || generation != _deliveryFeeRequestGeneration) return;
      setState(() {
        _deliveryFeeLoading = false;
        _deliveryFeeError = null;
        _deliveryFeeQuote = quote;
        _deliveryFee = quote.deliveryFeeSen / 100.0;
      });
    } on DeliveryDistanceLimitException catch (error) {
      if (!mounted || generation != _deliveryFeeRequestGeneration) return;
      setState(() {
        _deliveryFeeLoading = false;
        _deliveryFeeError = error.message;
      });
    } on DeliveryFeeException catch (error) {
      if (!mounted || generation != _deliveryFeeRequestGeneration) return;
      setState(() {
        _deliveryFeeLoading = false;
        _deliveryFeeError = error.message;
      });
    } on InvalidOrderException catch (error) {
      if (!mounted || generation != _deliveryFeeRequestGeneration) return;
      setState(() {
        _deliveryFeeLoading = false;
        _deliveryFeeError = error.message;
      });
    } catch (_) {
      if (!mounted || generation != _deliveryFeeRequestGeneration) return;
      setState(() {
        _deliveryFeeLoading = false;
        _deliveryFeeError = 'Delivery route could not be calculated.';
      });
    }
  }

  OrderRepository? _resolveOrderRepository() {
    final supplied = widget.orderRepository;
    if (supplied != null) return supplied;
    final existing = _ownedOrderRepository;
    if (existing != null) return existing;
    try {
      final repository = SupabaseOrderRepository(Supabase.instance.client);
      _ownedOrderRepository = repository;
      return repository;
    } catch (_) {
      return null;
    }
  }

  List<OrderItemSnapshot> _buildOrderItems() {
    if (_cartItems.isEmpty) {
      throw const InvalidOrderException('Your cart is empty.');
    }
    return _cartItems
        .map((item) {
          final foodId = item.id?.trim();
          if (foodId == null || foodId.isEmpty) {
            throw const InvalidOrderException(
              'A cart item is missing its menu ID. Please remove it and add it again from the menu.',
            );
          }
          final unitPriceSen = ((item.price + item.customizationTotal) * 100)
              .round();
          return OrderItemSnapshot(
            foodId: foodId,
            name: item.name,
            quantity: item.quantity,
            unitPriceSen: unitPriceSen,
            selectedOptions: {
              'customizations': item.customizations
                  .map((customization) => customization.toJson())
                  .toList(growable: false),
            },
            lineTotalSen: unitPriceSen * item.quantity,
            isStateSpecial: false,
          );
        })
        .toList(growable: false);
  }

  int _discountSen({required int subtotalSen, required int deliveryFeeSen}) {
    final voucher = _appliedVoucher;
    if (voucher == null) return 0;
    final type = voucher['type']?.toString();
    var discount = 0;
    final isFreeDelivery = voucher['is_free_delivery'] == true ||
        type == 'free_delivery';
    if (isFreeDelivery) {
      discount = deliveryFeeSen;
    } else if (type == 'percentage') {
      final percentage = (voucher['discountValue'] as num?)?.toDouble() ?? 0;
      if (percentage.isFinite && percentage > 0) {
        discount = (subtotalSen * percentage / 100).round();
      }
    } else {
      // Current vouchers store a fixed RM amount in discount_amount.
      // Keep discountValue as a fallback for older local voucher records.
      final rawAmount = voucher['discount_amount'] ?? voucher['discountValue'];
      if (rawAmount is num) {
        final amount = rawAmount.toDouble();
        if (amount.isFinite && amount > 0) {
          discount = (amount * 100).round();
        }
      }
    }
    final maximum = subtotalSen + deliveryFeeSen;
    return discount.clamp(0, maximum);
  }

  OrderSubmission _buildOrderSubmission() {
    final branch = _effectiveBranchSnapshot;
    if (branch == null) {
      throw const InvalidOrderException(
        'A restaurant branch is still being assigned. Please try again.',
      );
    }

    final items = _buildOrderItems();
    final subtotalSen = items.fold<int>(
      0,
      (sum, item) => sum + item.lineTotalSen,
    );
    final isDelivery = !_isSelfPickup;
    final quote = isDelivery ? _deliveryFeeQuote : null;
    final destination = isDelivery
        ? (_resolvedDeliveryAddressSnapshot ?? widget.deliveryAddressSnapshot)
        : null;
    if (isDelivery) {
      if (destination == null ||
          destination.latitude == null ||
          destination.longitude == null) {
        throw const InvalidOrderException(
          'A map-ready delivery address is required before placing the order.',
        );
      }
      if (quote == null || _deliveryFeeError != null) {
        throw const InvalidOrderException(
          'The delivery route and fee must be calculated before placing the order.',
        );
      }
    }

    final deliveryFeeSen = quote?.deliveryFeeSen ?? 0;
    final discountSen = _discountSen(
      subtotalSen: subtotalSen,
      deliveryFeeSen: deliveryFeeSen,
    );
    final totalSen = subtotalSen + deliveryFeeSen - discountSen;

    return OrderSubmission(
      orderNumber: 'ORD-${DateTime.now().toUtc().millisecondsSinceEpoch}',
      paymentIdempotencyKey: 'checkout-${const Uuid().v4()}',
      paymentType:
          _selectedPaymentMethod == 'Credit / Debit Card' ? 'Card' : 'COD',
      paymentStatus: _selectedPaymentMethod == 'Credit / Debit Card'
          ? 'Completed'
          : 'Pending',
      paymentMethodId: _selectedPaymentMethod == 'Credit / Debit Card'
          ? (_selectedSavedCard != null
              ? _selectedSavedCard!['id']?.toString()
              : null)
          : null,
      fulfilmentType: isDelivery
          ? FulfilmentType.delivery
          : FulfilmentType.pickup,
      branchSnapshot: branch,
      deliveryAddressSnapshot: destination,
      subtotalSen: subtotalSen,
      discountSen: discountSen,
      deliveryFeeSen: deliveryFeeSen,
      totalSen: totalSen,
      roadDistanceKm: quote?.oneWayRoadDistanceKm,
      items: items,
    );
  }

  double _calculateCurrentTotal() {
    double subtotal = 0;
    for (var item in _cartItems) {
      double customTotal = item.customizations.fold(
        0.0,
        (sum, c) => sum + c.price,
      );
      subtotal += (item.price + customTotal) * item.quantity;
    }
    final effectiveDeliveryFee = _isSelfPickup ? 0.0 : _deliveryFee;
    double discount = 0.0;
    if (_appliedVoucher != null) {
      if (_appliedVoucher!['is_free_delivery'] == true) {
        discount = effectiveDeliveryFee;
      } else {
        final rawDiscount =
            _appliedVoucher!['discount_amount'] ?? _appliedVoucher!['discountValue'];
        final discountAmount = rawDiscount is num
            ? rawDiscount.toDouble()
            : 0.0;
        discount = discountAmount;
        if (discount > subtotal) {
          discount = subtotal;
        }
      }
    }
    final sst = subtotal * 0.06;
    double total = subtotal + sst + effectiveDeliveryFee - discount;
    return total < 0 ? 0 : total;
  }

  Future<bool> _showExitConfirmationDialog() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color.fromARGB(255, 255, 160, 122),
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Leave Checkout?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to leave checkout? Your items will remain in your cart, but your order has not been placed yet.',
          style: TextStyle(fontSize: 14.0, color: Colors.black87),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Stay',
              style: TextStyle(
                color: Color.fromARGB(255, 120, 120, 120),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 160, 122),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: const Text(
              'Leave',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = _resolveOrderRepository();
      if (repository == null) {
        throw const OrderRepositoryException(
          'Supabase is not ready. The order could not be submitted.',
        );
      }
      final submission = _buildOrderSubmission();
      await repository.createOrder(submission);
      await CartStorage.clearCart();
      if (!mounted) return;
      setState(() {
        _cartItems.clear();
        _isSubmitting = false;
      });
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerOrderConfirmation(
            totalPaid: _calculateCurrentTotal(),
            paymentMethod: _selectedPaymentMethod,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is OrderRepositoryException
          ? error.message
          : error is OrderDataException
          ? error.message
          : error.toString();
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  void dispose() {
    _addressResolutionGeneration++;
    _deliveryFeeRequestGeneration++;
    _ownedRouteProvider?.dispose();
    _ownedFuelPriceRepository?.dispose();
    super.dispose();
  }

  Future<void> _openManageAddresses(BuildContext context) async {
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
    );
    CustomerHeader.clearLocationCache();
    await _loadAddresses();
  }

  void _showAddressSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Delivery Address',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xDD000000),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  if (_detectedLocation != null)
                    _buildAddressOptionTile(
                      _detectedLocation!,
                      icon: Icons.my_location,
                      sheetContext: sheetContext,
                    ),
                  if (_addressOptions.isNotEmpty) const Divider(height: 24.0),
                  ..._addressOptions.map(
                    (addr) => _buildAddressOptionTile(
                      addr,
                      icon: addr.isDefault
                          ? Icons.home_outlined
                          : (addr.label.toLowerCase() == 'home'
                                ? Icons.home_outlined
                                : (addr.label.toLowerCase() == 'work' ||
                                          addr.label.toLowerCase() == 'office'
                                      ? Icons.work_outline
                                      : Icons.location_on_outlined)),
                      sheetContext: sheetContext,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  InkWell(
                    onTap: () => _openManageAddresses(sheetContext),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_location_alt_outlined,
                            size: 18,
                            color: Color.fromARGB(255, 255, 160, 122),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Manage Saved Addresses',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 160, 122),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressOptionTile(
      AddressOption option, {
        required IconData icon,
        required BuildContext sheetContext,
      }) {
    final isSelected = _selectedAddress == option.fullAddress;
    return InkWell(
      onTap: () {
        _addressResolutionGeneration++;
        _deliveryFeeRequestGeneration++;
        setState(() {
          _selectedAddressOption = option;
          _selectedAddress = option.fullAddress;
          _resolvedDeliveryAddressSnapshot = null;
          _deliveryFeeQuote = null;
          _deliveryFeeError = null;
          _deliveryFee = 0.0;
        });
        Navigator.pop(sheetContext);
        if (!_isSelfPickup) {
          unawaited(_resolveDeliveryContext());
        }
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
              color: isSelected
                  ? const Color.fromARGB(255, 255, 160, 122)
                  : const Color(0xFF9E9E9E),
              size: 22,
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
                              ? const Color.fromARGB(255, 255, 160, 122)
                              : const Color(0xDD000000),
                        ),
                      ),
                      if (option.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(40, 255, 160, 122),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: Color.fromARGB(255, 255, 160, 122),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color.fromARGB(255, 255, 160, 122),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _showExitConfirmationDialog();
        if (shouldLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(248, 255, 255, 255),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color.fromARGB(221, 0, 0, 0),
              size: 20,
            ),
            onPressed: () async {
              final shouldLeave = await _showExitConfirmationDialog();
              if (shouldLeave && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Checkout',
            style: TextStyle(
              color: Color.fromARGB(221, 0, 0, 0),
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: const Color.fromARGB(255, 214, 214, 214),
              height: 1.0,
            ),
          ),
        ),
        body: CheckoutLayout(
          cartItems: _cartItems,
          isSelfPickup: _isSelfPickup,
          onFulfillmentChanged: _setFulfillmentType,
          branchSelectionEnabled: _isSelfPickup,
          selectedBranch: _selectedBranch,
          fallbackBranchSnapshot: widget.branchSnapshot,
          branches: _branches,
          branchLoading: _branchesLoading,
          branchError: _branchesError,
          onBranchTap: () => _showBranchSelectionDialog(context),
          onRetryBranches: _loadBranches,
          selectedAddress: _selectedAddress,
          selectedAddressLabel: _selectedAddressOption?.label,
          onAddressTap: () => _showAddressSelectionDialog(context),
          selectedPaymentMethod: _selectedPaymentMethod,
          availablePaymentMethods: _availablePaymentMethods,
          selectedSavedCard: _selectedSavedCard,
          savedCards: _savedCards,
          savedCardsLoading: _savedCardsLoading,
          onPaymentMethodChanged: (method, card) {
            setState(() {
              _selectedPaymentMethod = method;
              _selectedSavedCard = card;
            });
          },
          onAddNewCard: () => _openAddCardModal(context),
          appliedVoucher: _appliedVoucher,
          deliveryFee: _deliveryFee,
          deliveryFeeQuote: _deliveryFeeQuote,
          deliveryFeeRequired: _routedFeeEnabled,
          deliveryFeeLoading: _deliveryFeeLoading,
          deliveryFeeError: _deliveryFeeError,
          onRetryDeliveryFee: _loadRoutedDeliveryFee,
          availableVouchers: _availableVouchers,
          placeOrderLoading: _isSubmitting,
          navigateToConfirmation: false,
          onVoucherApplied: (voucher) {
            setState(() {
              _appliedVoucher = voucher;
            });
          },
          onPlaceOrder: _submitOrder,
        ),
      ),
    );
  }
}

class CheckoutLayout extends StatelessWidget {
  final List<CartItem> cartItems;
  final bool isSelfPickup;
  final ValueChanged<bool> onFulfillmentChanged;
  final bool branchSelectionEnabled;
  final BranchRecord? selectedBranch;
  final BranchSnapshot? fallbackBranchSnapshot;
  final List<BranchRecord> branches;
  final bool branchLoading;
  final String? branchError;
  final VoidCallback onBranchTap;
  final VoidCallback onRetryBranches;
  final String selectedAddress;
  final String? selectedAddressLabel;
  final VoidCallback onAddressTap;
  final String selectedPaymentMethod;
  final List<String> availablePaymentMethods;
  final Map<String, dynamic>? selectedSavedCard;
  final List<Map<String, dynamic>> savedCards;
  final bool savedCardsLoading;
  final Function(String, Map<String, dynamic>?) onPaymentMethodChanged;
  final VoidCallback onAddNewCard;
  final Map<String, dynamic>? appliedVoucher;
  final double deliveryFee;
  final DeliveryFeeQuote? deliveryFeeQuote;
  final bool deliveryFeeRequired;
  final bool deliveryFeeLoading;
  final String? deliveryFeeError;
  final VoidCallback? onRetryDeliveryFee;
  final List<Map<String, dynamic>> availableVouchers;
  final Function(Map<String, dynamic>?) onVoucherApplied;
  final FutureOr<void> Function() onPlaceOrder;
  final bool placeOrderLoading;
  final bool navigateToConfirmation;

  const CheckoutLayout({
    super.key,
    required this.cartItems,
    this.isSelfPickup = false,
    this.onFulfillmentChanged = _noopValueChanged,
    this.branchSelectionEnabled = false,
    this.selectedBranch,
    this.fallbackBranchSnapshot,
    this.branches = const [],
    this.branchLoading = false,
    this.branchError,
    this.onBranchTap = _noop,
    this.onRetryBranches = _noop,
    required this.selectedAddress,
    this.selectedAddressLabel,
    required this.onAddressTap,
    required this.selectedPaymentMethod,
    required this.availablePaymentMethods,
    this.selectedSavedCard,
    this.savedCards = const [],
    this.savedCardsLoading = false,
    required this.onPaymentMethodChanged,
    this.onAddNewCard = _noop,
    required this.appliedVoucher,
    required this.deliveryFee,
    this.deliveryFeeQuote,
    this.deliveryFeeRequired = false,
    this.deliveryFeeLoading = false,
    this.deliveryFeeError,
    this.onRetryDeliveryFee,
    required this.availableVouchers,
    required this.onVoucherApplied,
    required this.onPlaceOrder,
    this.placeOrderLoading = false,
    this.navigateToConfirmation = true,
  });

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    for (var item in cartItems) {
      double customTotal = item.customizations.fold(
        0.0,
            (sum, c) => sum + c.price,
      );
      subtotal += (item.price + customTotal) * item.quantity;
    }

    final effectiveDeliveryFee = isSelfPickup ? 0.0 : deliveryFee;

    double discount = 0.0;

    if (appliedVoucher != null) {
      if (appliedVoucher!['is_free_delivery'] == true) {
        discount = effectiveDeliveryFee;
      } else {
        final rawDiscount =
            appliedVoucher!['discount_amount'] ?? appliedVoucher!['discountValue'];
        final discountAmount = rawDiscount is num
            ? rawDiscount.toDouble()
            : 0.0;
        discount = discountAmount;
        if (discount > subtotal) {
          discount = subtotal;
        }
      }
    }

    final double sst = subtotal * 0.06;
    double total = subtotal + sst + effectiveDeliveryFee - discount;
    if (total < 0) total = 0;

    final addressReady = isSelfPickup || selectedAddress.trim().isNotEmpty;
    final effectiveBranchReady =
        selectedBranch != null || fallbackBranchSnapshot != null;
    final effectiveFeeReady = isSelfPickup
        ? true
        : (deliveryFeeQuote != null &&
              deliveryFeeError == null &&
              !deliveryFeeLoading);

    final placeOrderEnabled =
        cartItems.isNotEmpty &&
        addressReady &&
        effectiveBranchReady &&
        effectiveFeeReady &&
        !placeOrderLoading;

    final buttonText = selectedPaymentMethod == 'Cash on Delivery'
        ? 'Place Order'
        : 'Proceed to Payment';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FulfillmentOptionSwitch(
                  isSelfPickup: isSelfPickup,
                  onOptionChanged: onFulfillmentChanged,
                ),
                const SizedBox(height: 20.0),
                if (!isSelfPickup) ...[
                  AddressSelection(
                    address: selectedAddress,
                    addressLabel: selectedAddressLabel,
                    onTap: onAddressTap,
                  ),
                  const SizedBox(height: 20.0),
                ],
                BranchSelection(
                  selectedBranch: selectedBranch,
                  fallbackSnapshot: fallbackBranchSnapshot,
                  branches: branches,
                  isLoading: branchLoading,
                  error: branchError,
                  onTap: onBranchTap,
                  onRetry: onRetryBranches,
                  isEnabled: isSelfPickup,
                ),
                const SizedBox(height: 20.0),
                CheckoutOrderItems(cartItems: cartItems),
                const SizedBox(height: 20.0),
                CheckoutVoucher(
                  appliedVoucher: appliedVoucher,
                  availableVouchers: availableVouchers,
                  subtotal: subtotal,
                  isSelfPickup: isSelfPickup,
                  onVoucherApplied: onVoucherApplied,
                ),
                const SizedBox(height: 20.0),
                CheckoutPayment(
                  selectedPaymentMethod: selectedPaymentMethod,
                  availablePaymentMethods: availablePaymentMethods,
                  selectedSavedCard: selectedSavedCard,
                  savedCards: savedCards,
                  savedCardsLoading: savedCardsLoading,
                  onPaymentMethodChanged: onPaymentMethodChanged,
                  onAddNewCard: onAddNewCard,
                ),
                const SizedBox(height: 20.0),
                if (!isSelfPickup && deliveryFeeRequired) ...[
                  DeliveryFeeStatus(
                    quote: deliveryFeeQuote,
                    isLoading: deliveryFeeLoading,
                    error: deliveryFeeError,
                    onRetry: onRetryDeliveryFee ?? () {},
                  ),
                  const SizedBox(height: 20.0),
                ],
                CheckoutSummary(
                  subtotal: subtotal,
                  sst: sst,
                  deliveryFee: effectiveDeliveryFee,
                  discount: discount,
                  total: total,
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
        CheckoutBottomBar(
          total: total,
          onPlaceOrder: onPlaceOrder,
          placeOrderEnabled: placeOrderEnabled,
          placeOrderLoading: placeOrderLoading,
          navigateToConfirmation: navigateToConfirmation,
          buttonText: buttonText,
          selectedPaymentMethod: selectedPaymentMethod,
          selectedSavedCard: selectedSavedCard,
        ),
      ],
    );
  }
}

void _noop() {}
void _noopValueChanged(bool _) {}

class FulfillmentOptionSwitch extends StatelessWidget {
  final bool isSelfPickup;
  final ValueChanged<bool> onOptionChanged;

  const FulfillmentOptionSwitch({
    super.key,
    required this.isSelfPickup,
    required this.onOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              context: context,
              title: 'Delivery',
              icon: Icons.delivery_dining_outlined,
              isSelected: !isSelfPickup,
              onTap: () => onOptionChanged(false),
            ),
          ),
          Expanded(
            child: _buildTab(
              context: context,
              title: 'Self Pickup',
              icon: Icons.storefront_outlined,
              isSelected: isSelfPickup,
              onTap: () => onOptionChanged(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6.0,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.0,
              color: isSelected
                  ? const Color(0xFFFFA07A)
                  : const Color(0xFF757575),
            ),
            const SizedBox(width: 8.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddressSelection extends StatelessWidget {
  final String address;
  final String? addressLabel;
  final VoidCallback onTap;

  const AddressSelection({
    super.key,
    required this.address,
    this.addressLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLabel = addressLabel != null && addressLabel!.trim().isNotEmpty;
    final isCurrentLocation = addressLabel == 'Current Location';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Address',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 12.0),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: const Color.fromARGB(255, 238, 238, 238),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 245, 245, 245),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    isCurrentLocation
                        ? Icons.my_location
                        : (addressLabel?.toLowerCase() == 'home'
                              ? Icons.home_outlined
                              : (addressLabel?.toLowerCase() == 'work' ||
                                        addressLabel?.toLowerCase() == 'office'
                                    ? Icons.work_outline
                                    : Icons.location_on)),
                    color: const Color.fromARGB(255, 255, 160, 122),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasLabel) ...[
                        Text(
                          addressLabel!,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xDD000000),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                      ],
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: hasLabel ? 12.5 : 14.0,
                          fontWeight: hasLabel
                              ? FontWeight.normal
                              : FontWeight.w500,
                          color: hasLabel
                              ? const Color(0xFF757575)
                              : const Color(0xDD000000),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color.fromARGB(255, 189, 189, 189),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CheckoutOrderItems extends StatelessWidget {
  final List<CartItem> cartItems;

  const CheckoutOrderItems({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    if (cartItems.isEmpty) {
      return const FallbackMessage(
        icon: Icons.shopping_bag_outlined,
        title: 'No Items to Checkout',
        description: 'Please add items to your cart first.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 12.0),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color.fromARGB(255, 238, 238, 238)),
          ),
          child: Column(
            children: cartItems.asMap().entries.map((entry) {
              int idx = entry.key;
              CartItem item = entry.value;
              double customTotal = item.customizations.fold(
                0.0,
                    (sum, c) => sum + c.price,
              );
              double itemTotal = (item.price + customTotal) * item.quantity;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: idx == cartItems.length - 1 ? 0 : 16.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 160, 122),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          if (item.customizations.isNotEmpty) ...[
                            const SizedBox(height: 4.0),
                            ...item.customizations.map(
                                  (c) => Text(
                                '• ${c.name}',
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: Color.fromARGB(255, 117, 117, 117),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      'RM ${itemTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class CheckoutVoucher extends StatelessWidget {
  final Map<String, dynamic>? appliedVoucher;
  final List<Map<String, dynamic>> availableVouchers;
  final double subtotal;
  final bool isSelfPickup;
  final Function(Map<String, dynamic>?) onVoucherApplied;

  const CheckoutVoucher({
    super.key,
    required this.appliedVoucher,
    required this.availableVouchers,
    required this.subtotal,
    required this.isSelfPickup,
    required this.onVoucherApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Voucher',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 12.0),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => VoucherSelectionBottomSheet(
                availableVouchers: availableVouchers,
                subtotal: subtotal,
                isSelfPickup: isSelfPickup,
                appliedVoucher: appliedVoucher,
                onVoucherApplied: (v) {
                  onVoucherApplied(v);
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: const Color.fromARGB(255, 238, 238, 238),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    appliedVoucher != null
                        ? appliedVoucher!['code'].toString().toUpperCase()
                        : 'Select or enter code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: appliedVoucher != null
                          ? const Color.fromARGB(221, 0, 0, 0)
                          : const Color.fromARGB(255, 158, 158, 158),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color.fromARGB(255, 189, 189, 189),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class VoucherSelectionBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> availableVouchers;
  final double subtotal;
  final bool isSelfPickup;
  final Map<String, dynamic>? appliedVoucher;
  final Function(Map<String, dynamic>?) onVoucherApplied;

  const VoucherSelectionBottomSheet({
    super.key,
    required this.availableVouchers,
    required this.subtotal,
    required this.isSelfPickup,
    required this.appliedVoucher,
    required this.onVoucherApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 224, 224, 224),
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Vouchers',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                if (appliedVoucher != null)
                  TextButton(
                    onPressed: () {
                      onVoucherApplied(null);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20.0),
            if (availableVouchers.isEmpty)
              const Text(
                'No vouchers available right now.',
                style: TextStyle(color: Color.fromARGB(255, 117, 117, 117)),
              )
            else
              ...availableVouchers.map((voucher) {
                final code = voucher['code'] ?? 'Voucher';
                final isFreeDelivery = voucher['is_free_delivery'] == true;
                final discountAmt = (voucher['discount_amount'] as num?)?.toDouble() ?? 0.0;
                final minSpend = (voucher['min_spend'] as num?)?.toDouble() ?? 0.0;
                final expiry = voucher['expiry_date'] ?? '';

                bool isUsable = subtotal >= minSpend;
                String disabledReason = '';

                if (!isUsable) {
                  disabledReason = 'Add RM ${(minSpend - subtotal).toStringAsFixed(2)} more to use';
                }

                if (isFreeDelivery && isSelfPickup) {
                  isUsable = false;
                  disabledReason = 'Not applicable for Self Pickup';
                }

                bool isSelected = appliedVoucher?['id'] == voucher['id'];

                return Opacity(
                  opacity: isUsable ? 1.0 : 0.4,
                  child: InkWell(
                    onTap: isUsable
                        ? () {
                      onVoucherApplied(voucher);
                      Navigator.pop(context);
                    }
                        : null,
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.1)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color.fromARGB(255, 255, 160, 122)
                              : const Color.fromARGB(255, 238, 238, 238),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFreeDelivery ? Icons.local_shipping : Icons.local_offer,
                              color: const Color.fromARGB(255, 255, 160, 122),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      code.toString().toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle, color: Color.fromARGB(255, 255, 160, 122), size: 20)
                                  ],
                                ),
                                const SizedBox(height: 4.0),

                                Text(
                                  isFreeDelivery ? 'Free Delivery' : 'RM ${discountAmt.toStringAsFixed(2)} Off',
                                  style: TextStyle(
                                    color: isUsable
                                        ? const Color.fromARGB(
                                            255,
                                            255,
                                            160,
                                            122,
                                          )
                                        : Colors.redAccent,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2.0),

                                if (!isUsable)
                                  Text(
                                    disabledReason,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 12.0, fontWeight: FontWeight.bold),
                                  )
                                else if (minSpend > 0)
                                  Text(
                                    'Min. spend RM ${minSpend.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Color.fromARGB(255, 117, 117, 117), fontSize: 12.0),
                                  )
                                else
                                  const Text(
                                    'No Minimum Spend',
                                    style: TextStyle(color: Color.fromARGB(255, 117, 117, 117), fontSize: 12.0),
                                  ),

                                if (expiry.isNotEmpty) ...[
                                  const SizedBox(height: 4.0),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Color.fromARGB(
                                          255,
                                          158,
                                          158,
                                          158,
                                        ),
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        'Valid till $expiry',
                                        style: const TextStyle(color: Color.fromARGB(255, 158, 158, 158), fontSize: 11.0),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class CheckoutPayment extends StatelessWidget {
  final String selectedPaymentMethod;
  final List<String> availablePaymentMethods;
  final Map<String, dynamic>? selectedSavedCard;
  final List<Map<String, dynamic>> savedCards;
  final bool savedCardsLoading;
  final Function(String paymentMethod, Map<String, dynamic>? savedCard)
  onPaymentMethodChanged;
  final VoidCallback onAddNewCard;

  const CheckoutPayment({
    super.key,
    required this.selectedPaymentMethod,
    required this.availablePaymentMethods,
    this.selectedSavedCard,
    this.savedCards = const [],
    this.savedCardsLoading = false,
    required this.onPaymentMethodChanged,
    this.onAddNewCard = _noop,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor = const Color.fromARGB(255, 255, 160, 122);
    String title = selectedPaymentMethod.isNotEmpty
        ? selectedPaymentMethod
        : 'Payment Method';
    String subtitle;

    if (selectedPaymentMethod == 'Cash on Delivery') {
      icon = Icons.payments_outlined;
      subtitle = 'Pay upon receiving your order.';
    } else if (selectedPaymentMethod == 'Credit / Debit Card') {
      if (selectedSavedCard != null &&
          selectedSavedCard!['card_brand'] == 'Visa') {
        icon = Icons.payment;
      } else {
        icon = Icons.credit_card;
      }
      if (selectedSavedCard != null) {
        final masked =
            selectedSavedCard!['card_number_masked']?.toString() ?? '';
        final last4 = masked.length >= 4
            ? masked.substring(masked.length - 4)
            : '••••';
        final brand = selectedSavedCard!['card_brand'] ?? 'Card';
        final exp = selectedSavedCard!['expiry_date'] ?? '';
        subtitle = '$brand •••• $last4 (Exp: $exp)';
      } else {
        subtitle = 'Enter card details at payment';
      }
    } else if (selectedPaymentMethod == 'Online Banking') {
      icon = Icons.account_balance_outlined;
      subtitle = 'FPX / Internet Banking';
    } else {
      icon = Icons.credit_card;
      subtitle = 'Select payment method';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 12.0),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => PaymentSelectionBottomSheet(
                availablePaymentMethods: availablePaymentMethods,
                selectedPaymentMethod: selectedPaymentMethod,
                selectedSavedCard: selectedSavedCard,
                savedCards: savedCards,
                savedCardsLoading: savedCardsLoading,
                onPaymentMethodSelected: onPaymentMethodChanged,
                onAddNewCard: onAddNewCard,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: const Color.fromARGB(255, 238, 238, 238),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      255,
                      160,
                      122,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: Color.fromARGB(255, 117, 117, 117),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color.fromARGB(255, 189, 189, 189),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PaymentSelectionBottomSheet extends StatefulWidget {
  final List<String> availablePaymentMethods;
  final String selectedPaymentMethod;
  final Map<String, dynamic>? selectedSavedCard;
  final List<Map<String, dynamic>> savedCards;
  final bool savedCardsLoading;
  final Function(String paymentMethod, Map<String, dynamic>? savedCard)
  onPaymentMethodSelected;
  final VoidCallback onAddNewCard;

  const PaymentSelectionBottomSheet({
    super.key,
    required this.availablePaymentMethods,
    required this.selectedPaymentMethod,
    this.selectedSavedCard,
    this.savedCards = const [],
    this.savedCardsLoading = false,
    required this.onPaymentMethodSelected,
    required this.onAddNewCard,
  });

  @override
  State<PaymentSelectionBottomSheet> createState() =>
      _PaymentSelectionBottomSheetState();
}

class _PaymentSelectionBottomSheetState
    extends State<PaymentSelectionBottomSheet> {
  late String _selectedMethod;
  Map<String, dynamic>? _selectedCard;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedPaymentMethod;
    _selectedCard = widget.selectedSavedCard;
  }

  void _selectMethod(String method) {
    setState(() {
      _selectedMethod = method;
    });
  }

  void _selectCard(Map<String, dynamic> card) {
    setState(() {
      _selectedMethod = 'Credit / Debit Card';
      if (_selectedCard?['id'] == card['id']) {
        _selectedCard = null;
      } else {
        _selectedCard = card;
      }
    });
  }

  Widget _buildCoDOption() {
    final isSelected = _selectedMethod == 'Cash on Delivery';
    return InkWell(
      onTap: () {
        _selectMethod('Cash on Delivery');
      },
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 255, 160, 122)
                : const Color.fromARGB(255, 238, 238, 238),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : const Color.fromARGB(255, 245, 245, 245),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                Icons.payments_outlined,
                color: isSelected
                    ? const Color.fromARGB(255, 255, 160, 122)
                    : const Color.fromARGB(255, 120, 120, 120),
                size: 24,
              ),
            ),
            const SizedBox(width: 14.0),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash on Delivery',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.0,
                    ),
                  ),
                  SizedBox(height: 3.0),
                  Text(
                    'Pay upon receiving your order.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color.fromARGB(255, 117, 117, 117),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color.fromARGB(255, 255, 160, 122)
                  : const Color.fromARGB(255, 200, 200, 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOption() {
    final isSelected = _selectedMethod == 'Credit / Debit Card';
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.06)
            : Colors.white,
        border: Border.all(
          color: isSelected
              ? const Color.fromARGB(255, 255, 160, 122)
              : const Color.fromARGB(255, 238, 238, 238),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _selectMethod('Credit / Debit Card'),
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : const Color.fromARGB(255, 245, 245, 245),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      Icons.credit_card,
                      color: isSelected
                          ? const Color.fromARGB(255, 255, 160, 122)
                          : const Color.fromARGB(255, 120, 120, 120),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Credit / Debit Card',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.0,
                          ),
                        ),
                        const SizedBox(height: 3.0),
                        const Text(
                          'Visa, Mastercard',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color.fromARGB(255, 117, 117, 117),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? const Color.fromARGB(255, 255, 160, 122)
                        : const Color.fromARGB(255, 200, 200, 200),
                  ),
                ],
              ),
            ),
          ),
          if (isSelected) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(
                height: 1,
                color: Color.fromARGB(255, 230, 230, 230),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Cards',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 117, 117, 117),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onAddNewCard();
                        },
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: Color.fromARGB(255, 255, 160, 122),
                        ),
                        label: const Text(
                          'Add New Card',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 160, 122),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  if (widget.savedCardsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color.fromARGB(255, 255, 160, 122),
                          ),
                        ),
                      ),
                    )
                  else if (widget.savedCards.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: const Color.fromARGB(255, 238, 238, 238),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.credit_card_off_outlined,
                                size: 20,
                                color: Color.fromARGB(255, 158, 158, 158),
                              ),
                              SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'No saved cards found for your account.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color.fromARGB(255, 117, 117, 117),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onAddNewCard();
                              },
                              icon: const Icon(
                                Icons.add,
                                size: 16,
                                color: Color.fromARGB(255, 255, 160, 122),
                              ),
                              label: const Text(
                                'Add a Card',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 255, 160, 122),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 255, 160, 122),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCard = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(12.0),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: _selectedCard == null
                              ? Colors.white
                              : const Color.fromARGB(255, 250, 250, 250),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: _selectedCard == null
                                ? const Color.fromARGB(255, 255, 160, 122)
                                : const Color.fromARGB(255, 230, 230, 230),
                            width: _selectedCard == null ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_note_outlined,
                              color: _selectedCard == null
                                  ? const Color.fromARGB(255, 255, 160, 122)
                                  : const Color.fromARGB(255, 140, 140, 140),
                              size: 22,
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                'Enter Card Details Manually',
                                style: TextStyle(
                                  fontWeight: _selectedCard == null
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            Icon(
                              _selectedCard == null
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _selectedCard == null
                                  ? const Color.fromARGB(255, 255, 160, 122)
                                  : const Color.fromARGB(255, 200, 200, 200),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...widget.savedCards.map((card) {
                      final isCardSelected = _selectedCard?['id'] == card['id'];
                      final isDefault = card['is_default'] == true;
                      final brand = card['card_brand'] ?? 'Card';
                      final maskedNumber =
                          card['card_number_masked'] ?? '•••• 0000';
                      final expiry = card['expiry_date'] ?? '00/00';
                      final holder = card['cardholder_name'] ?? '';

                      return InkWell(
                        onTap: () {
                          _selectCard(card);
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isCardSelected
                                ? Colors.white
                                : const Color.fromARGB(255, 250, 250, 250),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: isCardSelected
                                  ? const Color.fromARGB(255, 255, 160, 122)
                                  : const Color.fromARGB(255, 230, 230, 230),
                              width: isCardSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                brand == 'Visa'
                                    ? Icons.payment
                                    : Icons.credit_card,
                                color: isCardSelected
                                    ? const Color.fromARGB(255, 255, 160, 122)
                                    : const Color.fromARGB(255, 140, 140, 140),
                                size: 20,
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '$brand $maskedNumber',
                                          style: TextStyle(
                                            fontWeight: isCardSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        if (isDefault) ...[
                                          const SizedBox(width: 6.0),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6.0,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                40,
                                                255,
                                                160,
                                                122,
                                              ),
                                              borderRadius:
                                              BorderRadius.circular(4.0),
                                            ),
                                            child: const Text(
                                              'Default',
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                  255,
                                                  255,
                                                  160,
                                                  122,
                                                ),
                                                fontSize: 10.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      '$holder · Exp: $expiry',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color.fromARGB(
                                          255,
                                          140,
                                          140,
                                          140,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isCardSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isCardSelected
                                    ? const Color.fromARGB(255, 255, 160, 122)
                                    : const Color.fromARGB(255, 200, 200, 200),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOnlineBankingOption() {
    final isSelected = _selectedMethod == 'Online Banking';
    return InkWell(
      onTap: () {
        _selectMethod('Online Banking');
      },
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 255, 160, 122)
                : const Color.fromARGB(255, 238, 238, 238),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : const Color.fromARGB(255, 245, 245, 245),
              ),
              child: Icon(
                Icons.account_balance_outlined,
                color: isSelected
                    ? const Color.fromARGB(255, 255, 160, 122)
                    : const Color.fromARGB(255, 120, 120, 120),
                size: 24,
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Online Banking',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.0,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  const Text(
                    'FPX / Internet Banking (Maybank, CIMB, Public Bank, etc.)',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color.fromARGB(255, 117, 117, 117),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color.fromARGB(255, 255, 160, 122)
                  : const Color.fromARGB(255, 200, 200, 200),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 224, 224, 224),
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choose Payment Method',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCoDOption(),
                    const SizedBox(height: 14.0),
                    _buildCardOption(),
                    if (widget.availablePaymentMethods
                        .contains('Online Banking')) ...[
                      const SizedBox(height: 14.0),
                      _buildOnlineBankingOption(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onPaymentMethodSelected(
                    _selectedMethod,
                    _selectedCard,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryFeeStatus extends StatelessWidget {
  final DeliveryFeeQuote? quote;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const DeliveryFeeStatus({
    super.key,
    required this.quote,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _DeliveryFeeStatusCard(
        color: Color(0xffe3f2fd),
        icon: CircularProgressIndicator(strokeWidth: 2),
        message: 'Calculating the real road delivery fee…',
      );
    }

    final failure = error;
    if (failure != null) {
      return _DeliveryFeeStatusCard(
        color: const Color(0xffffebee),
        icon: const Icon(Icons.error_outline, color: Colors.redAccent),
        message: failure,
        action: TextButton(onPressed: onRetry, child: const Text('Retry')),
      );
    }

    final result = quote;
    if (result == null) return const SizedBox.shrink();
    final routeType = result.returnRequired ? 'return route' : 'one-way route';
    return _DeliveryFeeStatusCard(
      color: const Color(0xffe8f5e9),
      icon: const Icon(Icons.route, color: Colors.green),
      message:
      'Road distance: ${result.chargedRoadDistanceKm.toStringAsFixed(2)} km '
          '($routeType) · RON95 RM ${result.fuelPrice.ron95RinggitPerLitre.toStringAsFixed(2)}/L',
    );
  }
}

class _DeliveryFeeStatusCard extends StatelessWidget {
  final Color color;
  final Widget icon;
  final String message;
  final Widget? action;

  const _DeliveryFeeStatusCard({
    required this.color,
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24.0, height: 24.0, child: Center(child: icon)),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13.0, height: 1.3),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 4.0), action!],
        ],
      ),
    );
  }
}

class CheckoutSummary extends StatelessWidget {
  final double subtotal;
  final double sst;
  final double deliveryFee;
  final double discount;
  final double total;

  const CheckoutSummary({
    super.key,
    required this.subtotal,
    this.sst = 0.0,
    required this.deliveryFee,
    required this.discount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(15, 0, 0, 0),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(color: Color.fromARGB(255, 117, 117, 117)),
              ),
              Text(
                'RM ${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SST (6%)',
                style: TextStyle(color: Color.fromARGB(255, 117, 117, 117)),
              ),
              Text(
                'RM ${sst.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Fee',
                style: TextStyle(color: Color.fromARGB(255, 117, 117, 117)),
              ),
              Text(
                'RM ${deliveryFee.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Discount',
                  style: TextStyle(color: Color.fromARGB(255, 117, 117, 117)),
                ),
                Text(
                  '- RM ${discount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(
              height: 1,
              color: Color.fromARGB(255, 214, 214, 214),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              Text(
                'RM ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CheckoutBottomBar extends StatefulWidget {
  final double total;
  final FutureOr<void> Function() onPlaceOrder;
  final bool placeOrderEnabled;
  final bool placeOrderLoading;
  final bool navigateToConfirmation;
  final String buttonText;
  final String selectedPaymentMethod;
  final Map<String, dynamic>? selectedSavedCard;

  const CheckoutBottomBar({
    super.key,
    required this.total,
    required this.onPlaceOrder,
    this.placeOrderEnabled = true,
    this.placeOrderLoading = false,
    this.navigateToConfirmation = true,
    this.buttonText = 'Proceed to Payment',
    this.selectedPaymentMethod = 'Cash on Delivery',
    this.selectedSavedCard,
  });

  @override
  State<CheckoutBottomBar> createState() => _CheckoutBottomBarState();
}

class _CheckoutBottomBarState extends State<CheckoutBottomBar> {
  bool _isProcessing = false;

  Future<void> _handlePayment() async {
    if (_isProcessing) return;

    if (widget.selectedPaymentMethod == 'Cash on Delivery') {
      await widget.onPlaceOrder();
      if (!mounted || !widget.navigateToConfirmation) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerOrderConfirmation(
            totalPaid: widget.total,
            paymentMethod: widget.selectedPaymentMethod,
          ),
        ),
      );
      return;
    }

    if (widget.selectedPaymentMethod == 'Credit / Debit Card') {
      setState(() => _isProcessing = true);
      try {
        final success = await StripeService.handleCardPayment(
          context: context,
          amount: widget.total,
          selectedCard: widget.selectedSavedCard,
        );

        if (!mounted) return;

        if (success) {
          await widget.onPlaceOrder();
          if (!mounted || !widget.navigateToConfirmation) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerOrderConfirmation(
                totalPaid: widget.total,
                paymentMethod: 'Credit / Debit Card',
              ),
            ),
          );
        }
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment failed: ${error.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.selectedPaymentMethod} payment via Stripe sandbox is not enabled yet. Please select Cash on Delivery or Credit / Debit Card.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.placeOrderLoading || _isProcessing;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(15, 0, 0, 0),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: (widget.placeOrderEnabled && !isLoading)
              ? _handlePayment
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 160, 122),
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.buttonText,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
