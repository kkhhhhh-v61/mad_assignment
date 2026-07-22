import 'package:flutter/material.dart';

import '../config.dart';

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
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
          boxShadow: [shadowLg],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Drag Handle & Header ---
            _buildHeader(context),
            const Divider(height: 1, color: borderLight),
            // --- Filter Sections ---
            Padding(
              padding: const EdgeInsets.all(spacingXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSortSection(),
                  const SizedBox(height: spacing2xl),
                  _buildPriceSection(),
                  const SizedBox(height: spacing2xl),
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
      padding: const EdgeInsets.symmetric(
        horizontal: spacingXl,
        vertical: spacingLg,
      ),
      child: Column(
        children: [
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: borderLight,
              borderRadius: BorderRadius.circular(radiusFull),
            ),
          ),
          const SizedBox(height: spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: fontHeadline,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: textSecondary, size: 24),
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
            fontSize: fontSubtitle,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: spacingXs),
        const Text(
          'Choose how menu items are ordered',
          style: TextStyle(fontSize: fontDetail, color: textSecondary),
        ),
        const SizedBox(height: spacingMd),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: spacingLg),
          decoration: BoxDecoration(
            color: surfaceLight,
            borderRadius: BorderRadius.circular(radiusLg),
            border: Border.all(color: borderLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.sort, color: brandColor, size: 22),
              const SizedBox(width: spacingMd),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: textSecondary,
                      size: 24,
                    ),
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: fontBodyLarge,
                      fontWeight: FontWeight.w600,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(radiusLg),
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
            fontSize: fontSubtitle,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: spacingXs),
        const Text(
          'Set your minimum and maximum budget',
          style: TextStyle(fontSize: fontDetail, color: textSecondary),
        ),
        const SizedBox(height: spacingMd),
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
              padding: EdgeInsets.only(
                left: spacingMd,
                right: spacingMd,
                top: 32,
              ),
              child: Text(
                '—',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: fontTitle,
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
            fontSize: fontCaption,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: spacingXs),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: fontBodyLarge,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixText: 'RM ',
            prefixStyle: const TextStyle(
              color: brandColor,
              fontWeight: FontWeight.bold,
              fontSize: fontBodyLarge,
            ),
            hintText: hint,
            hintStyle: const TextStyle(
              color: textHint,
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: spacingMd,
              vertical: spacingMd,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusLg),
              borderSide: const BorderSide(color: borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusLg),
              borderSide: const BorderSide(color: borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusLg),
              borderSide: const BorderSide(color: brandColor, width: 1.5),
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
                    fontSize: fontSubtitle,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: spacingXs),
                Text(
                  'Filter by customer satisfaction',
                  style: TextStyle(fontSize: fontDetail, color: textSecondary),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: spacingMd,
                vertical: spacingXs,
              ),
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(radiusFull),
              ),
              child: Text(
                ratingLabel,
                style: const TextStyle(
                  color: brandColor,
                  fontWeight: FontWeight.bold,
                  fontSize: fontBody,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: spacingLg),
        Slider(
          value: _minRating,
          min: 0.0,
          max: 5.0,
          divisions: 10,
          activeColor: brandColor,
          inactiveColor: surfaceMuted,
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
      padding: const EdgeInsets.all(spacingXl),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [shadowBottomBar],
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
                  foregroundColor: textPrimary,
                  side: const BorderSide(color: borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusFull),
                  ),
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: fontSubtitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: spacingMd),
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
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusFull),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: fontSubtitle,
                    fontWeight: FontWeight.bold,
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
