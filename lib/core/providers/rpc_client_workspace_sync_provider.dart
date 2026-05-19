import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps [rpcClientProvider]'s `activeWorkspaceId` pointed at the active
/// workspace, so every workspace-scoped RPC carries the right `workspace_id`.
///
/// The server is **stateless** — it holds no per-session workspace — so each
/// request must name its own workspace. `RemoteRpcClient` injects this active id
/// into every `call`/`subscribe` whose args don't already carry one. This sink
/// seeds it and follows every change, so all transports (web, desktop-remote,
/// in-process) scope to the workspace the user is viewing without any
/// server-side binding. Kept alive by `ControlCenterApp`.
///
/// It only ever *reads* [rpcClientProvider] (a one-shot `ref.read`, never a
/// `watch`), so it adds no dependency edge and stays out of the
/// `rpcClient → activeWorkspaceId` provider cycle the workspace library avoids.
final rpcClientWorkspaceSyncProvider = Provider<void>((ref) {
  final client = ref.read(rpcClientProvider);
  client.activeWorkspaceId = ref.read(activeWorkspaceIdProvider);
  ref.listen<String?>(activeWorkspaceIdProvider, (_, next) {
    client.activeWorkspaceId = next;
  });
});
