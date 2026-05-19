/// An immutable snapshot of the MCP HTTP server's control state.
///
/// Read by the settings UI to render the status badge + the start-on-launch /
/// port / token controls. It is HOST-GLOBAL (not workspace-scoped): the MCP
/// server is a single process-wide listener, so this carries no `workspaceId`.
/// The thin client receives it over the `mcp.status` RPC op (the desktop builds
/// it straight from its in-process server); the wire shape is the snake_case
/// JSON in [toJson]/[fromJson].
class McpServerStatus {
  /// Creates an [McpServerStatus] snapshot.
  const McpServerStatus({
    required this.running,
    required this.port,
    required this.enabled,
    required this.hasToken,
  });

  /// Reconstructs the snapshot from the `mcp.status` wire map.
  factory McpServerStatus.fromJson(Map<String, dynamic> json) =>
      McpServerStatus(
        running: json['running'] as bool? ?? false,
        port: (json['port'] as num?)?.toInt() ?? 9020,
        enabled: json['enabled'] as bool? ?? false,
        hasToken: json['has_token'] as bool? ?? false,
      );

  /// Whether the server is currently bound and listening.
  final bool running;

  /// TCP port the server listens on (when started).
  final int port;

  /// Whether the server is configured to start on app/server launch.
  final bool enabled;

  /// Whether a bearer auth token is configured (the token value itself is never
  /// sent to the client — only this boolean).
  final bool hasToken;

  /// The wire map (snake_case) the `mcp.status` op returns.
  Map<String, dynamic> toJson() => {
    'running': running,
    'port': port,
    'enabled': enabled,
    'has_token': hasToken,
  };

  @override
  bool operator ==(Object other) =>
      other is McpServerStatus &&
      other.running == running &&
      other.port == port &&
      other.enabled == enabled &&
      other.hasToken == hasToken;

  @override
  int get hashCode => Object.hash(running, port, enabled, hasToken);

  @override
  String toString() =>
      'McpServerStatus(running: $running, port: $port, '
      'enabled: $enabled, hasToken: $hasToken)';
}

/// A platform-neutral control surface for the MCP HTTP server, read by the
/// settings section. On the desktop it is backed by the in-process server +
/// its config providers; on the web/thin client it is backed by the `mcp.*`
/// RPC ops. The section watches [watchStatus] and calls the mutators, so it is
/// identical on both platforms.
abstract interface class McpServerControl {
  /// The current control snapshot (running / port / enabled / hasToken).
  Future<McpServerStatus> status();

  /// Starts the server. A no-op if it is already running.
  Future<void> start();

  /// Stops the server. A no-op if it is already stopped.
  Future<void> stop();

  /// Sets whether the server starts on launch (and starts/stops to match).
  Future<void> setEnabled({required bool enabled});

  /// Sets the TCP port the server listens on.
  Future<void> setPort(int port);

  /// Sets (or clears, when null/empty) the bearer auth token.
  Future<void> setToken(String? token);
}
