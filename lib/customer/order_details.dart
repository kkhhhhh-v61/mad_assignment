import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Order/order.dart';
import '../Order/order_repository.dart';
import 'cart.dart';
import 'customer_proof_photo_repository.dart';
import 'order_tracking.dart';
import 'reorder_service.dart';

Future<bool> cancelCustomerOrder({
  required BuildContext context,
  required Map<String, dynamic> order,
  OrderRepository? repository,
}) async {
  final typedOrder = order['typedOrder'];
  if (typedOrder is! Order || typedOrder.status != OrderStatus.placed) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Only newly placed orders can be cancelled.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA07A)),
          SizedBox(width: 8),
          Text('Cancel order?'),
        ],
      ),
      content: const Text(
        'This order has not been prepared yet. Do you want to cancel it?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFA07A),
          ),
          child: const Text('Cancel Order'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFA07A),
            foregroundColor: Colors.white,
          ),
          child: const Text('Keep Order'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  try {
    final orderRepository =
        repository ?? SupabaseOrderRepository(Supabase.instance.client);
    await orderRepository.transitionStatus(
      orderId: typedOrder.id,
      expectedStatus: OrderStatus.placed,
      nextStatus: OrderStatus.cancelled,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      final message = error is OrderRepositoryException
          ? error.message
          : 'The order could not be cancelled. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
    return false;
  }
}

class OrderDetails extends StatelessWidget {
  final Map<String, dynamic> order;
  final CustomerProofPhotoRepository? proofPhotoRepository;
  final OrderRepository? orderRepository;

  const OrderDetails({
    super.key,
    required this.order,
    this.proofPhotoRepository,
    this.orderRepository,
  });

  String get orderId => order['orderId'] as String;
  String get date => order['date'] as String;
  String get status => order['status'] as String;
  List<Map<String, Object>> get itemsList {
    final rawItems = order['items'];
    if (rawItems is! List) return const [];
    return rawItems
        .map((item) => Map<String, Object>.from(item as Map))
        .toList(growable: false);
  }

  double get subtotal => (order['subtotal'] as num).toDouble();
  double get deliveryFee => (order['deliveryFee'] as num).toDouble();
  double get discount => (order['discount'] as num).toDouble();
  String get totalPrice => order['totalPrice'] as String;
  String get info => order['info'] as String;
  IconData? get icon => order['icon'] as IconData?;
  String? get proofPhotoPath {
    final value = order['proofPhotoPath'] ?? order['proof_photo_path'];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    final typedOrder = order['typedOrder'];
    if (typedOrder is Order) return typedOrder.proofPhotoPath;
    return null;
  }

  String? get deliveryComments {
    final value = order['deliveryComments'] ?? order['delivery_comments'];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    final typedOrder = order['typedOrder'];
    if (typedOrder is Order) return typedOrder.deliveryComments;
    return null;
  }

  Order? get typedOrder {
    final value = order['typedOrder'];
    return value is Order ? value : null;
  }

  bool get canCancel => typedOrder?.status == OrderStatus.placed;

  Future<void> _handleReorder(BuildContext context) async {
    final sourceOrder = typedOrder;
    if (sourceOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This order cannot be reordered right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await CustomerReorderService.addOrderToCart(order: sourceOrder);
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerCart()),
      );
    } on ReorderException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The order could not be added to your cart.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors and Buttons Logic
    Color statusColor;
    IconData heroIcon;
    String buttonText;
    Color buttonColor;
    bool isOutlined;
    final showCancelAction = canCancel;

    switch (status) {
      case 'Preparing':
        statusColor = const Color.fromARGB(255, 255, 160, 122);
        heroIcon = Icons.outdoor_grill;
        buttonText = showCancelAction ? 'Cancel Order' : '';
        buttonColor = const Color.fromARGB(255, 229, 57, 53);
        isOutlined = showCancelAction;
        break;
      case 'Delivering':
        statusColor = const Color.fromARGB(255, 33, 150, 243);
        heroIcon = Icons.electric_moped;
        buttonText = 'Track Order';
        buttonColor = const Color.fromARGB(255, 255, 160, 122);
        isOutlined = false;
        break;
      case 'Cancelled':
        statusColor = const Color.fromARGB(255, 229, 57, 53);
        heroIcon = Icons.cancel_presentation;
        buttonText = 'Reorder';
        buttonColor = const Color.fromARGB(255, 255, 160, 122);
        isOutlined = true;
        break;
      case 'Completed':
      default:
        statusColor = const Color.fromARGB(255, 76, 175, 80);
        heroIcon = Icons.task_alt;
        buttonText = 'Reorder';
        buttonColor = const Color.fromARGB(255, 255, 160, 122);
        isOutlined = true;
        break;
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(221, 0, 0, 0),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          orderId,
          style: const TextStyle(
            color: Color.fromARGB(221, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20.0, bottom: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(heroIcon, size: 40, color: statusColor),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 24.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Placed on $date',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 158, 158, 158),
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20.0),
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromARGB(8, 0, 0, 0),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 243, 224),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color.fromARGB(255, 255, 160, 122),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delivery Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                    color: Color.fromARGB(221, 0, 0, 0),
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  info,
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Color.fromARGB(255, 117, 117, 117),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    OrderReceiptCard(
                      itemsList: itemsList,
                      subtotal: subtotal,
                      deliveryFee: deliveryFee,
                      discount: discount,
                      totalPrice: totalPrice,
                    ),
                    if (proofPhotoPath != null) ...[
                      const SizedBox(height: 20.0),
                      CustomerProofPhotoCard(
                        proofPhotoPath: proofPhotoPath!,
                        deliveryComments: deliveryComments,
                        repository: proofPhotoRepository,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (buttonText.isNotEmpty)
              Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(10, 0, 0, 0),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: isOutlined
                    ? OutlinedButton(
                        onPressed: () async {
                          if (buttonText == 'Cancel Order') {
                            final cancelled = await cancelCustomerOrder(
                              context: context,
                              order: order,
                              repository: orderRepository,
                            );
                            if (cancelled && context.mounted) {
                              Navigator.pop(context, true);
                            }
                          } else {
                            await _handleReorder(context);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: buttonColor,
                          side: BorderSide(color: buttonColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: buttonText == 'Track Order'
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderTracking(order: order),
                                  ),
                                );
                              }
                            : () {
                                //TODO: Handle Reorder API request or navigate to cart
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderReceiptCard extends StatelessWidget {
  final List<Map<String, Object>> itemsList;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final String totalPrice;

  const OrderReceiptCard({
    super.key,
    required this.itemsList,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(8, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Receipt',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
              color: Color.fromARGB(221, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 20.0),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemsList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16.0),
            itemBuilder: (context, index) {
              final item = itemsList[index];
              final String name = item['name'] as String;
              final int qty = item['quantity'] as int;
              final double price = (item['price'] as num).toDouble();
              final double itemTotal = price * qty;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 245, 245, 245),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Center(
                      child: Text(
                        '${qty}x',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                          color: Color.fromARGB(255, 117, 117, 117),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '@ RM ${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: Color.fromARGB(255, 158, 158, 158),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'RM ${itemTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.0,
                    ),
                  ),
                ],
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Divider(
              color: Color.fromARGB(255, 238, 238, 238),
              height: 1.0,
              thickness: 1.0,
            ),
          ),
          OrderReceiptRow(
            title: 'Subtotal',
            value: 'RM ${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12.0),
          OrderReceiptRow(
            title: 'Delivery Fee',
            value: 'RM ${deliveryFee.toStringAsFixed(2)}',
          ),
          if (discount > 0) ...[
            const SizedBox(height: 12.0),
            OrderReceiptRow(
              title: 'Voucher Discount',
              value: '-RM ${discount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Divider(
              color: Color.fromARGB(255, 238, 238, 238),
              height: 1.0,
              thickness: 1.0,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Color.fromARGB(221, 0, 0, 0),
                ),
              ),
              Text(
                totalPrice,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22.0,
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderReceiptRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isDiscount;

  const OrderReceiptRow({
    super.key,
    required this.title,
    required this.value,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.0,
            color: Color.fromARGB(255, 117, 117, 117),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.w600,
            color: isDiscount
                ? const Color.fromARGB(255, 76, 175, 80)
                : const Color.fromARGB(221, 0, 0, 0),
          ),
        ),
      ],
    );
  }
}

class CustomerProofPhotoCard extends StatefulWidget {
  final String proofPhotoPath;
  final String? deliveryComments;
  final CustomerProofPhotoRepository? repository;

  const CustomerProofPhotoCard({
    super.key,
    required this.proofPhotoPath,
    this.deliveryComments,
    this.repository,
  });

  @override
  State<CustomerProofPhotoCard> createState() => _CustomerProofPhotoCardState();
}

class _CustomerProofPhotoCardState extends State<CustomerProofPhotoCard> {
  String? _photoUrl;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPhoto());
  }

  Future<void> _loadPhoto() async {
    final repository = widget.repository ?? _defaultRepository();
    if (repository == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Proof photo access is not configured.';
      });
      return;
    }

    try {
      final signedUrl = await repository.createSignedUrl(widget.proofPhotoPath);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _photoUrl = signedUrl;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Proof photo could not be loaded.';
      });
    }
  }

  CustomerProofPhotoRepository? _defaultRepository() {
    try {
      return SupabaseCustomerProofPhotoRepository(Supabase.instance.client);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(8, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Proof',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
              color: Color.fromARGB(221, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            width: double.infinity,
            height: 180.0,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _photoUrl != null
                ? GestureDetector(
                    onTap: () => _showFullScreenPhoto(context, _photoUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _photoUrl!,
                            fit: BoxFit.cover,
                            semanticLabel: 'Delivery proof photo',
                            errorBuilder: (_, _, _) => _CustomerPhotoFallback(
                              message:
                                  _error ?? 'Proof photo could not be loaded.',
                            ),
                          ),
                          const Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 18.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _CustomerPhotoFallback(
                    message: _error ?? 'Proof photo is unavailable.',
                  ),
          ),
          if (widget.deliveryComments != null) ...[
            const SizedBox(height: 16.0),
            const Text(
              'Rider Comments',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
                color: Color.fromARGB(221, 0, 0, 0),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.deliveryComments!,
              style: const TextStyle(
                fontSize: 14.0,
                color: Color.fromARGB(255, 117, 117, 117),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullScreenPhoto(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      semanticLabel: 'Full-size delivery proof photo',
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    tooltip: 'Close full-screen photo',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CustomerPhotoFallback extends StatelessWidget {
  final String message;

  const _CustomerPhotoFallback({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfff5f5f5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xff9e9e9e), fontSize: 14.0),
        ),
      ),
    );
  }
}
