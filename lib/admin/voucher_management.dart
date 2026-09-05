import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminVoucherManagement extends StatefulWidget {
  const AdminVoucherManagement({super.key});

  @override
  State<AdminVoucherManagement> createState() => _AdminVoucherManagementState();
}

class _AdminVoucherManagementState extends State<AdminVoucherManagement> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVouchers();
  }

  Future<void> _fetchVouchers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('vouchers')
          .select('*, profiles(name)')
          .order('created_at', ascending: false);

      setState(() {
        _vouchers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching vouchers: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(String id, bool currentStatus) async {
    try {
      await _supabase.from('vouchers').update({'is_active': !currentStatus}).eq('id', id);
      _fetchVouchers();
    } catch (e) {
      print('Error toggling status: $e');
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Delete Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this voucher? This action cannot be undone.',
          style: TextStyle(color: Colors.black87, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteVoucher(id);
    }
  }

  Future<void> _deleteVoucher(String id) async {
    try {
      await _supabase.from('vouchers').delete().eq('id', id);
      _fetchVouchers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher deleted successfully!', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      print('Error deleting voucher: $e');
    }
  }

  void _showVoucherModal([Map<String, dynamic>? voucher]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (context) => VoucherForm(
        existingVoucher: voucher,
        onSave: _fetchVouchers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Vouchers', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18.0)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 255, 160, 122),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Voucher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showVoucherModal(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 255, 160, 122)))
          : _vouchers.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _vouchers.length,
        itemBuilder: (context, index) {
          final v = _vouchers[index];
          final isActive = v['is_active'] == true;

          return _buildCouponCard(v, isActive);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No vouchers created yet.', style: TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> v, bool isActive) {
    final customerData = v['profiles'];
    final targetName = customerData != null ? customerData['name'] : 'All Customers';
    final isSpecific = customerData != null;
    final isFreeDelivery = v['is_free_delivery'] == true;

    return Opacity(
      opacity: isActive ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        elevation: 0,
        color: Colors.white,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color.fromARGB(255, 255, 160, 122).withOpacity(0.15)
                      : Colors.grey.shade100,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(15.0)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isFreeDelivery ? 'FREE' : 'RM',
                      style: TextStyle(
                        color: isActive ? const Color.fromARGB(255, 255, 160, 122) : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: isFreeDelivery ? 20 : 14,
                      ),
                    ),
                    if (!isFreeDelivery)
                      Text(
                        '${v['discount_amount']}',
                        style: TextStyle(
                          color: isActive ? const Color.fromARGB(255, 255, 160, 122) : Colors.grey,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          height: 1.1,
                        ),
                      ),
                    if (isFreeDelivery)
                      Text(
                        'DELIVERY',
                        style: TextStyle(
                          color: isActive ? const Color.fromARGB(255, 255, 160, 122) : Colors.grey,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          height: 1.1,
                        ),
                      ),
                  ],
                ),
              ),

              Container(
                width: 1.5,
                color: Colors.grey.shade200,
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? const Color.fromARGB(255, 255, 160, 122) : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                v['code'].toString().toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'toggle') _toggleStatus(v['id'], isActive);
                              if (value == 'edit') _showVoucherModal(v);
                              if (value == 'delete') _confirmDelete(v['id']);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(isActive ? Icons.visibility_off : Icons.visibility, color: Colors.black54, size: 20),
                                    const SizedBox(width: 12),
                                    Text(isActive ? 'Deactivate' : 'Activate'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, color: Colors.black54, size: 20),
                                    SizedBox(width: 12),
                                    Text('Edit Voucher'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    SizedBox(width: 12),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(isSpecific ? Icons.person : Icons.people_alt, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              targetName,
                              style: TextStyle(
                                color: isSpecific ? const Color.fromARGB(255, 255, 160, 122) : Colors.black87,
                                fontSize: 13,
                                fontWeight: isSpecific ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('Min. Spend: RM ${v['min_spend']}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('Expires: ${v['expiry_date']}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                        ],
                      ),
                    ],
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

class VoucherForm extends StatefulWidget {
  final Map<String, dynamic>? existingVoucher;
  final VoidCallback onSave;

  const VoucherForm({super.key, this.existingVoucher, required this.onSave});

  @override
  State<VoucherForm> createState() => _VoucherFormState();
}

class _VoucherFormState extends State<VoucherForm> {
  final _supabase = Supabase.instance.client;
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final _minSpendController = TextEditingController();
  DateTime? _selectedDate;

  bool _isSaving = false;
  String? _errorMessage;

  bool _isForAll = true;
  String? _selectedCustomerId;
  List<Map<String, dynamic>> _customers = [];
  bool _isLoadingCustomers = false;

  bool _isFreeDelivery = false;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();

    if (widget.existingVoucher != null) {
      _codeController.text = widget.existingVoucher!['code'];
      _discountController.text = widget.existingVoucher!['discount_amount'].toString();
      _minSpendController.text = widget.existingVoucher!['min_spend'].toString();
      _selectedDate = DateTime.parse(widget.existingVoucher!['expiry_date']);

      _isFreeDelivery = widget.existingVoucher!['is_free_delivery'] == true;

      if (widget.existingVoucher!['customer_id'] != null) {
        _isForAll = false;
        _selectedCustomerId = widget.existingVoucher!['customer_id'];
      }
    }
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, name, phone')
          .eq('role', 'customer')
          .order('name');
      if (mounted) {
        setState(() {
          _customers = List<Map<String, dynamic>>.from(response);
          _isLoadingCustomers = false;
        });
      }
    } catch (e) {
      print('Error fetching customers: $e');
      if (mounted) setState(() => _isLoadingCustomers = false);
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 255, 160, 122),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _errorMessage = null);

    final code = _codeController.text.trim().toUpperCase();
    final discountStr = _discountController.text.trim();
    final minSpendStr = _minSpendController.text.trim();

    if (code.isEmpty || _selectedDate == null) {
      _showError('Please fill in all required fields.');
      return;
    }

    if (!_isFreeDelivery && discountStr.isEmpty) {
      _showError('Please enter a discount amount.');
      return;
    }

    if (RegExp(r'[^A-Z0-9_\-]').hasMatch(code)) {
      _showError('Voucher code can only contain letters, numbers, underscores, and dashes.');
      return;
    }

    double discount = 0.0;
    if (!_isFreeDelivery) {
      final parsed = double.tryParse(discountStr);
      if (parsed == null || parsed <= 0) {
        _showError('Discount amount must be greater than RM 0.');
        return;
      }
      discount = parsed;
    }

    double minSpend = 0.0;
    if (minSpendStr.isNotEmpty) {
      final parsedMinSpend = double.tryParse(minSpendStr);
      if (parsedMinSpend == null) {
        _showError('Please enter a valid number for the minimum spend.');
        return;
      }
      minSpend = parsedMinSpend;
    }

    if (!_isFreeDelivery && minSpend > 0 && minSpend <= discount) {
      _showError('Minimum spend cannot be less than or equal to the discount amount.');
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_selectedDate!.isBefore(today)) {
      _showError('The expiry date cannot be set to a past date.');
      return;
    }

    if (!_isForAll && _selectedCustomerId == null) {
      _showError('Please select a specific customer to assign this voucher to.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'code': code,
        'discount_amount': discount,
        'min_spend': minSpend,
        'expiry_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'customer_id': _isForAll ? null : _selectedCustomerId,
        'is_free_delivery': _isFreeDelivery,
      };

      if (widget.existingVoucher == null) {
        await _supabase.from('vouchers').insert(payload);

        final notifTitle = _isForAll ? 'New Voucher Available!' : 'Exclusive Reward for You!';
        final notifDesc = 'Use code $code to enjoy ${_isFreeDelivery ? "Free Delivery" : "RM ${discount.toStringAsFixed(2)} off"}!';

        if (_isForAll) {
          final payloads = _customers.map((c) => {
            'user_id': c['id'],
            'title': notifTitle,
            'description': notifDesc,
            'type': 'Promos',
            'is_read': false,
          }).toList();
          if (payloads.isNotEmpty) {
            await _supabase.from('notifications').insert(payloads);
          }
        } else {
          await _supabase.from('notifications').insert({
            'user_id': _selectedCustomerId,
            'title': notifTitle,
            'description': notifDesc,
            'type': 'Promos',
            'is_read': false,
          });
        }
      } else {
        await _supabase.from('vouchers').update(payload).eq('id', widget.existingVoucher!['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingVoucher == null
                  ? 'Voucher created successfully!'
                  : 'Voucher updated successfully!',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: const Color.fromARGB(255, 76, 175, 80),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
        widget.onSave();
      }

    } on PostgrestException catch (e) {
      print('Supabase DB Error: ${e.message}');
      if (mounted) {
        if (e.code == '23505') {
          _showError('This voucher code already exists! Please use a different code.');
        } else {
          _showError('DB Error: ${e.message}');
        }
      }
    } catch (e) {
      print('Save error: $e');
      if (mounted) {
        _showError('Unexpected error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.existingVoucher == null ? 'Create Voucher' : 'Edit Voucher', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 12),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

            const Text('Voucher Type', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isFreeDelivery = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isFreeDelivery ? const Color.fromARGB(255, 255, 160, 122).withOpacity(0.15) : const Color.fromARGB(255, 245, 245, 245),
                        border: Border.all(color: !_isFreeDelivery ? const Color.fromARGB(255, 255, 160, 122) : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Fixed Discount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_isFreeDelivery ? const Color.fromARGB(255, 255, 160, 122) : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isFreeDelivery = true;
                      _discountController.clear();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isFreeDelivery ? const Color.fromARGB(255, 255, 160, 122).withOpacity(0.15) : const Color.fromARGB(255, 245, 245, 245),
                        border: Border.all(color: _isFreeDelivery ? const Color.fromARGB(255, 255, 160, 122) : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Free Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isFreeDelivery ? const Color.fromARGB(255, 255, 160, 122) : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('Target Audience', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isForAll = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isForAll ? const Color.fromARGB(255, 255, 160, 122).withOpacity(0.15) : const Color.fromARGB(255, 245, 245, 245),
                        border: Border.all(color: _isForAll ? const Color.fromARGB(255, 255, 160, 122) : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'All Customers',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isForAll ? const Color.fromARGB(255, 255, 160, 122) : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isForAll = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isForAll ? const Color.fromARGB(255, 255, 160, 122).withOpacity(0.15) : const Color.fromARGB(255, 245, 245, 245),
                        border: Border.all(color: !_isForAll ? const Color.fromARGB(255, 255, 160, 122) : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Specific Customer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_isForAll ? const Color.fromARGB(255, 255, 160, 122) : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (!_isForAll) ...[
              const SizedBox(height: 16),
              _isLoadingCustomers
                  ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 255, 160, 122)))
                  : DropdownButtonFormField<String>(
                value: _selectedCustomerId,
                hint: const Text('Select a customer', style: TextStyle(color: Colors.black54)),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(255, 245, 245, 245),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
                ),
                items: _customers.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['id'].toString(),
                    child: Text('${c['name']} (${c['phone'] ?? "No phone"})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCustomerId = val;
                    _errorMessage = null;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),

            _buildFormInput(
                controller: _codeController,
                label: 'Voucher Code *',
                hint: 'e.g., FREESHIP2026',
                icon: Icons.local_offer_outlined
            ),
            const SizedBox(height: 16),

            if (!_isFreeDelivery)
              Row(
                children: [
                  Expanded(
                      child: _buildFormInput(
                          controller: _discountController,
                          label: 'Discount (RM) *',
                          hint: '10.00',
                          icon: Icons.payments_outlined,
                          isNumber: true
                      )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildFormInput(
                          controller: _minSpendController,
                          label: 'Min Spend (RM)',
                          hint: '25.00',
                          icon: Icons.shopping_cart_outlined,
                          isNumber: true
                      )
                  ),
                ],
              )
            else
              _buildFormInput(
                  controller: _minSpendController,
                  label: 'Min Spend (RM) [Optional]',
                  hint: 'e.g., 25.00',
                  icon: Icons.shopping_cart_outlined,
                  isNumber: true
              ),

            const SizedBox(height: 16),

            const Text('Expiry Date *', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6.0),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(15.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 245, 245, 245),
                    borderRadius: BorderRadius.circular(15.0)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.black54, size: 20),
                    const SizedBox(width: 12),
                    Text(
                        _selectedDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        style: TextStyle(
                            fontSize: 15,
                            color: _selectedDate == null ? const Color.fromARGB(255, 158, 158, 158) : Colors.black87
                        )
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Voucher', style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFormInput({required TextEditingController controller, required String label, required String hint, required IconData icon, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6.0),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          textCapitalization: isNumber ? TextCapitalization.none : TextCapitalization.characters,
          onChanged: (val) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
          style: const TextStyle(fontSize: 15.0, letterSpacing: 1.0),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color.fromARGB(255, 158, 158, 158), letterSpacing: 0),
            filled: true,
            fillColor: const Color.fromARGB(255, 245, 245, 245),
            prefixIcon: Icon(icon, color: Colors.black54, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: const BorderSide(color: Color.fromARGB(255, 255, 160, 122), width: 1.5)),
          ),
        ),
      ],
    );
  }
}
