import 'package:flutter/material.dart';

class SharedProfileScreen extends StatefulWidget {
  final String title;
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final Function(String name, String email, String phone, String password) onSave;
  final VoidCallback? onUpdatePicture;

  const SharedProfileScreen({
    super.key,
    required this.title,
    this.initialName = '',
    this.initialEmail = '',
    this.initialPhone = '',
    required this.onSave,
    this.onUpdatePicture,
  });

  @override
  State<SharedProfileScreen> createState() => _SharedProfileScreenState();
}

class _SharedProfileScreenState extends State<SharedProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(221, 0, 0, 0),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color.fromARGB(221, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
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
                    SharedProfilePicture(onUpdatePicture: widget.onUpdatePicture),
                    const SizedBox(height: 32.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SharedInputField(
                          controller: _nameController,
                          label: 'Full Name',
                          hintText: 'Enter your full name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16.0),
                        SharedInputField(
                          controller: _emailController,
                          label: 'Email Address',
                          hintText: 'Email cannot be changed',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                        ),
                        const SizedBox(height: 16.0),
                        SharedInputField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hintText: 'Enter your new phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 32.0),
                        const Divider(color: Color.fromARGB(255, 238, 238, 238), thickness: 1.5),
                        const SizedBox(height: 24.0),
                        const Text(
                          'Security',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(221, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        SharedInputField(
                          controller: _passwordController,
                          label: 'New Password',
                          hintText: 'Leave blank to keep current password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onTogglePassword: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        SharedInputField(
                          controller: _confirmPasswordController,
                          label: 'Confirm New Password',
                          hintText: 'Re-enter your new password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscureConfirmPassword,
                          onTogglePassword: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SharedSaveButton(
                isLoading: _isLoading,
                onPressed: () async {
                  final password = _passwordController.text.trim();
                  final confirmPassword = _confirmPasswordController.text.trim();

                  if (password.isNotEmpty && password != confirmPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Passwords do not match. Please check again.', style: TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: Color.fromARGB(255, 239, 83, 80),
                      ),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);
                  await widget.onSave(
                    _nameController.text.trim(),
                    _emailController.text.trim(),
                    _phoneController.text.trim(),
                    password,
                  );
                  if (mounted) setState(() => _isLoading = false);
                },
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}

class SharedProfilePicture extends StatelessWidget {
  final VoidCallback? onUpdatePicture;

  const SharedProfilePicture({super.key, this.onUpdatePicture});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 60,
            color: Color.fromARGB(255, 255, 160, 122),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 160, 122),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              onPressed: onUpdatePicture ?? () {},
            ),
          ),
        ),
      ],
    );
  }
}

class SharedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onTogglePassword;
  final bool readOnly;

  const SharedInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.obscureText = false,
    this.onTogglePassword,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 6.0),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          style: TextStyle(
              fontSize: 15.0,
              color: readOnly ? const Color.fromARGB(255, 158, 158, 158) : const Color.fromARGB(221, 0, 0, 0)
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
            filled: true,
            fillColor: readOnly ? const Color.fromARGB(255, 238, 238, 238) : const Color.fromARGB(255, 245, 245, 245),
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
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class SharedSaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const SharedSaveButton({super.key, required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 160, 122),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Text('Save Changes', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
      ),
    );
  }
}