import 'dart:async';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/mcp_config.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_server_port.dart';
import 'package:cc_mcp/src/mcp_request_handler.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';

/// Exception thrown when the MCP HTTP server fails to start or encounters a runtime error.
class McpServerException extends ServerException {
  /// Creates a new [McpServerException] with the error [message] and optional [cause].
  const McpServerException(super.message, {super.cause});
}

/// Loopback HTTP listener that exposes the MCP protocol over the Streamable
/// HTTP transport (POST /mcp for requests, GET /sse for server→client
/// notifications).
///
/// This is a thin socket binding around [McpRequestHandler] — all routing,
/// auth, CORS and SSE fan-out live there. The primary MCP surface rides the
/// main cc_server listener (mounted via the same handler); this standalone
/// listener remains for two cases:
///  * cc_server serving TLS in-process — local agent CLIs cannot validate the
///    host cert against 127.0.0.1, so dispatch keeps a plaintext loopback
///    companion;
///  * hosts with no main listener (unit tests, minimal embeddings).
class McpHttpServer implements McpServerPort {
  /// Creates a new [McpHttpServer] bound to [port] when started.
  ///
  /// [handler] is the request-handling core; when omitted one is created from
  /// [config]. Pass a shared instance so this listener and the main cc_server
  /// mount serve the same SSE clients and auth posture.
  McpHttpServer({
    required this.port,
    required McpToolDispatcher dispatcher,
    McpConfig config = const McpConfig(enabled: true),
    McpRequestHandler? handler,
    this.onRunningChanged,
  }) : handler =
           handler ?? McpRequestHandler(config: config, dispatcher: dispatcher);

  /// TCP port the listener binds on [start].
  final int port;

  /// The request-handling core every request is delegated to.
  final McpRequestHandler handler;

  /// Callback invoked whenever the server starts or stops.
  void Function({required bool running})? onRunningChanged;

  HttpServer? _server;
  bool _stopped = false;

  /// Whether the server is currently bound and listening.
  @override
  bool get isRunning => _server != null;

  /// Binds the HTTP server to [port] (loopback only) and begins listening.
  @override
  Future<void> start() async {
    _stopped = false;
    if (_server != null) {
      return;
    }
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      if (_stopped) {
        await server.close(force: true);
        return;
      }
      _server = server;
      _server!.listen(handler.handle);
      onRunningChanged?.call(running: true);
    } on SocketException catch (e) {
      throw McpServerException(
        'Port $port is already in use. '
        'Stop the existing server or free the port before starting.',
        cause: e,
      );
    }
  }

  /// Closes all connections, stops the server and resets state.
  @override
  Future<void> stop() async {
    _stopped = true;
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
    onRunningChanged?.call(running: false);
  }
}
