import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';

/// The host's standing approval posture for tools bridged from external MCP
/// servers, driven over the `mcp.client.*` ops.
///
/// The servers themselves are configured per workspace (`mcpServers.*`,
/// `WorkspaceMcpServerControl`); this is the one server-wide setting they
/// share.
abstract interface class McpClientControl {
  /// The host's standing tool-approval posture (governs the tier gate that
  /// decides whether a mutating/exec tool call auto-runs or prompts).
  Future<ApprovalMode> approvalMode();

  /// Sets the host's standing approval posture; takes effect immediately for
  /// subsequent tool calls.
  Future<void> setApprovalMode(ApprovalMode mode);
}
