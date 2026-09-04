import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'user_role.dart';

class SharedProfileScreen extends StatefulWidget {
  final String title;
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String? initialAvatarUrl;
  final Function(
      String name,
      String email,
      String phone,
      String password,
      ) onSave;
  final VoidCallback? onUpdatePicture;
  final UserRole role;
  final String vehicleType;
  final String vehiclePlate;
  final double rating;

  const SharedProfileScreen({
    super.key,
    required this.title,
    this.initialName = '',
    this.initialEmail = '',
    this.initialPhone = '',
    this.initialAvatarUrl,
    required this.onSave,
    this.onUpdatePicture,
    this.role = UserRole.customer,
    this.vehicleType = '',
    this.vehiclePlate = '',
    this.rating = 0.0,
  });

  @override
  State<SharedProfileScreen> createState() =>
      _SharedProfileScreenState();
}

class _SharedProfileScreenState
    extends State<SharedProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  String? _avatarUrl;
  bool _isUploading = false;
  final _supabase = Supabase.instance.client;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool get _isRider => widget.role == UserRole.rider;

  @override
  void initState() {
    super.initState();

    _avatarUrl = widget.initialAvatarUrl;

    _nameController =
        TextEditingController(text: widget.initialName);
    _emailController =
        TextEditingController(text: widget.initialEmail);
    _phoneController =
        TextEditingController(text: widget.initialPhone);
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

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(pickedFile.path);
      final fileExt = pickedFile.path.split('.').last;
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage.from('avatars').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      await _supabase.from('profiles').update({
        'avatar_url': imageUrl
      }).eq('id', userId);

      if (mounted) {
        setState(() {
          _avatarUrl = imageUrl;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color.fromARGB(255, 249, 250, 251),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(221, 0, 0, 0),
            size: 20.0,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SharedProfilePicture(
                      avatarUrl: _avatarUrl,
                      isUploading: _isUploading,
                      onUpdatePicture: _isUploading ? null : _pickAndUploadAvatar,
                    ),
                    const SizedBox(height: 32.0),
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(
                              221,
                              0,
                              0,
                              0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
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
                          keyboardType:
                          TextInputType.emailAddress,
                          readOnly: true,
                        ),
                        const SizedBox(height: 16.0),
                        SharedInputField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hintText:
                          'Enter your new phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        if (_isRider) ...[
                          const SizedBox(height: 32.0),
                          const Divider(
                            color: Color.fromARGB(
                              255,
                              238,
                              238,
                              238,
                            ),
                            thickness: 1.5,
                          ),
                          const SizedBox(height: 24.0),
                          const Text(
                            'Rider Information',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(
                                221,
                                0,
                                0,
                                0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          SharedReadOnlyField(
                            label: 'Vehicle Type',
                            value:
                            widget.vehicleType.isNotEmpty
                                ? widget.vehicleType
                                : 'Not Available',
                            icon: Icons.two_wheeler_outlined,
                          ),
                          const SizedBox(height: 16.0),
                          SharedReadOnlyField(
                            label: 'Vehicle Plate',
                            value:
                            widget.vehiclePlate.isNotEmpty
                                ? widget.vehiclePlate
                                : 'Not Available',
                            icon: Icons
                                .confirmation_number_outlined,
                          ),
                          const SizedBox(height: 16.0),
                          SharedRatingField(
                            rating: widget.rating,
                          ),
                        ],
                        const SizedBox(height: 32.0),
                        const Divider(
                          color: Color.fromARGB(
                            255,
                            238,
                            238,
                            238,
                          ),
                          thickness: 1.5,
                        ),
                        const SizedBox(height: 24.0),
                        const Text(
                          'Security',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(
                              221,
                              0,
                              0,
                              0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        SharedInputField(
                          controller: _passwordController,
                          label: 'New Password',
                          hintText:
                          'Leave blank to keep current password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onTogglePassword: () {
                            setState(() {
                              _obscurePassword =
                              !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        SharedInputField(
                          controller:
                          _confirmPasswordController,
                          label: 'Confirm New Password',
                          hintText:
                          'Re-enter your new password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText:
                          _obscureConfirmPassword,
                          onTogglePassword: () {
                            setState(() {
                              _obscureConfirmPassword =
                              !_obscureConfirmPassword;
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
              padding:
              const EdgeInsets.symmetric(horizontal: 20.0),
              child: SharedSaveButton(
                isLoading: _isLoading,
                onPressed: () async {
                  final password =
                  _passwordController.text.trim();
                  final confirmPassword =
                  _confirmPasswordController.text.trim();

                  if (password.isNotEmpty &&
                      password != confirmPassword) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Passwords do not match. Please check again.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Color.fromARGB(
                          255,
                          239,
                          83,
                          80,
                        ),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _isLoading = true;
                  });

                  await widget.onSave(
                    _nameController.text.trim(),
                    _emailController.text.trim(),
                    _phoneController.text.trim(),
                    password,
                  );

                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
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
  final String? avatarUrl;
  final bool isUploading;

  const SharedProfilePicture({
    super.key,
    this.onUpdatePicture,
    this.avatarUrl,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 100.0,
          width: 100.0,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 160, 122).withOpacity(0.2),
            shape: BoxShape.circle,
            image: avatarUrl != null
                ? DecorationImage(
              image: NetworkImage(avatarUrl!),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: isUploading
              ? const CircularProgressIndicator(color: Color.fromARGB(255, 255, 160, 122))
              : (avatarUrl == null
              ? const Icon(
            Icons.person,
            size: 60.0,
            color: Color.fromARGB(255, 255, 160, 122),
          )
              : null),
        ),
        if (!isUploading)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              height: 36.0,
              width: 36.0,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 160, 122),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3.0),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20.0),
                onPressed: onUpdatePicture,
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
            color: readOnly
                ? const Color.fromARGB(
              255,
              158,
              158,
              158,
            )
                : const Color.fromARGB(
              221,
              0,
              0,
              0,
            ),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color.fromARGB(
                255,
                158,
                158,
                158,
              ),
            ),
            filled: true,
            fillColor: readOnly
                ? const Color.fromARGB(
              255,
              238,
              238,
              238,
            )
                : const Color.fromARGB(
              255,
              245,
              245,
              245,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color.fromARGB(
                255,
                117,
                117,
                117,
              ),
              size: 20.0,
            ),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color.fromARGB(
                  255,
                  117,
                  117,
                  117,
                ),
                size: 20.0,
              ),
              onPressed: onTogglePassword,
            )
                : readOnly
                ? const Icon(
              Icons.lock_outline,
              size: 18.0,
              color: Color.fromARGB(
                255,
                158,
                158,
                158,
              ),
            )
                : null,
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(15.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class SharedReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const SharedReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
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
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
          decoration: BoxDecoration(
            color: const Color.fromARGB(
              255,
              238,
              238,
              238,
            ),
            borderRadius:
            BorderRadius.circular(15.0),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color.fromARGB(
                  255,
                  117,
                  117,
                  117,
                ),
                size: 20.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15.0,
                    color: Color.fromARGB(
                      255,
                      117,
                      117,
                      117,
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline,
                size: 18.0,
                color: Color.fromARGB(
                  255,
                  158,
                  158,
                  158,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SharedRatingField extends StatelessWidget {
  final double rating;

  const SharedRatingField({
    super.key,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 6.0),
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
          decoration: BoxDecoration(
            color: const Color.fromARGB(
              255,
              238,
              238,
              238,
            ),
            borderRadius:
            BorderRadius.circular(15.0),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star,
                color: Color.fromARGB(
                  255,
                  255,
                  193,
                  7,
                ),
                size: 22.0,
              ),
              const SizedBox(width: 10.0),
              Text(
                rating > 0
                    ? rating.toStringAsFixed(1)
                    : 'No Rating',
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(
                    255,
                    117,
                    117,
                    117,
                  ),
                ),
              ),
              if (rating > 0) ...[
                const SizedBox(width: 4.0),
                const Text(
                  '/ 5.0',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(
                      255,
                      158,
                      158,
                      158,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              const Icon(
                Icons.lock_outline,
                size: 18.0,
                color: Color.fromARGB(
                  255,
                  158,
                  158,
                  158,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SharedSaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const SharedSaveButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.0,
      child: ElevatedButton(
        onPressed:
        isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          const Color.fromARGB(
            255,
            255,
            160,
            122,
          ),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(16.0),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20.0,
          height: 20.0,
          child:
          CircularProgressIndicator(
            strokeWidth: 2.0,
            color: Colors.white,
          ),
        )
            : const Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
    );
  }
}