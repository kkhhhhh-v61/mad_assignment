import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mad_assignment/rider/data_gov_my_fuel_price_repository.dart';
import 'package:mad_assignment/rider/fuel_price_snapshot.dart';

class StubHttpClient extends http.BaseClient {
  final http.Response Function(Uri uri) responseFactory;
  bool called = false;

  StubHttpClient(this.responseFactory);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    called = true;
    final response = responseFactory(request.url);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

Future<SharedPreferences> _preferencesWithCache(
  FuelPriceSnapshot snapshot,
) async {
  SharedPreferences.setMockInitialValues({
    DataGovMyFuelPriceRepository.cacheKey: jsonEncode(snapshot.toJson()),
  });
  return SharedPreferences.getInstance();
}

void main() {
  final now = DateTime.utc(2026, 9, 1, 12);

  test('parses the general-market level record and query parameters', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final client = StubHttpClient((uri) {
      expect(uri.queryParameters['id'], 'fuelprice');
      expect(uri.queryParameters['filter'], 'level@series_type');
      expect(uri.queryParameters['limit'], '1');
      return http.Response(
        jsonEncode([
          {'date': '2026-08-31', 'ron95': 2.05, 'series_type': 'level'},
        ]),
        200,
      );
    });
    final repository = DataGovMyFuelPriceRepository(
      preferences: preferences,
      client: client,
      now: () => now,
    );

    final result = await repository.getLatest();

    expect(result.ron95RinggitPerLitre, 2.05);
    expect(result.effectiveDate, DateTime.utc(2026, 8, 31));
    expect(result.sourceUrl, DataGovMyFuelPriceRepository.catalogueUrl);
    expect(result.isFromCache, isFalse);
    expect(client.called, isTrue);
    repository.dispose();
  });

  test('ignores non-level records and reports unavailable data', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = DataGovMyFuelPriceRepository(
      preferences: preferences,
      client: StubHttpClient(
        (_) => http.Response(
          jsonEncode([
            {'date': '2026-08-31', 'ron95': 2.05, 'series_type': 'state'},
          ]),
          200,
        ),
      ),
      now: () => now,
    );

    expect(
      repository.getLatest(),
      throwsA(isA<FuelDataUnavailableException>()),
    );
    repository.dispose();
  });

  test('returns a fresh cached snapshot without an API call', () async {
    final cached = FuelPriceSnapshot(
      ron95RinggitPerLitre: 2.05,
      effectiveDate: DateTime.utc(2026, 8, 31),
      fetchedAt: now.subtract(const Duration(hours: 2)),
      sourceUrl: DataGovMyFuelPriceRepository.catalogueUrl,
      isFromCache: false,
    );
    final preferences = await _preferencesWithCache(cached);
    final client = StubHttpClient(
      (_) => throw StateError('fresh cache should prevent a request'),
    );
    final repository = DataGovMyFuelPriceRepository(
      preferences: preferences,
      client: client,
      now: () => now,
    );

    final result = await repository.getLatest();
    final secondResult = await repository.getLatest();

    expect(result.isFromCache, isTrue);
    expect(secondResult.isFromCache, isTrue);
    expect(result.ron95RinggitPerLitre, 2.05);
    expect(client.called, isFalse);
    repository.dispose();
  });

  test('falls back to a stale cache when refresh fails', () async {
    final cached = FuelPriceSnapshot(
      ron95RinggitPerLitre: 2.05,
      effectiveDate: DateTime.utc(2026, 8, 1),
      fetchedAt: now.subtract(const Duration(days: 3)),
      sourceUrl: DataGovMyFuelPriceRepository.catalogueUrl,
      isFromCache: false,
    );
    final preferences = await _preferencesWithCache(cached);
    final repository = DataGovMyFuelPriceRepository(
      preferences: preferences,
      client: StubHttpClient((_) => http.Response('upstream failure', 503)),
      now: () => now,
    );

    final result = await repository.getLatest(forceRefresh: true);

    expect(result.isFromCache, isTrue);
    expect(result.effectiveDate, DateTime.utc(2026, 8, 1));
    repository.dispose();
  });

  test('returns a typed failure for HTTP 429 with no cache', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = DataGovMyFuelPriceRepository(
      preferences: preferences,
      client: StubHttpClient((_) => http.Response('rate limited', 429)),
      now: () => now,
    );

    expect(
      repository.getLatest(),
      throwsA(
        predicate<FuelDataUnavailableException>(
          (error) => error.message.contains('rate limit'),
        ),
      ),
    );
    repository.dispose();
  });
}
