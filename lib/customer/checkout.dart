import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Order/branch_repository.dart';
import '../Order/delivery_fee.dart';
import '../Order/order.dart';
import '../global.dart';
import '../rider/data_gov_my_fuel_price_repository.dart';
import 'branch_selection.dart';
import 'cart.dart';
import 'order_confirmation.dart';

class CustomerCheckout extends StatefulWidget {
  final BranchSnapshot? branchSnapshot;
  final DeliveryAddressSnapshot? deliveryAddressSnapshot;
  final RoadDeliveryFeeService? deliveryFeeService;
  final BranchRepository? branchRepository;
  final bool enableBranchSelection;
  final bool returnRequired;

  const CustomerCheckout({
    super.key,
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
  late String _selectedAddress;
  late List<String> _addresses;
  late String _selectedPaymentMethod;
  late List<String> _availablePaymentMethods;
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
      widget.branchSnapshot != null ||
      widget.deliveryAddressSnapshot != null ||
      widget.deliveryFeeService != null ||
      (widget.enableBranchSelection && _selectedBranch != null);

  @override
  void initState() {
    super.initState();
    _cartItems = [];
    _selectedAddress = widget.deliveryAddressSnapshot?.formattedAddress ?? '';
    _addresses = [];
    _selectedPaymentMethod = '';
    _availablePaymentMethods = [];
    _appliedVoucher = null;
    _deliveryFee = 0.0;
    _availableVouchers = [];

    //TODO: Retrieve checkout items, available addresses, payment methods, and vouchers dynamically from backend
    if (widget.enableBranchSelection) {
      _loadBranches();
    }
    if (widget.branchSnapshot != null ||
        widget.deliveryAddressSnapshot != null ||
        widget.deliveryFeeService != null) {
      _loadRoutedDeliveryFee();
    }
  }

  @override
  void didUpdateWidget(covariant CustomerCheckout oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  void _showAddressSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 224, 224, 224),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ..._addresses.map((String address) {
                final isSelected = _selectedAddress == address;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAddress = address;
                    });
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 12.0),
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
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
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
                            Icons.location_on,
                            color: isSelected
                                ? const Color.fromARGB(255, 255, 160, 122)
                                : const Color.fromARGB(255, 158, 158, 158),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color.fromARGB(255, 255, 160, 122),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          onPressed: () => Navigator.pop(context),
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
        branchSelectionEnabled: widget.enableBranchSelection,
        selectedBranch: _selectedBranch,
        fallbackBranchSnapshot: widget.branchSnapshot,
        branches: _branches,
        branchLoading: _branchesLoading,
        branchError: _branchesError,
        onBranchTap: () => _showBranchSelectionDialog(context),
        onRetryBranches: _loadBranches,
        selectedAddress: _selectedAddress,
        onAddressTap: () => _showAddressSelectionDialog(context),
        selectedPaymentMethod: _selectedPaymentMethod,
        availablePaymentMethods: _availablePaymentMethods,
        onPaymentMethodChanged: (method) {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
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
        },
      ),
    );
  }
}

class CheckoutLayout extends StatelessWidget {
  final List<CartItem> cartItems;
  final bool branchSelectionEnabled;
  final BranchRecord? selectedBranch;
  final BranchSnapshot? fallbackBranchSnapshot;
  final List<BranchRecord> branches;
  final bool branchLoading;
  final String? branchError;
  final VoidCallback onBranchTap;
  final VoidCallback onRetryBranches;
  final String selectedAddress;
  final VoidCallback onAddressTap;
  final String selectedPaymentMethod;
  final List<String> availablePaymentMethods;
  final Function(String) onPaymentMethodChanged;
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
    this.branchSelectionEnabled = false,
    this.selectedBranch,
    this.fallbackBranchSnapshot,
    this.branches = const [],
    this.branchLoading = false,
    this.branchError,
    this.onBranchTap = _noop,
    this.onRetryBranches = _noop,
    required this.selectedAddress,
    required this.onAddressTap,
    required this.selectedPaymentMethod,
    required this.availablePaymentMethods,
    required this.onPaymentMethodChanged,
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

    double discount = 0.0;
    if (appliedVoucher != null) {
      if (appliedVoucher!['type'] == 'free_delivery') {
        discount = deliveryFee;
      } else if (appliedVoucher!['type'] == 'percentage') {
        discount = subtotal * (appliedVoucher!['discountValue'] as double) / 100;
      }
    }

    double total = subtotal + deliveryFee - discount;
    if (total < 0) total = 0;

    final branchReady =
        !branchSelectionEnabled ||
        selectedBranch != null ||
        fallbackBranchSnapshot != null;
    final feeReady =
        (!deliveryFeeRequired && !deliveryFeeLoading) ||
        (deliveryFeeQuote != null && deliveryFeeError == null);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (branchSelectionEnabled) ...[
                  BranchSelection(
                    selectedBranch: selectedBranch,
                    fallbackSnapshot: fallbackBranchSnapshot,
                    branches: branches,
                    isLoading: branchLoading,
                    error: branchError,
                    onTap: onBranchTap,
                    onRetry: onRetryBranches,
                  ),
                  const SizedBox(height: 20.0),
                ],
                AddressSelection(
                  address: selectedAddress,
                  onTap: onAddressTap,
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
                  onPaymentMethodChanged: onPaymentMethodChanged,
                ),
                const SizedBox(height: 20.0),
                if (deliveryFeeRequired)
                  DeliveryFeeStatus(
                    quote: deliveryFeeQuote,
                    isLoading: deliveryFeeLoading,
                    error: deliveryFeeError,
                    onRetry: onRetryDeliveryFee ?? () {},
                  ),
                if (deliveryFeeRequired) const SizedBox(height: 20.0),
                CheckoutSummary(
                  subtotal: subtotal,
                  deliveryFee: deliveryFee,
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
          placeOrderEnabled: cartItems.isNotEmpty && branchReady && feeReady,
        ),
      ],
    );
  }
}

void _noop() {}

class AddressSelection extends StatelessWidget {
  final String address;
  final VoidCallback onTap;

  const AddressSelection({
    super.key,
    required this.address,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              border: Border.all(color: const Color.fromARGB(255, 238, 238, 238)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 245, 245, 245),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color.fromARGB(255, 255, 160, 122),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
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
  final Function(String) onPaymentMethodChanged;

  const CheckoutPayment({
    super.key,
    required this.selectedPaymentMethod,
    required this.availablePaymentMethods,
    required this.onPaymentMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                onPaymentMethodChanged: (method) {
                  onPaymentMethodChanged(method);
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
                  Icons.credit_card,
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    selectedPaymentMethod,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

class PaymentSelectionBottomSheet extends StatelessWidget {
  final List<String> availablePaymentMethods;
  final String selectedPaymentMethod;
  final Function(String) onPaymentMethodChanged;

  const PaymentSelectionBottomSheet({
    super.key,
    required this.availablePaymentMethods,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
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
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20.0),
            ...availablePaymentMethods.map((method) {
              bool isSelected = method == selectedPaymentMethod;
              return InkWell(
                onTap: () => onPaymentMethodChanged(method),
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
                    children: [
                      Icon(
                        method == 'Credit Card'
                            ? Icons.credit_card
                            : method == 'Cash on Delivery'
                            ? Icons.money
                            : method == 'E-Wallet'
                            ? Icons.account_balance_wallet
                            : Icons.account_balance,
                        color: const Color.fromARGB(255, 255, 160, 122),
                        size: 24,
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Text(
                          method,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color.fromARGB(255, 255, 160, 122),
                        ),
                    ],
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
  final double deliveryFee;
  final double discount;
  final double total;

  const CheckoutSummary({
    super.key,
    required this.subtotal,
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

class CheckoutBottomBar extends StatelessWidget {
  final double total;
  final VoidCallback onPlaceOrder;
  final bool placeOrderEnabled;

  const CheckoutBottomBar({
    super.key,
    required this.total,
    required this.onPlaceOrder,
    this.placeOrderEnabled = true,
  });

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
          onPressed: placeOrderEnabled
              ? () {
                  //TODO: Submit order details to backend API and handle response
                  onPlaceOrder();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerOrderConfirmation(totalPaid: total),
                    ),
                  );
                }
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
          child: const Text(
            'Place Order',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
