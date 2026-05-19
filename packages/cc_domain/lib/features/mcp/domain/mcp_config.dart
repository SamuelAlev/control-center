/// Configuration for the MCP server.
///
/// Carries no port: the MCP surface rides the main cc_server HTTP listener
/// (`POST /mcp`, `GET /sse` on the server port — default 9030), so there is
/// nothing left to configure. The only remaining listener with a port of its
/// own is the loopback companion cc_server keeps when it serves TLS
/// in-process (local agent CLIs cannot validate the host cert against
/// 127.0.0.1); it binds the historic default 9020.
class McpConfig {
  /// Creates a new [McpConfig].
  const McpConfig({this.token, required this.enabled});

  /// Optional bearer token required for incoming requests.
  final String? token;

  /// Whether the server is enabled.
  final bool enabled;
}
