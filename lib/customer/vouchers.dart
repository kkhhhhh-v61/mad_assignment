import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerVouchersScreen extends StatefulWidget {
  const CustomerVouchersScreen({super.key});

  @override
  State<CustomerVouchersScreen> createState() => _CustomerVouchersScreenState();
}

class _CustomerVouchersScreenState extends State<CustomerVouchersScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('vouchers')
          .select()
          .eq('is_active', true)
          .or('customer_id.is.null, customer_id.eq.$userId')
          .order('expiry_date', ascending: true);

      if (mounted) {
        setState(() {
          _vouchers = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading customer vouchers: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher code "$code" copied to clipboard!', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 76, 175, 80),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Vouchers',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color.fromARGB(255, 255, 160, 122)),
      )
          : _vouchers.isEmpty
          ? _buildEmptyState()
          : _buildVouchersList(),
    );
  }

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
                color: const Color.fromARGB(255, 255, 160, 122).withOpacity(0.12),
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
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xDD000000)),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'You currently have no available vouchers.\nCheck back later for exciting offers and promotions!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Color.fromARGB(255, 117, 117, 117), height: 1.5),
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
        return _buildCouponCard(voucher);
      },
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> v) {
    final isSpecific = v['customer_id'] != null;
    final isFreeDelivery = v['is_free_delivery'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      elevation: 0,
      color: Colors.white,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 160, 122).withOpacity(0.15),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(15.0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFreeDelivery ? 'FREE' : 'RM',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 255, 160, 122),
                      fontWeight: FontWeight.bold,
                      fontSize: isFreeDelivery ? 20 : 14,
                    ),
                  ),
                  if (!isFreeDelivery)
                    Text(
                      '${v['discount_amount']}',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 160, 122),
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        height: 1.1,
                      ),
                    ),
                  if (isFreeDelivery)
                    const Text(
                      'DELIVERY',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 160, 122),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        height: 1.1,
                      ),
                    ),
                ],
              ),
            ),

            Container(
              width: 1.5,
              color: Colors.grey.shade200,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 160, 122),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            v['code'].toString().toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                          ),
                        ),
                        InkWell(
                          onTap: () => _copyToClipboard(v['code'].toString().toUpperCase()),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.copy_rounded, color: Color.fromARGB(255, 255, 160, 122), size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(isSpecific ? Icons.star : Icons.public, size: 14, color: isSpecific ? Colors.orange : Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          isSpecific ? 'Exclusive Reward' : 'General Offer',
                          style: TextStyle(
                            color: isSpecific ? Colors.orange : Colors.black87,
                            fontSize: 12,
                            fontWeight: isSpecific ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                            v['min_spend'] > 0 ? 'Min. Spend: RM ${v['min_spend']}' : 'No Min. Spend',
                            style: const TextStyle(color: Colors.black87, fontSize: 13)
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Valid till: ${v['expiry_date']}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}