import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

class _States {
  final String id;
  final String name;

  _States({required this.id, required this.name});

  factory _States.fromJson(Map<String, dynamic> json) {
    return _States(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class _FoodCategories {
  final String id;
  final String name;

  _FoodCategories({required this.id, required this.name});

  factory _FoodCategories.fromJson(Map<String, dynamic> json) {
    return _FoodCategories(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}


class AdminFoodEdit extends StatefulWidget {
  final Map<String, dynamic> item;

  const AdminFoodEdit({super.key, required this.item});

  @override
  State<AdminFoodEdit> createState() => _AdminFoodEditState();
}

class _AdminFoodEditState extends State<AdminFoodEdit> {
  final _formKey = GlobalKey<FormState>();

  File? _selectedImage;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();

  final foodNameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final preparationTimeCtrl = TextEditingController();

  List<_States> _availableStates = [];
  List<String> _selectedStates = [];
  bool _isLoadingStates = true;

  List<_FoodCategories> _foodCategories = [];
  List<String> _selectedCategories = [];
  bool _isLoadingCategories = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initItemData();
    _fetchStates();
    _fetchCategories();
  }

  void _initItemData() {
    foodNameCtrl.text = widget.item['name'] as String? ?? '';

    final price = (widget.item['price'] as num?)?.toDouble();
    priceCtrl.text = price != null ? price.toStringAsFixed(2) : '';

    final prepTime =
        widget.item['preparation_time'] ?? widget.item['prepTime'];
    preparationTimeCtrl.text = prepTime != null
        ? prepTime.toString().replaceAll(RegExp(r'[^0-9]'), '')
        : '';

    _existingImageUrl = widget.item['image_url'] as String?;

    final rawCats = widget.item['food_item_categories'] as List<dynamic>?;
    if (rawCats != null) {
      for (final entry in rawCats) {
        if (entry is Map<String, dynamic>) {
          final cat = entry['food_categories'] as Map<String, dynamic>?;
          if (cat != null && cat['name'] != null) {
            _selectedCategories.add(cat['name'].toString());
          }
        }
      }
    }

    final rawStates = widget.item['food_item_states'] as List<dynamic>?;
    if (rawStates != null) {
      for (final entry in rawStates) {
        if (entry is Map<String, dynamic>) {
          final state = entry['states'] as Map<String, dynamic>?;
          if (state != null && state['name'] != null) {
            _selectedStates.add(state['name'].toString());
          }
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    foodNameCtrl.dispose();
    priceCtrl.dispose();
    preparationTimeCtrl.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _fetchStates() async {
    try {
      final response = await supabase.from('states').select();
      if (mounted) {
        setState(() {
          _availableStates = (response as List)
              .map((e) => _States.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoadingStates = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingStates = false;
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await supabase
          .from('food_categories')
          .select()
          .order('display_order', ascending: true);
      if (mounted) {
        setState(() {
          _foodCategories = (response as List)
              .map((e) => _FoodCategories.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _saveFoodItem() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final foodId = widget.item['id'];
      String? imageUrl = _existingImageUrl;

      if (_selectedImage != null) {
        final fileExt = _selectedImage!.path.split('.').last.toLowerCase();
        final sanitizedName = foodNameCtrl.text
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '_');
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName.$fileExt';

        await supabase.storage.from('food-images').upload(
              fileName,
              _selectedImage!,
              fileOptions: const FileOptions(upsert: true),
            );

        imageUrl = supabase.storage.from('food-images').getPublicUrl(fileName);
      }

      await supabase.from('food_items').update({
        'name': foodNameCtrl.text.trim(),
        'price': double.parse(priceCtrl.text.trim()),
        'preparation_time': int.parse(preparationTimeCtrl.text.trim()),
        'image_url': imageUrl,
      }).eq('id', foodId);

      // Update categories
      await supabase
          .from('food_item_categories')
          .delete()
          .eq('food_id', foodId);

      if (_selectedCategories.isNotEmpty) {
        final categoryRows = _foodCategories
            .where((cat) => _selectedCategories.contains(cat.name))
            .map((cat) => {
                  'food_id': foodId,
                  'category_id': int.parse(cat.id),
                })
            .toList();

        if (categoryRows.isNotEmpty) {
          await supabase.from('food_item_categories').insert(categoryRows);
        }
      }


      // Update exclusive states
      await supabase
          .from('food_item_states')
          .delete()
          .eq('food_id', foodId);

      if (_selectedStates.isNotEmpty &&
          (_availableStates.isEmpty ||
              _selectedStates.length < _availableStates.length)) {
        final stateRows = _availableStates
            .where((s) => _selectedStates.contains(s.name))
            .map((s) => {
                  'food_id': foodId,
                  'state_id': int.parse(s.id),
                })
            .toList();

        if (stateRows.isNotEmpty) {
          await supabase.from('food_item_states').insert(stateRows);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food item updated successfully!'),
            backgroundColor: Color.fromARGB(255, 76, 175, 80),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update food item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteFoodItem() async {
    if (_isSaving) return;

    Navigator.pop(context); // Close dialog

    setState(() {
      _isSaving = true;
    });

    try {
      final foodId = widget.item['id'];

      // Delete storage image if present
      final imageUrl = widget.item['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(imageUrl);
          final segments = uri.pathSegments;
          final bucketIndex = segments.indexOf('food-images');
          if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
            final pathInBucket = segments.sublist(bucketIndex + 1).join('/');
            await supabase.storage.from('food-images').remove([pathInBucket]);
          }
        } catch (_) {}
      }

      await supabase
          .from('food_item_categories')
          .delete()
          .eq('food_id', foodId);
      await supabase
          .from('food_item_states')
          .delete()
          .eq('food_id', foodId);
      await supabase.from('food_items').delete().eq('id', foodId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food item deleted successfully!'),
            backgroundColor: Color.fromARGB(255, 76, 175, 80),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete food item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showDeleteConfirmModal() {
    final foodName = foodNameCtrl.text.trim().isNotEmpty
        ? foodNameCtrl.text.trim()
        : (widget.item['name']?.toString() ?? 'this food item');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(),
                const SizedBox(height: 20.0),
                Container(
                  height: 56,
                  width: 56,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 255, 235, 238),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color.fromARGB(255, 229, 57, 53),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Delete Food Item?',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 0, 0, 0),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Are you sure you want to delete "$foodName"? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
                const SizedBox(height: 24.0),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color.fromARGB(255, 224, 224, 224),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(221, 0, 0, 0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _deleteFoodItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 229, 57, 53),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _incrementPrice() {
    final current = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
    final next = current + 0.50;
    priceCtrl.text = next.toStringAsFixed(2);
    _formKey.currentState?.validate();
  }

  void _decrementPrice() {
    final current = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
    final next = current - 0.50;
    if (next > 0) {
      priceCtrl.text = next.toStringAsFixed(2);
    } else {
      priceCtrl.text = '0.00';
    }
    _formKey.currentState?.validate();
  }

  void _incrementPreparationTime() {
    final current = int.tryParse(preparationTimeCtrl.text.trim()) ?? 0;
    final next = current + 5;
    preparationTimeCtrl.text = next.toString();
    _formKey.currentState?.validate();
  }

  void _decrementPreparationTime() {
    final current = int.tryParse(preparationTimeCtrl.text.trim()) ?? 0;
    if (current > 5) {
      preparationTimeCtrl.text = (current - 5).toString();
    } else {
      preparationTimeCtrl.text = '1';
    }
    _formKey.currentState?.validate();
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
            onPressed: _isSaving ? null : _showDeleteConfirmModal,
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        _buildImagePickerAvatar(),
                        const SizedBox(height: 16.0),
                        _buildFormField(
                          label: 'Food Name',
                          isRequired: true,
                          controller: foodNameCtrl,
                          hintText: 'e.g., Spicy Chicken Burger',
                          prefixIcon: Icons.fastfood_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a food name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        _buildCategoryField(),
                        const SizedBox(height: 16.0),
                        _buildFormField(
                          label: 'Price (RM)',
                          isRequired: true,
                          controller: priceCtrl,
                          hintText: 'e.g., 10.00',
                          prefixIcon: Icons.price_change_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          onIncrement: _incrementPrice,
                          onDecrement: _decrementPrice,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a price';
                            }
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Please enter a valid price (e.g., 10.00)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        _buildFormField(
                          label: 'Preparation Time (minutes)',
                          isRequired: true,
                          controller: preparationTimeCtrl,
                          hintText: 'e.g., 30',
                          prefixIcon: Icons.timer,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onIncrement: _incrementPreparationTime,
                          onDecrement: _decrementPreparationTime,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a preparation time';
                            }
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Please enter a valid preparation time in minutes';
                            }
                            if (parsed > 32767) {
                              return 'Preparation time must be under 32,767 minutes';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        _buildExclusiveStateField(),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(221, 0, 0, 0),
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color.fromARGB(255, 158, 158, 158),
        fontSize: 14.0,
      ),
      filled: true,
      fillColor: const Color.fromARGB(255, 245, 245, 245),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color.fromARGB(255, 117, 117, 117),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 14.0,
      ),
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
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 255, 160, 122),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    bool isRequired = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
  }) {
    Widget? suffixIcon;
    if (onIncrement != null && onDecrement != null) {
      suffixIcon = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDecrement,
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 245, 240),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 200, 180),
                  ),
                ),
                child: const Icon(
                  Icons.remove,
                  size: 16,
                  color: Color.fromARGB(255, 255, 127, 80),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6.0),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 245, 240),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 200, 180),
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: Color.fromARGB(255, 255, 127, 80),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10.0),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 6.0),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: 15.0,
            color: Color.fromARGB(221, 0, 0, 0),
          ),
          decoration: _buildInputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return FormField<List<String>>(
      initialValue: _selectedCategories,
      validator: (_) {
        if (_selectedCategories.isEmpty) {
          return 'Please select at least one category';
        }
        return null;
      },
      builder: (FormFieldState<List<String>> formState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Category', isRequired: true),
            const SizedBox(height: 6.0),
            InkWell(
              onTap: _isLoadingCategories
                  ? null
                  : () => _showCategoryModal(formState),
              borderRadius: BorderRadius.circular(15.0),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 245, 245, 245),
                  borderRadius: BorderRadius.circular(15.0),
                  border: Border.all(
                    color: formState.hasError
                        ? Colors.red
                        : const Color.fromARGB(255, 224, 224, 224),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.category_outlined,
                      color: Color.fromARGB(255, 117, 117, 117),
                      size: 20,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: _isLoadingCategories
                          ? const Text(
                              'Loading categories...',
                              style: TextStyle(
                                color: Color.fromARGB(255, 158, 158, 158),
                                fontSize: 14.0,
                              ),
                            )
                          : _selectedCategories.isEmpty
                          ? const Text(
                              'Select categories',
                              style: TextStyle(
                                color: Color.fromARGB(255, 158, 158, 158),
                                fontSize: 14.0,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Wrap(
                                spacing: 6.0,
                                runSpacing: 4.0,
                                children: _selectedCategories.map((catName) {
                                  return Chip(
                                    label: Text(
                                      catName,
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        color: Color.fromARGB(221, 0, 0, 0),
                                      ),
                                    ),
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      255,
                                      245,
                                      240,
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Color.fromARGB(255, 255, 160, 122),
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedCategories.remove(catName);
                                      });
                                      formState.didChange(_selectedCategories);
                                    },
                                    side: const BorderSide(
                                      color: Color.fromARGB(255, 255, 160, 122),
                                      width: 1.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8.0),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color.fromARGB(255, 117, 117, 117),
                    ),
                  ],
                ),
              ),
            ),
            if (formState.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 6.0),
                child: Text(
                  formState.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12.0,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showCategoryModal(FormFieldState<List<String>> formState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allSelected =
                _foodCategories.isNotEmpty &&
                _selectedCategories.length == _foodCategories.length;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      _buildDragHandle(),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(221, 0, 0, 0),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                if (allSelected) {
                                  _selectedCategories.clear();
                                } else {
                                  _selectedCategories = _foodCategories
                                      .map((c) => c.name)
                                      .toList();
                                }
                              });
                              formState.didChange(_selectedCategories);
                              setState(() {});
                            },
                            child: Text(
                              allSelected ? 'Deselect All' : 'Select All',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 255, 160, 122),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color.fromARGB(255, 238, 238, 238)),
                      Expanded(
                        child: _foodCategories.isEmpty
                            ? const Center(
                                child: Text('No categories available'),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _foodCategories.length,
                                itemBuilder: (context, index) {
                                  final cat = _foodCategories[index];
                                  final isSelected = _selectedCategories
                                      .contains(cat.name);

                                  return CheckboxListTile(
                                    activeColor: const Color.fromARGB(
                                      255,
                                      255,
                                      160,
                                      122,
                                    ),
                                    title: Text(
                                      cat.name,
                                      style: const TextStyle(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setSheetState(() {
                                        if (value == true) {
                                          _selectedCategories.add(cat.name);
                                        } else {
                                          _selectedCategories.remove(cat.name);
                                        }
                                      });
                                      formState.didChange(_selectedCategories);
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8.0),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              160,
                              122,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildImagePickerAvatar() {
    ImageProvider? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_existingImageUrl!);
    }

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
            image: imageProvider != null
                ? DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageProvider == null
              ? const Icon(
                  Icons.image_outlined,
                  size: 50,
                  color: Color.fromARGB(255, 158, 158, 158),
                )
              : null,
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
            onPressed: _showImagePickerModal,
          ),
        ),
      ],
    );
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(),
                const SizedBox(height: 16.0),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExclusiveStateField() {
    final bool isAllSelected = _availableStates.isNotEmpty &&
        _selectedStates.length == _availableStates.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Exclusive State'),
        const SizedBox(height: 6.0),
        InkWell(
          onTap: _isLoadingStates ? null : _showExclusiveStatesModal,
          borderRadius: BorderRadius.circular(15.0),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 245, 245, 245),
              borderRadius: BorderRadius.circular(15.0),
              border: Border.all(
                color: const Color.fromARGB(255, 224, 224, 224),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.map_outlined,
                  color: Color.fromARGB(255, 117, 117, 117),
                  size: 20,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: _isLoadingStates
                      ? const Text(
                          'Loading states...',
                          style: TextStyle(
                            color: Color.fromARGB(255, 158, 158, 158),
                            fontSize: 14.0,
                          ),
                        )
                      : _selectedStates.isEmpty
                      ? const Text(
                          'Select exclusive states (or none for all)',
                          style: TextStyle(
                            color: Color.fromARGB(255, 158, 158, 158),
                            fontSize: 14.0,
                          ),
                        )
                      : isAllSelected
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 5.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 237, 247, 237),
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 200, 230, 201),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.public,
                                    size: 14.0,
                                    color: Color.fromARGB(255, 46, 125, 50),
                                  ),
                                  const SizedBox(width: 6.0),
                                  const Text(
                                    'All States (Nationwide)',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Color.fromARGB(255, 46, 125, 50),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6.0),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedStates.clear();
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Color.fromARGB(255, 46, 125, 50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Wrap(
                            spacing: 6.0,
                            runSpacing: 4.0,
                            children: _selectedStates.map((stateName) {
                              return Chip(
                                label: Text(
                                  stateName,
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Color.fromARGB(221, 0, 0, 0),
                                  ),
                                ),
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  255,
                                  245,
                                  240,
                                ),
                                deleteIcon: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Color.fromARGB(255, 255, 160, 122),
                                ),
                                onDeleted: () {
                                  setState(() {
                                    _selectedStates.remove(stateName);
                                  });
                                },
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 255, 160, 122),
                                  width: 1.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ),
                ),
                const SizedBox(width: 8.0),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color.fromARGB(255, 117, 117, 117),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showExclusiveStatesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allSelected =
                _availableStates.isNotEmpty &&
                _selectedStates.length == _availableStates.length;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      _buildDragHandle(),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Exclusive States',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(221, 0, 0, 0),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                if (allSelected) {
                                  _selectedStates.clear();
                                } else {
                                  _selectedStates = _availableStates
                                      .map((s) => s.name)
                                      .toList();
                                }
                              });
                              setState(() {});
                            },
                            child: Text(
                              allSelected ? 'Deselect All' : 'Select All',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 255, 160, 122),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color.fromARGB(255, 238, 238, 238)),
                      Expanded(
                        child: _availableStates.isEmpty
                            ? const Center(child: Text('No states available'))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _availableStates.length,
                                itemBuilder: (context, index) {
                                  final stateItem = _availableStates[index];
                                  final isSelected = _selectedStates.contains(
                                    stateItem.name,
                                  );

                                  return CheckboxListTile(
                                    activeColor: const Color.fromARGB(
                                      255,
                                      255,
                                      160,
                                      122,
                                    ),
                                    title: Text(
                                      stateItem.name,
                                      style: const TextStyle(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setSheetState(() {
                                        if (value == true) {
                                          _selectedStates.add(stateItem.name);
                                        } else {
                                          _selectedStates.remove(
                                            stateItem.name,
                                          );
                                        }
                                      });
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8.0),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              160,
                              122,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
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
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveFoodItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 160, 122),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
