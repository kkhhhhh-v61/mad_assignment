import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'fuel_price_repository.dart';
import 'fuel_price_snapshot.dart';

class DataGovMyFuelPriceRepository implements FuelPriceRepository {
  static const catalogueUrl = 'https://data.gov.my/data-catalogue/fuelprice';
  static const apiUrl = 'https://api.data.gov.my/data-catalogue';
  static const cacheKey = 'rider.fuel_price_snapshot.v1';
  static const cacheMaxAge = Duration(hours: 24);

  final SharedPreferences preferences;
  final http.Client httpClient;
  final DateTime Function() now;
  final bool _ownsHttpClient;
  Future<FuelPriceSnapshot>? _inFlight;
  FuelPriceSnapshot? _memory;

  DataGovMyFuelPriceRepository({
    required this.preferences,
    http.Client? client,
    DateTime Function()? now,
  }) : httpClient = client ?? http.Client(),
       now = now ?? DateTime.now,
       _ownsHttpClient = client == null;

  @override
  Future<FuelPriceSnapshot> getLatest({bool forceRefresh = false}) {
    if (!forceRefresh) {
      final memory = _memory;
      if (memory != null && memory.isFresh(now: now())) {
        return Future.value(memory);
      }
    }
    final running = _inFlight;
    if (running != null) {
      return running;
    }
    final request = _loadLatest(forceRefresh: forceRefresh);
    _inFlight = request;
    return request.whenComplete(() => _inFlight = null);
  }

  Future<FuelPriceSnapshot> _loadLatest({required bool forceRefresh}) async {
    FuelPriceSnapshot? cached;
    try {
      cached = _readCache();
      if (!forceRefresh && cached != null && cached.isFresh(now: now())) {
        _memory = cached.copyWith(isFromCache: true);
        return _memory!;
      }
    } catch (_) {
      cached = null;
    }

    try {
      final snapshot = await _fetchFromApi();
      _memory = snapshot;
      await preferences.setString(cacheKey, jsonEncode(snapshot.toJson()));
      return snapshot;
    } catch (error) {
      if (cached != null) {
        _memory = cached.copyWith(isFromCache: true);
        return _memory!;
      }
      if (error is FuelDataUnavailableException) {
        rethrow;
      }
      throw FuelDataUnavailableException('Live fuel data is unavailable.');
    }
  }

  Future<FuelPriceSnapshot> _fetchFromApi() async {
    final uri = Uri.parse(apiUrl).replace(
      queryParameters: const {
        'id': 'fuelprice',
        'filter': 'level@series_type',
        'sort': '-date',
        'limit': '1',
        'include': 'date,ron95,series_type',
      },
    );
    http.Response response;
    try {
      response = await httpClient
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const FuelDataUnavailableException('Fuel data request timed out.');
    } catch (_) {
      throw const FuelDataUnavailableException('Fuel data request failed.');
    }
    if (response.statusCode == 429) {
      throw const FuelDataUnavailableException('Fuel data rate limit reached.');
    }
    if (response.statusCode != 200) {
      throw FuelDataUnavailableException(
        'Fuel data returned HTTP ${response.statusCode}.',
      );
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FuelDataUnavailableException(
        'Fuel data response was invalid.',
      );
    }
    final records = _records(decoded);
    final record = records.cast<Map<String, dynamic>>().firstWhere(
      (item) => item['series_type']?.toString() == 'level',
      orElse: () => <String, dynamic>{},
    );
    if (record.isEmpty) {
      throw const FuelDataUnavailableException(
        'No general-market RON95 record was found.',
      );
    }
    final date = _parseApiDate(record['date']);
    final price = double.tryParse('${record['ron95']}');
    if (date == null || price == null || !price.isFinite || price <= 0) {
      throw const FuelDataUnavailableException('RON95 data was malformed.');
    }
    return FuelPriceSnapshot(
      ron95RinggitPerLitre: price,
      effectiveDate: date.toUtc(),
      fetchedAt: now().toUtc(),
      sourceUrl: catalogueUrl,
      isFromCache: false,
    );
  }

  FuelPriceSnapshot? _readCache() {
    final raw = preferences.getString(cacheKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return FuelPriceSnapshot.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _records(dynamic decoded) {
    dynamic value = decoded;
    if (decoded is Map) {
      value = decoded['data'] ?? decoded['results'] ?? decoded['records'];
    }
    if (value is! List) {
      throw const FuelDataUnavailableException(
        'Fuel data response was not a list.',
      );
    }
    return value
        .whereType<Map>()
        .map((record) => Map<String, dynamic>.from(record))
        .toList(growable: false);
  }

  void dispose() {
    if (_ownsHttpClient) {
      httpClient.close();
    }
  }
}

DateTime? _parseApiDate(Object? value) {
  final raw = '$value'.trim();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
    return DateTime.tryParse('${raw}T00:00:00Z');
  }
  return DateTime.tryParse(raw)?.toUtc();
}
