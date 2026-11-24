import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web-safe access to the connected host's standing tool-approval posture,
/// driven over the `mcp.client.*` ops. The same provider backs desktop and
/// web identically and the file carries no `dart:io`, so it is safe in the
/// shared web compilation graph.

/// RPC-backed [McpClientControl] over the `mcp.client.*` ops.
class RpcMcpClientControl implements McpClientControl {
  /// Creates a control over the given client.
  RpcMcpClientControl(this._client);

  final RemoteRpcClient _client;

  @override
  Future<ApprovalMode> approvalMode() async {
    final data = await _client.call('mcp.client.approvalMode', const {});
    return ApprovalMode.fromWire(data['mode'] as String?);
  }

  @override
  Future<void> setApprovalMode(ApprovalMode mode) =>
      _client.call('mcp.client.setApprovalMode', {'mode': mode.wire});
}

/// The control the approval-mode setting drives, talking to the connected
/// host.
final mcpClientControlProvider = Provider<McpClientControl>(
  (ref) => RpcMcpClientControl(ref.watch(rpcClientProvider)),
);

/// The connected host's standing tool-approval posture. Defaults to
/// `always-ask` when the host exposes no `mcp.client.*` ops.
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
