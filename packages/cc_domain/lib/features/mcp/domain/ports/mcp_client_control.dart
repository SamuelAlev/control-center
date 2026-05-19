import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';

/// An immutable, platform-neutral snapshot of ONE external MCP server the host
/// connects to as a *client* (PRD 01).
///
/// This is the wire contract the settings UI reads — it carries no `dart:io`
/// types, so it is web-safe. The host maps its live `cc_mcp_client`
/// `McpServerStatusSnapshot` onto this DTO and ships it over the
/// `mcp.client.servers` RPC op; the thin client (desktop in-process OR web)
/// reconstructs it with `fromJson`. It is HOST-GLOBAL (the external servers are
/// a process-wide concern, not workspace data), so it carries no `workspaceId`.
class McpExternalServerInfo {
  /// Creates an [McpExternalServerInfo].
  const McpExternalServerInfo({
    required this.name,
    required this.transport,
    required this.lifecycle,
    required this.auth,
    this.toolCount = 0,
    this.resourceCount = 0,
    this.promptCount = 0,
    this.source,
    this.lastError,
  });

  /// Reconstructs the snapshot from the `mcp.client.servers` wire map.
  factory McpExternalServerInfo.fromJson(Map<String, dynamic> json) =>
      McpExternalServerInfo(
        name: json['name'] as String? ?? '',
        transport: json['transport'] as String? ?? 'stdio',
        lifecycle: json['lifecycle'] as String? ?? 'disabled',
        auth: json['auth'] as String? ?? 'none',
        toolCount: (json['tool_count'] as num?)?.toInt() ?? 0,
        resourceCount: (json['resource_count'] as num?)?.toInt() ?? 0,
        promptCount: (json['prompt_count'] as num?)?.toInt() ?? 0,
        source: json['source'] as String?,
        lastError: json['last_error'] as String?,
      );

  /// The server's configured name (its stable identifier in `mcp.client.*` ops).
  final String name;

  /// Transport wire string (`stdio` | `http` | `sse`).
  final String transport;

  /// Lifecycle wire string (`disabled` | `connecting` | `connected` | `failed`
  /// | `needs_auth` | `needs_client_registration` | `circuit_open`).
  final String lifecycle;

  /// Auth wire string (`none` | `oauth` | `header`). Drives whether the UI
  /// offers an authorize action.
  final String auth;

  /// Number of bridged tools (0 unless connected).
  final int toolCount;

  /// Number of bridged resources.
  final int resourceCount;

  /// Number of bridged prompts.
  final int promptCount;

  /// Where the config came from (discovery source: `claude`, `cursor`, …), or
  /// null for a hand-added server.
  final String? source;

  /// Last error message when [lifecycle] is `failed` / `needs_auth`.
  final String? lastError;

  /// Whether tools are live (the connection completed its handshake).
  bool get isConnected => lifecycle == 'connected';

  /// Whether the server is awaiting OAuth authorization.
  bool get needsAuth =>
      lifecycle == 'needs_auth' || lifecycle == 'needs_client_registration';

  /// Whether the server authenticates via OAuth (so the UI offers authorize).
  bool get usesOAuth => auth == 'oauth';

  /// The snake_case wire map the `mcp.client.servers` op returns.
  Map<String, dynamic> toJson() => {
    'name': name,
    'transport': transport,
    'lifecycle': lifecycle,
    'auth': auth,
    'tool_count': toolCount,
    'resource_count': resourceCount,
    'prompt_count': promptCount,
    if (source != null) 'source': source,
    if (lastError != null) 'last_error': lastError,
  };

  @override
  bool operator ==(Object other) =>
      other is McpExternalServerInfo &&
      other.name == name &&
      other.transport == transport &&
      other.lifecycle == lifecycle &&
      other.auth == auth &&
      other.toolCount == toolCount &&
      other.resourceCount == resourceCount &&
      other.promptCount == promptCount &&
      other.source == source &&
      other.lastError == lastError;

  @override
  int get hashCode => Object.hash(
    name,
    transport,
    lifecycle,
    auth,
    toolCount,
    resourceCount,
    promptCount,
    source,
    lastError,
  );
}

/// A platform-neutral control surface for the host's EXTERNAL MCP client — the
/// subsystem that connects to other MCP servers and bridges their tools into
/// the agent tool surface (PRD 01).
///
/// The external servers live in the HOST (the desktop in-process host or the
/// spawned `cc_server`), so the settings UI never talks to `cc_mcp_client`
/// directly — it drives this control over the `mcp.client.*` RPC ops. The same
/// two providers back desktop and web identically; when the connected host
/// exposes no client control (the ops are absent), the UI degrades to "external
/// MCP not available on this server".
abstract interface class McpClientControl {
  /// The external servers the host knows about (discovered + hand-added),
  /// with their live connection state.
  Future<List<McpExternalServerInfo>> servers();

  /// The host's standing tool-approval posture (governs the tier gate that
  /// decides whether a mutating/exec tool call auto-runs or prompts).
  Future<ApprovalMode> approvalMode();

  /// Sets the host's standing approval posture; takes effect immediately for
  /// subsequent tool calls.
  Future<void> setApprovalMode(ApprovalMode mode);

  /// Runs the interactive OAuth authorization for [serverName], then reconnects
  /// it. Only works on a host that can reach the user's browser + a local
  /// loopback callback (the desktop in-process host); a remote headless host
  /// rejects it and the caller surfaces the message.
  Future<void> authorize(String serverName);

  /// Reconnects [serverName] (resets the crash-storm circuit breaker), e.g.
  /// after a `failed` / `circuit_open` server is fixed.
  Future<void> reconnect(String serverName);
}
