import 'package:flutter/material.dart';

import '../config.dart';
import '../data.dart';

class FoodItemCard extends StatelessWidget {
  final MenuItem item;

  const FoodItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: spacingLg),
      padding: const EdgeInsets.all(spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: const [shadowMd],
      ),
      child: Row(
        children: [
          // --- Item Icon ---
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            child: Icon(
              // TODO: replace with image
              item.icon,
              color: textHint,
              size: 40,
            ),
          ),
          const SizedBox(width: spacingLg),
          // --- Item Details ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: fontSubtitle,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: spacingXs),
                Row(
                  children: [
                    const Icon(Icons.star, color: starColor, size: 16),
                    const SizedBox(width: spacingXs),
                    Text(
                      item.rating,
                      style: const TextStyle(
                        fontSize: fontDetail,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: spacingLg),
                    const Icon(Icons.access_time, color: textHint, size: 16),
                    const SizedBox(width: spacingXs),
                    Text(
                      item.prepTime,
                      style: const TextStyle(
                        fontSize: fontDetail,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: spacingSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatPrice(item.price),
                      style: const TextStyle(
                        fontSize: fontBodyLarge,
                        fontWeight: FontWeight.bold,
                        color: brandColor,
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 30,
                      decoration: const BoxDecoration(
                        color: brandColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        onPressed: () {
                          // TODO
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
