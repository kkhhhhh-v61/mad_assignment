import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_assignment/customer/checkout.dart';

void main() {
  group('CheckoutBottomBar', () {
    testWidgets('displays Proceed to Payment by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CheckoutBottomBar(
              total: 50.0,
              onPlaceOrder: () {},
            ),
          ),
        ),
      );

      expect(find.text('Proceed to Payment'), findsOneWidget);
    });

    testWidgets('displays Place Order when buttonText is Place Order', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CheckoutBottomBar(
              total: 50.0,
              buttonText: 'Place Order',
              onPlaceOrder: () {},
            ),
          ),
        ),
      );

      expect(find.text('Place Order'), findsOneWidget);
    });
  });

  group('CheckoutPayment', () {
    testWidgets('displays Cash on Delivery details correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutPayment(
              selectedPaymentMethod: 'Cash on Delivery',
              availablePaymentMethods: const [
                'Cash on Delivery',
                'Credit / Debit Card',
                'Online Banking',
              ],
              onPaymentMethodChanged: (_, _) {},
            ),
          ),
        ),
      );

      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Cash on Delivery'), findsOneWidget);
      expect(find.text('Pay with cash upon arrival'), findsOneWidget);
      expect(find.text('Stripe Sandbox'), findsNothing);
    });

    testWidgets('displays Credit / Debit Card with saved card details and Stripe Sandbox badge', (tester) async {
      final savedCard = {
        'id': 'card-1',
        'cardholder_name': 'John Doe',
        'card_number_masked': '**** **** **** 4242',
        'expiry_date': '12/28',
        'card_brand': 'Visa',
        'is_default': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutPayment(
              selectedPaymentMethod: 'Credit / Debit Card',
              availablePaymentMethods: const [
                'Cash on Delivery',
                'Credit / Debit Card',
                'Online Banking',
              ],
              selectedSavedCard: savedCard,
              savedCards: [savedCard],
              onPaymentMethodChanged: (_, _) {},
            ),
          ),
        ),
      );

      expect(find.text('Credit / Debit Card'), findsOneWidget);
      expect(find.text('Visa •••• 4242 (Exp: 12/28)'), findsOneWidget);
      expect(find.text('Stripe Sandbox'), findsOneWidget);
    });

    testWidgets('displays Online Banking details with Stripe Sandbox badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutPayment(
              selectedPaymentMethod: 'Online Banking',
              availablePaymentMethods: const [
                'Cash on Delivery',
                'Credit / Debit Card',
                'Online Banking',
              ],
              onPaymentMethodChanged: (_, _) {},
            ),
          ),
        ),
      );

      expect(find.text('Online Banking'), findsOneWidget);
      expect(find.text('FPX / Internet Banking (Stripe Sandbox)'), findsOneWidget);
      expect(find.text('Stripe Sandbox'), findsOneWidget);
    });
  });

  group('PaymentSelectionBottomSheet', () {
    testWidgets('shows all 3 payment methods and lists saved cards', (tester) async {
      final savedCards = [
        {
          'id': 'card-1',
          'cardholder_name': 'Alice Tan',
          'card_number_masked': '**** **** **** 1234',
          'expiry_date': '05/27',
          'card_brand': 'Mastercard',
          'is_default': true,
        },
      ];

      String? selectedMethod;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSelectionBottomSheet(
              availablePaymentMethods: const [
                'Cash on Delivery',
                'Credit / Debit Card',
                'Online Banking',
              ],
              selectedPaymentMethod: 'Credit / Debit Card',
              selectedSavedCard: savedCards.first,
              savedCards: savedCards,
              onPaymentMethodSelected: (method, card) {
                selectedMethod = method;
              },
              onAddNewCard: () {},
            ),
          ),
        ),
      );

      expect(find.text('Choose Payment Method'), findsOneWidget);
      expect(find.text('Cash on Delivery'), findsOneWidget);
      expect(find.text('Credit / Debit Card'), findsOneWidget);
      expect(find.text('Online Banking'), findsOneWidget);
      expect(find.text('Saved Cards'), findsOneWidget);
      expect(find.text('Mastercard **** **** **** 1234'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Alice Tan · Exp: 05/27'), findsOneWidget);

      // Tap Cash on Delivery
      await tester.tap(find.text('Cash on Delivery'));
      await tester.pumpAndSettle();

      expect(selectedMethod, 'Cash on Delivery');
    });
  });
}
