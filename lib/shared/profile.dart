import 'package:flutter/material.dart';

class SharedProfileScreen extends StatefulWidget {
  final String title;
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final Function(String name, String email, String phone) onSave;
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
                          hintText: 'Enter your email address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16.0),
                        SharedInputField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hintText: 'Enter your phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
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
                onPressed: () {
                  widget.onSave(
                    _nameController.text,
                    _emailController.text,
                    _phoneController.text,
                  );
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

  const SharedInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
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
          style: const TextStyle(fontSize: 15.0, color: Color.fromARGB(221, 0, 0, 0)),
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
              borderSide: const BorderSide(color: Color.fromARGB(255, 255, 160, 122), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class SharedSaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SharedSaveButton({super.key, required this.onPressed});

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        ),
        child: const Text('Save Changes', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
      ),
    );
  }
}