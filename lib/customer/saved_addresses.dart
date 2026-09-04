import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _supabase = Supabase.instance.client;

  String? _mainAddress;
  List<Map<String, dynamic>> _otherAddresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      final profileRes = await _supabase
          .from('profiles')
          .select('address')
          .eq('id', userId)
          .single();

      final otherRes = await _supabase
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _mainAddress = profileRes['address'];
        _otherAddresses = List<Map<String, dynamic>>.from(otherRes);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching addresses: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 8),
              Text('Delete Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this address? This action cannot be undone.',
            style: TextStyle(color: Colors.black87, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _supabase.from('user_addresses').delete().eq('id', addressId);
      _fetchAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Color.fromARGB(255, 255, 160, 122),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,),
        );
      }
    }
  }

  void _navigateToForm({String? addressId, String? initialLabel, String? initialAddress}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressFormScreen(
          addressId: addressId,
          initialLabel: initialLabel,
          initialAddress: initialAddress,
        ),
      ),
    );

    if (result == true) {
      _fetchAddresses();
    }
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
        title: const Text(
          'Saved Addresses',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 255, 160, 122)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Default Address', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12.0),
            _buildAddressCard(
              label: 'Main Address',
              address: _mainAddress ?? 'No main address set',
              isMain: true,
              onEdit: () => _navigateToForm(
                addressId: 'main',
                initialLabel: 'Main Address',
                initialAddress: _mainAddress,
              ),
            ),

            const SizedBox(height: 24.0),

            const Text('Other Saved Addresses', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12.0),
            if (_otherAddresses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  border: Border.all(color: const Color.fromARGB(255, 238, 238, 238)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.location_off_outlined, size: 48, color: Colors.black26),
                    SizedBox(height: 8),
                    Text('No other addresses saved yet.', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              )
            else
              ..._otherAddresses.map((addr) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildAddressCard(
                  label: addr['label'],
                  address: addr['full_address'],
                  isMain: false,
                  onEdit: () => _navigateToForm(
                    addressId: addr['id'],
                    initialLabel: addr['label'],
                    initialAddress: addr['full_address'],
                  ),
                  onDelete: () => _deleteAddress(addr['id']),
                ),
              )),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: const Color.fromARGB(255, 255, 160, 122),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAddressCard({
    required String label,
    required String address,
    required bool isMain,
    required VoidCallback onEdit,
    VoidCallback? onDelete,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: isMain ? const Color.fromARGB(255, 255, 160, 122) : const Color.fromARGB(255, 238, 238, 238), width: isMain ? 1.5 : 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isMain ? const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.2) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(isMain ? Icons.home : Icons.location_on, color: isMain ? const Color.fromARGB(255, 255, 160, 122) : Colors.black54),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
                  const SizedBox(height: 6.0),
                  Text(address, style: const TextStyle(color: Colors.black87, height: 1.4)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.black54, size: 22),
                  onPressed: onEdit,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8.0),
                ),
                if (!isMain && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8.0),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddressFormScreen extends StatefulWidget {
  final String? addressId;
  final String? initialLabel;
  final String? initialAddress;

  const AddressFormScreen({super.key, this.addressId, this.initialLabel, this.initialAddress});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _supabase = Supabase.instance.client;

  final _labelController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _postcodeController = TextEditingController();

  String? _selectedStateName;
  List<States> _statesList = [];
  bool _isLoadingStates = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchStates();

    if (widget.initialLabel != null) {
      _labelController.text = widget.initialLabel!;
    }
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _parseAddress(widget.initialAddress!);
    }
  }

  void _parseAddress(String fullAddress) {
    List<String> parts = fullAddress.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      _selectedStateName = parts.last;
      _postcodeController.text = parts[parts.length - 2];
      _streetAddressController.text = parts.sublist(0, parts.length - 2).join(', ');
    } else {
      _streetAddressController.text = fullAddress;
    }
  }

  Future<void> _fetchStates() async {
    try {
      final response = await _supabase.from('states').select().order('name', ascending: true).timeout(const Duration(seconds: 10));
      setState(() {
        _statesList = (response as List).map((e) => States.fromJson(e)).toList();

        if (_selectedStateName != null && !_statesList.any((s) => s.name == _selectedStateName)) {
          _selectedStateName = null;
        }
        _isLoadingStates = false;
      });
    } catch (e) {
      setState(() => _isLoadingStates = false);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetAddressController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_streetAddressController.text.trim().isEmpty || _postcodeController.text.trim().isEmpty || _selectedStateName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: Colors.red));
      return;
    }

    if (widget.addressId != 'main' && _labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a label (e.g., Office)'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser!.id;

      String street = _streetAddressController.text.trim();
      String postcode = _postcodeController.text.trim();
      String fullAddress = '$street, $postcode, $_selectedStateName';

      if (widget.addressId == 'main') {
        await _supabase.from('profiles').update({'address': fullAddress}).eq('id', userId);
      } else if (widget.addressId == null) {
        await _supabase.from('user_addresses').insert({
          'user_id': userId,
          'label': _labelController.text.trim(),
          'full_address': fullAddress,
        });
      } else {
        await _supabase.from('user_addresses').update({
          'label': _labelController.text.trim(),
          'full_address': fullAddress,
        }).eq('id', widget.addressId!);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving address: $e'), backgroundColor: Colors.red));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMain = widget.addressId == 'main';
    String pageTitle = widget.addressId == null ? 'Add New Address' : 'Edit Address';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(pageTitle, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18.0)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Address Label *', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6.0),
            TextField(
              controller: _labelController,
              readOnly: isMain,
              decoration: InputDecoration(
                hintText: 'e.g., Home, Office, Campus',
                filled: true,
                fillColor: isMain ? Colors.grey.shade200 : const Color.fromARGB(255, 245, 245, 245),
                prefixIcon: const Icon(Icons.bookmark_border, color: Colors.black54, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 24.0),
            const Divider(color: Color.fromARGB(255, 238, 238, 238), thickness: 1.5),
            const SizedBox(height: 20.0),

            const Text('Address Line 1 *', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6.0),
            TextField(
              controller: _streetAddressController,
              decoration: InputDecoration(
                hintText: 'House/Unit No., Building, Street',
                filled: true,
                fillColor: const Color.fromARGB(255, 245, 245, 245),
                prefixIcon: const Icon(Icons.home_outlined, color: Colors.black54, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16.0),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Postcode *', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6.0),
                      TextField(
                        controller: _postcodeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                        decoration: InputDecoration(
                          hintText: '11200',
                          filled: true,
                          fillColor: const Color.fromARGB(255, 245, 245, 245),
                          prefixIcon: const Icon(Icons.markunread_mailbox_outlined, color: Colors.black54, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('State *', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6.0),
                      DropdownButtonFormField<String>(
                        value: _selectedStateName,
                        onChanged: _isLoadingStates ? null : (val) => setState(() => _selectedStateName = val),
                        icon: _isLoadingStates
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.keyboard_arrow_down),
                        decoration: InputDecoration(
                          hintText: _isLoadingStates ? 'Loading...' : 'Select State',
                          filled: true,
                          fillColor: const Color.fromARGB(255, 245, 245, 245),
                          prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.black54, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
                        ),
                        items: _statesList.map((state) => DropdownMenuItem(value: state.name, child: Text(state.name, overflow: TextOverflow.ellipsis))).toList(),
                        isExpanded: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Address', style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}