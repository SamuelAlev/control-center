import 'dart:async';

/// A bidirectional JSON-RPC frame pipe to one external MCP server.
///
/// The transport is deliberately dumb: it moves *raw* JSON-RPC frames (decoded
/// maps) in both directions and reports when the underlying channel dies. All
/// protocol logic — request/response correlation, `initialize`, capability
/// negotiation, tool listing — lives one layer up in `McpClient`, so the three
/// concrete transports (stdio / Streamable HTTP / SSE) only differ in how bytes
/// flow.
abstract interface class McpTransport {
  /// Opens the channel (spawns the process / dials the URL). Throws
  /// [McpTransportException] on failure.
  Future<void> start();

  /// Sends a raw JSON-RPC frame ([message] is a request or a notification).
  /// For requests, the response arrives later on [incoming]; correlation is
  /// the caller's job (it set the `id`).
  Future<void> send(Map<String, dynamic> message);

  /// Every frame the server sends us: responses to our requests, server→client
  /// notifications, and server→client requests (sampling/elicitation/etc.).
  Stream<Map<String, dynamic>> get incoming;

  /// Completes when the channel closes for any reason (process exit, stream
  /// EOF, network drop). Never completes with an error.
  Future<void> get done;

  /// Tears the channel down. Idempotent.
  Future<void> close();
}

/// Raised when a transport cannot open or has died irrecoverably.
class McpTransportException implements Exception {
  /// Creates an [McpTransportException].
  const McpTransportException(this.message, {this.cause});

  /// Human-readable failure description.
  final String message;

  /// The wrapped lower-level error, if any.
  final Object? cause;

  @override
  String toString() => 'McpTransportException: $message'
      '${cause != null ? ' ($cause)' : ''}';
}
