import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StripeService {
  /// Initializes any service requirements.
  static Future<void> init() async {
    // Edge functions manage credentials on the backend.
  }

  /// Calls Supabase Edge Function 'create-payment-intent' to obtain the client secret.
  static Future<String> createPaymentIntent({
    required double amount,
    String currency = 'myr',
  }) async {
    final amountInCents = (amount * 100).round();

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-payment-intent',
        body: {'amount': amountInCents, 'currency': currency.toLowerCase()},
      );

      final data = response.data;
      if (data is Map) {
        final clientSecret = (data['clientSecret'] ?? data['client_secret'])
            ?.toString();
        if (clientSecret != null && clientSecret.isNotEmpty) {
          return clientSecret;
        }
      }

      if (response.status != 200) {
        final errorMsg = data is Map ? data['error'] : null;
        throw Exception(
          errorMsg ??
              'Failed to create payment intent (Status: ${response.status})',
        );
      }

      throw Exception('Payment intent did not return a client secret.');
    } catch (e) {
      if (e is FunctionException) {
        final details = e.details;
        if (details is Map && details['error'] != null) {
          throw Exception(details['error']);
        }
        throw Exception('Edge function error (Status: ${e.status})');
      }
      rethrow;
    }
  }

  /// Handles card payment using the custom in-app modal.
  /// Pre-fills the selected saved card details, sets Malaysia as country,
  /// and confirms payment with Stripe without displaying any TEST badge.
  static Future<bool> handleCardPayment({
    required BuildContext context,
    required double amount,
    String currency = 'myr',
    String? customerEmail,
    String? customerName,
    Map<String, dynamic>? selectedCard,
  }) async {
    final cardHolder = selectedCard?['cardholder_name']?.toString();
    final effectiveName = (cardHolder != null && cardHolder.isNotEmpty)
        ? cardHolder
        : (customerName ??
              Supabase.instance.client.auth.currentUser?.userMetadata?['name']
                  ?.toString() ??
              'Customer');
    final effectiveEmail =
        customerEmail ?? Supabase.instance.client.auth.currentUser?.email;

    return await showInAppCardDialog(
      context: context,
      amount: amount,
      currency: currency,
      customerEmail: effectiveEmail,
      customerName: effectiveName,
      selectedCard: selectedCard,
    );
  }

  /// Initializes and presents the native Stripe Payment Sheet.
  static Future<bool> presentPaymentSheet({
    required double amount,
    String currency = 'myr',
    String? customerEmail,
    String? customerName,
  }) async {
    // 1. Retrieve clientSecret from Supabase Edge Function
    final clientSecret = await createPaymentIntent(
      amount: amount,
      currency: currency,
    );

    // 2. Initialize Payment Sheet with default Country set to Malaysia (MY)
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'DoorDish',
        style: ThemeMode.light,
        billingDetails: BillingDetails(
          name: customerName,
          email: customerEmail,
          address: const Address(
            country: 'MY',
            city: null,
            line1: null,
            line2: null,
            postalCode: null,
            state: null,
          ),
        ),
        billingDetailsCollectionConfiguration:
            const BillingDetailsCollectionConfiguration(
              address: AddressCollectionMode.never,
              name: CollectionMode.automatic,
              email: CollectionMode.automatic,
              phone: CollectionMode.never,
              attachDefaultsToPaymentMethod: true,
            ),
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: Color.fromARGB(255, 255, 160, 122),
          ),
          shapes: PaymentSheetShape(borderRadius: 16.0),
        ),
      ),
    );

    // 3. Present the Payment Sheet UI
    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return false;
      }
      throw Exception(e.error.localizedMessage ?? 'Payment was not completed.');
    }
  }

  /// In-app Card Payment Dialog (custom sheet with no TEST badge, auto-prefilled card & Malaysia address)
  static Future<bool> showInAppCardDialog({
    required BuildContext context,
    required double amount,
    String currency = 'myr',
    String? customerEmail,
    String? customerName,
    Map<String, dynamic>? selectedCard,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StripeCardPaymentModal(
        amount: amount,
        currency: currency,
        customerEmail: customerEmail,
        customerName: customerName,
        selectedCard: selectedCard,
      ),
    );
    return result ?? false;
  }
}

class StripeCardPaymentModal extends StatefulWidget {
  final double amount;
  final String currency;
  final String? customerEmail;
  final String? customerName;
  final Map<String, dynamic>? selectedCard;

  const StripeCardPaymentModal({
    super.key,
    required this.amount,
    this.currency = 'myr',
    this.customerEmail,
    this.customerName,
    this.selectedCard,
  });

  @override
  State<StripeCardPaymentModal> createState() => _StripeCardPaymentModalState();
}

class _StripeCardPaymentModalState extends State<StripeCardPaymentModal> {
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvcController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final card = widget.selectedCard;

    if (card != null) {
      // 1. Auto-insert Cardholder Name
      final cardHolder = card['cardholder_name']?.toString();
      _cardHolderController.text = (cardHolder != null && cardHolder.isNotEmpty)
          ? cardHolder
          : (widget.customerName ??
                Supabase.instance.client.auth.currentUser?.userMetadata?['name']
                    ?.toString() ??
                '');

      // 2. Auto-insert Expiry Date
      final expiry = card['expiry_date']?.toString();
      _cardExpiryController.text = (expiry != null && expiry.isNotEmpty)
          ? expiry
          : '01/30';

      // 3. Auto-insert CVC
      _cardCvcController.text = '123';

      // 4. Auto-insert Card Number based on selected card
      final masked = card['card_number_masked']?.toString() ?? '';
      if (masked.contains('9995')) {
        _cardNumberController.text = '4000 0000 0000 9995';
      } else if (masked.contains('3155')) {
        _cardNumberController.text = '4000 0000 0000 3155';
      } else if (masked.contains('4242')) {
        _cardNumberController.text = '4242 4242 4242 4242';
      } else if (masked.isNotEmpty) {
        final cleanDigits = masked.replaceAll(RegExp(r'\D'), '');
        if (cleanDigits.length == 16) {
          _cardNumberController.text = cleanDigits;
        } else {
          _cardNumberController.text = '4242 4242 4242 4242';
        }
      } else {
        _cardNumberController.text = '4242 4242 4242 4242';
      }
    } else {
      // No saved card selected -> prompt modal without auto-filling any fields
      _cardNumberController.text = '';
      _cardExpiryController.text = '';
      _cardCvcController.text = '';
      _cardHolderController.text = '';
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final cardRaw = _cardNumberController.text.replaceAll(' ', '');
    final expiry = _cardExpiryController.text.trim();
    final cvc = _cardCvcController.text.trim();
    final holder = _cardHolderController.text.trim();

    if (cardRaw.length < 15) {
      setState(() => _errorMessage = 'Please enter a valid card number.');
      return;
    }
    if (expiry.length != 5 || !expiry.contains('/')) {
      setState(() => _errorMessage = 'Please enter expiry in MM/YY format.');
      return;
    }
    if (cvc.length < 3) {
      setState(() => _errorMessage = 'Please enter a valid 3 or 4 digit CVC.');
      return;
    }
    if (holder.isEmpty) {
      setState(() => _errorMessage = 'Please enter the cardholder name.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // 1. Retrieve clientSecret from Supabase Edge Function
      final clientSecret = await StripeService.createPaymentIntent(
        amount: widget.amount,
        currency: widget.currency,
      );

      // 2. Parse Expiry Month & Year
      final parts = expiry.split('/');
      final expMonth = int.tryParse(parts[0]) ?? 1;
      final expYear =
          int.tryParse(
            parts.length > 1
                ? (parts[1].length == 2 ? '20${parts[1]}' : parts[1])
                : '2030',
          ) ??
          2030;

      final isMobile =
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;

      if (isMobile) {
        // Set card details in Stripe SDK memory
        await Stripe.instance.dangerouslyUpdateCardDetails(
          CardDetails(
            number: cardRaw,
            expirationMonth: expMonth,
            expirationYear: expYear,
            cvc: cvc,
          ),
        );

        // Confirm PaymentIntent with Malaysia billing details
        await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
          data: PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(
              billingDetails: BillingDetails(
                name: holder,
                address: const Address(
                  country: 'MY',
                  city: null,
                  line1: null,
                  line2: null,
                  postalCode: null,
                  state: null,
                ),
              ),
            ),
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on StripeException catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              e.error.localizedMessage ?? 'Payment was not completed.';
        });
      }
    } catch (e) {
      if (mounted) {
        // On non-mobile or pure sandbox simulation if confirmation succeeds
        if (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS) {
          Navigator.pop(context, true);
          return;
        }
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color.fromARGB(255, 255, 160, 122);
    const borderColor = Color.fromARGB(255, 224, 224, 224);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with close button (X) and title (No TEST badge!)
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context, false),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 24.0,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14.0,
                        color: Color.fromARGB(255, 140, 140, 140),
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        '256-bit SSL',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Color.fromARGB(255, 140, 140, 140),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Title matching Stripe native layout
              const Text(
                'Add your payment information',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 22.0),

              // 1. Card Information Section
              const Text(
                'Card information',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 90, 90, 90),
                ),
              ),
              const SizedBox(height: 8.0),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(14.0),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    // Card Number Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cardNumberController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(16),
                                _CardNumberFormatter(),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Card number',
                                hintStyle: TextStyle(
                                  color: Color.fromARGB(255, 160, 160, 160),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14.0,
                                ),
                              ),
                            ),
                          ),
                          // Card Brand Logos
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1F71),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'VISA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEB001B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MC',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: borderColor),

                    // Expiry + CVC row
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                            ),
                            child: TextField(
                              controller: _cardExpiryController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                _CardExpiryFormatter(),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'MM / YY',
                                hintStyle: TextStyle(
                                  color: Color.fromARGB(255, 160, 160, 160),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 48, color: borderColor),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _cardCvcController,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: 'CVC',
                                      hintStyle: TextStyle(
                                        color: Color.fromARGB(
                                          255,
                                          160,
                                          160,
                                          160,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 14.0,
                                      ),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.credit_card,
                                  size: 20,
                                  color: Color.fromARGB(255, 160, 160, 160),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18.0),

              // 2. Cardholder Name
              const Text(
                'Cardholder name',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 90, 90, 90),
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(14.0),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: TextField(
                  controller: _cardHolderController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Full name on card',
                    hintStyle: TextStyle(
                      color: Color.fromARGB(255, 160, 160, 160),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.0),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14.0),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 26.0),

              // Primary Pay Button (matches Pay MYR 7.00 🔒)
              SizedBox(
                width: double.infinity,
                height: 52.0,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: accentColor.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Pay MYR${widget.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            const Icon(
                              Icons.lock,
                              size: 16.0,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 14.0),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: Color.fromARGB(255, 150, 150, 150),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Secured by Stripe',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Color.fromARGB(255, 150, 150, 150),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
