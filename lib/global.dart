import 'package:flutter/material.dart';

class FallbackMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FallbackMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color.fromARGB(255, 238, 238, 238)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                255,
                255,
                160,
                122,
              ).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36.0,
              color: const Color.fromARGB(255, 255, 160, 122),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(221, 0, 0, 0),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4.0),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14.0,
              color: Color.fromARGB(255, 117, 117, 117),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
