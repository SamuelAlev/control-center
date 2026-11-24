import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';

/// Whose a configured MCP server is, within its workspace.
enum McpServerScope {
  /// The workspace's: every run in it gets its tools. Admins configure it.
  workspace,

  /// One member's own: only the runs that member starts there get its tools.
  personal;

  /// The canonical wire string.
  String get wire => name;

  /// Parses [raw]; anything else is refused, never guessed.
  static McpServerScope fromWire(Object? raw) {
    for (final value in values) {
      if (value.wire == raw) {
        return value;
      }
    }
    throw McpServerDefinitionException.invalid('scope');
  }
}

/// A browser sign-in to an MCP server, as the client that started it sees it.
///
/// The browser comes back to this server, which shows a confirmation code;
/// only the person who began the attempt finishes it, by typing that code.
class McpServerAuthorization {
  /// Creates an authorization.
  const McpServerAuthorization({
    required this.attemptId,
    required this.url,
    required this.status,
    this.triesLeft = 0,
  });

  /// Reads the wire map [toJson] writes.
  factory McpServerAuthorization.fromJson(Map<String, dynamic> json) =>
      McpServerAuthorization(
        attemptId: json['attempt_id'] as String? ?? '',
        url: json['url'] as String? ?? '',
        status: McpServerAuthorizationStatus.fromWire(json['status']),
        triesLeft: (json['tries_left'] as num?)?.toInt() ?? 0,
      );

  /// The opaque handle of the attempt.
  final String attemptId;

  /// Where to send the browser.
  final String url;

  /// Where the attempt stands.
  final McpServerAuthorizationStatus status;

  /// How many more codes a [McpServerAuthorizationStatus.wrongCode] attempt
  /// accepts.
  final int triesLeft;

  /// The wire map.
  Map<String, dynamic> toJson() => {
    'attempt_id': attemptId,
    'url': url,
    'status': status.wire,
    'tries_left': triesLeft,
  };
}

/// Where an [McpServerAuthorization] stands.
enum McpServerAuthorizationStatus {
  /// Waiting for the browser and the confirmation code.
  pending('pending'),

  /// The last code was not the one the browser showed; it can be retried.
  wrongCode('wrong_code'),

  /// Signed in: the server reconnected with the new token.
  done('done'),

  /// Over: expired, refused by the provider, or out of tries.
  failed('failed');

  const McpServerAuthorizationStatus(this.wire);

  /// The canonical wire string.
  final String wire;

  /// Parses [raw]; anything unknown is [failed].
  static McpServerAuthorizationStatus fromWire(Object? raw) =>
      values.firstWhere((v) => v.wire == raw, orElse: () => failed);
}

/// One MCP server configured in a workspace, as the settings UI reads it:
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

  /// Whether the server is still being dialled, so its state is about to
  /// change.
  bool get isConnecting => lifecycle == 'connecting';

  /// Whether it waits for a browser sign-in before its tools can be listed.
  bool get needsAuth =>
      lifecycle == 'needs_auth' || lifecycle == 'needs_client_registration';

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

/// Drives the MCP servers configured in a workspace over the `mcpServers.*`
/// ops: the workspace's ([McpServerScope.workspace]) and the caller's own
/// ([McpServerScope.personal]).
///
/// Workspace admins add, change and remove the workspace's; every member does
/// the same with their own. The server owner approves the ones that need the
/// host ([WorkspaceMcpServerEntry.hostApproved]). The server decides who is
/// acting from the session, never from an argument.
abstract interface class WorkspaceMcpServerControl {
  /// The servers of [scope] in [workspaceId], with their live state.
  Future<List<WorkspaceMcpServerEntry>> list(
    String workspaceId,
    McpServerScope scope,
  );

  /// Adds or changes a server of [scope] in [workspaceId] and returns it as
  /// stored.
  Future<WorkspaceMcpServerEntry> save(
    String workspaceId,
    McpServerScope scope,
    McpServerDraft draft,
  );

  /// Removes server [id] of [scope] in [workspaceId], its stored values and
  /// its sign-in.
  Future<void> delete(String workspaceId, McpServerScope scope, String id);

  /// Records the server owner's approval of the workspace's server [id] as
  /// it stands.
  Future<WorkspaceMcpServerEntry> approve(String workspaceId, String id);

  /// Reconnects server [id], resetting its crash-storm breaker.
  Future<void> reconnect(String workspaceId, McpServerScope scope, String id);

  /// Starts a browser sign-in to server [id] and returns where to send the
  /// browser.
  Future<McpServerAuthorization> beginAuthorization(
    String workspaceId,
    McpServerScope scope,
    String id,
  );

  /// Finishes [attemptId], begun on a server of [scope], with the
  /// confirmation [code] the browser showed.
  Future<McpServerAuthorization> completeAuthorization(
    String workspaceId,
    McpServerScope scope,
    String attemptId,
    String code,
  );
}
