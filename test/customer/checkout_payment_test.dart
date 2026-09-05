import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_assignment/Order/branch_repository.dart';
import 'package:mad_assignment/Order/order.dart';
import 'package:mad_assignment/Order/order_repository.dart';
import 'package:mad_assignment/customer/cart.dart';
import 'package:mad_assignment/customer/checkout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeOrderRepository implements OrderRepository {
  OrderSubmission? lastSubmission;

  @override
  Future<Order> createOrder(OrderSubmission submission) async {
    lastSubmission = submission;
    return Order(
      id: 'order-123',
      orderNumber: submission.orderNumber,
      paymentIdempotencyKey: submission.paymentIdempotencyKey,
      customerId: 'customer-1',
      riderId: null,
      fulfilmentType: submission.fulfilmentType,
      status: OrderStatus.placed,
      branchSnapshot: submission.branchSnapshot,
      deliveryAddressSnapshot: submission.deliveryAddressSnapshot,
      subtotalSen: submission.subtotalSen,
      discountSen: submission.discountSen,
      deliveryFeeSen: submission.deliveryFeeSen,
      totalSen: submission.totalSen,
      items: submission.items,
      proofPhotoPath: null,
      deliveryComments: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      completedAt: null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
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

    testWidgets('displays Place Order when buttonText is Place Order', (
      tester,
    ) async {
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

    testWidgets(
      'tapping Place Order with Cash on Delivery calls onPlaceOrder and redirects to Order Confirmation',
      (tester) async {
        bool orderPlaced = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CheckoutBottomBar(
                total: 62.50,
                buttonText: 'Place Order',
                selectedPaymentMethod: 'Cash on Delivery',
                onPlaceOrder: () {
                  orderPlaced = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Place Order'));
        await tester.pumpAndSettle();

        expect(orderPlaced, isTrue);
        expect(find.text('Order Placed\nSuccessfully!'), findsOneWidget);
        expect(
          find.text('Total to pay upon receiving your order: RM 62.50'),
          findsOneWidget,
        );
      },
    );

  });

  group('CheckoutPayment', () {
    testWidgets('displays Cash on Delivery details with updated description', (
      tester,
    ) async {
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
      expect(find.text('Pay upon receiving your order.'), findsOneWidget);
      expect(find.text('Stripe Sandbox'), findsNothing);
    });

    testWidgets('displays Credit / Debit Card without Stripe Sandbox badge', (
      tester,
    ) async {
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
      expect(find.text('Stripe Sandbox'), findsNothing);
    });

    testWidgets(
      'displays Online Banking details without Stripe Sandbox badge',
      (tester) async {
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
        expect(find.text('FPX / Internet Banking'), findsOneWidget);
        expect(find.text('Stripe Sandbox'), findsNothing);
      },
    );
  });

  group('PaymentSelectionBottomSheet', () {
    testWidgets(
      'shows all 3 payment methods and lists saved cards without sandbox badges',
      (tester) async {
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
        expect(find.text('Stripe Sandbox'), findsNothing);
        expect(find.text('Confirm'), findsOneWidget);

        // Tap Cash on Delivery without confirming
        await tester.tap(find.text('Cash on Delivery'));
        await tester.pumpAndSettle();

        // Selection must not be committed yet
        expect(selectedMethod, isNull);

        // Tap Confirm button
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(selectedMethod, 'Cash on Delivery');
      },
    );

    testWidgets('tapping saved card selects it and only commits on Confirm', (
      tester,
    ) async {
      final savedCards = [
        {
          'id': 'card-1',
          'cardholder_name': 'Alice Tan',
          'card_number_masked': '**** **** **** 1234',
          'expiry_date': '05/27',
          'card_brand': 'Mastercard',
          'is_default': false,
        },
        {
          'id': 'card-2',
          'cardholder_name': 'Alice Tan',
          'card_number_masked': '**** **** **** 5678',
          'expiry_date': '08/29',
          'card_brand': 'Visa',
          'is_default': true,
        },
      ];

      String? selectedMethod;
      Map<String, dynamic>? selectedCard;

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
              selectedSavedCard: savedCards[1],
              savedCards: savedCards,
              onPaymentMethodSelected: (method, card) {
                selectedMethod = method;
                selectedCard = card;
              },
              onAddNewCard: () {},
            ),
          ),
        ),
      );

      // Select first card
      await tester.tap(find.text('Mastercard **** **** **** 1234'));
      await tester.pumpAndSettle();

      // Not committed yet
      expect(selectedCard, isNull);

      // Tap Confirm
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(selectedMethod, 'Credit / Debit Card');
      expect(selectedCard?['id'], 'card-1');
    });
  });

  group('AddressSelection', () {
    testWidgets('displays address title label and full address', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressSelection(
              address: '123 Jalan Ampang, Kuala Lumpur',
              addressLabel: 'Home',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Delivery Address'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('123 Jalan Ampang, Kuala Lumpur'), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets(
      'displays Current Location icon when label is Current Location',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AddressSelection(
                address: 'George Town, Penang',
                addressLabel: 'Current Location',
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Current Location'), findsOneWidget);
        expect(find.text('George Town, Penang'), findsOneWidget);
        expect(find.byIcon(Icons.my_location), findsOneWidget);
      },
    );
  });

  group('CustomerCheckout Place Order', () {
    testWidgets('blocks delivery until branch and road fee are ready', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerCheckout(
            cartItems: [
              CartItem(
                id: 'item-1',
                name: 'Nasi Lemak',
                price: 15.0,
                quantity: 1,
              ),
            ],
            deliveryAddress: '123 Jalan Ampang, Kuala Lumpur',
            enableBranchSelection: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Place Order'), findsOneWidget);
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();

      expect(find.text('Order Placed\nSuccessfully!'), findsNothing);
    });

    testWidgets(
      'order confirmation displays the full price paid tallying with checkout total',
      (tester) async {
        final fakeRepo = FakeOrderRepository();
        const branch = BranchSnapshot(
          branchId: 'b-1',
          name: 'Main Branch',
          stateCode: 'PNG',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CustomerCheckout(
              cartItems: [
                CartItem(
                  id: 'item-1',
                  name: 'Burger',
                  price: 20.0,
                  quantity: 2,
                ),
              ],
              branchSnapshot: branch,
              orderRepository: fakeRepo,
              enableBranchSelection: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Self Pickup so no geocoding is needed
        await tester.tap(find.text('Self Pickup'));
        await tester.pumpAndSettle();

        // Subtotal = 40.0, SST (6%) = 2.40, Total = 42.40
        expect(find.text('Place Order'), findsOneWidget);
        await tester.tap(find.text('Place Order'));
        await tester.pumpAndSettle();

        expect(find.text('Order Placed\nSuccessfully!'), findsOneWidget);
        expect(
          find.text('Total to pay upon receiving your order: RM 42.40'),
          findsOneWidget,
        );
      },
    );
  });

  group('Checkout branch selection', () {
    test(
      'nearest active branch is selected when coordinates are available',
      () {
        const branches = [
          BranchRecord(
            id: 'near',
            branchCode: 'DD-NEAR',
            name: 'DoorDish Near',
            stateId: 14,
            stateCode: 'WPKL',
            address: 'Kuala Lumpur',
            latitude: 3.140,
            longitude: 101.690,
            isActive: true,
          ),
          BranchRecord(
            id: 'far',
            branchCode: 'DD-FAR',
            name: 'DoorDish Far',
            stateId: 14,
            stateCode: 'WPKL',
            address: 'Kuala Lumpur',
            latitude: 3.220,
            longitude: 101.750,
            isActive: true,
          ),
        ];

        final selected = nearestActiveBranchForCoordinates(
          latitude: 3.141,
          longitude: 101.691,
          branches: branches,
        );

        expect(selected?.id, 'near');
      },
    );

    test(
      'nearest branch returns null when address coordinates are missing',
      () {
        const branch = BranchRecord(
          id: 'branch',
          branchCode: 'DD-1',
          name: 'DoorDish',
          stateId: 14,
          stateCode: 'WPKL',
          address: 'Kuala Lumpur',
          latitude: 3.140,
          longitude: 101.690,
          isActive: true,
        );

        expect(
          nearestActiveBranchForCoordinates(
            latitude: null,
            longitude: null,
            branches: const [branch],
          ),
          isNull,
        );
      },
    );
  });
}
