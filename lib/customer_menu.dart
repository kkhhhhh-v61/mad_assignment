import 'package:flutter/material.dart';

import 'customer_header.dart';

class CustomerMenu extends StatelessWidget {
  const CustomerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomerHeader(showFilter: true),
        const Expanded(
          child: SingleChildScrollView(
            child: Column(

            ),
          ),
        ),
      ],
    );
  }
}
