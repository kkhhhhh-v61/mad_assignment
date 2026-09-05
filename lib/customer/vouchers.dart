import 'package:flutter/material.dart';

class CustomerVouchersScreen extends StatefulWidget {
  const CustomerVouchersScreen({super.key});

  @override
  State<CustomerVouchersScreen> createState() => _CustomerVouchersScreenState();
}

class _CustomerVouchersScreenState extends State<CustomerVouchersScreen> {
  // 1. Declarations & Initializations
  final List<Map<String, dynamic>> _vouchers = [];
  bool _isLoading = false;

  // 2. Overrides & Lifecycle
  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  // 3. Logic Functions
  Future<void> _loadVouchers() async {
    //TODO: Retrieve available vouchers from database
    setState(() {
      _isLoading = false;
    });
  }

  // 4. Main Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vouchers',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 255, 160, 122),
              ),
            )
          : _vouchers.isEmpty
              ? _buildEmptyState()
              : _buildVouchersList(),
    );
  }

  // 5. UI Helpers / Sub-widgets
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 160, 122)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 52,
                color: Color.fromARGB(255, 255, 160, 122),
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'No Vouchers Available',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Color(0xDD000000),
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'You currently have no available vouchers.\nCheck back later for exciting offers and promotions!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Color.fromARGB(255, 117, 117, 117),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVouchersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _vouchers.length,
      itemBuilder: (context, index) {
        final voucher = _vouchers[index];
        return _buildVoucherCard(voucher);
      },
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final title = voucher['title'] ?? 'Voucher';
    final description = voucher['description'] ?? '';
    final code = voucher['code'] ?? '';
    final expiryDate = voucher['expiry_date'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color.fromARGB(255, 238, 238, 238),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(8, 0, 0, 0),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 160, 122)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Icon(
              Icons.local_offer,
              color: Color.fromARGB(255, 255, 160, 122),
              size: 24,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color.fromARGB(255, 117, 117, 117),
                    ),
                  ),
                ],
                if (code.isNotEmpty || expiryDate.isNotEmpty) ...[
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      if (code.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 245, 245, 245),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 66, 66, 66),
                            ),
                          ),
                        ),
                      if (code.isNotEmpty && expiryDate.isNotEmpty)
                        const SizedBox(width: 8.0),
                      if (expiryDate.isNotEmpty)
                        Text(
                          'Expires $expiryDate',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color.fromARGB(255, 140, 140, 140),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
