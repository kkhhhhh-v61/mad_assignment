import 'package:flutter/material.dart';

import '../config.dart';
import '../data.dart';
import 'customer_header.dart';
import 'food_item_card.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CustomerHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: spacingXl),
                // --- Promotional Banner ---
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: spacingXl,
                        ),
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/images/banner_1.webp'),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(radiusXl),
                          boxShadow: const [shadowLg],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: spacingLg),
                // --- Quick Categories ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacingXl),
                  child: Text(
                    'Quick Categories',
                    style: TextStyle(
                      fontSize: fontTitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: spacingLg),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: spacingXl),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: spacingXl),
                        child: Column(
                          children: [
                            Container(
                              height: 65,
                              width: 65,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [shadowMd],
                              ),
                              child: Icon(
                                // TODO: replace with image
                                categories[index].icon,
                                color: brandColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: spacingSm),
                            Text(
                              categories[index].name,
                              style: const TextStyle(
                                fontSize: fontDetail,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: spacingLg),
                // --- Trending Now ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: spacingXl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trending Now',
                        style: TextStyle(
                          fontSize: fontTitle,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: brandColor,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: spacingLg),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: spacingXl),
                  itemCount: trendingItems.length > 3
                      ? 3
                      : trendingItems.length,
                  itemBuilder: (context, index) {
                    return FoodItemCard(item: trendingItems[index]);
                  },
                ),
                const SizedBox(height: spacingXl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
