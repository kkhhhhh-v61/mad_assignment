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
          .select()
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

  Future<void> _deleteVoucher(String id) async {
    try {
      await _supabase.from('vouchers').delete().eq('id', id);
      _fetchVouchers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher deleted!'), backgroundColor: Colors.redAccent),
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
                      'RM',
                      style: TextStyle(
                        color: isActive ? const Color.fromARGB(255, 255, 160, 122) : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${v['discount_amount']}',
                      style: TextStyle(
                        color: isActive ? const Color.fromARGB(255, 255, 160, 122) : Colors.grey,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? const Color.fromARGB(255, 255, 160, 122) : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              v['code'].toString().toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                            ),
                          ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'toggle') _toggleStatus(v['id'], isActive);
                              if (value == 'edit') _showVoucherModal(v);
                              if (value == 'delete') _deleteVoucher(v['id']);
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

  @override
  void initState() {
    super.initState();
    if (widget.existingVoucher != null) {
      _codeController.text = widget.existingVoucher!['code'];
      _discountController.text = widget.existingVoucher!['discount_amount'].toString();
      _minSpendController.text = widget.existingVoucher!['min_spend'].toString();
      _selectedDate = DateTime.parse(widget.existingVoucher!['expiry_date']);
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

    if (code.isEmpty || discountStr.isEmpty || _selectedDate == null) {
      _showError('Please fill in all required fields (Code, Discount, and Expiry Date).');
      return;
    }

    if (RegExp(r'[^A-Z0-9_\-]').hasMatch(code)) {
      _showError('Voucher code can only contain letters, numbers, underscores, and dashes. No symbols like @, #, \$, % allowed.');
      return;
    }

    final discount = double.tryParse(discountStr);
    if (discount == null) {
      _showError('Please enter a valid number for the discount amount.');
      return;
    }

    if (discount <= 0) {
      _showError('Discount amount must be greater than RM 0.');
      return;
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

    if (minSpend > 0 && minSpend <= discount) {
      _showError('Minimum spend (RM $minSpend) cannot be less than or equal to the discount amount (RM $discount).');
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_selectedDate!.isBefore(today)) {
      _showError('The expiry date cannot be set to a past date.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'code': code,
        'discount_amount': discount,
        'min_spend': minSpend,
        'expiry_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      };

      if (widget.existingVoucher == null) {
        await _supabase.from('vouchers').insert(payload);
      } else {
        await _supabase.from('vouchers').update(payload).eq('id', widget.existingVoucher!['id']);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
      }
    } catch (e) {
      print('Save error: $e');
      if (mounted) {
        _showError('This voucher code already exists in the system or a database error occurred.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 使用 Padding 将键盘高度整体垫在最底部，去掉多余的 SingleChildScrollView 导致的冲突
    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
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

          _buildFormInput(
              controller: _codeController,
              label: 'Voucher Code *',
              hint: 'e.g., NEWYEAR20',
              icon: Icons.local_offer_outlined
          ),
          const SizedBox(height: 16),

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