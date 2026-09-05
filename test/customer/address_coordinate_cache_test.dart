import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/customer/address_coordinate_cache.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists valid OSM coordinates by the saved address text', () async {
    await AddressCoordinateCache.save(
      address: 'No. 1, Jalan Test, 14000, Pulau Pinang',
      latitude: 5.3638,
      longitude: 100.4642,
    );

    final values = await AddressCoordinateCache.loadAll();
    expect(values['No. 1, Jalan Test, 14000, Pulau Pinang']?.latitude, 5.3638);
    expect(
      values['No. 1, Jalan Test, 14000, Pulau Pinang']?.longitude,
      100.4642,
    );
  });

  test('ignores invalid coordinates', () async {
    await AddressCoordinateCache.save(
      address: 'Invalid',
      latitude: 91,
      longitude: 100,
    );

    expect(await AddressCoordinateCache.loadAll(), isEmpty);
  });
}
