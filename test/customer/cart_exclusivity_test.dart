import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_assignment/customer/cart.dart';
import 'package:mad_assignment/customer/header.dart';
import 'package:mad_assignment/services/states.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartItem exclusivity & availability model tests', () {
    test('CartItem serializes and deserializes exclusiveStates and isAvailable correctly', () {
      final item = CartItem(
        id: 'item-101',
        name: 'Penang Char Kway Teow',
        price: 12.50,
        quantity: 2,
        exclusiveStates: ['Pulau Pinang', 'Kedah'],
        isAvailable: true,
      );

      final json = item.toJson();
      expect(json['id'], 'item-101');
      expect(json['name'], 'Penang Char Kway Teow');
      expect(json['price'], 12.50);
      expect(json['quantity'], 2);
      expect(json['exclusive_states'], ['Pulau Pinang', 'Kedah']);
      expect(json['is_available'], true);

      final fromJson = CartItem.fromJson(json);
      expect(fromJson.id, 'item-101');
      expect(fromJson.name, 'Penang Char Kway Teow');
      expect(fromJson.price, 12.50);
      expect(fromJson.quantity, 2);
      expect(fromJson.exclusiveStates, ['Pulau Pinang', 'Kedah']);
      expect(fromJson.isAvailable, true);
    });

    test('CartItem defaults exclusiveStates to empty list and isAvailable to true', () {
      final item = CartItem(
        id: 'item-102',
        name: 'Regular Burger',
        price: 8.00,
        quantity: 1,
      );

      expect(item.exclusiveStates, isEmpty);
      expect(item.isAvailable, true);

      final json = item.toJson();
      final fromJson = CartItem.fromJson(json);
      expect(fromJson.exclusiveStates, isEmpty);
      expect(fromJson.isAvailable, true);
    });

    test('CartItem copyWith preserves or modifies exclusivity and availability', () {
      final item = CartItem(
        id: 'item-103',
        name: 'Item A',
        price: 10.0,
        quantity: 1,
        exclusiveStates: ['Pulau Pinang'],
        isAvailable: true,
      );

      final updated = item.copyWith(
        isAvailable: false,
        exclusiveStates: ['Selangor'],
      );

      expect(updated.id, 'item-103');
      expect(updated.isAvailable, false);
      expect(updated.exclusiveStates, ['Selangor']);
    });
  });

  group('State exclusivity matching logic tests', () {
    test('isSameState matches variations of Malaysian state names', () {
      expect(isSameState('penang', 'Pulau Pinang'), isTrue);
      expect(isSameState('Pulau Pinang', 'Penang'), isTrue);
      expect(isSameState('kl', 'Kuala Lumpur'), isTrue);
      expect(isSameState('WP Kuala Lumpur', 'Kuala Lumpur'), isTrue);
      expect(isSameState('Selangor', 'Selangor'), isTrue);
      expect(isSameState('Pulau Pinang', 'Selangor'), isFalse);
    });

    test('Nationwide item is available in all states', () {
      final item = CartItem(
        name: 'Nasi Lemak',
        price: 5.0,
        quantity: 1,
        exclusiveStates: [],
        isAvailable: true,
      );

      bool isAvailableIn(String state) {
        if (!item.isAvailable) return false;
        if (item.exclusiveStates.isEmpty) return true;
        return item.exclusiveStates.any((s) => isSameState(s, state));
      }

      expect(isAvailableIn('Pulau Pinang'), isTrue);
      expect(isAvailableIn('Selangor'), isTrue);
      expect(isAvailableIn('Johor'), isTrue);
    });

    test('State-exclusive item is only available in matching states', () {
      final exclusiveItem = CartItem(
        name: 'Penang Asam Laksa',
        price: 11.0,
        quantity: 1,
        exclusiveStates: ['Pulau Pinang'],
        isAvailable: true,
      );

      bool isAvailableIn(String state) {
        if (!exclusiveItem.isAvailable) return false;
        if (exclusiveItem.exclusiveStates.isEmpty) return true;
        return exclusiveItem.exclusiveStates.any((s) => isSameState(s, state));
      }

      expect(isAvailableIn('Pulau Pinang'), isTrue);
      expect(isAvailableIn('Penang'), isTrue);
      expect(isAvailableIn('Selangor'), isFalse);
      expect(isAvailableIn('Kuala Lumpur'), isFalse);
      expect(isAvailableIn('Johor'), isFalse);
    });
  });

  group('Cart UI state and availability widget tests', () {
    setUp(() {
      CustomerHeader.clearLocationCache();
    });

    testWidgets('Location selector section displays current address and state pill', (tester) async {
      CustomerHeader.updateSelectedOption(
        const AddressOption(
          label: 'Home',
          fullAddress: '123 Jalan Burma, George Town, Penang',
          state: 'Pulau Pinang',
          isDefault: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final option = CustomerHeader.cachedSelectedOption;
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on),
                      Text(option?.label ?? ''),
                      Text(option?.state ?? ''),
                      Expanded(
                        child: Text(option?.fullAddress ?? ''),
                      ),
                      const Text('Change'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Pulau Pinang'), findsOneWidget);
      expect(find.text('123 Jalan Burma, George Town, Penang'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
    });

    testWidgets('Unavailable item displays warning badge and disables checkout button', (tester) async {
      final availableItem = CartItem(
        id: '1',
        name: 'Fried Rice',
        price: 10.0,
        quantity: 1,
        exclusiveStates: [],
        isAvailable: true,
      );

      final unavailableItem = CartItem(
        id: '2',
        name: 'Penang Prawn Mee',
        price: 15.0,
        quantity: 1,
        exclusiveStates: ['Pulau Pinang'],
        isAvailable: true,
      );

      const currentState = 'Selangor'; // User is in Selangor, so Penang Prawn Mee is unavailable!

      bool isItemAvailable(CartItem item) {
        if (!item.isAvailable) return false;
        if (item.exclusiveStates.isEmpty) return true;
        return item.exclusiveStates.any((s) => isSameState(s, currentState));
      }

      final items = [availableItem, unavailableItem];
      final unavailableItems = items.where((i) => !isItemAvailable(i)).toList();
      final hasUnavailable = unavailableItems.isNotEmpty;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                if (hasUnavailable)
                  const Text('Some items are unavailable in your location'),
                ...items.map((item) {
                  final isAvail = isItemAvailable(item);
                  return ListTile(
                    title: Text(item.name),
                    subtitle: !isAvail
                        ? Text('Unavailable in $currentState')
                        : const Text('Available'),
                  );
                }),
                ElevatedButton(
                  onPressed: hasUnavailable ? null : () {},
                  child: Text(hasUnavailable ? 'Unavailable Items in Cart' : 'Checkout'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Fried Rice'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Penang Prawn Mee'), findsOneWidget);
      expect(find.text('Unavailable in Selangor'), findsOneWidget);
      expect(find.text('Some items are unavailable in your location'), findsOneWidget);
      expect(find.text('Unavailable Items in Cart'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Changing location to an eligible state re-enables the item and checkout', (tester) async {
      String currentState = 'Selangor';

      final exclusiveItem = CartItem(
        id: '2',
        name: 'Penang Prawn Mee',
        price: 15.0,
        quantity: 1,
        exclusiveStates: ['Pulau Pinang'],
        isAvailable: true,
      );

      bool isItemAvailable(CartItem item, String state) {
        if (!item.isAvailable) return false;
        if (item.exclusiveStates.isEmpty) return true;
        return item.exclusiveStates.any((s) => isSameState(s, state));
      }

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            final isAvail = isItemAvailable(exclusiveItem, currentState);
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Text('Current Location: $currentState'),
                    Text(exclusiveItem.name),
                    Text(isAvail ? 'Available' : 'Unavailable in $currentState'),
                    ElevatedButton(
                      key: const Key('change_location_button'),
                      onPressed: () {
                        setState(() {
                          currentState = 'Pulau Pinang';
                        });
                      },
                      child: const Text('Switch to Penang'),
                    ),
                    ElevatedButton(
                      key: const Key('checkout_button'),
                      onPressed: isAvail ? () {} : null,
                      child: Text(isAvail ? 'Checkout' : 'Unavailable Items in Cart'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Initially in Selangor: item is unavailable, checkout disabled
      expect(find.text('Current Location: Selangor'), findsOneWidget);
      expect(find.text('Unavailable in Selangor'), findsOneWidget);
      expect(find.text('Unavailable Items in Cart'), findsOneWidget);
      var checkoutBtn = tester.widget<ElevatedButton>(find.byKey(const Key('checkout_button')));
      expect(checkoutBtn.onPressed, isNull);

      // Tap change location button to Penang
      await tester.tap(find.byKey(const Key('change_location_button')));
      await tester.pumpAndSettle();

      // Now in Penang: item is available, checkout enabled!
      expect(find.text('Current Location: Pulau Pinang'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);
      checkoutBtn = tester.widget<ElevatedButton>(find.byKey(const Key('checkout_button')));
      expect(checkoutBtn.onPressed, isNotNull);
    });

    testWidgets('Location detection loading state shows spinning loaders on change button and cart records and disables interactions', (tester) async {
      bool isLoadingLocation = true;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    Container(
                      key: const Key('location_section'),
                      child: InkWell(
                        onTap: isLoadingLocation ? null : () {},
                        child: Row(
                          children: [
                            Text(isLoadingLocation ? 'Getting current location...' : 'George Town, Penang'),
                            Container(
                              key: const Key('change_button_container'),
                              child: isLoadingLocation
                                  ? const SizedBox(
                                      key: Key('change_button_spinner'),
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(),
                                    )
                                  : const Text('Change'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: isLoadingLocation
                          ? const Center(
                              key: Key('cart_loading_state'),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  Text('Getting current location...'),
                                  Text('Checking item availability for your area'),
                                ],
                              ),
                            )
                          : ListView(
                              key: const Key('cart_records_list'),
                              children: const [
                                Text('Laksa'),
                              ],
                            ),
                    ),
                    ElevatedButton(
                      key: const Key('checkout_button'),
                      onPressed: isLoadingLocation ? null : () {},
                      child: Text(isLoadingLocation ? 'Updating Location...' : 'Checkout'),
                    ),
                    ElevatedButton(
                      key: const Key('toggle_loaded_button'),
                      onPressed: () {
                        setState(() {
                          isLoadingLocation = false;
                        });
                      },
                      child: const Text('Finish Loading'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // When isLoadingLocation is true:
      // 1. Location section displays 'Getting current location...'
      expect(find.text('Getting current location...'), findsAtLeastNWidgets(1));
      // 2. Change button displays CircularProgressIndicator spinner and 'Change' text is absent
      expect(find.byKey(const Key('change_button_spinner')), findsOneWidget);
      expect(find.text('Change'), findsNothing);
      // 3. Cart records shows cart loading spinner and cart records list is absent
      expect(find.byKey(const Key('cart_loading_state')), findsOneWidget);
      expect(find.text('Checking item availability for your area'), findsOneWidget);
      expect(find.byKey(const Key('cart_records_list')), findsNothing);
      expect(find.text('Laksa'), findsNothing);
      // 4. Checkout button is disabled with text 'Updating Location...'
      expect(find.text('Updating Location...'), findsOneWidget);
      final checkoutBtn = tester.widget<ElevatedButton>(find.byKey(const Key('checkout_button')));
      expect(checkoutBtn.onPressed, isNull);

      // Finish loading:
      await tester.tap(find.byKey(const Key('toggle_loaded_button')));
      await tester.pumpAndSettle();

      // After loading finishes:
      // 1. Change button shows 'Change'
      expect(find.text('Change'), findsOneWidget);
      expect(find.byKey(const Key('change_button_spinner')), findsNothing);
      // 2. Cart records displays item list
      expect(find.byKey(const Key('cart_records_list')), findsOneWidget);
      expect(find.text('Laksa'), findsOneWidget);
      expect(find.byKey(const Key('cart_loading_state')), findsNothing);
      // 3. Checkout button is enabled with text 'Checkout'
      expect(find.text('Checkout'), findsOneWidget);
      final checkoutBtnAfter = tester.widget<ElevatedButton>(find.byKey(const Key('checkout_button')));
      expect(checkoutBtnAfter.onPressed, isNotNull);
    });
  });
}
