import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';
import 'package:cc_domain/features/weather/domain/repositories/weather_repository.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/weather_api_client.dart';
import 'package:path/path.dart' as p;

/// A resolved weather location: coordinates plus an optional display label.
typedef _Location = ({double latitude, double longitude, String? label});

/// Server-side [WeatherRepository] backing the soundscapes ambience.
///
/// Owns the live Open-Meteo fetch and all weather state (thin clients read it
/// over RPC). It caches the latest snapshot per workspace, persists per-workspace
/// manual location overrides to `<dataDir>/weather_locations.json` and refreshes
/// every tracked workspace on a [Timer.periodic]. Mirrors `CalendarSyncService`'s
/// timer + immediate-run-on-[start] + [dispose] shape.
///
/// Location resolution per workspace is: a pinned manual override, else a single
/// IP-geolocated fallback shared across workspaces. The IP fallback resolves the
/// server's OWN public IP — a deliberately server-global, coarse location (it is
/// not workspace-scoped data, so sharing it across workspaces is correct here).
class ServerWeatherService implements WeatherRepository {
  /// Creates a [ServerWeatherService] and loads any persisted manual locations.
  ServerWeatherService({
    required WeatherApiClient client,
    required String dataDir,
    Duration refreshInterval = const Duration(minutes: 15),
  }) : _client = client,
       _refreshInterval = refreshInterval,
       _locationsFile = File(p.join(dataDir, 'weather_locations.json')) {
    _loadManualLocations();
  }

  final WeatherApiClient _client;
  final Duration _refreshInterval;
  final File _locationsFile;

  /// Latest snapshot per workspace id.
  final Map<String, WeatherSnapshot> _latest = {};

  /// Broadcast controllers per workspace id, created lazily on first watch.
  final Map<String, StreamController<WeatherSnapshot?>> _controllers = {};

  /// Persisted manual location overrides, keyed by workspace id.
  final Map<String, _Location> _manual = {};

  Timer? _timer;

  /// The cached server-global IP-geolocated fallback (shared across workspaces).
  _Location? _ipLocation;

  /// A single in-flight IP-geo lookup, so concurrent refreshes coalesce into one
  /// call to the geolocation provider instead of each firing their own.
  Future<_Location?>? _ipLocationFuture;

  /// Starts the periodic refresh and runs one immediate sweep.
  void start() {
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(_refreshInterval, (_) => _sweep());
    _sweep();
  }

  /// Cancels the timer and closes every watcher stream.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    for (final controller in _controllers.values) {
      unawaited(controller.close());
    }
    _controllers.clear();
  }

  @override
  Future<WeatherSnapshot?> getCurrent(String workspaceId) async {
    final cached = _latest[workspaceId];
    if (cached == null) {
      // Nothing cached yet — kick off a background fetch so the next read (and
      // any active watcher) lands a snapshot, but don't block this call on it.
      unawaited(refreshNow(workspaceId));
    }
    return cached;
  }

  @override
  Stream<WeatherSnapshot?> watchCurrent(String workspaceId) async* {
    // Replay the current cache to this listener immediately, then follow live
    // updates. Each subscription is its own async generator, so every new
    // listener gets the latest value even though the controller is broadcast
    // (a bare broadcast stream would replay to no one).
    yield _latest[workspaceId];
    yield* _controllerFor(workspaceId).stream;
  }

  @override
  Future<void> refreshNow(String workspaceId) async {
    try {
      final location = await _resolveLocation(workspaceId);
      if (location == null) {
        CcInfraLog.warning(
          'weather: no location resolved for workspace $workspaceId',
        );
        return;
      }
      final snapshot = await _client.fetchCurrent(
        latitude: location.latitude,
        longitude: location.longitude,
        label: location.label,
      );
      _latest[workspaceId] = snapshot;
      _emit(workspaceId, snapshot);
    } on Object catch (e) {
      // A single failed fetch must never crash the periodic sweep or the
      // caller — the previous cached snapshot (if any) stays live.
      CcInfraLog.warning('weather: refresh failed for $workspaceId: $e');
    }
  }

  @override
  Future<void> setManualLocation(
    String workspaceId, {
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    _manual[workspaceId] = (
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
    await _saveManualLocations();
    await refreshNow(workspaceId);
  }

  @override
  Future<void> clearManualLocation(String workspaceId) async {
    _manual.remove(workspaceId);
    await _saveManualLocations();
    await refreshNow(workspaceId);
  }

  /// Refreshes every workspace we track — anything with a cached snapshot, an
  /// active watcher, or a pinned manual location.
  void _sweep() {
    final ids = <String>{
      ..._latest.keys,
      ..._controllers.keys,
      ..._manual.keys,
    };
    for (final id in ids) {
      unawaited(refreshNow(id));
    }
  }

  StreamController<WeatherSnapshot?> _controllerFor(String workspaceId) {
    return _controllers.putIfAbsent(workspaceId, () {
      late final StreamController<WeatherSnapshot?> controller;
      controller = StreamController<WeatherSnapshot?>.broadcast(
        onCancel: () {
          // Last watcher gone: drop the controller. The cached snapshot in
          // [_latest] survives, so a future watcher rehydrates from it (and the
          // sweep still refreshes the workspace via its cache/manual entry).
          if (!controller.hasListener) {
            _controllers.remove(workspaceId);
            controller.close();
          }
        },
      );
      return controller;
    });
  }

  void _emit(String workspaceId, WeatherSnapshot? snapshot) {
    if (_controllers[workspaceId] case final controller?
        when !controller.isClosed) {
      controller.add(snapshot);
    }
  }

  Future<_Location?> _resolveLocation(String workspaceId) async {
    final manual = _manual[workspaceId];
    if (manual != null) {
      return manual;
    }
    return _resolveIpLocation();
  }

  Future<_Location?> _resolveIpLocation() async {
    if (_ipLocation != null) {
      return _ipLocation;
    }
    // Coalesce concurrent lookups onto one in-flight future; a failure (null)
    // isn't cached, so a later refresh retries.
    return _ipLocationFuture ??= _fetchIpLocation();
  }

  Future<_Location?> _fetchIpLocation() async {
    try {
      final resolved = await _client.ipGeolocate();
      if (resolved != null) {
        _ipLocation = resolved;
      }
      return resolved;
    } finally {
      _ipLocationFuture = null;
    }
  }

  void _loadManualLocations() {
    try {
      if (!_locationsFile.existsSync()) {
        return;
      }
      final decoded = jsonDecode(_locationsFile.readAsStringSync());
      if (decoded is! Map) {
        return;
      }
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map) {
          continue;
        }
        final latitude = _asDouble(value['lat']);
        final longitude = _asDouble(value['lon']);
        if (latitude == null || longitude == null) {
          continue;
        }
        final label = value['label'];
        _manual['${entry.key}'] = (
          latitude: latitude,
          longitude: longitude,
          label: label is String ? label : null,
        );
      }
    } on Object catch (e) {
      CcInfraLog.warning('weather: failed to load manual locations: $e');
    }
  }

  Future<void> _saveManualLocations() async {
    try {
      await _locationsFile.parent.create(recursive: true);
      final map = <String, dynamic>{
        for (final entry in _manual.entries)
          entry.key: <String, dynamic>{
            'lat': entry.value.latitude,
            'lon': entry.value.longitude,
            'label': entry.value.label,
          },
      };
      // Atomic write (temp + rename) so a crash never leaves a half-written map.
      final tmp = File('${_locationsFile.path}.tmp');
      await tmp.writeAsString(jsonEncode(map));
      await tmp.rename(_locationsFile.path);
    } on Object catch (e) {
      CcInfraLog.warning('weather: failed to save manual locations: $e');
    }
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
