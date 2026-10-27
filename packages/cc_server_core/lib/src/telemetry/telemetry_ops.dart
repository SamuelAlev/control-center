import 'package:cc_domain/cc_domain.dart'
    show AuthException, RepoOpKind, ValidationException;
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:cc_host/cc_host.dart';

/// `telemetry.*` repo-RPC ops: the install's usage-analytics decision.
///
/// Unlike the raw `server_settings.*` ops, reading the config is open to every
/// authenticated session: each client must know whether it may collect, and
/// a client never decides that on its own. Only the server owner flips the
/// switch. All ops are `workspaceScoped: false`; nothing here is workspace
/// data.
List<RepoOp> buildTelemetryOps({
  required TelemetryConfigRepository config,
  required Future<bool> Function(String userId) isServerOwner,
}) => [
  RepoOp(
    name: 'telemetry.config',
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) async => (await config.get()).toWire(),
  ),
  RepoOp(
    name: 'telemetry.setUsageAnalytics',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    serverAuthority: ServerAuthority.serverOwner,
    requiredArgs: ['enabled'],
    handler: (ctx) async {
      // Depth behind `serverAuthority`, for catalogs driven without the
      // dispatcher.
      if (!await isServerOwner(ctx.userId)) {
        throw const AuthException(
          'Only the server owner may change usage analytics for this install',
        );
      }
      final enabled = ctx.args['enabled'];
      if (enabled is! bool) {
        throw const ValidationException(
          'Invalid argument: enabled (expected a boolean)',
        );
      }
      await config.setUsageAnalyticsEnabled(enabled: enabled);
      return {'ok': true};
    },
  ),
];

/// `telemetry.watch`: the config, then every change, for every session (see
/// [buildTelemetryOps]).
List<WatchQuery> buildTelemetryWatchQueries(TelemetryConfigRepository config) =>
    [
      WatchQuery(
        name: 'telemetry.watch',
        workspaceScoped: false,
        handler: (ctx) => config.watch().map((c) => c.toWire()),
      ),
    ];
