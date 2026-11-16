import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web-safe access to a workspace's configured MCP servers. They live on the
/// connected server, which bridges their tools into every agent run of the
/// workspace, so the settings UI drives the `mcpServers.*` ops through this
/// control on desktop and web alike. No `dart:io`.

/// RPC-backed [WorkspaceMcpServerControl] over the `mcpServers.*` ops.
class RpcWorkspaceMcpServerControl implements WorkspaceMcpServerControl {
  /// Creates a control over the given client.
  RpcWorkspaceMcpServerControl(this._client);

  final RemoteRpcClient _client;

  @override
  Future<List<WorkspaceMcpServerEntry>> list(String workspaceId) async {
    final data = await _client.call('mcpServers.list', {
      'workspace_id': workspaceId,
    });
    return [
      for (final e in (data['servers'] as List?) ?? const [])
        if (e is Map)
          WorkspaceMcpServerEntry.fromJson(e.cast<String, dynamic>()),
    ];
  }

  @override
  Future<WorkspaceMcpServerEntry> save(
    String workspaceId,
    McpServerDraft draft,
  ) async => _entry(
    await _client.call('mcpServers.save', {
      ...draft.toJson(),
      'workspace_id': workspaceId,
    }),
  );

  @override
  Future<void> delete(String workspaceId, String id) => _client.call(
    'mcpServers.delete',
    {'workspace_id': workspaceId, 'id': id},
  );

  @override
  Future<WorkspaceMcpServerEntry> approve(
    String workspaceId,
    String id,
  ) async => _entry(
    await _client.call('mcpServers.approve', {
      'workspace_id': workspaceId,
      'id': id,
    }),
  );

  @override
  Future<void> reconnect(String workspaceId, String id) => _client.call(
    'mcpServers.reconnect',
    {'workspace_id': workspaceId, 'id': id},
  );

  static WorkspaceMcpServerEntry _entry(Map<String, dynamic> data) =>
      WorkspaceMcpServerEntry.fromJson(
        (data['server'] as Map).cast<String, dynamic>(),
      );
}

/// The control the workspace MCP section drives.
final workspaceMcpServerControlProvider = Provider<WorkspaceMcpServerControl>(
  (ref) => RpcWorkspaceMcpServerControl(ref.watch(rpcClientProvider)),
);

/// The MCP servers configured for a workspace, with their live state; null
/// when the connected server has no `mcpServers.*` ops (`opUnknown`), which
/// the section words as "not available on this server". Refreshed by the
/// section (`ref.invalidate`) after each action.
final workspaceMcpServersProvider =
    FutureProvider.family<List<WorkspaceMcpServerEntry>?, String>((
      ref,
      workspaceId,
    ) async {
      try {
        return await ref
            .watch(workspaceMcpServerControlProvider)
            .list(workspaceId);
      } on RemoteRpcException catch (e) {
        if (e.code == RpcErrorCodes.opUnknown) {
          return null;
        }
        rethrow;
      }
    });
