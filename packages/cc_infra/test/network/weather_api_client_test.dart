import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';
import 'package:cc_infra/src/network/weather_api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises [WeatherApiClient] — the keyless Open-Meteo + IP-geo client. Pure
/// response parsing over an injectable [Dio]: pins the forecast/geocode/ipgeo
/// request paths + params, the WMO-condition bucketing, the numeric coercion,
/// and the error mapping (DioException → NetworkException), plus the
/// best-effort null-on-error behavior of [WeatherApiClient.ipGeolocate].
void main() {
  late RecordingAdapter adapter;
  late WeatherApiClient client;

  setUp(() {
    adapter = RecordingAdapter();
    client = WeatherApiClient(dio: Dio()..httpClientAdapter = adapter);
  });

  group('fetchCurrent', () {
    test(
      'parses a daytime clear-weather forecast with sunrise/sunset',
      () async {
        adapter.nextJson({
          'current': {
            'temperature_2m': 21.5,
            'weather_code': 0,
            'is_day': 1,
            'wind_speed_10m': 12,
          },
          'daily': {
            'sunrise': ['2026-01-01T06:00:00'],
            'sunset': ['2026-01-01T18:00:00'],
          },
        });
        final snap = await client.fetchCurrent(
          latitude: 40.0,
          longitude: -73.0,
          label: 'NYC',
        );
        expect(
          adapter.requests.single.path,
          'https://api.open-meteo.com/v1/forecast',
        );
        final qp = adapter.requests.single.queryParameters;
        expect(qp['latitude'], 40.0);
        expect(qp['longitude'], -73.0);
        expect(qp['timezone'], 'auto');
        expect(qp['forecast_days'], 1);

        expect(snap.latitude, 40.0);
        expect(snap.longitude, -73.0);
        expect(snap.locationLabel, 'NYC');
        expect(snap.condition, WeatherCondition.clear);
        expect(snap.isDay, isTrue);
        expect(snap.temperatureCelsius, 21.5);
        expect(snap.windSpeedKmh, 12);
        expect(snap.sunrise, DateTime.tryParse('2026-01-01T06:00:00'));
        expect(snap.sunset, DateTime.tryParse('2026-01-01T18:00:00'));
        expect(snap.observedAt, isNotNull);
      },
    );

    test('nighttime rain condition with string-typed numeric fields', () async {
      adapter.nextJson({
        'current': {
          'temperature_2m': '5',
          'weather_code': 61,
          'is_day': 0,
          'wind_speed_10m': '8.5',
        },
        'daily': <String, dynamic>{},
      });
      final snap = await client.fetchCurrent(latitude: 0, longitude: 0);
      expect(snap.condition, WeatherCondition.rain);
      expect(snap.isDay, isFalse);
      expect(snap.temperatureCelsius, 5.0);
      expect(snap.windSpeedKmh, 8.5);
      expect(snap.sunrise, isNull);
      expect(snap.sunset, isNull);
    });

    test('unknown weather_code falls back to clouds', () async {
      adapter.nextJson({
        'current': {'weather_code': 999, 'is_day': 1},
      });
      final snap = await client.fetchCurrent(latitude: 0, longitude: 0);
      expect(snap.condition, WeatherCondition.clouds);
      expect(snap.temperatureCelsius, 0);
      expect(snap.windSpeedKmh, 0);
    });

    test('a missing weather_code defaults to 0 → clear', () async {
      adapter.nextJson({'current': <String, dynamic>{}});
      final snap = await client.fetchCurrent(latitude: 0, longitude: 0);
      expect(snap.condition, WeatherCondition.clear);
    });

    test('a DioException is mapped to a NetworkException', () async {
      adapter.throwNext = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 500),
      );
      expect(
        () => client.fetchCurrent(latitude: 0, longitude: 0),
        throwsA(isA<NetworkException>()),
      );
    });

    test('a non-map body is tolerated (empty current)', () async {
      adapter.nextJson('not a map');
      final snap = await client.fetchCurrent(latitude: 0, longitude: 0);
      expect(snap.condition, WeatherCondition.clear);
      expect(snap.isDay, isFalse);
      expect(snap.temperatureCelsius, 0);
    });
  });

  group('geocodeCity', () {
    test('returns the top match coordinates + label', () async {
      adapter.nextJson({
        'results': [
          {'latitude': 48.8, 'longitude': 2.3, 'name': 'Paris'},
        ],
      });
      final r = (await client.geocodeCity('Paris'))!;
      expect(r.latitude, 48.8);
      expect(r.longitude, 2.3);
      expect(r.label, 'Paris');
      expect(
        adapter.requests.single.path,
        'https://geocoding-api.open-meteo.com/v1/search',
      );
      expect(adapter.requests.single.queryParameters['count'], 1);
    });

    test('returns null when no results', () async {
      adapter.nextJson({'results': const []});
      expect(await client.geocodeCity('nowhere'), isNull);

      adapter.nextJson(<String, dynamic>{});
      expect(await client.geocodeCity('nowhere'), isNull);
    });

    test('returns null when the top match lacks coordinates', () async {
      adapter.nextJson({
        'results': [
          {'name': 'X'},
        ],
      });
      expect(await client.geocodeCity('x'), isNull);
    });

    test('a DioException is mapped to a NetworkException', () async {
      adapter.throwNext = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
      );
      expect(() => client.geocodeCity('x'), throwsA(isA<NetworkException>()));
    });
  });

  group('ipGeolocate', () {
    test('returns coordinates + city label on a 200 response', () async {
      adapter.nextJson({'latitude': 35.0, 'longitude': 139.0, 'city': 'Tokyo'});
      final r = (await client.ipGeolocate())!;
      expect(r.latitude, 35.0);
      expect(r.longitude, 139.0);
      expect(r.label, 'Tokyo');
      expect(adapter.requests.single.path, 'https://ipapi.co/json/');
    });

    test('returns null when coordinates are missing', () async {
      adapter.nextJson({'city': 'X'});
      expect(await client.ipGeolocate(), isNull);
    });

    test('swallows errors and returns null (best-effort)', () async {
      adapter.throwNext = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 500),
      );
      expect(await client.ipGeolocate(), isNull);
    });
  });
}

class RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Object _nextBody = <String, dynamic>{};
  Object? _throwNext;
  void nextJson(Object body) => _nextBody = body;
  set throwNext(Object value) => _throwNext = value;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final err = _throwNext;
    if (err != null) {
      _throwNext = null;
      throw err;
    }
    return ResponseBody.fromString(
      jsonEncode(_nextBody),
      200,
      headers: const {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
