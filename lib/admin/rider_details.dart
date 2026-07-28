import 'package:flutter/material.dart';

class AdminRiderDetails extends StatefulWidget {
  final Map<String, dynamic> rider;

  const AdminRiderDetails({super.key, required this.rider});

  @override
  State<AdminRiderDetails> createState() => _AdminRiderDetailsState();
}

class _AdminRiderDetailsState extends State<AdminRiderDetails> {
  bool _isAccountEnabled = true;

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
          'Rider Details',
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
                    buildImageDisplay(widget.rider['icon'] as IconData?),
                    const SizedBox(height: 32.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildDetailField(
                          label: 'Rider Name',
                          value: widget.rider['name'] as String? ?? 'N/A',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16.0),
                        buildDetailField(
                          label: 'Phone Number',
                          value: widget.rider['phone'] as String? ?? 'N/A',
                          icon: Icons.phone_outlined,
                        ),
                        const SizedBox(height: 16.0),
                        buildDetailField(
                          label: 'Email Address',
                          value: widget.rider['email'] as String? ?? 'N/A',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 16.0),
                        buildDetailField(
                          label: 'Vehicle Type',
                          value: widget.rider['vehicle'] as String? ?? 'N/A',
                          icon: Icons.directions_car_outlined,
                        ),
                        const SizedBox(height: 16.0),
                        buildDetailField(
                          label: 'Vehicle Plate',
                          value: widget.rider['plate'] as String? ?? 'N/A',
                          icon: Icons.pin_outlined,
                        ),
                        const SizedBox(height: 16.0),
                        buildDetailField(
                          label: 'Rating',
                          value: widget.rider['rating'] as String? ?? 'N/A',
                          icon: Icons.star_outline,
                        ),
                        const SizedBox(height: 16.0),
                        buildDetailField(
                          label: 'Current Status',
                          value: widget.rider['status'] as String? ?? 'N/A',
                          icon: Icons.info_outline,
                        ),
                        const SizedBox(height: 32.0),
                        buildAccountToggleSection(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAccountToggleSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(15, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
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
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(221, 0, 0, 0),
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                'Enable or disable access',
                style: TextStyle(
                  fontSize: 13.0,
                  color: Color.fromARGB(255, 117, 117, 117),
                ),
              ),
            ],
          ),
          Switch(
            value: _isAccountEnabled,
            activeThumbColor: const Color.fromARGB(255, 255, 160, 122),
            activeTrackColor: const Color.fromARGB(100, 255, 160, 122),
            onChanged: (bool value) {
              setState(() {
                _isAccountEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }
}

Widget buildImageDisplay(IconData? existingIcon) {
  return Container(
    height: 120,
    width: 120,
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 245, 245, 245),
      borderRadius: BorderRadius.circular(20.0),
      border: Border.all(
        color: const Color.fromARGB(255, 224, 224, 224),
        width: 2.0,
      ),
    ),
    child: Icon(
      existingIcon ?? Icons.image_outlined,
      size: 50,
      color: const Color.fromARGB(255, 158, 158, 158),
    ),
  );
}

Widget buildDetailField({
  required String label,
  required String value,
  required IconData icon,
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
        controller: TextEditingController(text: value),
        readOnly: true,
        style: const TextStyle(
          fontSize: 15.0,
          color: Color.fromARGB(221, 0, 0, 0),
        ),
        decoration: InputDecoration(
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
              color: Color.fromARGB(255, 224, 224, 224),
            ),
          ),
        ),
      ),
    ],
  );
}
