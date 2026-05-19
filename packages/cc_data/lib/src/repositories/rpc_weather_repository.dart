import 'package:cc_data/src/repositories/remote_weather_repository.dart';
import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';
import 'package:cc_domain/features/weather/domain/repositories/weather_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [WeatherRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `weather.*` ops + the
/// `weather.watchCurrent` subscription, mapping the `WeatherSnapshotDto` wire
/// shape back to [WeatherSnapshot]. The host is the single source of truth and
/// owns the live Open-Meteo fetch + all persistence; this client never touches
/// a database.
///
/// Every method takes a leading `workspaceId` (the workspace-isolation
/// contract), but it is NOT sent over the wire: the host injects the
/// authoritative bound workspace per session (`session/set_workspace`) and
/// scopes every query by it, so the client's `workspaceId` arg is validated
/// server-side via the session binding.
///
/// All ops are exposed to the client — reads ([getCurrent] / [watchCurrent]) and
/// the host-serviced writes ([refreshNow] / [setManualLocation] /
/// [clearManualLocation]) — so none throw.
class RpcWeatherRepository implements WeatherRepository {
  /// Creates an [RpcWeatherRepository] over [client].
  RpcWeatherRepository(RemoteRpcClient client)
    : _remote = RemoteWeatherRepository(client);

  final RemoteWeatherRepository _remote;

  @override
  Future<WeatherSnapshot?> getCurrent(String workspaceId) async {
    final dto = await _remote.getCurrent();
    return dto?.toEntity();
  }

  @override
  Stream<WeatherSnapshot?> watchCurrent(String workspaceId) =>
      _remote.watchCurrent().map((dto) => dto?.toEntity());

  @override
  Future<void> refreshNow(String workspaceId) => _remote.refreshNow();

  @override
  Future<void> setManualLocation(
    String workspaceId, {
    required double latitude,
    required double longitude,
    String? label,
  }) => _remote.setManualLocation(
    latitude: latitude,
    longitude: longitude,
    label: label,
  );

  @override
  Future<void> clearManualLocation(String workspaceId) =>
      _remote.clearManualLocation();
}
