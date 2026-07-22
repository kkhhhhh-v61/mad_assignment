import 'package:flutter/material.dart';

void showFilterOverlay(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const FilterOverlay(),
  );
}

class FilterOverlay extends StatefulWidget {
  const FilterOverlay({super.key});

  @override
  State<FilterOverlay> createState() => _FilterOverlayState();
}

class _FilterOverlayState extends State<FilterOverlay> {
  // --- Filter State ---
  String _sortBy = 'Popularity';
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  double _minRating = 0.0;

  final List<String> _sortOptions = const [
    'Popularity',
    'Rating: High to Low',
    'Preparation Time',
    'Price: Low to High',
    'Price: High to Low',
  ];

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(25, 0, 0, 0),
              blurRadius: 15,
              spreadRadius: 2,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Drag Handle & Header ---
            _buildHeader(context),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            // --- Filter Sections ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSortSection(),
                  const SizedBox(height: 24.0),
                  _buildPriceSection(),
                  const SizedBox(height: 24.0),
                  _buildRatingSection(),
                ],
              ),
            ),
            // --- Bottom Action Buttons ---
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  // --- Header Section ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xDD000000),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFF757575),
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Sort By Section ---
  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color(0xDD000000),
          ),
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Choose how menu items are ordered',
          style: TextStyle(fontSize: 13.0, color: Color(0xFF757575)),
        ),
        const SizedBox(height: 12.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.sort,
                color: Color.fromARGB(255, 255, 160, 122),
                size: 22,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF757575),
                      size: 24,
                    ),
                    style: const TextStyle(
                      color: Color(0xDD000000),
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                    items: _sortOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _sortBy = newValue);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Price Range Section ---
  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Range',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color(0xDD000000),
          ),
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Set your minimum and maximum budget',
          style: TextStyle(fontSize: 13.0, color: Color(0xFF757575)),
        ),
        const SizedBox(height: 12.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPriceField(
                controller: _minPriceController,
                label: 'Minimum',
                hint: '0.00',
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 12.0, right: 12.0, top: 32),
              child: Text(
                '—',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            Expanded(
              child: _buildPriceField(
                controller: _maxPriceController,
                label: 'Maximum',
                hint: 'Any',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Price Input Field ---
  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 4.0),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.w600,
            color: Color(0xDD000000),
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixText: 'RM ',
            prefixStyle: const TextStyle(
              color: Color.fromARGB(255, 255, 160, 122),
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
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

  // --- Minimum Rating Section ---
  Widget _buildRatingSection() {
    String ratingLabel;
    if (_minRating == 0.0) {
      ratingLabel = 'Any Rating';
    } else if (_minRating == 5.0) {
      ratingLabel = '5.0 ★';
    } else {
      ratingLabel = '${_minRating.toStringAsFixed(1)} ★ & above';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minimum Rating',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xDD000000),
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Filter by customer satisfaction',
                  style: TextStyle(fontSize: 13.0, color: Color(0xFF757575)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  255,
                  160,
                  122,
                ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: Text(
                ratingLabel,
                style: const TextStyle(
                  color: Color.fromARGB(255, 255, 160, 122),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Slider(
          value: _minRating,
          min: 0.0,
          max: 5.0,
          divisions: 10,
          activeColor: const Color.fromARGB(255, 255, 160, 122),
          inactiveColor: const Color(0xFFEEEEEE),
          onChanged: (value) {
            setState(() => _minRating = value);
          },
        ),
      ],
    );
  }

  // --- Bottom Action Buttons ---
  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(15, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _sortBy = 'Popularity';
                    _minPriceController.clear();
                    _maxPriceController.clear();
                    _minRating = 0.0;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xDD000000),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: pass applied filter criteria back when dynamic data is connected
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
                  'Apply Filters',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
