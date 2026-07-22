import 'package:flutter/material.dart';

// ignore: unused_import
import '../global.dart';
// TODELETE
import '../data.dart';
import 'header.dart';

class CustomerHome extends StatelessWidget {
  final ValueChanged<String>? onCategorySelected;

  const CustomerHome({super.key, this.onCategorySelected});

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
                const SizedBox(height: 20.0),
                // --- Promotional Banner ---
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20.0),
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/images/banner_1.webp'),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(25, 0, 0, 0),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                // --- Quick Categories ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Quick Categories',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // TODO: Replace with dynamic categories data fetched from database
                // TODELETE
                buildDummyCategories(onSelected: onCategorySelected),
                const SizedBox(height: 16.0),
                // --- Trending Now ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trending Now',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(
                            255,
                            255,
                            160,
                            122,
                          ),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                // TODO: Replace with dynamic trending menu items fetched from database
                // TODELETE
                buildDummyMenuItems(onlyTrending: true),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== Category Item UI ====================
Widget buildCategoryItem({
  required IconData icon,
  required String name,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      margin: const EdgeInsets.only(right: 20.0),
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(20, 0, 0, 0),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Color.fromARGB(255, 255, 160, 122),
              size: 28,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: Color(0xDD000000),
            ),
          ),
        ],
      ),
    ),
  );
}
