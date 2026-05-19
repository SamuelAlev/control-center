import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web-safe access to the connected host's EXTERNAL MCP client subsystem
/// (PRD 01). The external servers live in the HOST (the spawned `cc_server` that
/// BOTH the desktop and the web client connect to), so the settings UI never
/// touches `cc_mcp_client` — it drives the `mcp.client.*` RPC ops through this
/// control. The same provider backs desktop and web identically, and the file
/// carries no `dart:io`, so it is safe in the shared web compilation graph.

/// RPC-backed [McpClientControl]: drives the host's external-MCP subsystem over
/// the `mcp.client.*` ops.
class RpcMcpClientControl implements McpClientControl {
  /// Creates a control over the given [client].
  RpcMcpClientControl(this._client);

  final RemoteRpcClient _client;

  @override
  Future<List<McpExternalServerInfo>> servers() async {
    final data = await _client.call('mcp.client.servers', const {});
    final list = (data['servers'] as List?) ?? const [];
    return [
      for (final e in list)
        if (e is Map) McpExternalServerInfo.fromJson(e.cast<String, dynamic>()),
    ];
  }

  @override
  Future<ApprovalMode> approvalMode() async {
    final data = await _client.call('mcp.client.approvalMode', const {});
    return ApprovalMode.fromWire(data['mode'] as String?);
  }

  @override
  Future<void> setApprovalMode(ApprovalMode mode) =>
      _client.call('mcp.client.setApprovalMode', {'mode': mode.wire});

  @override
  Future<void> authorize(String serverName) =>
      _client.call('mcp.client.authorize', {'name': serverName});

  @override
  Future<void> reconnect(String serverName) =>
      _client.call('mcp.client.reconnect', {'name': serverName});
}

/// The control the settings section drives — RPC-backed, talking to the
/// connected host.
final mcpClientControlProvider = Provider<McpClientControl>(
  (ref) => RpcMcpClientControl(ref.watch(rpcClientProvider)),
);

/// The external MCP servers the connected host knows about (discovered +
/// hand-added) with their live connection state. Resolves to an empty list when
/// the host exposes no external-MCP control (`mcp.client.*` absent →
/// `opUnknown`) — the section then renders "external MCP not available on this
/// server". Refreshed by the section (`ref.invalidate`) after each action.
final mcpExternalServersProvider = FutureProvider<List<McpExternalServerInfo>>((
  ref,
) async {
  try {
    return await ref.watch(mcpClientControlProvider).servers();
  } on RemoteRpcException catch (e) {
    if (e.code == RpcErrorCodes.opUnknown) {
      return const [];
    }
    rethrow;
  }
});

/// The connected host's standing tool-approval posture. Defaults to
/// `always-ask` when the host exposes no external-MCP control.
final mcpApprovalModeProvider = FutureProvider<ApprovalMode>((ref) async {
  try {
    return await ref.watch(mcpClientControlProvider).approvalMode();
  } on RemoteRpcException catch (e) {
    if (e.code == RpcErrorCodes.opUnknown) {
      return ApprovalMode.alwaysAsk;
    }
    rethrow;
  }
});
