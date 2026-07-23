import 'package:flutter/material.dart';

class OrderTracking extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTracking({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Placeholder Map
          buildOrderTrackingMapPlaceholderUI(),

          // Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.only(left: 6.0),
                  child: Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: Color(0xDD000000),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Sheet
          buildOrderTrackingSheetUI(context, order),
        ],
      ),
    );
  }
}

// ==================== Dynamic UI Functions ====================

Widget buildOrderTrackingMapPlaceholderUI() {
  return Container(
    width: double.infinity,
    height: double.infinity,
    decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
    child: Stack(
      children: [
        // Custom Grid pattern to simulate map texture
        Positioned.fill(child: CustomPaint(painter: GridPainter())),
        // Center Location Pin
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Color(0xFFE53935), size: 64),
              SizedBox(height: 8),
              Text(
                'Delivering to Destination...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildOrderTrackingSheetUI(
  BuildContext context,
  Map<String, dynamic> order,
) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ETA and Status Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimated Arrival',
                    style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['info'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xDD000000),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'On The Way',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEEEEEE), height: 1),
          const SizedBox(height: 24),

          // Rider Info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCC80), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Color(0xFFFF9800)),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Azizul Rahman',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xDD000000),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '4.9',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF757575),
                          ),
                        ),
                        Text(
                          ' (1.2k+ deliveries)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.call, color: Colors.white, size: 20),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEEEEEE), height: 1),
          const SizedBox(height: 24),

          // Vertical Stepper
          buildOrderTrackingTimelineStepUI(
            title: 'Order Placed',
            subtitle: 'Restaurant confirmed your order.',
            icon: Icons.receipt,
            isCompleted: true,
            isLast: false,
          ),
          buildOrderTrackingTimelineStepUI(
            title: 'Preparing',
            subtitle: 'Your food is being prepared.',
            icon: Icons.outdoor_grill,
            isCompleted: true,
            isLast: false,
          ),
          buildOrderTrackingTimelineStepUI(
            title: 'On The Way',
            subtitle: 'Rider is heading to your location.',
            icon: Icons.electric_moped,
            isCompleted: false,
            isActive: true,
            isLast: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Widget buildOrderTrackingTimelineStepUI({
  required String title,
  required String subtitle,
  required IconData icon,
  required bool isCompleted,
  bool isActive = false,
  required bool isLast,
}) {
  final Color color = isActive
      ? const Color(0xFF2196F3)
      : (isCompleted ? const Color(0xFF4CAF50) : const Color(0xFFBDBDBD));

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted || isActive ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              icon,
              color: isCompleted || isActive ? Colors.white : color,
              size: 16,
            ),
          ),
          if (!isLast)
            Container(
              width: 2,
              height: 40,
              color: isCompleted
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFEEEEEE),
            ),
        ],
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isActive
                    ? const Color(0xDD000000)
                    : const Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
            ),
            if (!isLast) const SizedBox(height: 24),
          ],
        ),
      ),
    ],
  );
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
