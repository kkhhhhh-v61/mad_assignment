import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mad_assignment/shared/update_password.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

import '../admin/main_navigation.dart';
import '../rider/main_navigation.dart';

import '../services/auth_service.dart';
import '../models.dart';

class SharedAuthScreen extends StatefulWidget {
  final Function(AppUser)? onAuthSuccess;

  const SharedAuthScreen({super.key, this.onAuthSuccess});

  @override
  State<SharedAuthScreen> createState() => _SharedAuthScreenState();
}

class _SharedAuthScreenState extends State<SharedAuthScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  bool _agreeTerms = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();

  String? _selectedStateName;
  List<States> _statesList = [];
  bool _isLoadingStates = true;

  List<dynamic> _osmSuggestions = [];
  bool _isSearchingOsm = false;
  Timer? _debounce;

  void _searchOsmAddress(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (query.trim().length < 3) {
        setState(() => _osmSuggestions = []);
        return;
      }
      setState(() => _isSearchingOsm = true);
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&countrycodes=my&limit=5',
        );
        final response = await http.get(url, headers: {'User-Agent': 'DoorDishApp/1.0'});
        if (response.statusCode == 200) {
          setState(() {
            _osmSuggestions = json.decode(response.body);
            _isSearchingOsm = false;
          });
        } else {
          setState(() => _isSearchingOsm = false);
        }
      } catch (e) {
        print('OSM Search Error: $e');
        setState(() => _isSearchingOsm = false);
      }
    });
  }

  void _onSelectOsmSuggestion(Map<String, dynamic> item) {
    final addressDetails = item['address'] ?? {};
    final displayName = item['display_name']?.toString() ?? '';

    String postcode = addressDetails['postcode'] ?? '';
    String stateFromOsm = addressDetails['state'] ?? '';

    List<String> parts = displayName.split(',').map((e) => e.trim()).toList();
    List<String> filteredParts = parts.where((part) {
      if (RegExp(r'^\d{5}$').hasMatch(part)) return false;
      if (stateFromOsm.isNotEmpty && part.toLowerCase().contains(stateFromOsm.toLowerCase())) return false;
      if (part.toLowerCase() == 'malaysia') return false;
      return true;
    }).toList();

    String fullStreetAddress = filteredParts.join(', ');

    setState(() {
      _addressController.text = fullStreetAddress;
      _postcodeController.text = postcode;
      _osmSuggestions = [];
    });

    if (stateFromOsm.isNotEmpty) {
      for (var s in _statesList) {
        if (stateFromOsm.toLowerCase().contains(s.name.toLowerCase()) ||
            s.name.toLowerCase().contains(stateFromOsm.toLowerCase())) {
          setState(() {
            _selectedStateName = s.name;
          });
          break;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
    _fetchStates();
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
          );
        }
      }
    });
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    final savedEmail = prefs.getString('saved_email') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';

    if (savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = rememberMe;
      });
    }

    if (rememberMe) {
      final session = supabase.auth.currentSession;

      if (session != null) {
        try {
          final profile = await supabase
              .from('profiles')
              .select()
              .eq('id', session.user.id)
              .single();

          if (profile['status'] == 'Inactive') {
            await supabase.auth.signOut();
            if (mounted) _showErrorSnackBar('Your account has been deactivated.');
            return;
          }

          AppUser loggedInUser = AppUser(
            id: session.user.id,
            role: profile['role'],
            name: profile['name'],
            email: session.user.email ?? '',
            phone: profile['phone'],
            address: '',
          );

          if (!mounted) return;

          if (loggedInUser.role == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminMainNavigation(user: loggedInUser)));
          } else if (loggedInUser.role == 'rider') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RiderMainNavigation(user: loggedInUser)));
          } else {
            widget.onAuthSuccess?.call(loggedInUser);
          }
        } catch (e) {
          print('Auto-login error: $e');
          if (savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
            _handleAuthAction();
          }
        }
      } else {
        if (savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
          _handleAuthAction();
        }
      }
    } else {
      await supabase.auth.signOut();
    }
  }

  Future<void> _fetchStates() async {
    try {
      final response = await supabase.from('states').select().order('name', ascending: true);
      setState(() {
        _statesList = (response as List).map((e) => States.fromJson(e)).toList();
        _isLoadingStates = false;
      });
    } catch (e) {
      print('Error fetching states: $e');
      setState(() => _isLoadingStates = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    _unitController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your registered email address. We will send you a link to reset your password.',
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
                  ],
                ),
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

                    if (email.isEmpty || !email.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid email address.', style: TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: Color.fromARGB(255, 239, 83, 80),
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isLoading = true);

                    try {
                      await supabase.auth.resetPasswordForEmail(email,redirectTo: 'doordish://reset-password',);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset link sent! Please check your email.', style: TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: Color.fromARGB(255, 76, 175, 80),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      : const Text('Send Link', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleAuthAction() async {
    if (!_isLogin) {
      if (_nameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty ||
          _unitController.text.trim().isEmpty ||
          _addressController.text.trim().isEmpty ||
          _postcodeController.text.trim().isEmpty ||
          _selectedStateName == null ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        _showErrorSnackBar('Please fill in all required fields before registering.');
        return;
      }

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

      String unit = _unitController.text.trim();
      String street = _addressController.text.trim();
      String postcode = _postcodeController.text.trim();

      String fullAddress = '$unit, $street, $postcode, $_selectedStateName';

      String? errorMessage = await registerCustomer(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: fullAddress,
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
          _unitController.clear();
          _addressController.clear();
          _postcodeController.clear();
          _selectedStateName = null;
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

      try {
        final profile = await supabase
            .from('profiles')
            .select('status')
            .eq('id', loggedInUser.id)
            .single();

        if (profile['status'] == 'Inactive') {
          await supabase.auth.signOut();
          _showErrorSnackBar('Your account has been deactivated. Please contact support.');
          return;
        }
      } catch (e) {
        print('Error checking user status: $e');
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
                    unitController: _unitController,
                    addressController: _addressController,
                    postcodeController: _postcodeController,
                    selectedStateName: _selectedStateName,
                    statesList: _statesList,
                    isLoadingStates: _isLoadingStates,
                    onStateChanged: (value) => setState(() => _selectedStateName = value),
                    onAddressChanged: (val) => _searchOsmAddress(val),
                    osmSuggestions: _osmSuggestions,
                    isSearchingOsm: _isSearchingOsm,
                    onSelectSuggestion: (item) => _onSelectOsmSuggestion(item),
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
          label: 'Email',
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

  final TextEditingController unitController;
  final TextEditingController addressController;
  final TextEditingController postcodeController;

  final String? selectedStateName;
  final List<States> statesList;
  final bool isLoadingStates;
  final ValueChanged<String?> onStateChanged;

  final Function(String) onAddressChanged;
  final List<dynamic> osmSuggestions;
  final bool isSearchingOsm;
  final Function(Map<String, dynamic>) onSelectSuggestion;

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
    required this.unitController,
    required this.addressController,
    required this.postcodeController,
    required this.selectedStateName,
    required this.statesList,
    required this.isLoadingStates,
    required this.onStateChanged,
    required this.onAddressChanged,
    required this.osmSuggestions,
    required this.isSearchingOsm,
    required this.onSelectSuggestion,
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
          label: 'Full Name *',
          hintText: 'e.g., Kai Hao',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16.0),
        AuthInputField(
          controller: emailController,
          label: 'Email Address *',
          hintText: 'e.g., kaihao0303@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16.0),
        AuthInputField(
          controller: phoneController,
          label: 'Phone Number *',
          hintText: 'e.g., 012-345 6789',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneWithDashFormatter()],
        ),
        const SizedBox(height: 24.0),

        const Text(
          'Delivery Address',
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12.0),
        AuthInputField(
          controller: unitController,
          label: 'Unit / House No. *',
          hintText: 'e.g., No. 12, Block A',
          icon: Icons.home_work_outlined,
        ),
        const SizedBox(height: 16.0),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Street / Area (OSM Search) *',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Color.fromARGB(221, 0, 0, 0)),
            ),
            const SizedBox(height: 6.0),
            TextField(
              controller: addressController,
              onChanged: onAddressChanged,
              decoration: InputDecoration(
                hintText: 'Type street name (e.g., Jalan Timur)',
                hintStyle: const TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
                filled: true,
                fillColor: const Color.fromARGB(255, 245, 245, 245),
                prefixIcon: const Icon(Icons.search, color: Color.fromARGB(255, 117, 117, 117), size: 20),
                suffixIcon: isSearchingOsm
                    ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
              ),
            ),

            if (osmSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: osmSuggestions.length,
                  itemBuilder: (context, index) {
                    final item = osmSuggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on, color: Color.fromARGB(255, 255, 160, 122), size: 18),
                      title: Text(item['display_name'] ?? '', style: const TextStyle(fontSize: 13.0)),
                      onTap: () => onSelectSuggestion(item),
                    );
                  },
                ),
              ),
          ],
        ),

        const SizedBox(height: 16.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: AuthInputField(
                controller: postcodeController,
                label: 'Postcode *',
                hintText: 'Auto-filled',
                icon: Icons.markunread_mailbox_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              flex: 1,
              child: SharedDropdownField(
                label: 'State *',
                hintText: 'Auto-selected',
                icon: Icons.location_city_outlined,
                value: selectedStateName,
                items: statesList.map((state) => state.name).toList(),
                isLoading: isLoadingStates,
                onChanged: onStateChanged,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24.0),
        const Divider(color: Color.fromARGB(255, 238, 238, 238), thickness: 1.5),
        const SizedBox(height: 16.0),

        AuthInputField(
          controller: passwordController,
          label: 'Password *',
          hintText: 'Create your password (min. 8 chars)',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: obscurePassword,
          onTogglePassword: onTogglePassword,
        ),
        const SizedBox(height: 16.0),
        AuthInputField(
          controller: confirmPasswordController,
          label: 'Confirm Password *',
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

class SharedDropdownField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final String? value;
  final List<String> items;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  const SharedDropdownField({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.value,
    required this.items,
    this.isLoading = false,
    required this.onChanged,
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
        DropdownButtonFormField<String>(
          value: value,
          onChanged: isLoading ? null : onChanged,
          icon: isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.keyboard_arrow_down, color: Color.fromARGB(255, 158, 158, 158)),
          style: const TextStyle(fontSize: 15.0, color: Color.fromARGB(221, 0, 0, 0)),
          decoration: InputDecoration(
            hintText: isLoading ? 'Loading...' : hintText,
            hintStyle: const TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
            filled: true,
            fillColor: const Color.fromARGB(255, 245, 245, 245),
            prefixIcon: Icon(icon, color: const Color.fromARGB(255, 117, 117, 117), size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          isExpanded: true,
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