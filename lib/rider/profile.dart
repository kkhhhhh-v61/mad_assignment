import 'package:flutter/material.dart';

class RiderProfile extends StatefulWidget {
  const RiderProfile({super.key});

  @override
  State<RiderProfile> createState() => _RiderProfileState();
}

class _RiderProfileState extends State<RiderProfile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    //TODO: Populate controllers with existing rider profile data
    _nameController.text = 'Rider Ahmad';
    _emailController.text = 'ahmad_rider@example.com';
    _phoneController.text = '+60 12-345 6789';
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
        title: const Text(
          'Rider Profile',
          style: TextStyle(
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
              buildProfilePicture(),
              const SizedBox(height: 32.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildInputField(
                    controller: _nameController,
                    label: 'Full Name',
                    hintText: 'e.g., Ahmad',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16.0),
                  buildInputField(
                    controller: _emailController,
                    label: 'Email Address',
                    hintText: 'e.g., ahmad_rider@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16.0),
                  buildInputField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hintText: 'e.g., +60 12-345 6789',
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
              child: buildSaveButton(context),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}

Widget buildProfilePicture() {
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
            icon: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              //TODO: Handle rider profile picture update
            },
          ),
        ),
      ),
    ],
  );
}

Widget buildInputField({
  required TextEditingController controller,
  required String label,
  required String hintText,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
}) {
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
        style: const TextStyle(
          fontSize: 15.0,
          color: Color.fromARGB(221, 0, 0, 0),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color.fromARGB(255, 158, 158, 158),
          ),
          filled: true,
          fillColor: const Color.fromARGB(255, 245, 245, 245),
          prefixIcon: Icon(
            icon,
            color: const Color.fromARGB(255, 117, 117, 117),
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 224, 224, 224),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 224, 224, 224),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 255, 160, 122),
              width: 1.5,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget buildSaveButton(BuildContext context) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: () {
        //TODO: Update rider profile via backend API
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color.fromARGB(255, 255, 160, 122),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 255, 160, 122),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      child: const Text(
        'Save Changes',
        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
