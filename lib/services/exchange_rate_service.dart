import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result returned by the exchange-rate API.
class RateResult {
  RateResult(this.base, this.date, this.rates);
  final String base;
  final String date;

  /// Currency code -> rate relative to [base].
  final Map<String, double> rates;
}

/// Local data is recorded in PHP by default; `base` is user selectable.
class ExchangeRateService {
  ExchangeRateService([http.Client? client, Duration? timeout])
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 12);

  final http.Client _client;
  final Duration _timeout;

  /// Frankfurter public API (https://www.frankfurter.app).
  static const String host = 'api.frankfurter.app';
  static const String path = '/latest';
  static const String symbols = 'USD,EUR,JPY,GBP,SGD,PHP';

  /// Fetches the latest rates with [base] as the base currency.
  ///
  /// Throws when the network fails, the request times out, the server
  /// returns a non-success status, or the response body is invalid.
  Future<RateResult> fetch(String base) async {
    final uri = Uri.https(host, path, {'from': base, 'to': symbols});
    final response = await _client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception(
          'Exchange-rate API request failed (status ${response.statusCode}).');
    }
    return parseResponse(response.body, base);
  }

  /// Parses a raw API response body into [RateResult].
  ///
  /// Throws [FormatException] when the body is not a JSON object.
  /// Missing `rates` data is handled gracefully (empty map) rather than
  /// throwing, so the UI can show an empty state.
  RateResult parseResponse(String body, String fallbackBase) {
    final parsed = jsonDecode(body);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Invalid exchange-rate response.');
    }
    final raw = parsed['rates'];
    final Map<String, double> rates = {};
    if (raw is Map) {
      for (final entry in (raw as Map<String, dynamic>).entries) {
        final value = entry.value;
        if (value is num) {
          rates[entry.key] = value.toDouble();
        }
      }
    }
    final base =
        parsed['base'] is String ? parsed['base'] as String : fallbackBase;
    final date =
        parsed['date'] is String ? parsed['date'] as String : 'Unknown';
    return RateResult(base, date, rates);
  }
}
