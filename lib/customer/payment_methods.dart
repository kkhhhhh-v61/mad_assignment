import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      setState(() {
        _cards = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching cards: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCard(String id) async {
    try {
      await _supabase.from('payment_methods').delete().eq('id', id);
      _fetchCards();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card removed successfully'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _setDefaultCard(String id) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('payment_methods').update({'is_default': false}).eq('user_id', userId);
      await _supabase.from('payment_methods').update({'is_default': true}).eq('id', id);
      _fetchCards();
    } catch (e) {
      print('Error setting default: $e');
    }
  }

  void _showAddCardModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddCardForm(onSave: _fetchCards),
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
        title: const Text('Payment Methods', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18.0)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 255, 160, 122)))
          : _cards.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          final isDefault = card['is_default'] == true;
          return _buildCardItem(card, isDefault);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardModal,
        backgroundColor: const Color.fromARGB(255, 255, 160, 122),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No payment methods saved', style: TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> card, bool isDefault) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: isDefault ? const Color.fromARGB(255, 255, 160, 122) : Colors.transparent, width: 2),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(card['card_brand'] == 'Visa' ? Icons.payment : Icons.credit_card, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Text(card['card_brand'] ?? 'Card', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color.fromARGB(40, 255, 160, 122), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Default', style: TextStyle(color: Color.fromARGB(255, 255, 160, 122), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(card['card_number_masked'] ?? '**** **** **** 0000', style: const TextStyle(fontSize: 18, letterSpacing: 2.0)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Card Holder', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(card['cardholder_name'] ?? 'UNKNOWN', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expires', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(card['expiry_date'] ?? '00/00', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') _deleteCard(card['id']);
                    if (value == 'default') _setDefaultCard(card['id']);
                  },
                  itemBuilder: (context) => [
                    if (!isDefault) const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Card', style: TextStyle(color: Colors.red))),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    String newText = '';
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) newText += ' ';
      newText += text[i];
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    String newText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2) newText += '/';
      newText += text[i];
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class AddCardForm extends StatefulWidget {
  final VoidCallback onSave;
  const AddCardForm({super.key, required this.onSave});

  @override
  State<AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends State<AddCardForm> {
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _saveNewCard() async {
    setState(() {
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final number = _numberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text.trim();
    final cvv = _cvvController.text.trim();

    if (name.isEmpty || number.isEmpty || expiry.isEmpty || cvv.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    if (number.length != 16) {
      _showError('Card number must be exactly 16 digits.');
      return;
    }

    if (expiry.length != 5 || !expiry.contains('/')) {
      _showError('Invalid expiry date format. Use MM/YY.');
      return;
    }

    final expiryParts = expiry.split('/');
    final month = int.tryParse(expiryParts[0]);
    final year = int.tryParse(expiryParts[1]);

    if (month == null || month < 1 || month > 12) {
      _showError('Invalid month. Must be between 01 and 12.');
      return;
    }

    if (year == null) {
      _showError('Invalid year format.');
      return;
    }

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      _showError('This card has expired.');
      return;
    }

    if (cvv.length < 3) {
      _showError('CVV must be at least 3 digits.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final lastFour = number.substring(number.length - 4);
      final maskedNumber = '**** **** **** $lastFour';
      final brand = number.startsWith('4') ? 'Visa' : (number.startsWith('5') ? 'Mastercard' : 'Other');

      await _supabase.from('payment_methods').insert({
        'user_id': userId,
        'cardholder_name': name,
        'card_number_masked': maskedNumber,
        'expiry_date': expiry,
        'card_brand': brand,
        'is_default': false,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
      }
    } catch (e) {
      _showError('Error saving card: $e');
      setState(() => _isSaving = false);
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6.0),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          onChanged: (val) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
          style: const TextStyle(fontSize: 15.0, letterSpacing: 1.0),
          decoration: InputDecoration(
            hintText: hintText,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24.0, right: 24.0, top: 24.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add New Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

          _buildModernTextField(
            controller: _nameController,
            label: 'Cardholder Name',
            hintText: 'e.g., John Doe',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),

          _buildModernTextField(
            controller: _numberController,
            label: 'Card Number',
            hintText: '1234 1234 1234 1234',
            icon: Icons.credit_card_outlined,
            keyboardType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              CardNumberFormatter(),
              LengthLimitingTextInputFormatter(19),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  controller: _expiryController,
                  label: 'Expiry Date',
                  hintText: 'MM/YY',
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ExpiryDateFormatter(),
                    LengthLimitingTextInputFormatter(5),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernTextField(
                  controller: _cvvController,
                  label: 'CVV',
                  hintText: '123',
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveNewCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Card', style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}