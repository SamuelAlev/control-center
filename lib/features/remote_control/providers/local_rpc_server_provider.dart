import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/mcp/providers/mcp_server_provider.dart';
import 'package:control_center/features/remote_control/providers/remote_control_config_provider.dart';
import 'package:control_center/features/remote_control/providers/remote_control_devices_provider.dart';
import 'package:control_center/features/remote_control/providers/remote_control_server_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds and manages the WSS [LocalRpcServer] — the desktop's "act as server"
/// mode (the plan's same-origin / LAN / Tailnet reachable-server path).
///
/// Reuses the SAME dispatcher / DAO / secrets / event-bus singletons as the
/// WebRTC server ([remoteControlServerProvider]) — one RPC surface, multiple
/// transports. Every dependency is `read` (never `watch`), exactly like the
/// WebRTC server, so the listener is a single long-lived instance and never
/// rebuilds into a second bound socket. Binds loopback by default (a browser
/// secure context for `http://localhost`); auto-starts only when
/// `wsServeEnabled`.
final localRpcServerProvider = Provider<LocalRpcServer>((ref) {
  ref.keepAlive();
  final config = ref.read(remoteControlConfigProvider);
  final catalog = ref.read(remoteRpcCatalogProvider);
  final server = LocalRpcServer(
    dispatcher: ref.read(mcpToolDispatcherProvider),
    devicesDao: ref.read(pairedDeviceDaoProvider),
    secrets: ref.read(pairedDeviceSecretsProvider),
    eventBus: ref.read(domainEventBusProvider),
    workspaceResolver: ref.read(remoteWorkspaceListResolverProvider),
    repoOps: RepoOpDispatcher(
      registry: catalog.ops,
      mapException: mapAppExceptionToRpc,
    ),
    watchQueries: catalog.watch,
    port: config.wsServePort,
  );
  ref.onDispose(() {
    server.onRunningChanged = null;
    server.stop();
  });
  if (config.wsServeEnabled) {
    Future.microtask(() async {
      try {
        await server.start();
      } catch (e, st) {
        AppLog.e('RemoteControl', 'Failed to start WSS server: $e', e, st);
      }
    });
  }
  return server;
});
