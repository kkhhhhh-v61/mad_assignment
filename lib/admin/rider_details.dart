import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRiderDetails extends StatefulWidget {
  final Map<String, dynamic> rider;

  const AdminRiderDetails({super.key, required this.rider});

  @override
  State<AdminRiderDetails> createState() => _AdminRiderDetailsState();
}

class _AdminRiderDetailsState extends State<AdminRiderDetails> {
  final _supabase = Supabase.instance.client;
  late bool _isAccountEnabled;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _needsRefresh = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _plateController;
  String? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _isAccountEnabled = widget.rider['is_active'] ?? true;
    _nameController = TextEditingController(text: widget.rider['name'] ?? '');
    _phoneController = TextEditingController(text: widget.rider['phone'] ?? '');
    _plateController = TextEditingController(text: widget.rider['plate'] ?? '');
    _selectedVehicle = widget.rider['vehicle'] ?? 'Motorcycle';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _updateRiderDetails() async {
    final plate = _plateController.text.trim();

    if (plate.isEmpty || _selectedVehicle == null) {
      _showSnackBar('Please fill in all editable fields.', Colors.red);
      return;
    }

    if (!RegExp(r'^[A-Za-z0-9\s]+$').hasMatch(plate)) {
      _showSnackBar('Vehicle Plate can only contain letters and numbers.', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final riderId = widget.rider['id'];

      await _supabase.from('riders').update({
        'vehicle': _selectedVehicle,
        'plate': plate.toUpperCase(),
      }).eq('id', riderId);

      setState(() {
        widget.rider['vehicle'] = _selectedVehicle;
        widget.rider['plate'] = plate.toUpperCase();
        _isEditing = false;
        _isSaving = false;
        _needsRefresh = true;
      });

      if (mounted) {
        _showSnackBar('Vehicle details updated successfully!', const Color.fromARGB(255, 76, 175, 80));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating vehicle: $e', Colors.red);
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _toggleAccountStatus(bool value) async {
    setState(() => _isAccountEnabled = value);
    try {
      await _supabase.from('riders').update({'is_active': value}).eq('id', widget.rider['id']);
      _needsRefresh = true;
    } catch (e) {
      setState(() => _isAccountEnabled = !value);
      if (mounted) {
        _showSnackBar('Error updating status: $e', Colors.red);
      }
    }
  }

  Future<void> _deleteRider() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 8),
              Text('Delete Rider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this rider? This action cannot be undone.',
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
      await _supabase.from('riders').delete().eq('id', widget.rider['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider deleted successfully', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Color.fromARGB(255, 255, 160, 122),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _needsRefresh);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 249, 250, 251),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color.fromARGB(221, 0, 0, 0), size: 20),
            onPressed: () => Navigator.pop(context, _needsRefresh),
          ),
          title: const Text(
            'Rider Details',
            style: TextStyle(color: Color.fromARGB(221, 0, 0, 0), fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
          actions: _isEditing
              ? [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black54),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = widget.rider['name'] ?? '';
                  _phoneController.text = widget.rider['phone'] ?? '';
                  _plateController.text = widget.rider['plate'] ?? '';
                  _selectedVehicle = widget.rider['vehicle'] ?? 'Motorcycle';
                });
              },
            ),
          ]
              : [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black87),
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteRider,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ImageDisplay(avatarUrl: widget.rider['avatar_url']?.toString()),
                      const SizedBox(height: 32.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailField(
                            label: 'Rider Name',
                            controller: _nameController,
                            icon: Icons.person_outline,
                            readOnly: true,
                            isLocked: _isEditing,
                          ),
                          const SizedBox(height: 16.0),
                          _DetailField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            readOnly: true,
                            isLocked: _isEditing,
                          ),
                          const SizedBox(height: 16.0),
                          _DetailField(
                            label: 'Email Address',
                            controller: TextEditingController(text: widget.rider['email'] as String? ?? 'N/A'),
                            icon: Icons.email_outlined,
                            readOnly: true,
                            isLocked: _isEditing,
                          ),
                          const SizedBox(height: 16.0),
                          if (_isEditing)
                            _DropdownField(
                              value: _selectedVehicle,
                              label: 'Vehicle Type',
                              icon: Icons.directions_car_outlined,
                              items: const ['Motorcycle', 'Car', 'Bicycle'],
                              onChanged: (value) => setState(() => _selectedVehicle = value),
                            )
                          else
                            _DetailField(
                              label: 'Vehicle Type',
                              controller: TextEditingController(text: widget.rider['vehicle'] as String? ?? 'N/A'),
                              icon: Icons.directions_car_outlined,
                              readOnly: true,
                            ),
                          const SizedBox(height: 16.0),
                          _DetailField(
                            label: 'Vehicle Plate',
                            controller: _plateController,
                            icon: Icons.pin_outlined,
                            readOnly: !_isEditing,
                          ),
                          const SizedBox(height: 16.0),
                          _DetailField(
                            label: 'Current Status',
                            controller: TextEditingController(text: widget.rider['status'] as String? ?? 'Offline'),
                            icon: Icons.info_outline,
                            readOnly: true,
                            isLocked: _isEditing,
                          ),
                          const SizedBox(height: 32.0),
                          if (!_isEditing)
                            _AccountToggleSection(
                              isEnabled: _isAccountEnabled,
                              onChanged: _toggleAccountStatus,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_isEditing)
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Color.fromARGB(15, 0, 0, 0), blurRadius: 10, offset: Offset(0, -5))],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateRiderDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white)),
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

class _ImageDisplay extends StatelessWidget {
  final String? avatarUrl;
  const _ImageDisplay({this.avatarUrl});

  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 245),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color.fromARGB(255, 224, 224, 224), width: 2.0),
        image: avatarUrl != null && avatarUrl!.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(avatarUrl!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? const Icon(
        Icons.person,
        size: 50,
        color: Color.fromARGB(255, 158, 158, 158),
      )
          : null,
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool readOnly;
  final bool isLocked;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _DetailField({
    required this.label,
    required this.controller,
    required this.icon,
    this.readOnly = true,
    this.isLocked = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final bool showAsLocked = readOnly && isLocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Color.fromARGB(221, 0, 0, 0)),
        ),
        const SizedBox(height: 6.0),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: 15.0,
            color: showAsLocked ? const Color.fromARGB(255, 158, 158, 158) : const Color.fromARGB(221, 0, 0, 0),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: showAsLocked ? const Color.fromARGB(255, 238, 238, 238) : const Color.fromARGB(255, 245, 245, 245),
            prefixIcon: Icon(icon, color: const Color.fromARGB(255, 117, 117, 117), size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: const BorderSide(color: Color.fromARGB(255, 224, 224, 224)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide(
                color: readOnly ? const Color.fromARGB(255, 224, 224, 224) : const Color.fromARGB(255, 255, 160, 122),
                width: readOnly ? 1.0 : 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide(
                color: readOnly ? const Color.fromARGB(255, 224, 224, 224) : const Color.fromARGB(255, 255, 160, 122),
                width: readOnly ? 1.0 : 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Color.fromARGB(221, 0, 0, 0)),
        ),
        const SizedBox(height: 6.0),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color.fromARGB(255, 245, 245, 245),
            prefixIcon: Icon(icon, color: const Color.fromARGB(255, 117, 117, 117), size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: const BorderSide(color: Color.fromARGB(255, 224, 224, 224)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: const BorderSide(color: Color.fromARGB(255, 255, 160, 122), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: const BorderSide(color: Color.fromARGB(255, 255, 160, 122), width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountToggleSection extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _AccountToggleSection({
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: const [
          BoxShadow(color: Color.fromARGB(15, 0, 0, 0), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Status',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color.fromARGB(221, 0, 0, 0)),
              ),
              SizedBox(height: 4.0),
              Text(
                'Enable or disable access',
                style: TextStyle(fontSize: 13.0, color: Color.fromARGB(255, 117, 117, 117)),
              ),
            ],
          ),
          Switch(
            value: isEnabled,
            activeThumbColor: const Color.fromARGB(255, 255, 160, 122),
            activeTrackColor: const Color.fromARGB(100, 255, 160, 122),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class PhoneWithDashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text.length > newValue.text.length) {
      return newValue;
    }
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    bool is11Digits = text.startsWith('011');
    int maxDigits = is11Digits ? 11 : 10;
    if (text.length > maxDigits) {
      text = text.substring(0, maxDigits);
    }
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3) {
        formatted += '-';
      } else if (is11Digits && i == 7) {
        formatted += ' ';
      } else if (!is11Digits && i == 6) {
        formatted += ' ';
      }
      formatted += text[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}