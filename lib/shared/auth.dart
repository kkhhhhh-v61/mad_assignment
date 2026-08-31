import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

// Import role-specific navigations for RBAC routing
import '../admin/main_navigation.dart';
import '../rider/main_navigation.dart';

import '../services/auth_service.dart';
import '../models.dart';

class SharedAuthScreen extends StatefulWidget {
  // Callback to trigger upon successful customer authentication
  final Function(AppUser)? onAuthSuccess;

  const SharedAuthScreen({super.key, this.onAuthSuccess});

  @override
  State<SharedAuthScreen> createState() => _SharedAuthScreenState();
}

class _SharedAuthScreenState extends State<SharedAuthScreen> {
  // Form toggle states
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  bool _agreeTerms = false;

  // Text controllers for input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  Future<void> _loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe) {
      setState(() {
        _rememberMe = true;
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              title: const Text(
                'Reset Password',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your registered email, phone number, and a new password.',
                    style: TextStyle(fontSize: 13.0, color: Color.fromARGB(255, 117, 117, 117)),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: const TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 245, 245, 245),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneWithDashFormatter()],
                    decoration: InputDecoration(
                      hintText: 'Phone Number (e.g., 012-345 6789)',
                      hintStyle: const TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 245, 245, 245),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'New Password (min. 8 chars)',
                      hintStyle: const TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 245, 245, 245),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color.fromARGB(255, 117, 117, 117), fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    final email = emailController.text.trim();
                    final phone = phoneController.text.trim();
                    final newPassword = newPasswordController.text.trim();

                    if (email.isEmpty || phone.isEmpty || newPassword.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields (password min. 8 chars).', style: TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: Color.fromARGB(255, 239, 83, 80),
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isLoading = true);

                    try {
                      await supabase.rpc('reset_password_by_email_and_phone', params: {
                        'target_email': email,
                        'target_phone': phone,
                        'new_pass': newPassword,
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated successfully! Please log in.', style: TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: Color.fromARGB(255, 255, 160, 122),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: Email or phone not matched.', style: TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: const Color.fromARGB(255, 239, 83, 80),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Handles authentication logic (Login/Register) and RBAC routing
  void _handleAuthAction() async {
    if (!_isLogin) {
      if (_nameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty ||
          _addressController.text.trim().isEmpty ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        _showErrorSnackBar('Please fill in all fields before registering.');
        return;
      }

      // verify name no have number
      if (RegExp(r'[0-9]').hasMatch(_nameController.text.trim())) {
        _showErrorSnackBar('Full Name cannot contain numbers.');
        return;
      }

      if (_phoneController.text.trim().length < 10) {
        _showErrorSnackBar('Please enter a valid phone number.');
        return;
      }

      if (_passwordController.text.length < 8) {
        _showErrorSnackBar('Password must be at least 8 characters long.');
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorSnackBar('Passwords do not match. Please check again.');
        return;
      }

      if (!_agreeTerms) {
        _showErrorSnackBar('Please agree to the Terms of Service to continue.');
        return;
      }

      String? errorMessage = await registerCustomer(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please log in.', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Color.fromARGB(255, 255, 160, 122),
          ),
        );
        setState(() {
          _isLogin = true;
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _addressController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _agreeTerms = false;
        });
      } else {
        _showErrorSnackBar(errorMessage);
      }

    } else {
      AppUser? loggedInUser = await loginUser(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (loggedInUser == null) {
        _showErrorSnackBar('Invalid email or password.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setString('saved_password', _passwordController.text);
      } else {
        await prefs.remove('remember_me');
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }

      String role = loggedInUser.role;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminMainNavigation(user: loggedInUser)),
        );
      } else if (role == 'rider') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RiderMainNavigation(user: loggedInUser)),
        );
      } else {
        widget.onAuthSuccess?.call(loggedInUser);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${loggedInUser.name}!', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color.fromARGB(255, 255, 160, 122),
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 239, 83, 80),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            color: Colors.white,
            alignment: Alignment.center,
            child: const Text(
              'Account',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 12.0),
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 0, 0, 0),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _isLogin
                      ? 'Sign in to access your account'
                      : 'Join us today to start ordering delicious food',
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                AuthTabSelector(
                  isLogin: _isLogin,
                  onToggle: (bool isLogin) {
                    setState(() {
                      _isLogin = isLogin;
                    });
                  },
                ),
                const SizedBox(height: 24.0),
                if (_isLogin)
                  LoginForm(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    rememberMe: _rememberMe,
                    onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                    onRememberMeChanged: (value) => setState(() => _rememberMe = value),
                    onForgotPassword: _showForgotPasswordDialog,
                  )
                else
                  RegisterForm(
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    addressController: _addressController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    obscurePassword: _obscurePassword,
                    obscureConfirmPassword: _obscureConfirmPassword,
                    agreeTerms: _agreeTerms,
                    onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                    onToggleConfirmPassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    onAgreeTermsChanged: (value) => setState(() => _agreeTerms = value),
                  ),
                const SizedBox(height: 24.0),
                AuthActionButton(
                  isLogin: _isLogin,
                  onPressed: _handleAuthAction,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AuthTabSelector extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onToggle;

  const AuthTabSelector({super.key, required this.isLogin, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 238, 238, 238),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: isLogin ? const Color.fromARGB(255, 255, 160, 122) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: isLogin
                      ? const [BoxShadow(color: Color.fromARGB(40, 255, 160, 122), blurRadius: 8, offset: Offset(0, 3))]
                      : const [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Log In',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: isLogin ? Colors.white : const Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: !isLogin ? const Color.fromARGB(255, 255, 160, 122) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: !isLogin
                      ? const [BoxShadow(color: Color.fromARGB(40, 255, 160, 122), blurRadius: 8, offset: Offset(0, 3))]
                      : const [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: !isLogin ? Colors.white : const Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onForgotPassword;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.onTogglePassword,
    required this.onRememberMeChanged,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthInputField(
          controller: emailController,
          label: 'Email or Phone Number',
          hintText: 'e.g., kaihao0303@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16.0),
        AuthInputField(
          controller: passwordController,
          label: 'Password',
          hintText: 'Enter your password',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: obscurePassword,
          onTogglePassword: onTogglePassword,
        ),
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: rememberMe,
                    activeColor: const Color.fromARGB(255, 255, 160, 122),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                    onChanged: (value) => onRememberMeChanged(value ?? false),
                  ),
                ),
                const SizedBox(width: 8.0),
                const Text(
                  'Remember me',
                  style: TextStyle(fontSize: 13.0, color: Color.fromARGB(255, 117, 117, 117)),
                ),
              ],
            ),
            GestureDetector(
              onTap: onForgotPassword,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RegisterForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool agreeTerms;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<bool> onAgreeTermsChanged;

  const RegisterForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.agreeTerms,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onAgreeTermsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthInputField(
          controller: nameController,
          label: 'Full Name',
          hintText: 'e.g., Kai Hao',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16.0),
        AuthInputField(
          controller: emailController,
          label: 'Email Address',
          hintText: 'e.g., kaihao0303@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16.0),
        AuthInputField(
          controller: phoneController,
          label: 'Phone Number',
          hintText: 'e.g., 012-345 6789',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneWithDashFormatter()],
        ),
        const SizedBox(height: 16.0),
        AddressAutocompleteField(
          controller: addressController,
          label: 'Address',
          hintText: 'Search address in Malaysia (e.g., Subang Jaya, Penang)...',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16.0),
        AuthInputField(
          controller: passwordController,
          label: 'Password',
          hintText: 'Create your password (min. 8 characters)',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: obscurePassword,
          onTogglePassword: onTogglePassword,
        ),
        const SizedBox(height: 16.0),
        AuthInputField(
          controller: confirmPasswordController,
          label: 'Confirm Password',
          hintText: 'Re-enter your password',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: obscureConfirmPassword,
          onTogglePassword: onToggleConfirmPassword,
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: agreeTerms,
                activeColor: const Color.fromARGB(255, 255, 160, 122),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                onChanged: (value) => onAgreeTermsChanged(value ?? false),
              ),
            ),
            const SizedBox(width: 8.0),
            const Expanded(
              child: Text(
                'I agree to the Terms of Service & Privacy Policy',
                style: TextStyle(fontSize: 13.0, color: Color.fromARGB(255, 117, 117, 117)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onTogglePassword;
  final List<TextInputFormatter>? inputFormatters;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.obscureText = false,
    this.onTogglePassword,
    this.inputFormatters,
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
          inputFormatters: inputFormatters,
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
              borderSide: const BorderSide(color: Color.fromARGB(255, 255, 160, 122), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  List<String> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  void _onSearchChanged(String query) {
    widget.controller.text = query;

    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchAddresses(query);
    });
  }

  Future<void> _fetchAddresses(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$encodedQuery&countrycodes=my&limit=5&addressdetails=1',
      );

      // for OSM req needed（User-Agent)
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'DoorDishFoodDeliveryApp/1.0 (student@taylors.edu.my)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _suggestions = data.map((item) => item['display_name'].toString()).toList();
          _isLoading = false;
        });
      } else {
        print('OSM API Status Code: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('OSM Search Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 6.0),
        TextField(
          controller: widget.controller,
          onChanged: _onSearchChanged,
          keyboardType: TextInputType.streetAddress,
          style: const TextStyle(fontSize: 15.0, color: Color.fromARGB(221, 0, 0, 0)),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
            filled: true,
            fillColor: const Color.fromARGB(255, 245, 245, 245),
            prefixIcon: Icon(widget.icon, color: const Color.fromARGB(255, 117, 117, 117), size: 20),
            suffixIcon: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(strokeWidth: 2, color: Color.fromARGB(255, 255, 160, 122)),
              ),
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
              borderSide: const BorderSide(color: Color.fromARGB(255, 255, 160, 122), width: 1.5),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(25, 0, 0, 0),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final address = _suggestions[index];
                return ListTile(
                  title: Text(
                    address,
                    style: const TextStyle(fontSize: 13.0, color: Color.fromARGB(221, 0, 0, 0)),
                  ),
                  onTap: () {
                    widget.controller.text = address;
                    setState(() {
                      _suggestions = [];
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class AuthActionButton extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onPressed;

  const AuthActionButton({
    super.key,
    required this.isLogin,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 160, 122),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
        ),
        child: Text(
          isLogin ? 'Log In' : 'Create Account',
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class PhoneWithDashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text.length > newValue.text.length) {
      return newValue;
    }

    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    String formatted = '';
    bool is11Digits = text.startsWith('011') && text.length > 3;

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

    if (formatted.length > 13) {
      return oldValue;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}