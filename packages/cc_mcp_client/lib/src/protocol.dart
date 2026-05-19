/// MCP protocol constants shared by the client transports and `McpClient`.
///
/// CC's *server* implements `2024-11-05` (see `cc_mcp`). The *client* advertises
/// a newer version on `initialize`; a well-behaved server negotiates down, so
/// advertising the later revision lets us talk to modern servers (Streamable
/// HTTP, resources, prompts) while still interoperating with older ones.
abstract final class McpProtocol {
  /// The protocol version the client advertises on `initialize`.
  static const String version = '2025-06-18';

  /// The client identity reported to servers.
  static const String clientName = 'control-center';

  /// The client version reported to servers.
  static const String clientVersion = '0.1.0';

  // ── Client → server methods ──

  /// Capability handshake.
  static const String initialize = 'initialize';

  /// Post-handshake notification.
  static const String initialized = 'notifications/initialized';

  /// List tools.
  static const String toolsList = 'tools/list';

  /// Call a tool.
  static const String toolsCall = 'tools/call';

  /// List resources.
  static const String resourcesList = 'resources/list';

  /// List resource templates.
  static const String resourceTemplatesList = 'resources/templates/list';

  /// Read a resource.
  static const String resourcesRead = 'resources/read';

  /// List prompts.
  static const String promptsList = 'prompts/list';

  /// Get a prompt.
  static const String promptsGet = 'prompts/get';

  /// Liveness check.
  static const String ping = 'ping';

  // ── Server → client notifications ──

  /// The server's tool list changed.
  static const String toolListChanged = 'notifications/tools/list_changed';

  /// The server's resource list changed.
  static const String resourceListChanged =
      'notifications/resources/list_changed';

  /// The server's prompt list changed.
  static const String promptListChanged =
      'notifications/prompts/list_changed';
}
