
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/mcp_config.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_server_port.dart';
import 'package:cc_mcp/src/log/cc_mcp_log.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';

/// Exception thrown when the MCP HTTP server fails to start or encounters a runtime error.
class McpServerException extends ServerException {
  /// Creates a new [McpServerException] with the error [message] and optional [cause].
  const McpServerException(super.message, {super.cause});
}

/// HTTP server that exposes the MCP protocol over the Streamable HTTP transport
/// (POST /mcp for requests, GET /sse for server→client notifications).
class McpHttpServer implements McpServerPort {
  /// Creates a new [McpHttpServer].
  McpHttpServer({
    required this.config,
    required this.dispatcher,
    this.onRunningChanged,
  }) : _activeConfig = config;

  /// Server configuration (port, auth, enabled).
  final McpConfig config;

  /// Dispatcher that routes incoming JSON-RPC tool requests.
  final McpToolDispatcher dispatcher;

  /// Callback invoked whenever the server starts or stops.
  void Function({required bool running})? onRunningChanged;

  HttpServer? _server;
  McpConfig _activeConfig;
  bool _stopped = false;

  /// Active SSE connections (for fan-out of server→client notifications).
  final Set<HttpResponse> _sseConnections = {};

  /// Whether the server is currently bound and listening.
  @override
  bool get isRunning => _server != null;

  /// Updates the active configuration (e.g. after async token load).
  void updateConfig(McpConfig config) {
    _activeConfig = config;
  }

  /// Binds the HTTP server to `config.port` and begins listening.
  @override
  Future<void> start() async {
    _stopped = false;
    if (!_activeConfig.enabled || _server != null) {
      return;
    }
    try {
      final server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        _activeConfig.port,
      );
      if (_stopped) {
        await server.close(force: true);
        return;
      }
      _server = server;
      _server!.listen(_handleRequest);
      onRunningChanged?.call(running: true);
    } on SocketException catch (e) {
      throw McpServerException(
        'Port ${_activeConfig.port} is already in use. '
        'Stop the existing server or free the port before starting.',
        cause: e,
      );
    }
  }

  /// Closes all connections, stops the server, and resets state.
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

  void _handleRequest(HttpRequest request) {
    _addCorsHeaders(request, request.response);

    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.noContent
        ..close();
      return;
    }

    // SSE connection (GET /sse) — auth check happens inside the handler
    // since we keep the connection open. No auth on this GET for now (token
    // auth is optional and the client can't send headers on EventSource).
    if (request.method == 'GET' && request.uri.path == '/sse') {
      _handleSse(request);
      return;
    }

    if (!_checkAuth(request)) {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..write(jsonEncode({'error': 'Unauthorized'}))
        ..close();
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/mcp') {
      _handlePost(request);
      return;
    }

    if (request.method == 'DELETE' && request.uri.path == '/mcp') {
      _handleDelete(request);
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..write(jsonEncode({'error': 'Not Found'}))
      ..close();
  }

  bool _checkAuth(HttpRequest request) {
    final token = _activeConfig.token;
    if (token == null || token.isEmpty) {
      return true;
    }
    final auth = request.headers.value('Authorization');
    if (auth == null) {
      return false;
    }
    final expected = 'Bearer $token';
    final a = Uint8List.fromList(utf8.encode(auth));
    final b = Uint8List.fromList(utf8.encode(expected));
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  void _addCorsHeaders(HttpRequest request, HttpResponse response) {
    final origin = request.headers.value('Origin') ?? '*';
    // Echo back whatever headers the client preflight-requested so browser
    // clients (MCP Inspector, web UIs) can send MCP-specific headers like
    // MCP-Protocol-Version, Mcp-Session-Id, Last-Event-ID without us having
    // to hard-code every variant.
    final requested = request.headers.value('Access-Control-Request-Headers');
    response.headers
      ..set('Access-Control-Allow-Origin', origin)
      ..set('Access-Control-Allow-Methods', 'POST, GET, DELETE, OPTIONS')
      ..set(
        'Access-Control-Allow-Headers',
        requested ??
            'Content-Type, Authorization, Accept, '
                'MCP-Protocol-Version, Mcp-Session-Id, Last-Event-ID',
      )
      // Inspector reads Mcp-Session-Id off responses to resume sessions.
      ..set('Access-Control-Expose-Headers', 'Mcp-Session-Id')
      ..set('Access-Control-Max-Age', '600');
  }

  /// Handles GET /sse — establishes an SSE connection for server→client
  /// notifications per the MCP Streamable HTTP transport (2025-03-26).
  ///
  /// Sends an initial `endpoint` event with the URL the client should POST
  /// requests to, then keeps the connection open for pushed notifications.
  void _handleSse(HttpRequest request) {
    final response = request.response;
    response.headers
      ..set('Content-Type', 'text/event-stream')
      ..set('Cache-Control', 'no-cache')
      ..set('Connection', 'keep-alive')
      ..set('Access-Control-Allow-Origin', '*');

    // Add to active connections for fan-out
    _sseConnections.add(response);
    CcMcpLog.i('MCP-HTTP', 'SSE client connected (${_sseConnections.length} active)');

    // Send the endpoint event — tells the client where to POST requests.
    // The URL is the same server on /mcp.
    response
      ..write('event: endpoint\n')
      ..write('data: /mcp\n')
      ..write('\n');
    // Flush immediately. Dart buffers HttpResponse writes until the buffer
    // fills or the response closes; an SSE stream never closes, so without an
    // explicit flush the `endpoint` event sits in the buffer and clients time
    // out during the handshake (e.g. "Body Timeout Error").
    unawaited(response.flush());

    response.done.then((_) {
      _sseConnections.remove(response);
      CcMcpLog.i(
        'MCP-HTTP',
        'SSE client disconnected (${_sseConnections.length} active)',
      );
    }).catchError((_) {
      _sseConnections.remove(response);
    });

    // Keep the connection alive with periodic heartbeats
    Timer? heartbeat;
    heartbeat = Timer.periodic(const Duration(seconds: 30), (timer) {
      try {
        response.write(': heartbeat\n\n');
        unawaited(response.flush());
      } catch (_) {
        timer.cancel();
        _sseConnections.remove(response);
      }
    });

    response.done.whenComplete(() {
      heartbeat?.cancel();
      _sseConnections.remove(response);
    });
  }

  /// Handles DELETE /mcp — terminates the MCP session per the Streamable
  /// HTTP transport spec.
  void _handleDelete(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.ok
      ..close();
  }

  Future<void> _handlePost(HttpRequest request) async {
    final sw = Stopwatch()..start();
    String label = 'POST /mcp';
    try {
      final body = await utf8.decodeStream(request);
      if (body.isEmpty) {
        CcMcpLog.w('MCP-HTTP', '$label empty body — 400');
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write(jsonEncode({'error': 'Empty body'}));
        unawaited(request.response.close());
        return;
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final rpcRequest = JsonRpcRequest.fromJson(json);
      label =
          'rpc#${rpcRequest.id ?? '-'} ${rpcRequest.method}'
          '${rpcRequest.method == 'tools/call' ? ' ${rpcRequest.params['name']}' : ''}';
      CcMcpLog.i('MCP-HTTP', '→ $label');

      final result = await dispatcher.handleRequest(rpcRequest);

      request.response.headers.contentType = ContentType(
        'application',
        'json',
        charset: 'utf-8',
      );
      if (result.isNotEmpty) {
        request.response.add(utf8.encode(jsonEncode(result)));
      } else {
        request.response.statusCode = HttpStatus.accepted;
      }
      await request.response.close();
      CcMcpLog.d('MCP-HTTP', '← $label ${sw.elapsedMilliseconds}ms');
    } on FormatException catch (e) {
      CcMcpLog.e('MCP-HTTP', '✗ $label parse error: $e', e);
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType(
          'application',
          'json',
          charset: 'utf-8',
        )
        ..add(
          utf8.encode(
            jsonEncode({
              'jsonrpc': '2.0',
              'error': {'code': -32700, 'message': 'Parse error'},
            }),
          ),
        );
      unawaited(request.response.close());
    } catch (e, st) {
      CcMcpLog.e('MCP-HTTP', '✗ $label internal error: $e', e, st);
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..headers.contentType = ContentType(
            'application',
            'json',
            charset: 'utf-8',
          )
          ..add(
            utf8.encode(
              jsonEncode({
                'jsonrpc': '2.0',
                'error': {'code': -32603, 'message': 'Internal error: $e'},
              }),
            ),
          );
        unawaited(request.response.close());
      } catch (_) {
        // Connection closed, nothing to do
      }
    }
  }
}
