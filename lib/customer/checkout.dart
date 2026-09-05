import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Order/branch_repository.dart';
import '../Order/delivery_fee.dart';
import '../Order/order.dart';
import '../global.dart';
import '../rider/data_gov_my_fuel_price_repository.dart';
import '../services/states.dart';
import 'branch_selection.dart';
import 'cart.dart';
import 'header.dart';
import 'order_confirmation.dart';
import 'payment_methods.dart';
import 'saved_addresses.dart';
import '../services/stripe_service.dart';

class CustomerCheckout extends StatefulWidget {
  final List<CartItem>? cartItems;
  final String? deliveryAddress;
  final BranchSnapshot? branchSnapshot;
  final DeliveryAddressSnapshot? deliveryAddressSnapshot;
  final RoadDeliveryFeeService? deliveryFeeService;
  final BranchRepository? branchRepository;
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
  List<BranchRecord> _branches = [];
  BranchRecord? _selectedBranch;
  bool _branchesLoading = false;
  String? _branchesError;
  int _deliveryFeeRequestGeneration = 0;

  BranchSnapshot? get _effectiveBranchSnapshot =>
      _selectedBranch?.snapshot ?? widget.branchSnapshot;

  bool get _routedFeeEnabled =>
      (widget.deliveryAddressSnapshot != null &&
          (widget.branchSnapshot != null ||
              (widget.enableBranchSelection && _selectedBranch != null))) ||
      widget.deliveryFeeService != null;

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cartItems != null
        ? List<CartItem>.from(widget.cartItems!)
        : [];
    _isSelfPickup = false;
    final initialAddress = (widget.deliveryAddress != null &&
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

    //TODO: Retrieve checkout items, available addresses, payment methods, and vouchers dynamically from backend
    if (_cartItems.isEmpty) {
      _loadCartItems();
    }
    _loadAddresses();
    _loadPaymentMethods();
    if (widget.enableBranchSelection) {
      _loadBranches();
    }
    if (widget.branchSnapshot != null ||
        widget.deliveryAddressSnapshot != null ||
        widget.deliveryFeeService != null) {
      _loadRoutedDeliveryFee();
    }
  }

  void _setFulfillmentType(bool isSelfPickup) {
    if (_isSelfPickup == isSelfPickup) return;
    setState(() {
      _isSelfPickup = isSelfPickup;
      if (!_isSelfPickup && _selectedAddress.isEmpty) {
        _selectedAddress = CustomerHeader.cachedAddress;
      }
    });
  }

  Future<void> _loadAddresses() async {
    final AddressOption detected = CustomerHeader.cachedDetectedLocation ??
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
              ));

    final List<AddressOption> options = [];

    final headerSaved = CustomerHeader.cachedSavedAddresses;
    if (headerSaved != null) {
      for (final opt in headerSaved) {
        if (!options.any((o) => o.fullAddress == opt.fullAddress)) {
          options.add(opt);
        }
      }
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('address')
            .eq('id', user.id)
            .maybeSingle();
        final pAddr = profileRes?['address']?.toString().trim();
        if (pAddr != null && pAddr.isNotEmpty) {
          if (!options.any((o) => o.fullAddress == pAddr)) {
            options.insert(
              0,
              AddressOption(
                label: 'Default Address',
                fullAddress: pAddr,
                state: extractStateFromAddress(pAddr),
                isDefault: true,
              ),
            );
          }
        }

        final savedRes = await Supabase.instance.client
            .from('user_addresses')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        for (final row in savedRes) {
          final sAddr = row['full_address']?.toString().trim();
          final sLabel = row['label']?.toString().trim();
          if (sAddr != null && sAddr.isNotEmpty) {
            final existingIndex =
                options.indexWhere((o) => o.fullAddress == sAddr);
            if (existingIndex >= 0) {
              if (sLabel != null && sLabel.isNotEmpty) {
                options[existingIndex] = AddressOption(
                  label: sLabel,
                  fullAddress: sAddr,
                  state: extractStateFromAddress(sAddr),
                  isDefault: options[existingIndex].isDefault,
                );
              }
            } else {
              options.add(
                AddressOption(
                  label: (sLabel != null && sLabel.isNotEmpty)
                      ? sLabel
                      : 'Saved Address',
                  fullAddress: sAddr,
                  state: extractStateFromAddress(sAddr),
                ),
              );
            }
          }
        }
      }
    } catch (_) {}

    AddressOption? selectedOption = _selectedAddressOption;
    if (_selectedAddress.isNotEmpty) {
      selectedOption = options
          .where((o) => o.fullAddress == _selectedAddress)
          .firstOrNull;
      if (selectedOption == null &&
          detected.fullAddress == _selectedAddress) {
        selectedOption = detected;
      }
      selectedOption ??= AddressOption(
        label: 'Delivery Address',
        fullAddress: _selectedAddress,
        state: extractStateFromAddress(_selectedAddress),
      );
    } else if (options.isNotEmpty) {
      selectedOption = options.first;
      _selectedAddress = options.first.fullAddress;
    } else {
      selectedOption = detected;
      _selectedAddress = detected.fullAddress;
    }

    if (mounted) {
      setState(() {
        _detectedLocation = detected;
        _addressOptions = options;
        _selectedAddressOption = selectedOption;
      });
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
                if (_savedCards.isNotEmpty) {
                  _selectedSavedCard = _savedCards.first;
                }
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
        oldWidget.enableBranchSelection != widget.enableBranchSelection ||
        oldWidget.returnRequired != widget.returnRequired) {
      if (oldWidget.branchSnapshot?.branchId !=
          widget.branchSnapshot?.branchId) {
        _selectedBranch = null;
      }
      if (widget.enableBranchSelection) {
        _loadBranches();
      }
      if (_routedFeeEnabled) {
        _selectedAddress =
            widget.deliveryAddressSnapshot?.formattedAddress ?? '';
        _loadRoutedDeliveryFee();
      } else {
        _deliveryFeeQuote = null;
        _deliveryFeeLoading = false;
        _deliveryFeeError = null;
        _deliveryFee = 0.0;
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
                branch.address.toLowerCase().contains(candidateState.toLowerCase()) ||
                branch.name.toLowerCase().contains(candidateState.toLowerCase())) {
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
      if (widget.deliveryAddressSnapshot != null &&
          _effectiveBranchSnapshot != null) {
        _loadRoutedDeliveryFee();
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
      _deliveryFeeQuote = null;
      _deliveryFeeError = null;
      _deliveryFee = 0.0;
    });
    if (widget.deliveryAddressSnapshot != null) {
      _loadRoutedDeliveryFee();
    }
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
    final generation = ++_deliveryFeeRequestGeneration;
    setState(() {
      _deliveryFeeLoading = true;
      _deliveryFeeError = null;
      _deliveryFeeQuote = null;
      _deliveryFee = 0.0;
    });

    final branch = _effectiveBranchSnapshot;
    final destination = widget.deliveryAddressSnapshot;
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

  @override
  void dispose() {
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                  ..._addressOptions.map((addr) => _buildAddressOptionTile(
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
                      )),
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
        setState(() {
          _selectedAddressOption = option;
          _selectedAddress = option.fullAddress;
          if (!_isSelfPickup && _branches.isNotEmpty) {
            final addressState = option.state.isNotEmpty
                ? option.state
                : extractStateFromAddress(option.fullAddress);
            if (addressState.isNotEmpty) {
              for (final branch in _branches) {
                if (isSameState(branch.stateCode, addressState) ||
                    branch.address
                        .toLowerCase()
                        .contains(addressState.toLowerCase()) ||
                    branch.name
                        .toLowerCase()
                        .contains(addressState.toLowerCase())) {
                  _selectedBranch = branch;
                  break;
                }
              }
            }
          }
        });
        Navigator.pop(sheetContext);
        if (!_isSelfPickup && widget.deliveryAddressSnapshot != null) {
          _loadRoutedDeliveryFee();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 0,
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
          onVoucherApplied: (voucher) {
            setState(() {
              _appliedVoucher = voucher;
            });
          },
          onPlaceOrder: () {
            setState(() {
              _cartItems.clear();
            });
            CartStorage.clearCart();
          },
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
  final VoidCallback onPlaceOrder;

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
      if (appliedVoucher!['type'] == 'free_delivery') {
        discount = effectiveDeliveryFee;
      } else if (appliedVoucher!['type'] == 'percentage') {
        discount = subtotal * (appliedVoucher!['discountValue'] as double) / 100;
      }
    }

    final double sst = subtotal * 0.06;
    double total = subtotal + sst + effectiveDeliveryFee - discount;
    if (total < 0) total = 0;

    final addressReady = isSelfPickup || selectedAddress.trim().isNotEmpty;
    final effectiveBranchReady = isSelfPickup
        ? (selectedBranch != null || fallbackBranchSnapshot != null)
        : true;
    final effectiveFeeReady = isSelfPickup
        ? true
        : ((!deliveryFeeRequired && !deliveryFeeLoading) ||
            (deliveryFeeQuote != null && deliveryFeeError == null));

    final placeOrderEnabled = cartItems.isNotEmpty &&
        addressReady &&
        effectiveBranchReady &&
        effectiveFeeReady;

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
              border:
                  Border.all(color: const Color.fromARGB(255, 238, 238, 238)),
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
                          fontWeight:
                              hasLabel ? FontWeight.normal : FontWeight.w500,
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
  final Function(Map<String, dynamic>?) onVoucherApplied;

  const CheckoutVoucher({
    super.key,
    required this.appliedVoucher,
    required this.availableVouchers,
    required this.subtotal,
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
                appliedVoucher: appliedVoucher,
                onVoucherApplied: (v) {
                  onVoucherApplied(v);
                  Navigator.pop(context);
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color.fromARGB(255, 238, 238, 238)),
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
                        ? appliedVoucher!['title']
                        : 'No voucher applied',
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
  final Map<String, dynamic>? appliedVoucher;
  final Function(Map<String, dynamic>?) onVoucherApplied;

  const VoucherSelectionBottomSheet({
    super.key,
    required this.availableVouchers,
    required this.subtotal,
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
                    onPressed: () => onVoucherApplied(null),
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
                'No vouchers available.',
                style: TextStyle(color: Color.fromARGB(255, 117, 117, 117)),
              )
            else
              ...availableVouchers.map((voucher) {
                bool isUsable = subtotal >= (voucher['minSpend'] as double);
                bool isSelected = appliedVoucher?['id'] == voucher['id'];

                return Opacity(
                  opacity: isUsable ? 1.0 : 0.5,
                  child: InkWell(
                    onTap: isUsable ? () => onVoucherApplied(voucher) : null,
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromARGB(
                                255,
                                255,
                                160,
                                122,
                              ).withValues(alpha: 0.1)
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
                              color: const Color.fromARGB(
                                255,
                                255,
                                160,
                                122,
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_offer,
                              color: Color.fromARGB(255, 255, 160, 122),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  voucher['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  'Min. spend RM ${voucher['minSpend'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isUsable
                                        ? const Color.fromARGB(255, 117, 117, 117)
                                        : Colors.redAccent,
                                    fontSize: 13.0,
                                    fontWeight: isUsable
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                                if (voucher.containsKey('expiryDate')) ...[
                                  const SizedBox(height: 4.0),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Color.fromARGB(255, 158, 158, 158),
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        voucher['expiryDate'],
                                        style: const TextStyle(
                                          color: Color.fromARGB(
                                            255,
                                            158,
                                            158,
                                            158,
                                          ),
                                          fontSize: 12.0,
                                        ),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border:
                  Border.all(color: const Color.fromARGB(255, 238, 238, 238)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 160, 122)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
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

  void _selectCard(Map<String, dynamic>? card) {
    setState(() {
      _selectedMethod = 'Credit / Debit Card';
      _selectedCard = card;
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
                  // Option: Enter Card Details Manually (No saved card)
                  InkWell(
                    onTap: () {
                      _selectCard(null);
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Cards (Optional)',
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
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: const Color.fromARGB(255, 238, 238, 238),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Color.fromARGB(255, 158, 158, 158),
                          ),
                          SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              'No saved cards. Card details will be entered manually at payment.',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Color.fromARGB(255, 117, 117, 117),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
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
                          // Tap to toggle selection: if already selected, unselect to manual entry
                          if (isCardSelected) {
                            _selectCard(null);
                          } else {
                            _selectCard(card);
                          }
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
                                        color:
                                            Color.fromARGB(255, 140, 140, 140),
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
              ),
            ),
          ],
        ],
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
                  style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
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
                    _selectedMethod == 'Credit / Debit Card'
                        ? _selectedCard
                        : null,
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
            child: Divider(height: 1, color: Color.fromARGB(255, 214, 214, 214)),
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
  final VoidCallback onPlaceOrder;
  final bool placeOrderEnabled;
  final String buttonText;
  final String selectedPaymentMethod;
  final Map<String, dynamic>? selectedSavedCard;

  const CheckoutBottomBar({
    super.key,
    required this.total,
    required this.onPlaceOrder,
    this.placeOrderEnabled = true,
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
      widget.onPlaceOrder();
      Navigator.push(
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
          widget.onPlaceOrder();
          Navigator.push(
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
          onPressed: (widget.placeOrderEnabled && !_isProcessing)
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
          child: _isProcessing
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
