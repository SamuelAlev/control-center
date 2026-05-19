import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';

/// Persistence/read port for the soundscapes weather feature. Every method is
/// workspace-scoped (the workspace clause, not id uniqueness, is the isolation
/// boundary) and takes a required `workspaceId` — never optional, never an
/// implicit "current" workspace.
///
/// Thin clients consume this over RPC (the host owns the live Open-Meteo fetch
/// and holds all state); the desktop's in-process host binds the same interface
/// to the server-side implementation. Reads ([getCurrent]/[watchCurrent]) work
/// on every tier; the write/refresh methods are serviced host-side.
abstract class WeatherRepository {
  /// The latest weather snapshot for [workspaceId], or null when none has been
  /// fetched yet.
  Future<WeatherSnapshot?> getCurrent(String workspaceId);

  /// Watches the latest weather snapshot for [workspaceId], emitting null until
  /// the first fetch lands and again if it is cleared.
  Stream<WeatherSnapshot?> watchCurrent(String workspaceId);

  /// Forces an immediate re-fetch for [workspaceId]. Host-only: the RPC client
  /// implementation forwards the request to the server, and the server
  /// implementation performs the Open-Meteo fetch and persists the result.
  Future<void> refreshNow(String workspaceId);

  /// Pins the workspace's weather location to explicit coordinates (overriding
  /// any auto-detected one), optionally with a display [label]. Host-only.
  Future<void> setManualLocation(
    String workspaceId, {
    required double latitude,
    required double longitude,
    String? label,
  });

  /// Clears a manual location for [workspaceId], reverting to auto-detection.
  /// Host-only.
  Future<void> clearManualLocation(String workspaceId);
}
