import 'package:flutter/material.dart';

import 'main_navigation.dart';

class CustomerOrderConfirmation extends StatelessWidget {
  final double totalPaid;
  final String? paymentMethod;

  const CustomerOrderConfirmation({
    super.key,
    required this.totalPaid,
    this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final paymentNotice = paymentMethod == 'Cash on Delivery'
        ? 'Total to pay upon receiving your order: RM ${totalPaid.toStringAsFixed(2)}'
        : 'You have successfully paid RM ${totalPaid.toStringAsFixed(2)}';

    return Scaffold(
      backgroundColor: const Color.fromARGB(248, 255, 255, 255),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    76,
                    175,
                    80,
                  ).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 76, 175, 80),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromARGB(50, 76, 175, 80),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 64.0,
                  ),
                ),
              ),
              const SizedBox(height: 40.0),
              const Text(
                'Order Placed\nSuccessfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: Color.fromARGB(221, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                paymentNotice,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Color.fromARGB(255, 117, 117, 117),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CustomerMainNavigation(initialIndex: 2),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined, size: 20),
                label: const Text(
                  'View My Orders',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CustomerMainNavigation(initialIndex: 0),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home_outlined, size: 20),
                label: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 80, 80, 80),
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                    color: Color.fromARGB(255, 210, 210, 210),
                    width: 1.5,
                  ),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
