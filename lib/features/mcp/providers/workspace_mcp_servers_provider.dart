import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web-safe access to the MCP servers configured in a workspace: the
/// workspace's and the caller's own. They live on the connected server, which
/// bridges their tools into the agent runs they belong to, so the settings UI
/// drives the `mcpServers.*` ops through this control on desktop and web
/// alike. No `dart:io`.

/// RPC-backed [WorkspaceMcpServerControl] over the `mcpServers.*` ops.
class RpcWorkspaceMcpServerControl implements WorkspaceMcpServerControl {
  /// Creates a control over the given client.
  RpcWorkspaceMcpServerControl(this._client);

  final RemoteRpcClient _client;

  @override
  Future<List<WorkspaceMcpServerEntry>> list(
    String workspaceId,
    McpServerScope scope,
  ) async {
    final data = await _client.call('mcpServers.list', {
      'workspace_id': workspaceId,
      'scope': scope.wire,
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
    McpServerScope scope,
    McpServerDraft draft,
  ) async => _entry(
    await _client.call('mcpServers.save', {
      ...draft.toJson(),
      'workspace_id': workspaceId,
      'scope': scope.wire,
    }),
  );

  @override
  Future<void> delete(String workspaceId, McpServerScope scope, String id) =>
      _client.call('mcpServers.delete', {
        'workspace_id': workspaceId,
        'scope': scope.wire,
        'id': id,
      });

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
  Future<void> reconnect(String workspaceId, McpServerScope scope, String id) =>
      _client.call('mcpServers.reconnect', {
        'workspace_id': workspaceId,
        'scope': scope.wire,
        'id': id,
      });

  @override
  Future<McpServerAuthorization> beginAuthorization(
    String workspaceId,
    McpServerScope scope,
    String id,
  ) async => McpServerAuthorization.fromJson(
    await _client.call('mcpServers.authorize', {
      'workspace_id': workspaceId,
      'scope': scope.wire,
      'id': id,
    }),
  );

  @override
  Future<McpServerAuthorization> completeAuthorization(
    String workspaceId,
    McpServerScope scope,
    String attemptId,
    String code,
  ) async => McpServerAuthorization.fromJson(
    await _client.call('mcpServers.authorizeComplete', {
      'workspace_id': workspaceId,
      'scope': scope.wire,
      'attempt_id': attemptId,
      'code': code,
    }),
  );

  static WorkspaceMcpServerEntry _entry(Map<String, dynamic> data) =>
      WorkspaceMcpServerEntry.fromJson(
        (data['server'] as Map).cast<String, dynamic>(),
      );
}

/// The control the MCP server sections drive.
final workspaceMcpServerControlProvider = Provider<WorkspaceMcpServerControl>(
  (ref) => RpcWorkspaceMcpServerControl(ref.watch(rpcClientProvider)),
);

/// How often a list with a connecting server is read again.
const mcpServersSettleInterval = Duration(seconds: 2);

/// Which list of MCP servers: a workspace, and whose servers in it.
typedef McpServersKey = ({String workspaceId, McpServerScope scope});

/// The MCP servers of one scope in a workspace, with their live state; null
/// when the connected server has no `mcpServers.*` ops (`opUnknown`), which
/// the section words as "not available on this server". Refreshed by the
/// section (`ref.invalidate`) after each action, and by itself every
/// [mcpServersSettleInterval] while a server is still connecting and someone
/// is looking: the server dials in the background and sends no event when it
/// settles.
final workspaceMcpServersProvider =
    FutureProvider.family<List<WorkspaceMcpServerEntry>?, McpServersKey>((
      ref,
      key,
    ) async {
      try {
        final entries = await ref
            .watch(workspaceMcpServerControlProvider)
            .list(key.workspaceId, key.scope);
        if (entries.any((e) => e.isConnecting)) {
          final timer = Timer(mcpServersSettleInterval, ref.invalidateSelf);
          ref
            ..onDispose(timer.cancel)
            ..onCancel(timer.cancel);
        }
        return entries;
      } on RemoteRpcException catch (e) {
        if (e.code == RpcErrorCodes.opUnknown) {
          return null;
        }
        rethrow;
      }
    });
