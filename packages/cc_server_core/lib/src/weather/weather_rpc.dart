import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/weather/domain/repositories/weather_repository.dart';
import 'package:cc_host/cc_host.dart';

/// Repo-RPC ops exposing the workspace's live weather to thin clients.
///
/// The client READS this surface (current conditions) and can trigger a manual
/// refresh or override the location; the actual Open-Meteo fetch, IP-geolocation
/// fallback and periodic sweep all run host-side in `ServerWeatherService`
/// (`cc_infra`) — a thin client never dials a weather API directly.
///
/// Injected into the catalog via `extraOps` / `extraWatchQueries` (the same seam
/// the fleet and evals ops use), so the 12k-line `remote_rpc_catalog.dart` is
/// left untouched.
List<RepoOp> buildWeatherOps(WeatherRepository weather) => [
  RepoOp(
    name: 'weather.getCurrent',
    kind: RepoOpKind.read,
    handler: (ctx) async {
      final snapshot = await weather.getCurrent(ctx.workspaceId!);
      return {
        'weather': snapshot == null
            ? null
            : WeatherSnapshotDto.fromEntity(snapshot).toJson(),
      };
    },
  ),
  RepoOp(
    name: 'weather.refreshNow',
    kind: RepoOpKind.mutate,
    handler: (ctx) async {
      await weather.refreshNow(ctx.workspaceId!);
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'weather.setManualLocation',
    kind: RepoOpKind.mutate,
    requiredArgs: ['latitude', 'longitude'],
    handler: (ctx) async {
      await weather.setManualLocation(
        ctx.workspaceId!,
        latitude: (ctx.args['latitude'] as num).toDouble(),
        longitude: (ctx.args['longitude'] as num).toDouble(),
        label: ctx.args['label'] as String?,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'weather.clearManualLocation',
    kind: RepoOpKind.mutate,
    handler: (ctx) async {
      await weather.clearManualLocation(ctx.workspaceId!);
      return {'ok': true};
    },
  ),
];

/// The reactive counterpart: `weather.watchCurrent` streams the workspace's
/// current `WeatherSnapshot` (or null before the first fetch) as it refreshes.
List<WatchQuery> buildWeatherWatchQueries(WeatherRepository weather) => [
  WatchQuery(
    name: 'weather.watchCurrent',
    handler: (ctx) => weather
        .watchCurrent(ctx.workspaceId!)
        .map(
          (snapshot) => {
            'weather': snapshot == null
                ? null
                : WeatherSnapshotDto.fromEntity(snapshot).toJson(),
          },
        ),
  ),
];
