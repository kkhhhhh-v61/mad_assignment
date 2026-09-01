import 'dart:math' as math;

class FuelPriceSnapshot {
  static const cacheSchemaVersion = 1;

  final double ron95RinggitPerLitre;
  final DateTime effectiveDate;
  final DateTime fetchedAt;
  final String sourceUrl;
  final bool isFromCache;

  FuelPriceSnapshot({
    required this.ron95RinggitPerLitre,
    required this.effectiveDate,
    required this.fetchedAt,
    required this.sourceUrl,
    required this.isFromCache,
  }) {
    if (!ron95RinggitPerLitre.isFinite || ron95RinggitPerLitre <= 0) {
      throw const FuelPriceDataException('RON95 price must be positive.');
    }
    if (sourceUrl.trim().isEmpty) {
      throw const FuelPriceDataException('Fuel price source is required.');
    }
  }

  factory FuelPriceSnapshot.fromJson(Map<String, dynamic> json) {
    final price = _asDouble(
      json['ron95RinggitPerLitre'] ?? json['ron95_ringgit_per_litre'],
    );
    final effectiveDate = _asDate(
      json['effectiveDate'] ?? json['effective_date'],
    );
    final fetchedAt = _asDate(json['fetchedAt'] ?? json['fetched_at']);
    final sourceUrl = json['sourceUrl'] ?? json['source_url'];
    final schemaVersion = json['schemaVersion'] ?? json['schema_version'];
    if (schemaVersion != null && schemaVersion != cacheSchemaVersion) {
      throw const FuelPriceDataException('Unsupported fuel cache version.');
    }
    if (sourceUrl is! String) {
      throw const FuelPriceDataException('Fuel price source is invalid.');
    }
    return FuelPriceSnapshot(
      ron95RinggitPerLitre: price,
      effectiveDate: effectiveDate,
      fetchedAt: fetchedAt,
      sourceUrl: sourceUrl,
      isFromCache:
          json['isFromCache'] as bool? ??
          json['is_from_cache'] as bool? ??
          true,
    );
  }

  FuelPriceSnapshot copyWith({bool? isFromCache}) {
    return FuelPriceSnapshot(
      ron95RinggitPerLitre: ron95RinggitPerLitre,
      effectiveDate: effectiveDate,
      fetchedAt: fetchedAt,
      sourceUrl: sourceUrl,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  bool isFresh({
    required DateTime now,
    Duration maxAge = const Duration(hours: 24),
  }) {
    final age = now.toUtc().difference(fetchedAt.toUtc());
    return age >= Duration.zero && age <= maxAge;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': cacheSchemaVersion,
    'ron95RinggitPerLitre': ron95RinggitPerLitre,
    'effectiveDate': effectiveDate.toUtc().toIso8601String(),
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'sourceUrl': sourceUrl,
    'isFromCache': isFromCache,
  };
}

class FuelPriceDataException implements Exception {
  final String message;

  const FuelPriceDataException(this.message);

  @override
  String toString() => message;
}

class FuelDataUnavailableException extends FuelPriceDataException {
  const FuelDataUnavailableException(super.message);
}

double _asDouble(Object? value) {
  final result = value is num ? value.toDouble() : double.tryParse('$value');
  if (result == null || !result.isFinite || result <= 0) {
    throw const FuelPriceDataException('RON95 price is invalid.');
  }
  return result;
}

DateTime _asDate(Object? value) {
  final result = value is DateTime ? value : DateTime.tryParse('$value');
  if (result == null) {
    throw const FuelPriceDataException('Fuel price date is invalid.');
  }
  return result.toUtc();
}

int roundCostSen(double ringgitPerLitre, double litres) {
  final sen = ringgitPerLitre * litres * 100;
  if (!sen.isFinite || sen < 0) {
    throw const FuelPriceDataException('Fuel cost is invalid.');
  }
  return math.max(0, sen.round());
}
