/// Configuration for the MCP server.
class McpConfig {
  /// Creates a new [McpConfig].
  const McpConfig({required this.port, this.token, required this.enabled});

  /// TCP port the server listens on.
  final int port;
  /// Optional bearer token required for incoming requests.
  final String? token;
  /// Whether the server is enabled.
  final bool enabled;
}

