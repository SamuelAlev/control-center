import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';
import 'package:cc_infra/src/network/weather_api_client.dart';
import 'package:cc_infra/src/weather/server_weather_service.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Subclasses [WeatherApiClient] so the service's network calls are scripted
/// without touching the real Open-Meteo endpoint. The superclass constructor
/// receives a plain [Dio] that is never actually used (every method is
/// overridden).
class _FakeWeatherClient extends WeatherApiClient {
  _FakeWeatherClient({
    WeatherSnapshot? snapshot,
    this.ipLocation,
    this.fetchThrows,
  }) : snapshot = snapshot ?? _defaultSnapshot,
       super(dio: Dio());

  static final WeatherSnapshot _defaultSnapshot = WeatherSnapshot(
    latitude: 1,
    longitude: 2,
    locationLabel: 'Test',
    condition: WeatherCondition.clear,
    isDay: true,
    temperatureCelsius: 20,
    windSpeedKmh: 5,
    sunrise: null,
    sunset: null,
    observedAt: DateTime.utc(2026, 1, 1),
  );

  final WeatherSnapshot snapshot;
  final ({double latitude, double longitude, String? label})? ipLocation;
  final Object? fetchThrows;

  int fetchCalls = 0;
  List<({double lat, double lon, String? label})> fetchArgs = [];

  @override
  Future<WeatherSnapshot> fetchCurrent({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    fetchCalls++;
    fetchArgs.add((lat: latitude, lon: longitude, label: label));
    if (fetchThrows != null) {
      throw fetchThrows!;
    }
    return snapshot;
  }

  @override
  Future<({double latitude, double longitude, String? label})?>
  ipGeolocate() async => ipLocation;
}

WeatherSnapshot _snap(double lat, double lon) => WeatherSnapshot(
  latitude: lat,
  longitude: lon,
  locationLabel: null,
  condition: WeatherCondition.clear,
  isDay: true,
  temperatureCelsius: 10,
  windSpeedKmh: 0,
  sunrise: null,
  sunset: null,
  observedAt: DateTime.utc(2026, 1, 1),
);

ServerWeatherService _service(
  Directory temp, {
  WeatherSnapshot? snapshot,
  ({double latitude, double longitude, String? label})? ipLocation,
  Object? fetchThrows,
  Duration refreshInterval = const Duration(minutes: 15),
}) => ServerWeatherService(
  client: _FakeWeatherClient(
    snapshot: snapshot ?? _snap(1, 2),
    ipLocation: ipLocation,
    fetchThrows: fetchThrows,
  ),
  dataDir: temp.path,
  refreshInterval: refreshInterval,
);

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('weather_svc_');
  });

  tearDown(() async {
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  group('ServerWeatherService persistence', () {
    test(
      'loads manual locations from weather_locations.json on construction',
      () async {
        final file = File(p.join(temp.path, 'weather_locations.json'));
        await file.writeAsString(
          jsonEncode({
            'ws1': {'lat': 40.0, 'lon': -73.0, 'label': 'NYC'},
            'ws2': {'lat': 'invalid', 'lon': 5},
          }),
        );

        final client = _FakeWeatherClient();
        final svc = ServerWeatherService(client: client, dataDir: temp.path);

        await svc.refreshNow('ws1');
        expect(client.fetchCalls, 1);
        expect(client.fetchArgs.single.lat, 40.0);
        expect(client.fetchArgs.single.lon, -73.0);
        expect(client.fetchArgs.single.label, 'NYC');

        // ws2 had an invalid lat — skipped and no IP fallback configured.
        client.fetchCalls = 0;
        client.fetchArgs.clear();
        await svc.refreshNow('ws2');
        expect(client.fetchCalls, 0);
      },
    );

    test('corrupt locations file is swallowed (no crash)', () async {
      final file = File(p.join(temp.path, 'weather_locations.json'));
      await file.writeAsString('{ not valid json');
      final svc = _service(temp);
      await svc.refreshNow('ws1');
    });

    test('non-map locations file is swallowed', () async {
      final file = File(p.join(temp.path, 'weather_locations.json'));
      await file.writeAsString('[1,2,3]');
      final svc = _service(temp);
      await svc.refreshNow('ws1');
    });
  });

  group('ServerWeatherService.getCurrent / refreshNow', () {
    test('getCurrent returns null when nothing cached yet', () async {
      final svc = _service(temp);
      expect(await svc.getCurrent('ws1'), isNull);
    });

    test('refreshNow via IP fallback caches a snapshot', () async {
      final svc = _service(
        temp,
        snapshot: _snap(10, 20),
        ipLocation: (latitude: 12.0, longitude: 34.0, label: 'Somewhere'),
      );
      await svc.refreshNow('ws1');
      final snap = await svc.getCurrent('ws1');
      expect(snap, isNotNull);
      expect(snap!.latitude, 10);
    });

    test('refreshNow without any resolved location is a no-op', () async {
      final client = _FakeWeatherClient(ipLocation: null);
      final svc = ServerWeatherService(client: client, dataDir: temp.path);
      await svc.refreshNow('ws1');
      expect(client.fetchCalls, 0);
      expect(await svc.getCurrent('ws1'), isNull);
    });

    test('refreshNow swallows fetch errors', () async {
      final svc = _service(
        temp,
        ipLocation: (latitude: 1, longitude: 2, label: null),
        fetchThrows: StateError('api down'),
      );
      await svc.refreshNow('ws1');
      expect(await svc.getCurrent('ws1'), isNull);
    });
  });

  group('ServerWeatherService manual location', () {
    test('setManualLocation persists to disk and refreshes', () async {
      final client = _FakeWeatherClient();
      final svc = ServerWeatherService(client: client, dataDir: temp.path);

      await svc.setManualLocation(
        'ws1',
        latitude: 48.8,
        longitude: 2.3,
        label: 'Paris',
      );

      final file = File(p.join(temp.path, 'weather_locations.json'));
      expect(file.existsSync(), isTrue);
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final ws1 = decoded['ws1'] as Map<String, dynamic>;
      expect(ws1['lat'], 48.8);
      expect(ws1['lon'], 2.3);
      expect(ws1['label'], 'Paris');

      expect(client.fetchArgs.single.lat, 48.8);
      expect(client.fetchArgs.single.lon, 2.3);
    });

    test('clearManualLocation removes the override and refreshes', () async {
      final client = _FakeWeatherClient(
        ipLocation: (latitude: 0, longitude: 0, label: 'IP'),
      );
      final svc = ServerWeatherService(client: client, dataDir: temp.path);

      await svc.setManualLocation('ws1', latitude: 1, longitude: 1);
      client.fetchArgs.clear();

      await svc.clearManualLocation('ws1');

      // After clear, refresh uses the IP fallback (0,0).
      expect(client.fetchArgs.single.lat, 0);
      expect(client.fetchArgs.single.lon, 0);

      final file = File(p.join(temp.path, 'weather_locations.json'));
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(decoded.containsKey('ws1'), isFalse);
    });
  });

  group('ServerWeatherService.watchCurrent', () {
    test('replays cache then forwards updates', () async {
      final svc = _service(
        temp,
        ipLocation: (latitude: 1, longitude: 2, label: null),
      );
      await svc.refreshNow('ws1');

      final snaps = <WeatherSnapshot?>[];
      final sub = svc.watchCurrent('ws1').listen(snaps.add);
      await Future<void>.delayed(Duration.zero);
      expect(snaps, hasLength(1));
      expect(snaps.single, isNotNull);

      await svc.refreshNow('ws1');
      await Future<void>.delayed(Duration.zero);
      expect(snaps, hasLength(2));

      await sub.cancel();
    });
  });

  group('ServerWeatherService.start / dispose', () {
    test(
      'start runs a sweep for tracked workspaces; dispose stops refreshes',
      () async {
        final svc = _service(
          temp,
          ipLocation: (latitude: 1, longitude: 2, label: null),
          refreshInterval: const Duration(milliseconds: 50),
        );
        // Seed a tracked workspace so the sweep picks it up.
        await svc.setManualLocation('ws1', latitude: 1, longitude: 2);

        svc.start();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final snap = await svc.getCurrent('ws1');
        expect(snap, isNotNull);

        svc.dispose();
        // Cache is still readable after dispose.
        expect(await svc.getCurrent('ws1'), isNotNull);
      },
    );

    test('start is idempotent', () async {
      final svc = _service(temp);
      svc.start();
      svc.start(); // no throw
      svc.dispose();
    });
  });
}
