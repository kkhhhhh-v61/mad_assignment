import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRiderCreation extends StatefulWidget {
  const AdminRiderCreation({super.key});

  @override
  State<AdminRiderCreation> createState() => _AdminRiderCreationState();
}

class _AdminRiderCreationState extends State<AdminRiderCreation> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  String? _selectedVehicle;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveRider() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final plate = _plateController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || _selectedVehicle == null || plate.isEmpty) {
      _showErrorSnackBar('Please fill in all fields.');
      return;
    }

    if (RegExp(r'[0-9@#\$%^&*()_=+\[\]{}|\\;:"<>\?]').hasMatch(name)) {
      _showErrorSnackBar('Rider Name cannot contain numbers or special characters (@, #, *, etc.).');
      return;
    }

    if (password.length < 8 || password != confirmPassword) {
      _showErrorSnackBar('Passwords must match and be at least 8 characters.');
      return;
    }

    if (phone.length < 10) {
      _showErrorSnackBar('Please enter a valid phone number.');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final adminClient = SupabaseClient(
        'https://xjumxpsalmmyboqlvand.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhqdW14cHNhbG1teWJvcWx2YW5kIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NTk4NDA0MiwiZXhwIjoyMTAxNTYwMDQyfQ.PjdI_LWUrk-KVb-eiFBATAaqXOyqMRSvLb6OeQ5eZso',
      );

      final userRes = await adminClient.auth.admin.createUser(
        AdminUserAttributes(email: email, password: password, emailConfirm: true),
      );
      final newUserId = userRes.user!.id;

      await Future.delayed(const Duration(milliseconds: 1500));

      await adminClient.from('profiles').upsert({
        'id': newUserId,
        'name': name,
        'phone': phone,
        'email': email,
        'role': 'rider',
      });

      await adminClient.from('riders').insert({
        'id': newUserId,
        'vehicle': _selectedVehicle,
        'plate': plate.toUpperCase(),
      });

      adminClient.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider created successfully!', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('already been registered') || errorMsg.contains('email_exists')) {
          _showErrorSnackBar('This email address is already registered.');
        } else {
          _showErrorSnackBar('Error: $e');
        }
        setState(() => _isLoading = false);
      }
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
          icon: const Icon(Icons.arrow_back_ios, color: Color.fromARGB(221, 0, 0, 0), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Rider Account',
          style: TextStyle(color: Color.fromARGB(221, 0, 0, 0), fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
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
                    const _ImagePlaceholder(),
                    const SizedBox(height: 32.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Personal Information', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12.0),

                        _InputField(
                          controller: _nameController,
                          label: 'Rider Name',
                          hintText: 'e.g., Ali Bin Abu',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16.0),
                        _InputField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hintText: 'e.g., 012-345 6789',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [PhoneWithDashFormatter()],
                        ),

                        const SizedBox(height: 24.0),
                        const Divider(color: Color.fromARGB(255, 238, 238, 238), thickness: 1.5),
                        const SizedBox(height: 16.0),

                        const Text('Account Credentials', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12.0),

                        _InputField(
                          controller: _emailController,
                          label: 'Email Address',
                          hintText: 'e.g., rider@doordish.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16.0),
                        _InputField(
                          controller: _passwordController,
                          label: 'Password',
                          hintText: 'Create a password (min 8 chars)',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 16.0),
                        _InputField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hintText: 'Re-enter the password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscureConfirmPassword,
                          onTogglePassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),

                        const SizedBox(height: 24.0),
                        const Divider(color: Color.fromARGB(255, 238, 238, 238), thickness: 1.5),
                        const SizedBox(height: 16.0),

                        const Text('Vehicle Information', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12.0),

                        _DropdownField(
                          value: _selectedVehicle,
                          label: 'Vehicle Type',
                          hintText: 'Select a vehicle type',
                          icon: Icons.directions_car_outlined,
                          items: const ['Motorcycle', 'Car', 'Bicycle'],
                          onChanged: (value) {
                            setState(() {
                              _selectedVehicle = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        _InputField(
                          controller: _plateController,
                          label: 'Vehicle Plate',
                          hintText: 'e.g., VBE 1234',
                          icon: Icons.pin_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Color.fromARGB(15, 0, 0, 0), blurRadius: 10, offset: Offset(0, -5)),
                ],
              ),
              child: _CreateButton(
                onPressed: _saveRider,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 245, 245, 245),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: const Color.fromARGB(255, 224, 224, 224), width: 2.0),
          ),
          child: const Icon(Icons.person_outline, size: 50, color: Color.fromARGB(255, 158, 158, 158)),
        ),
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 160, 122),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.0),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onTogglePassword;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.isPassword = false,
    this.obscureText = false,
    this.onTogglePassword,
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 15.0, color: Color.fromARGB(221, 0, 0, 0)),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
            filled: true,
            fillColor: const Color.fromARGB(255, 245, 245, 245),
            prefixIcon: Icon(icon, color: const Color.fromARGB(255, 117, 117, 117), size: 20),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color.fromARGB(255, 117, 117, 117),
                size: 20,
              ),
              onPressed: onTogglePassword,
            )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: const BorderSide(color: Color.fromARGB(255, 224, 224, 224)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: const BorderSide(color: Color.fromARGB(255, 224, 224, 224)),
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

class _DropdownField extends StatelessWidget {
  final String? value;
  final String label;
  final String hintText;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.value,
    required this.label,
    required this.hintText,
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
            hintText: hintText,
            hintStyle: const TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
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
              borderSide: const BorderSide(color: Color.fromARGB(255, 224, 224, 224)),
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

class _CreateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _CreateButton({required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 160, 122),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Create Rider', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white)),
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