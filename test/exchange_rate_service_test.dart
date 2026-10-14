import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as testing;
import 'package:budget_buddy/services/exchange_rate_service.dart';

void main() {
  group('parseResponse', () {
    test('parses a valid Frankfurter response', () {
      final service = ExchangeRateService();
      final r = service.parseResponse(
          '{"amount":1.0,"base":"PHP","date":"2024-01-02","rates":{"USD":0.018,"EUR":0.016}}',
          'EUR');
      expect(r.base, 'PHP');
      expect(r.date, '2024-01-02');
      expect(r.rates['USD'], closeTo(0.018, 0.0001));
      expect(r.rates['EUR'], closeTo(0.016, 0.0001));
    });

    test('uses fallback base and date when fields are missing', () {
      final service = ExchangeRateService();
      final r = service.parseResponse('{"rates":{"USD":0.018}}', 'EUR');
      expect(r.base, 'EUR');
      expect(r.date, 'Unknown');
    });

    test('returns an empty rate map when rates are missing', () {
      final service = ExchangeRateService();
      final r =
          service.parseResponse('{"base":"EUR","date":"2024-01-01"}', 'EUR');
      expect(r.rates, isEmpty);
    });

    test('ignores non-numeric rate values', () {
      final service = ExchangeRateService();
      final r =
          service.parseResponse('{"rates":{"USD":0.018,"BAD":"oops"}}', 'EUR');
      expect(r.rates.length, 1);
      expect(r.rates['USD'], closeTo(0.018, 0.0001));
    });

    test('throws FormatException on malformed JSON', () {
      final service = ExchangeRateService();
      expect(() => service.parseResponse('not json', 'EUR'),
          throwsA(isA<FormatException>()));
    });

    test('throws FormatException on non-object JSON', () {
      final service = ExchangeRateService();
      expect(() => service.parseResponse('[1,2,3]', 'EUR'),
          throwsA(isA<FormatException>()));
    });
  });

  group('fetch', () {
    test('queries the Frankfurter API with the correct params', () async {
      Uri? captured;
      final client = testing.MockClient((request) async {
        captured = request.url;
        return http.Response(
            '{"amount":1.0,"base":"PHP","date":"2024-01-02","rates":{"USD":0.018,"EUR":0.016,"SGD":1.3}}',
            200);
      });
      final service = ExchangeRateService(client);
      final r = await service.fetch('PHP');
      expect(captured?.host, 'api.frankfurter.app');
      expect(captured?.path, '/latest');
      expect(captured?.queryParameters['from'], 'PHP');
      expect(captured?.queryParameters['to'], 'USD,EUR,JPY,GBP,SGD,PHP');
      expect(r.base, 'PHP');
      expect(r.rates['USD'], closeTo(0.018, 0.0001));
    });

    test('retrieved rate converts amounts via multiplication', () async {
      final client = testing.MockClient((request) async => http.Response(
          '{"base":"PHP","date":"2024-01-02","rates":{"USD":0.018}}', 200));
      final r = await ExchangeRateService(client).fetch('PHP');
      // converted amount = entered amount * retrieved exchange rate
      expect((100 * r.rates['USD']!).toStringAsFixed(2), '1.80');
    });

    test('throws on a non-200 HTTP status', () async {
      final client = testing.MockClient(
          (request) async => http.Response('Not Found', 404));
      final service = ExchangeRateService(client);
      expect(() => service.fetch('PHP'), throwsException);
    });

    test('throws on a malformed response body', () async {
      final client =
          testing.MockClient((request) async => http.Response('not json', 200));
      final service = ExchangeRateService(client);
      expect(() => service.fetch('PHP'), throwsA(isA<FormatException>()));
    });

    test('throws TimeoutException when the request is too slow', () async {
      final client = testing.MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 300));
        return http.Response(
            '{"base":"PHP","date":"2024-01-02","rates":{"USD":0.018}}', 200);
      });
      final service =
          ExchangeRateService(client, const Duration(milliseconds: 50));
      expect(() => service.fetch('PHP'), throwsA(isA<TimeoutException>()));
    });
  });
}
