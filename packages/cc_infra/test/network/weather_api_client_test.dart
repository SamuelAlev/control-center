import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';
import 'package:cc_infra/src/network/weather_api_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Exercises [WeatherApiClient] — the keyless Open-Meteo + IP-geo client. Pure
/// response parsing over an injectable [RhttpClient]: pins the
/// forecast/geocode/ipgeo request paths + params, the WMO-condition bucketing,
/// the numeric coercion, and the error mapping (RhttpException →
/// NetworkException), plus the best-effort null-on-error behavior of
/// [WeatherApiClient.ipGeolocate].
void main() {
  late TestHttpClient fake;
  late WeatherApiClient client;

  /// How the canned response to the next request should fail, if at all.
  String? failWith;
  Object nextBody = <String, dynamic>{};

  setUp(() {
    failWith = null;
    nextBody = <String, dynamic>{};
    fake = TestHttpClient(
      handler: (request) {
        switch (failWith) {
          case 'timeout':
            throw RhttpTimeoutException(request);
          case 'server_error':
            return httpTextResponse(request, 'boom', statusCode: 500);
        }
        return httpTextResponse(request, nextBody);
      },
    );
    client = WeatherApiClient(httpClient: fake);
  });

  group('fetchCurrent', () {
    test(
      'parses a daytime clear-weather forecast with sunrise/sunset',
      () async {
        nextBody = {
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
        };
        final snap = await client.fetchCurrent(
          latitude: 40.0,
          longitude: -73.0,
          label: 'NYC',
        );
        final uri = httpRequestUri(fake.requests.single);
        expect(uri.host, 'api.open-meteo.com');
        expect(uri.path, '/v1/forecast');
        final qp = fake.requests.single.query!;
        expect(qp['latitude'], '40.0');
        expect(qp['longitude'], '-73.0');
        expect(qp['timezone'], 'auto');
        expect(qp['forecast_days'], '1');

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
      nextBody = {
        'current': {
          'temperature_2m': '5',
          'weather_code': 61,
          'is_day': 0,
          'wind_speed_10m': '8.5',
        },
        'daily': <String, dynamic>{},
      };
      final snap = await client.fetchCurrent(latitude: 0, longitude: 0);
      expect(snap.condition, WeatherCondition.rain);
      expect(snap.isDay, isFalse);
      expect(snap.temperatureCelsius, 5.0);
      expect(snap.windSpeedKmh, 8.5);
      expect(snap.sunrise, isNull);
      expect(snap.sunset, isNull);
    });

    test('unknown weather_code falls back to clouds', () async {
      nextBody = {
        'current': {'weather_code': 999, 'is_day': 1},
      };
      final snap = await client.fetchCurrent(latitude: 0, longitude: 0);
      expect(snap.condition, WeatherCondition.clouds);
      expect(snap.temperatureCelsius, 0);
      expect(snap.windSpeedKmh, 0);
    });

    test('a missing weather_code defaults to 0 → clear', () async {
      nextBody = {'current': <String, dynamic>{}};
      final snap = await client.fetchCurrent(latitude: 0, longitude: 0);
      expect(snap.condition, WeatherCondition.clear);
    });

    test('a failed request is mapped to a NetworkException', () async {
      failWith = 'server_error';
      expect(
        () => client.fetchCurrent(latitude: 0, longitude: 0),
        throwsA(isA<NetworkException>()),
      );
    });

    test('a non-map body is tolerated (empty current)', () async {
      nextBody = 'not a map';
      final snap = await client.fetchCurrent(latitude: 0, longitude: 0);
      expect(snap.condition, WeatherCondition.clear);
      expect(snap.isDay, isFalse);
      expect(snap.temperatureCelsius, 0);
    });
  });

  group('geocodeCity', () {
    test('returns the top match coordinates + label', () async {
      nextBody = {
        'results': [
          {'latitude': 48.8, 'longitude': 2.3, 'name': 'Paris'},
        ],
      };
      final r = (await client.geocodeCity('Paris'))!;
      expect(r.latitude, 48.8);
      expect(r.longitude, 2.3);
      expect(r.label, 'Paris');
      final uri = httpRequestUri(fake.requests.single);
      expect(uri.host, 'geocoding-api.open-meteo.com');
      expect(uri.path, '/v1/search');
      expect(fake.requests.single.query!['count'], '1');
    });

    test('returns null when no results', () async {
      nextBody = {'results': const []};
      expect(await client.geocodeCity('nowhere'), isNull);

      nextBody = <String, dynamic>{};
      expect(await client.geocodeCity('nowhere'), isNull);
    });

    test('returns null when the top match lacks coordinates', () async {
      nextBody = {
        'results': [
          {'name': 'X'},
        ],
      };
      expect(await client.geocodeCity('x'), isNull);
    });

    test('a timeout is mapped to a NetworkException', () async {
      failWith = 'timeout';
      expect(() => client.geocodeCity('x'), throwsA(isA<NetworkException>()));
    });
  });

  group('nearestCity', () {
    test('returns the nearest city and its own coordinates', () async {
      nextBody = {
        'features': [
          {
            'properties': {'name': 'Regensdorf'},
            'geometry': {
              'coordinates': [8.4680435, 47.4317645],
            },
          },
        ],
      };
      final city = (await client.nearestCity(
        latitude: 47.44,
        longitude: 8.47,
      ))!;
      expect(city.label, 'Regensdorf');
      expect(city.latitude, 47.4317645);
      expect(city.longitude, 8.4680435);
      final uri = httpRequestUri(fake.requests.single);
      expect(uri.host, 'photon.komoot.io');
      expect(uri.path, '/reverse');
      final qp = fake.requests.single.query!;
      expect(qp['layer'], 'city');
      expect(qp['lat'], '47.44');
      expect(qp['lon'], '8.47');
    });

    test('returns null when there is no city', () async {
      nextBody = {'features': const []};
      expect(await client.nearestCity(latitude: 0, longitude: 0), isNull);
    });

    test('swallows errors and returns null', () async {
      failWith = 'timeout';
      expect(await client.nearestCity(latitude: 1, longitude: 2), isNull);
    });
  });

  group('ipGeolocate', () {
    test('returns coordinates + city label on a 200 response', () async {
      nextBody = {'latitude': 35.0, 'longitude': 139.0, 'city': 'Tokyo'};
      final r = (await client.ipGeolocate())!;
      expect(r.latitude, 35.0);
      expect(r.longitude, 139.0);
      expect(r.label, 'Tokyo');
      final uri = httpRequestUri(fake.requests.single);
      expect(uri.host, 'ipapi.co');
      expect(uri.path, '/json/');
    });

    test('returns null when coordinates are missing', () async {
      nextBody = {'city': 'X'};
      expect(await client.ipGeolocate(), isNull);
    });

    test('swallows errors and returns null (best-effort)', () async {
      failWith = 'server_error';
      expect(await client.ipGeolocate(), isNull);
    });
  });
}
