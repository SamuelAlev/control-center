import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/mcp_config.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/log/cc_mcp_log.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';

/// Transport-independent MCP request handler: the Streamable HTTP transport
/// routing (POST /mcp for requests, GET /sse for server→client notifications,
/// DELETE /mcp for session teardown, OPTIONS preflight), bearer-token auth,
/// CORS and SSE fan-out — decoupled from any socket binding.
///
/// One handler serves every listener the host mounts it on: the standalone
/// loopback `McpHttpServer` and the main cc_server HTTP listener (the
/// single-port topology, where cc_server routes `/mcp` + `/sse` to it) share
/// the same instance, so SSE clients on either listener receive the same
/// `tools/list_changed` fan-out and every request hits the same auth posture.
class McpRequestHandler {
  /// Creates a handler over [dispatcher] with the given auth [config].
  McpRequestHandler({required McpConfig config, required this.dispatcher})
    : _activeConfig = config;

  /// Dispatcher that routes incoming JSON-RPC tool requests.
  final McpToolDispatcher dispatcher;

  McpConfig _activeConfig;

  /// Active SSE connections (for fan-out of server→client notifications).
  final Set<HttpResponse> _sseConnections = {};

  /// Cap on concurrent SSE connections. Generous for real clients (an editor,
  /// the Inspector, a couple of agents), bounded against a peer that opens
  /// sockets in a loop.
  static const int _maxSseConnections = 32;

  /// Cap on a `POST /mcp` body. JSON-RPC tool calls are small; anything larger
  /// is abusive, and `utf8.decodeStream` would otherwise buffer all of it.
  static const int _maxPostBodyBytes = 4 * 1024 * 1024;

  /// Whether a bearer token is configured. The host's non-loopback guard
  /// reads this to fail closed: a tokenless MCP surface must never answer
  /// off-host clients (the pre-unification standalone listener bound
  /// loopback-only and mounting on a LAN/Tailscale listener must not widen
  /// that exposure silently).
  bool get hasToken {
    final token = _activeConfig.token;
    return token != null && token.isNotEmpty;
  }

  /// Updates the active configuration (e.g. after a token change). Takes
  /// effect on the next request — no rebind required.
  void updateConfig(McpConfig config) {
    _activeConfig = config;
  }

  /// Routes [request] to the MCP transport handlers. Unknown paths 404.
  Future<void> handle(HttpRequest request) async {
    _addCorsHeaders(request, request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      unawaited(request.response.close());
      return;
    }

    // SSE connection (GET /sse). This used to skip auth entirely, on the
    // grounds that `EventSource` cannot send an Authorization header — but
    // `hasToken` is the documented fail-closed posture for a non-loopback
    // mount, so an unauthenticated, uncapped, long-lived GET was a hole in it.
    // EventSource CAN carry a query parameter, so the token is accepted from
    // `?token=` as well as the header.
    if (request.method == 'GET' && request.uri.path == '/sse') {
      if (!_checkAuth(request, allowQueryToken: true)) {
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write(jsonEncode({'error': 'Unauthorized'}));
        unawaited(request.response.close());
        return;
      }
      _handleSse(request);
      return;
    }

    if (!_checkAuth(request)) {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..write(jsonEncode({'error': 'Unauthorized'}));
      unawaited(request.response.close());
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/mcp') {
      await _handlePost(request);
      return;
    }

    if (request.method == 'DELETE' && request.uri.path == '/mcp') {
      _handleDelete(request);
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..write(jsonEncode({'error': 'Not Found'}));
    unawaited(request.response.close());
  }

  /// Closes every open SSE connection (server stop). Idempotent.
  Future<void> close() async {
    for (final connection in _sseConnections.toList()) {
      try {
        await connection.close();
      } catch (_) {
        // Connection already gone.
      }
    }
    _sseConnections.clear();
  }

  /// Reads [request]'s body, refusing (null) once it exceeds [maxBytes].
  ///
  /// `utf8.decodeStream(request)` buffers whatever the peer sends, so an
  /// unauthenticated-adjacent endpoint with no cap is a memory-pressure
  /// primitive. Mirrors the SCIM/SAML/webhook readers in `LocalRpcServer`.
  static Future<List<int>?> _readBodyCapped(
    HttpRequest request,
    int maxBytes,
  ) async {
    // Declared over the cap: refuse without reading a byte.
    if (request.contentLength > maxBytes) {
      return null;
    }
    final chunks = <int>[];
    await for (final chunk in request) {
      chunks.addAll(chunk);
      if (chunks.length > maxBytes) {
        return null;
      }
    }
    return chunks;
  }

  /// A short, greppable id tying a scrubbed client-facing error to its log
  /// line (the same discipline `RemoteRpcSession` uses).
  static String _diagnosticId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  bool _checkAuth(HttpRequest request, {bool allowQueryToken = false}) {
    final token = _activeConfig.token;
    if (token == null || token.isEmpty) {
      return true;
    }
    var auth = request.headers.value('Authorization');
    if (auth == null && allowQueryToken) {
      final query = request.uri.queryParameters['token'];
      if (query != null && query.isNotEmpty) {
        auth = 'Bearer $query';
      }
    }
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
    if (_sseConnections.length >= _maxSseConnections) {
      // Each connection holds a socket AND a heartbeat timer for its lifetime,
      // so an unbounded set is a free resource-exhaustion primitive for any
      // peer that can reach the listener.
      CcMcpLog.w(
        'MCP-HTTP',
        'SSE connection refused — $_maxSseConnections already open',
      );
      response
        ..statusCode = HttpStatus.serviceUnavailable
        ..write(jsonEncode({'error': 'Too many SSE connections'}));
      unawaited(response.close());
      return;
    }
    // Disable dart:io's output buffering for the stream's lifetime. flush()
    // only drains the socket — it does NOT push data sitting in HttpResponse's
    // internal buffer, so with buffering on, SSE events accumulate until 8KB
    // or close and the client sees NOTHING (verified empirically: the endpoint
    // event never arrived). Every write below must hit the wire immediately.
    response.bufferOutput = false;
    response.headers
      ..set('Content-Type', 'text/event-stream')
      ..set('Cache-Control', 'no-cache')
      ..set('Connection', 'keep-alive')
      ..set('Access-Control-Allow-Origin', '*');

    // Add to active connections for fan-out
    _sseConnections.add(response);
    CcMcpLog.i(
      'MCP-HTTP',
      'SSE client connected (${_sseConnections.length} active)',
    );

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

    response.done
        .then((_) {
          _sseConnections.remove(response);
          CcMcpLog.i(
            'MCP-HTTP',
            'SSE client disconnected (${_sseConnections.length} active)',
          );
        })
        .catchError((_) {
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

  /// Broadcasts `notifications/tools/list_changed` to every connected SSE
  /// client. The host wires this to `McpToolRegistry.onToolsChanged` so
  /// spec-compliant clients re-list when the catalogue mutates (external
  /// servers bridged in, tools hot-reloaded) instead of serving a stale cache
  /// forever — `initialize` advertises `tools.listChanged: true`, so this is
  /// the emission that makes that advertisement true.
  void notifyToolsListChanged() {
    if (_sseConnections.isEmpty) {
      return;
    }
    final payload = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'notifications/tools/list_changed',
    });
    for (final connection in List.of(_sseConnections)) {
      try {
        connection
          ..write('event: message\n')
          ..write('data: $payload\n')
          ..write('\n');
        unawaited(connection.flush());
      } catch (_) {
        _sseConnections.remove(connection);
      }
    }
    CcMcpLog.i(
      'MCP-HTTP',
      'tools/list_changed → ${_sseConnections.length} SSE client(s)',
    );
  }

  /// Handles DELETE /mcp — terminates the MCP session per the Streamable
  /// HTTP transport spec.
  void _handleDelete(HttpRequest request) {
    request.response.statusCode = HttpStatus.ok;
    unawaited(request.response.close());
  }

  Future<void> _handlePost(HttpRequest request) async {
    final sw = Stopwatch()..start();
    String label = 'POST /mcp';
    try {
      final bytes = await _readBodyCapped(request, _maxPostBodyBytes);
      if (bytes == null) {
        CcMcpLog.w('MCP-HTTP', '$label body over cap — 413');
        request.response
          ..statusCode = HttpStatus.requestEntityTooLarge
          ..write(jsonEncode({'error': 'Request body too large'}));
        unawaited(request.response.close());
        return;
      }
      final body = utf8.decode(bytes, allowMalformed: true);
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

      final result = await dispatcher.handleScopedRequest(
        rpcRequest,
        scope: _scopeFromHeaders(request),
      );

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
      final diagnosticId = _diagnosticId();
      CcMcpLog.e(
        'MCP-HTTP',
        '✗ $label internal error [$diagnosticId]: $e',
        e,
        st,
      );
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
                'error': {
                  'code': -32603,
                  // Never echo the exception: it carries paths, SQL and auth
                  // detail to an HTTP client. The full error is in the log
                  // line above, keyed by this id.
                  'message': 'Internal error (ref: $diagnosticId)',
                },
              }),
            ),
          );
        unawaited(request.response.close());
      } catch (_) {
        // Connection closed, nothing to do
      }
    }
  }

  /// Builds the trusted identity scope from the `X-CC-*` headers dispatch
  /// writes into each agent's `.mcp.json`. Requests without them (MCP
  /// Inspector, user tooling) get no scope and arguments pass through
  /// verbatim. These headers ride the same bearer-token-authenticated,
  /// loopback-only channel as the request itself, so they are exactly as
  /// trustworthy as the call.
  static McpCallScope? _scopeFromHeaders(HttpRequest request) {
    String? header(String name) {
      final value = request.headers.value(name);
      return (value == null || value.isEmpty) ? null : value;
    }

    final scope = McpCallScope(
      workspaceId: header('X-CC-Workspace-Id'),
      agentId: header('X-CC-Agent-Id'),
      conversationId: header('X-CC-Conversation-Id'),
      spaceId: header('X-CC-Space-Id'),
    );
    return scope.isEmpty ? null : scope;
  }
}
