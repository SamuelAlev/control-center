// The MCP-server control surface the settings section reads, identical on
// desktop and web: no client hosts an MCP server, so both ask the connected
// `cc_server` to start/stop/reconfigure its MCP HTTP server over the `mcp.*`
// RPC ops. When the server exposes no MCP control (`mcp.*` ops absent), the
// status provider resolves to `null` and the section renders an honest "MCP
// not available on this server" placeholder.
library;

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/server_owner_required.dart';
import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// RPC-backed [McpServerControl]: drives the SERVER's MCP HTTP server over the
/// `mcp.*` ops. Each mutator returns the fresh status snapshot from the server,
/// the same shape `mcp.status` returns.
class RpcMcpServerControl implements McpServerControl {
  /// Creates a control over the given client.
  RpcMcpServerControl(this._client);

  final RemoteRpcClient _client;

  @override
  Future<McpServerStatus> status() async {
    final data = await _client.call('mcp.status', const {});
    return McpServerStatus.fromJson(data);
  }

  @override
  Future<void> start() => _client.call('mcp.start', const {});

  @override
  Future<void> stop() => _client.call('mcp.stop', const {});

  @override
  Future<void> setEnabled({required bool enabled}) =>
      _client.call('mcp.setEnabled', {'enabled': enabled});

  @override
  Future<String> token() => _ownerToken('mcp.token');

  @override
  Future<String> rotateToken() => _ownerToken('mcp.rotateToken');

  /// Calls an owner-only token op. A refusal for not being the server owner
  /// surfaces as `ServerOwnerRequiredException`, so the section words it.
  Future<String> _ownerToken(String op) async {
    try {
      return (await _client.call(op, const {}))['token'] as String;
    } on RemoteRpcException catch (e) {
      throw serverOwnerRequiredFromRpc(
            code: e.code,
            message: e.message,
            data: e.data,
          ) ??
          e;
    }
  }
}

/// The MCP-server control the settings section drives — the RPC-backed control
/// talking to the connected server.
final mcpServerControlProvider = Provider<McpServerControl>(
  (ref) => RpcMcpServerControl(ref.watch(rpcClientProvider)),
);

/// The current MCP-server status, or `null` when the connected server exposes no
/// MCP control (`mcp.*` ops absent → `opUnknown`). The section renders an
/// "MCP not available on this server" placeholder for the null case. Refreshed
/// by the section (`ref.invalidate`) after every control action.
final mcpServerStatusProvider = FutureProvider<McpServerStatus?>((ref) async {
  try {
    return await ref.watch(mcpServerControlProvider).status();
  } on RemoteRpcException catch (e) {
    if (e.code == RpcErrorCodes.opUnknown) {
      return null;
    }
    rethrow;
  }
});
