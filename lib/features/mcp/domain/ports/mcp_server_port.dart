/// Port for controlling an MCP server lifecycle.
abstract interface class McpServerPort {
  /// Starts the server.
  Future<void> start();
  /// Stops the server.
  Future<void> stop();
  /// Whether the server is currently running.
  bool get isRunning;
}

