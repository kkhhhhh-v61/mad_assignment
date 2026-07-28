import 'package:flutter/material.dart';

class AdminFoodEdit extends StatefulWidget {
  final Map<String, dynamic> item;

  const AdminFoodEdit({super.key, required this.item});

  @override
  State<AdminFoodEdit> createState() => _AdminFoodEditState();
}

class _AdminFoodEditState extends State<AdminFoodEdit> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _selectedState = 'Selangor';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.item['name'] as String? ?? '';
    final price = widget.item['price'] as double?;
    _priceController.text = price != null ? price.toStringAsFixed(2) : '';
    _prepTimeController.text = widget.item['prepTime'] as String? ?? '';
    _descController.text = 'A delicious food item.'; // Dummy description
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    _descController.dispose();
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
          'Edit Food Item',
          style: TextStyle(
            color: Color.fromARGB(221, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Color.fromARGB(255, 229, 57, 53),
            ),
            onPressed: () {
              //TODO: Implement delete food item logic
            },
          ),
          const SizedBox(width: 8.0),
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
                    buildImagePlaceholder(widget.item['icon'] as IconData?),
                    const SizedBox(height: 32.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildInputField(
                          controller: _nameController,
                          label: 'Food Name',
                          hintText: 'e.g., Spicy Chicken Burger',
                          icon: Icons.fastfood_outlined,
                        ),
                        const SizedBox(height: 16.0),
                        buildInputField(
                          controller: _descController,
                          label: 'Description',
                          hintText: 'Brief description of the food item',
                          icon: Icons.description_outlined,
                        ),
                        const SizedBox(height: 16.0),
                        buildInputField(
                          controller: _prepTimeController,
                          label: 'Preparation Time',
                          hintText: 'e.g., 15-20 min',
                          icon: Icons.access_time,
                        ),
                        const SizedBox(height: 16.0),
                        buildDropdownField(
                          value: _selectedState,
                          label: 'State',
                          hintText: 'Select a state',
                          icon: Icons.map_outlined,
                          items: [
                            'Johor',
                            'Kedah',
                            'Kelantan',
                            'Melaka',
                            'Negeri Sembilan',
                            'Pahang',
                            'Perak',
                            'Perlis',
                            'Penang',
                            'Sabah',
                            'Sarawak',
                            'Selangor',
                            'Terengganu',
                            'Kuala Lumpur',
                            'Labuan',
                            'Putrajaya'
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedState = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        buildInputField(
                          controller: _priceController,
                          label: 'Price (RM)',
                          hintText: 'e.g., 15.90',
                          icon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 24.0),
                        buildCustomizationSection(),
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
                  BoxShadow(
                    color: Color.fromARGB(15, 0, 0, 0),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: buildSaveButton(context),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildImagePlaceholder(IconData? existingIcon) {
  return Stack(
    alignment: Alignment.bottomRight,
    children: [
      Container(
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
          icon: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () {
            //TODO: Implement image picker for editing food item
          },
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

Widget buildDropdownField({
  required String? value,
  required String label,
  required String hintText,
  required IconData icon,
  required List<String> items,
  required ValueChanged<String?> onChanged,
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
      DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
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
        icon: const Icon(Icons.keyboard_arrow_down, color: Color.fromARGB(255, 117, 117, 117)),
      ),
    ],
  );
}

Widget buildCustomizationSection() {
  final List<Map<String, dynamic>> dummyOptions = [
    {'name': 'Size', 'options': 'Small, Medium, Large', 'required': true},
    {'name': 'Add-ons', 'options': 'Extra Cheese, Fried Egg, Bacon', 'required': false},
    {'name': 'Spiciness', 'options': 'Mild, Normal, Extra Spicy', 'required': true},
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Customization Options',
        style: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(221, 0, 0, 0),
        ),
      ),
      const SizedBox(height: 12.0),
      ...dummyOptions.map((opt) => Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: const Color.fromARGB(255, 224, 224, 224)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(10, 0, 0, 0),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        opt['name'] as String,
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (opt['required'] as bool) ...[
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 235, 238),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 10.0,
                              color: Color.fromARGB(255, 229, 57, 53),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    opt['options'] as String,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: Color.fromARGB(255, 117, 117, 117),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 32,
              width: 32,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 245, 245, 245),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color.fromARGB(255, 158, 158, 158),
                  size: 16,
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              height: 32,
              width: 32,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 245, 245, 245),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color.fromARGB(255, 229, 57, 53),
                  size: 16,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      )),
      InkWell(
        onTap: () {
          //TODO: Open dialog to add new customization option
        },
        borderRadius: BorderRadius.circular(15.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 245, 240),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(
              color: const Color.fromARGB(255, 255, 160, 122),
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Color.fromARGB(255, 255, 160, 122),
                size: 20,
              ),
              SizedBox(width: 8.0),
              Text(
                'Add Customization',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 160, 122),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                ),
              ),
            ],
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
        //TODO: Update food item via backend API
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Food item updated successfully',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color.fromARGB(255, 76, 175, 80),
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
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      child: const Text(
        'Save Changes',
        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
