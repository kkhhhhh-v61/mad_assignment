import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

class _NamedItem {
  final String id, name;
  const _NamedItem({required this.id, required this.name});
  factory _NamedItem.fromJson(Map<String, dynamic> json) => _NamedItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}

class FoodCreation extends StatefulWidget {
  const FoodCreation({super.key});

  @override
  State<FoodCreation> createState() => _FoodCreationState();
}

class _FoodCreationState extends State<FoodCreation> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _prepTimeController = TextEditingController();

  File? _selectedImage;
  List<_NamedItem> _availableStates = [];
  List<String> _selectedStates = [];
  bool _isLoadingStates = true;

  List<_NamedItem> _availableCategories = [];
  List<String> _selectedCategories = [];
  bool _isLoadingCategories = true;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchStates();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _fetchStates() async {
    try {
      final response = await supabase.from('states').select();
      if (mounted) {
        setState(() {
          _availableStates = (response as List)
              .map((e) => _NamedItem.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoadingStates = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStates = false);
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
          _availableCategories = (response as List)
              .map((e) => _NamedItem.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  void _stepPrice(double delta) {
    final cur = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final next = (cur + delta).clamp(0.0, double.infinity);
    _priceController.text = next.toStringAsFixed(2);
    _formKey.currentState?.validate();
  }

  void _stepPrepTime(int delta) {
    final cur = int.tryParse(_prepTimeController.text.trim()) ?? 0;
    _prepTimeController.text = (cur + delta > 0 ? cur + delta : 1).toString();
    _formKey.currentState?.validate();
  }

  Future<void> _submitFoodItem() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final ext = _selectedImage!.path.split('.').last.toLowerCase();
        final name = _nameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$name.$ext';

        await supabase.storage.from('food-images').upload(
              fileName,
              _selectedImage!,
              fileOptions: const FileOptions(upsert: true),
            );
        imageUrl = supabase.storage.from('food-images').getPublicUrl(fileName);
      }

      final res = await supabase.from('food_items').insert({
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'preparation_time': int.parse(_prepTimeController.text.trim()),
        'image_url': imageUrl,
        'is_available': true,
      }).select().single();

      final foodId = res['id'];

      if (_selectedCategories.isNotEmpty) {
        final catRows = _availableCategories
            .where((c) => _selectedCategories.contains(c.name))
            .map((c) => {'food_id': foodId, 'category_id': int.parse(c.id)})
            .toList();
        if (catRows.isNotEmpty) await supabase.from('food_item_categories').insert(catRows);
      }

      if (_selectedStates.isNotEmpty &&
          (_availableStates.isEmpty || _selectedStates.length < _availableStates.length)) {
        final stateRows = _availableStates
            .where((s) => _selectedStates.contains(s.name))
            .map((s) => {'food_id': foodId, 'state_id': int.parse(s.id)})
            .toList();
        if (stateRows.isNotEmpty) await supabase.from('food_item_states').insert(stateRows);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food item created successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create food item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(),
              const SizedBox(height: 16),
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
      ),
    );
  }

  void _showMultiSelectPicker({
    required String title,
    required List<String> options,
    required List<String> selectedItems,
    required ValueChanged<List<String>> onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final allSelected = options.isNotEmpty && selectedItems.length == options.length;
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _buildDragHandle(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xDD000000),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            if (allSelected) {
                              selectedItems.clear();
                            } else {
                              selectedItems..clear()..addAll(options);
                            }
                          });
                          onChanged(List.from(selectedItems));
                          setState(() {});
                        },
                        child: Text(
                          allSelected ? 'Deselect All' : 'Select All',
                          style: const TextStyle(
                            color: Color(0xFFFFA07A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: options.isEmpty
                        ? Center(child: Text('No $title available'.toLowerCase()))
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: options.length,
                            itemBuilder: (_, i) {
                              final item = options[i];
                              final isSelected = selectedItems.contains(item);
                              return CheckboxListTile(
                                activeColor: const Color(0xFFFFA07A),
                                title: Text(item, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                value: isSelected,
                                onChanged: (val) {
                                  setModalState(() {
                                    val == true ? selectedItems.add(item) : selectedItems.remove(item);
                                  });
                                  onChanged(List.from(selectedItems));
                                  setState(() {});
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA07A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xDD000000), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Food Item',
          style: TextStyle(color: Color(0xDD000000), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildImagePickerAvatar(),
                      const SizedBox(height: 16),
                      _buildFormField(
                        label: 'Food Name',
                        isRequired: true,
                        controller: _nameController,
                        hintText: 'e.g., Spicy Chicken Burger',
                        prefixIcon: Icons.fastfood_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a food name' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryField(),
                      const SizedBox(height: 16),
                      _buildFormField(
                        label: 'Price (RM)',
                        isRequired: true,
                        controller: _priceController,
                        hintText: 'e.g., 10.00',
                        prefixIcon: Icons.price_change_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                        onIncrement: () => _stepPrice(0.50),
                        onDecrement: () => _stepPrice(-0.50),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter a price';
                          final p = double.tryParse(v.trim());
                          return (p == null || p <= 0) ? 'Please enter a valid price (e.g., 10.00)' : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        label: 'Preparation Time (minutes)',
                        isRequired: true,
                        controller: _prepTimeController,
                        hintText: 'e.g., 30',
                        prefixIcon: Icons.timer,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onIncrement: () => _stepPrepTime(5),
                        onDecrement: () => _stepPrepTime(-5),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter a preparation time';
                          final p = int.tryParse(v.trim());
                          if (p == null || p <= 0) return 'Please enter a valid preparation time in minutes';
                          if (p > 32767) return 'Preparation time must be under 32,767 minutes';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildExclusiveStateField(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
            image: _selectedImage != null
                ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                : null,
          ),
          child: _selectedImage == null
              ? const Icon(Icons.image_outlined, size: 50, color: Color(0xFF9E9E9E))
              : null,
        ),
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFA07A),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            onPressed: _showImageSourcePicker,
          ),
        ),
      ],
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
          _buildStepperButton(icon: Icons.remove, onTap: onDecrement),
          const SizedBox(width: 6),
          _buildStepperButton(icon: Icons.add, onTap: onIncrement),
          const SizedBox(width: 10),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 15, color: Color(0xDD000000)),
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

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFC8B4)),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFFFF7F50)),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return FormField<List<String>>(
      initialValue: _selectedCategories,
      validator: (_) => _selectedCategories.isEmpty ? 'Please select at least one category' : null,
      builder: (state) => _buildSelectableChipField(
        label: 'Category',
        isRequired: true,
        icon: Icons.category_outlined,
        isLoading: _isLoadingCategories,
        loadingText: 'Loading categories...',
        placeholder: 'Select categories',
        selectedItems: _selectedCategories,
        onTap: _isLoadingCategories
            ? null
            : () => _showMultiSelectPicker(
                  title: 'Category',
                  options: _availableCategories.map((c) => c.name).toList(),
                  selectedItems: _selectedCategories,
                  onChanged: (items) {
                    setState(() => _selectedCategories = items);
                    state.didChange(items);
                  },
                ),
        onDeleted: (item) {
          setState(() => _selectedCategories.remove(item));
          state.didChange(_selectedCategories);
        },
        errorText: state.errorText,
      ),
    );
  }

  Widget _buildExclusiveStateField() {
    final isAllSelected = _availableStates.isNotEmpty && _selectedStates.length == _availableStates.length;
    return _buildSelectableChipField(
      label: 'Exclusive State',
      icon: Icons.map_outlined,
      isLoading: _isLoadingStates,
      loadingText: 'Loading states...',
      placeholder: 'Select exclusive states (or none for all)',
      selectedItems: _selectedStates,
      showAllBadge: true,
      isAllSelected: isAllSelected,
      onClearAll: () => setState(() => _selectedStates.clear()),
      onTap: _isLoadingStates
          ? null
          : () => _showMultiSelectPicker(
                title: 'Exclusive States',
                options: _availableStates.map((s) => s.name).toList(),
                selectedItems: _selectedStates,
                onChanged: (items) => setState(() => _selectedStates = items),
              ),
      onDeleted: (item) => setState(() => _selectedStates.remove(item)),
    );
  }

  Widget _buildSelectableChipField({
    required String label,
    required IconData icon,
    required bool isLoading,
    required String loadingText,
    required String placeholder,
    required List<String> selectedItems,
    required VoidCallback? onTap,
    required ValueChanged<String> onDeleted,
    bool isRequired = false,
    bool showAllBadge = false,
    bool isAllSelected = false,
    VoidCallback? onClearAll,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: errorText != null ? Colors.red : const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF757575), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: isLoading
                      ? Text(loadingText, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14))
                      : selectedItems.isEmpty
                          ? Text(placeholder, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14))
                          : showAllBadge && isAllSelected
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDF7ED),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFC8E6C9)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.public, size: 14, color: Color(0xFF2E7D32)),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'All States',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: onClearAll,
                                          child: const Icon(Icons.close, size: 14, color: Color(0xFF2E7D32)),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: selectedItems.map((item) {
                                    return Chip(
                                      label: Text(item, style: const TextStyle(fontSize: 12, color: Color(0xDD000000))),
                                      backgroundColor: const Color(0xFFFFF5F0),
                                      deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFFFFA07A)),
                                      onDeleted: () => onDeleted(item),
                                      side: const BorderSide(color: Color(0xFFFFA07A)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF757575)),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, -5)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFoodItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFA07A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xDD000000)),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
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
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  OutlineInputBorder _outlineBorder([Color color = const Color(0xFFE0E0E0), double width = 1.0]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF757575), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _outlineBorder(),
      enabledBorder: _outlineBorder(),
      focusedBorder: _outlineBorder(const Color(0xFFFFA07A), 1.5),
      errorBorder: _outlineBorder(Colors.red),
      focusedErrorBorder: _outlineBorder(Colors.red, 1.5),
    );
  }
}
