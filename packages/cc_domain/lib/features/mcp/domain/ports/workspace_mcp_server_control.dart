import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';

/// One MCP server configured for a workspace, as the settings UI reads it:
/// the definition plus its live connection state.
///
/// Wire contract of the `mcpServers.*` ops; web-safe.
class WorkspaceMcpServerEntry {
  /// Creates an entry.
  const WorkspaceMcpServerEntry({
    required this.definition,
    required this.lifecycle,
    required this.hostApproved,
    this.toolCount = 0,
    this.lastError,
  });

  /// Reads the wire map [toJson] writes.
  factory WorkspaceMcpServerEntry.fromJson(Map<String, dynamic> json) =>
      WorkspaceMcpServerEntry(
        definition: McpServerDefinition.fromJson(
          (json['definition'] as Map).cast<String, dynamic>(),
        ),
        lifecycle: json['lifecycle'] as String? ?? 'disabled',
        hostApproved: json['host_approved'] as bool? ?? false,
        toolCount: (json['tool_count'] as num?)?.toInt() ?? 0,
        lastError: json['last_error'] as String?,
      );

  /// Lifecycle of a stdio server the current server owner has not approved:
  /// it is never started.
  static const String awaitingApproval = 'awaiting_approval';

  /// The configuration.
  final McpServerDefinition definition;

  /// `disabled`, `connecting`, `connected`, `failed`, `needs_auth`,
  /// `circuit_open` or [awaitingApproval].
  final String lifecycle;

  /// Whether the current server owner approved it as it stands. A stdio
  /// server runs only when approved; a remote one reaches only public
  /// addresses until then.
  final bool hostApproved;

  /// Tools it bridged (0 unless connected).
  final int toolCount;

  /// The last connection error, already sanitised by the server.
  final String? lastError;

  /// Whether its tools are live.
  bool get isConnected => lifecycle == 'connected';

  /// Whether it waits on the server owner before it can start.
  bool get isAwaitingApproval => lifecycle == awaitingApproval;

  /// The wire map.
  Map<String, dynamic> toJson() => {
    'definition': definition.toJson(),
    'lifecycle': lifecycle,
    'host_approved': hostApproved,
    'tool_count': toolCount,
    if (lastError != null) 'last_error': lastError,
  };

  @override
  bool operator ==(Object other) =>
      other is WorkspaceMcpServerEntry &&
      other.definition == definition &&
      other.lifecycle == lifecycle &&
      other.hostApproved == hostApproved &&
      other.toolCount == toolCount &&
      other.lastError == lastError;

  @override
  int get hashCode =>
      Object.hash(definition, lifecycle, hostApproved, toolCount, lastError);
}

/// Drives a workspace's configured MCP servers over the `mcpServers.*` ops.
///
/// Workspace admins add, change and remove them; the server owner approves
/// the ones that need the host ([WorkspaceMcpServerEntry.hostApproved]). The
/// server decides who is acting from the session, never from an argument.
abstract interface class WorkspaceMcpServerControl {
  /// The servers configured in [workspaceId], with their live state.
  Future<List<WorkspaceMcpServerEntry>> list(String workspaceId);

  /// Adds or changes a server of [workspaceId] and returns it as stored.
  Future<WorkspaceMcpServerEntry> save(
    String workspaceId,
    McpServerDraft draft,
  );

  /// Removes server [id] of [workspaceId] and its stored values.
  Future<void> delete(String workspaceId, String id);

  /// Records the server owner's approval of server [id] as it stands.
  Future<WorkspaceMcpServerEntry> approve(String workspaceId, String id);

  /// Reconnects server [id], resetting its crash-storm breaker.
  Future<void> reconnect(String workspaceId, String id);
}
