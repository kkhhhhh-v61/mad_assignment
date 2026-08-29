import 'package:flutter/material.dart';

import '../global.dart';

class OrderTracking extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTracking({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const OrderTrackingMapPlaceholder(),
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
                    color: Color.fromARGB(221, 0, 0, 0),
                  ),
                ),
              ),
            ),
          ),
          OrderTrackingSheet(order: order),
        ],
      ),
    );
  }
}

//TODO: Replace with actual map widget and live location tracking from backend
class OrderTrackingMapPlaceholder extends StatelessWidget {
  const OrderTrackingMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(color: Color.fromARGB(255, 224, 224, 224)),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: Color.fromARGB(255, 229, 57, 53),
                  size: 64,
                ),
                SizedBox(height: 8),
                Text(
                  'Delivering to Destination...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderTrackingSheet extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTrackingSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? driver = order['driver'] as Map<String, dynamic>?;
    final List<Map<String, dynamic>> timeline = order['timeline'] != null
        ? List<Map<String, dynamic>>.from(order['timeline'])
        : [];

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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 224, 224, 224),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimated Arrival',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 117, 117, 117),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order['info'] as String? ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(221, 0, 0, 0),
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
                    color: const Color.fromARGB(
                      255,
                      33,
                      150,
                      243,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['status'] as String? ?? 'In Progress',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 33, 150, 243),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Color.fromARGB(255, 238, 238, 238), height: 1),
            const SizedBox(height: 24),
            
            if (driver != null) ...[
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 243, 224),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromARGB(255, 255, 204, 128),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: Color.fromARGB(255, 255, 152, 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['name'] as String? ?? 'Unknown Driver',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(221, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              driver['rating'] as String? ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 117, 117, 117),
                              ),
                            ),
                            Text(
                              ' (${driver['deliveries']} deliveries)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 158, 158, 158),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 76, 175, 80),
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
              const Divider(color: Color.fromARGB(255, 238, 238, 238), height: 1),
              const SizedBox(height: 24),
            ] else ...[
              const FallbackMessage(
                icon: Icons.person_off_outlined,
                title: 'Driver not assigned',
                description: 'We are finding a driver for your order.',
              ),
              const SizedBox(height: 24),
              const Divider(color: Color.fromARGB(255, 238, 238, 238), height: 1),
              const SizedBox(height: 24),
            ],

            if (timeline.isNotEmpty) ...[
              ...timeline.asMap().entries.map((entry) {
                int idx = entry.key;
                Map<String, dynamic> step = entry.value;
                return OrderTrackingTimelineStep(
                  title: step['title'] as String? ?? '',
                  subtitle: step['subtitle'] as String? ?? '',
                  icon: step['icon'] as IconData? ?? Icons.info,
                  isCompleted: step['isCompleted'] as bool? ?? false,
                  isActive: step['isActive'] as bool? ?? false,
                  isLast: idx == timeline.length - 1,
                );
              }),
            ] else ...[
              const FallbackMessage(
                icon: Icons.timeline,
                title: 'Timeline Unavailable',
                description: 'Tracking details will appear here soon.',
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class OrderTrackingTimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  const OrderTrackingTimelineStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    this.isActive = false,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isActive
        ? const Color.fromARGB(255, 33, 150, 243)
        : (isCompleted
            ? const Color.fromARGB(255, 76, 175, 80)
            : const Color.fromARGB(255, 189, 189, 189));

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
                    ? const Color.fromARGB(255, 76, 175, 80)
                    : const Color.fromARGB(255, 238, 238, 238),
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
                      ? const Color.fromARGB(221, 0, 0, 0)
                      : const Color.fromARGB(255, 117, 117, 117),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color.fromARGB(255, 158, 158, 158),
                ),
              ),
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
