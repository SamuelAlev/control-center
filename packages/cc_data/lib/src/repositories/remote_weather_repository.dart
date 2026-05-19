import 'package:cc_data/src/absent_op.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads the latest weather snapshot + drives refresh/location writes over the
/// RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The weather surface is
/// workspace-scoped and the workspace rides in the request args (the host is
/// stateless — it binds no "current workspace"), so the calls never pass a `workspace_id` — the host
/// injects the authoritative one and scopes every query by it. Mirrors the
/// `weather.*` ops + the `weather.watchCurrent` subscription in the host catalog.
///
/// Every op is exposed to the client: reads ([getCurrent] / [watchCurrent]) and
/// the host-serviced writes ([refreshNow] / [setManualLocation] /
/// [clearManualLocation]). The host owns the live Open-Meteo fetch and all
/// state; this client never touches a database.
class RemoteWeatherRepository {
  /// Creates a [RemoteWeatherRepository] over [_client].
  RemoteWeatherRepository(this._client);

  final RemoteRpcClient _client;

  /// The latest weather snapshot in the bound workspace, or null when none has
  /// been fetched yet.
  Future<WeatherSnapshotDto?> getCurrent() async {
    final data = await _client.readOr('weather.getCurrent', const {}, const {});
    return _snapshot(data);
  }

  /// Live latest weather snapshot in the bound workspace (null until the first
  /// fetch lands and again if it is cleared).
  Stream<WeatherSnapshotDto?> watchCurrent() =>
      _client.subscribe('weather.watchCurrent', const {}).map(_snapshot);

  /// Forces an immediate re-fetch for the bound workspace.
  Future<void> refreshNow() => _client.call('weather.refreshNow', const {});

  /// Pins the bound workspace's weather location to explicit coordinates,
  /// optionally with a display [label].
  Future<void> setManualLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) => _client.call('weather.setManualLocation', {
    'latitude': latitude,
    'longitude': longitude,
    'label': ?label,
  });

  /// Clears the bound workspace's manual location, reverting to auto-detection.
  Future<void> clearManualLocation() =>
      _client.call('weather.clearManualLocation', const {});

  WeatherSnapshotDto? _snapshot(Map<String, dynamic> data) {
    final weather = data['weather'];
    return weather is Map
        ? WeatherSnapshotDto.fromJson(weather.cast<String, dynamic>())
        : null;
  }
}
