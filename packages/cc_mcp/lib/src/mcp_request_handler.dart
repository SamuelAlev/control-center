import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/log/cc_mcp_log.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';

/// Transport-independent MCP request handler: the Streamable HTTP transport
/// routing (POST /mcp for requests, GET /sse for server→client notifications,
/// DELETE /mcp for session teardown, OPTIONS preflight), caller
/// authentication, CORS and SSE fan-out — decoupled from any socket binding.
///
/// Every request answers to one of two callers, loopback included:
///  * an agent run, proven by its live run secret ([McpCallScope.runGrantHeader])
///    from a loopback peer. Its scope is the gateway's attested grant and
///    nothing the request says;
///  * the server owner's own tooling, proven by the server's MCP token
///    (`Authorization: Bearer`). It carries no scope.
///
/// Before either is checked, a request a web page could have made is refused:
/// a foreign `Origin`, a `Host` that is not this listener's loopback address
/// or the server's public host (DNS rebinding), or a POST that is not JSON.
///
/// One handler serves every listener the host mounts it on: the standalone
/// loopback `McpHttpServer` and the main cc_server HTTP listener (the
/// single-port topology, where cc_server routes `/mcp` + `/sse` to it) share
/// the same instance, so SSE clients on either listener receive the same
/// `tools/list_changed` fan-out and every request hits the same auth posture.
class McpRequestHandler {
  /// Creates a handler over [dispatcher] that accepts the server MCP
  /// [token] and the run secrets [attestRun] proves.
  ///
  /// [streamAfter] and [streamHeartbeat] tune streamed `tools/call` replies;
  /// see [defaultStreamAfter].
  McpRequestHandler({
    required String token,
    required this.dispatcher,
    this.agentRoutes,
    this.attestRun,
    this.publicHosts,
    this.streamAfter = defaultStreamAfter,
    this.streamHeartbeat = defaultStreamHeartbeat,
  }) : _token = _checkedToken(token);

  /// Dispatcher that routes incoming JSON-RPC tool requests.
  final McpToolDispatcher dispatcher;

  /// Serves `/agent/…` — the agent run gateway (push proxy, Claude Code hook)
  /// that sandboxed agents reach on the same loopback port as MCP. It
  /// authenticates with its own per-run secret and refuses non-loopback
  /// callers itself, so the MCP bearer token does not apply. Null 404s them.
  final Future<void> Function(HttpRequest request)? agentRoutes;

  /// The scope a live run's secret proves, or null for a secret that names no
  /// run. Null means this server can attest nobody.
  final McpCallScope? Function(String secret)? attestRun;

  /// The host names, besides this listener's loopback address, that a request
  /// may name in its `Host` header: the server's configured public host. Read
  /// per request. Null or empty means loopback only.
  final Iterable<String> Function()? publicHosts;

  String _token;

  /// Active SSE connections (for fan-out of server→client notifications).
  final Set<HttpResponse> _sseConnections = {};

  /// Cap on concurrent SSE connections. Generous for real clients (an editor,
  /// the Inspector, a couple of agents), bounded against a peer that opens
  /// sockets in a loop.
  static const int _maxSseConnections = 32;

  /// Cap on a `POST /mcp` body. JSON-RPC tool calls are small; anything larger
  /// is abusive, and `utf8.decodeStream` would otherwise buffer all of it.
  static const int _maxPostBodyBytes = 4 * 1024 * 1024;

  /// How long a `tools/call` may run before its reply becomes an SSE stream
  /// ([defaultStreamAfter] unless a test shortens it).
  final Duration streamAfter;

  /// Keep-alive cadence on a streamed `tools/call` reply. Also how quickly a
  /// write notices a peer that vanished without closing its socket.
  final Duration streamHeartbeat;

  /// How long a `tools/call` may run before its reply becomes an SSE stream.
  ///
  /// Claude Code abandons a plain-JSON reply after 60 seconds ("The operation
  /// timed out.") without sending `notifications/cancelled`, while a reply
  /// whose headers are out and whose stream carries keep-alives is awaited
  /// for as long as the tool takes (verified against Claude Code 2.1.291). A
  /// tool that blocks on a human — `ask_user`, an approval — easily outlasts
  /// that, so the slow ones stream. Quick calls keep the plain JSON reply.
  static const Duration defaultStreamAfter = Duration(seconds: 5);

  /// Default for [streamHeartbeat].
  static const Duration defaultStreamHeartbeat = Duration(seconds: 15);

  /// Waits for a streamed reply's final bytes to leave before the socket is
  /// torn down regardless.
  static const Duration _streamFlushTimeout = Duration(seconds: 10);

  /// In-flight `tools/call` requests, keyed by [_callKey], completed when the
  /// caller stops waiting (`notifications/cancelled` or a closed stream).
  final Map<String, Completer<void>> _inFlightCalls = {};

  /// The request headers a browser may send on a cross-origin call from a
  /// loopback page (the MCP Inspector). Fixed: a requested header is never
  /// echoed back.
  static const String _allowedHeaders =
      'Content-Type, Authorization, Accept, MCP-Protocol-Version, '
      'Mcp-Session-Id, Last-Event-ID';

  /// The host names a loopback request may carry.
  static const Set<String> _loopbackHosts = {'localhost', '127.0.0.1', '::1'};

  /// Replaces the server's MCP token (a rotation). Takes effect on the next
  /// request — no rebind required.
  void updateToken(String token) {
    _token = _checkedToken(token);
  }

  static String _checkedToken(String token) {
    if (token.isEmpty) {
      throw ArgumentError.value(token, 'token', 'must not be empty');
    }
    return token;
  }

  /// Whether [path] is served by this handler: the MCP transport plus the
  /// [agentRoutes] under `/agent/`.
  static bool serves(String path) =>
      path == '/mcp' || path == '/sse' || path.startsWith('/agent/');

  /// Routes [request] to the MCP transport handlers. Unknown paths 404.
  Future<void> handle(HttpRequest request) async {
    final agent = agentRoutes;
    if (agent != null && request.uri.path.startsWith('/agent/')) {
      await agent(request);
      return;
    }

    final refusal = _browserRefusal(request);
    if (refusal != null) {
      CcMcpLog.w(
        'MCP-HTTP',
        'refused ${request.method} ${request.uri.path}: '
            '$refusal',
      );
      request.response
        ..statusCode = refusal == _unsupportedMediaType
            ? HttpStatus.unsupportedMediaType
            : HttpStatus.forbidden
        ..write(jsonEncode({'error': refusal}));
      unawaited(request.response.close());
      return;
    }

    _addCorsHeaders(request, request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      unawaited(request.response.close());
      return;
    }

    final caller = _authenticate(request);
    if (caller == null) {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..write(jsonEncode({'error': 'Unauthorized'}));
      unawaited(request.response.close());
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/sse') {
      _handleSse(request);
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/mcp') {
      await _handlePost(request, caller.scope);
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

  static const String _unsupportedMediaType =
      'A POST to /mcp must be application/json';

  /// Why [request] is refused before authentication, or null to go on.
  ///
  /// These stop a web page in a browser on this machine: it cannot choose its
  /// `Origin`, it reaches loopback through a rebound DNS name only with that
  /// name in `Host`, and a form or `no-cors` fetch cannot send JSON.
  String? _browserRefusal(HttpRequest request) {
    final origin = request.headers.value('Origin');
    if (origin != null && !isLoopbackOrigin(origin)) {
      return 'Cross-origin requests are not accepted';
    }
    if (!_hostAllowed(request)) {
      return 'Unknown host';
    }
    if (request.method == 'POST' &&
        request.headers.contentType?.mimeType != 'application/json') {
      return _unsupportedMediaType;
    }
    return null;
  }

  /// Whether [origin] is a page served from this machine's loopback address
  /// (`http://localhost`, `http://127.0.0.1` or `http://[::1]`, any port).
  static bool isLoopbackOrigin(String origin) {
    final uri = Uri.tryParse(origin);
    return uri != null &&
        uri.scheme == 'http' &&
        uri.path.isEmpty &&
        !uri.hasQuery &&
        _loopbackHosts.contains(uri.host.toLowerCase());
  }

  /// Whether the `Host` header names this listener on loopback, or the
  /// server's public host.
  bool _hostAllowed(HttpRequest request) {
    final raw = request.headers.value(HttpHeaders.hostHeader);
    if (raw == null || raw.isEmpty) {
      return false;
    }
    final Uri uri;
    try {
      uri = Uri.parse('http://$raw');
    } on FormatException {
      return false;
    }
    final host = uri.host.toLowerCase();
    if (_loopbackHosts.contains(host)) {
      return uri.port == request.connectionInfo?.localPort;
    }
    final public = publicHosts?.call() ?? const <String>[];
    return public.any((h) => h.isNotEmpty && h.toLowerCase() == host);
  }

  /// The caller [request] proves, or null to refuse it.
  ///
  /// A run secret is checked first and alone: one that names no live run, or
  /// arrives from off this host, is refused even if a token is also sent.
  _Caller? _authenticate(HttpRequest request) {
    final secret = request.headers.value(McpCallScope.runGrantHeader);
    if (secret != null) {
      final loopback =
          request.connectionInfo?.remoteAddress.isLoopback ?? false;
      final scope = loopback ? attestRun?.call(secret) : null;
      final ws = scope?.workspaceId;
      if (scope == null || !scope.attested || ws == null || ws.isEmpty) {
        return null;
      }
      return _Caller(scope);
    }
    final auth = request.headers.value(HttpHeaders.authorizationHeader);
    if (auth != null && _equalsConstantTime(auth, 'Bearer $_token')) {
      return const _Caller(null);
    }
    return null;
  }

  static bool _equalsConstantTime(String given, String expected) {
    final a = Uint8List.fromList(utf8.encode(given));
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

  /// CORS for a page on this machine's loopback address (the MCP Inspector).
  /// Any other origin was refused already; a request without one is not a
  /// browser's cross-origin call and gets no CORS headers.
  void _addCorsHeaders(HttpRequest request, HttpResponse response) {
    final origin = request.headers.value('Origin');
    if (origin == null) {
      return;
    }
    response.headers
      ..set('Access-Control-Allow-Origin', origin)
      ..set('Vary', 'Origin')
      ..set('Access-Control-Allow-Methods', 'POST, GET, DELETE, OPTIONS')
      ..set('Access-Control-Allow-Headers', _allowedHeaders)
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
      ..set('Connection', 'keep-alive');

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

  Future<void> _handlePost(HttpRequest request, McpCallScope? scope) async {
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

      if (rpcRequest.method == 'notifications/cancelled') {
        _cancelCall(request, rpcRequest.params['requestId']);
        request.response.statusCode = HttpStatus.accepted;
        await request.response.close();
        return;
      }

      if (rpcRequest.method == 'tools/call' && rpcRequest.id != null) {
        await _handleToolsCall(request, rpcRequest, scope, label, sw);
        return;
      }

      final result = await dispatcher.handleScopedRequest(
        rpcRequest,
        scope: scope,
      );
      await _writeJson(request, result, label, sw);
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

  Future<void> _writeJson(
    HttpRequest request,
    Map<String, dynamic> result,
    String label,
    Stopwatch sw,
  ) async {
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
  }

  /// Runs a `tools/call`, telling the tool when its caller stops waiting.
  ///
  /// A call that settles within [streamAfter] answers with plain JSON. A
  /// slower one, from a client that accepts `text/event-stream`, switches to
  /// a streamed reply (see [defaultStreamAfter] for why).
  Future<void> _handleToolsCall(
    HttpRequest request,
    JsonRpcRequest rpcRequest,
    McpCallScope? scope,
    String label,
    Stopwatch sw,
  ) async {
    final abandoned = Completer<void>();
    final key = _callKey(request, rpcRequest.id);
    _inFlightCalls[key] = abandoned;
    try {
      var settled = false;
      final pending = dispatcher
          .handleScopedRequest(
            rpcRequest,
            scope: scope,
            abandoned: abandoned.future,
          )
          .whenComplete(() => settled = true);

      if (_acceptsEventStream(request)) {
        final streamAt = Completer<void>();
        final timer = Timer(streamAfter, streamAt.complete);
        await Future.any<void>([
          pending.then((_) {}, onError: (Object _) {}),
          streamAt.future,
        ]);
        timer.cancel();
        if (!settled) {
          await _streamToolsCall(
            request,
            rpcRequest,
            pending,
            abandoned,
            label,
            sw,
          );
          return;
        }
      }
      await _writeJson(request, await pending, label, sw);
    } finally {
      if (identical(_inFlightCalls[key], abandoned)) {
        _inFlightCalls.remove(key);
      }
    }
  }

  /// Streams the reply to a slow `tools/call` as SSE: keep-alives (progress
  /// notifications when the caller sent a `progressToken`) until the tool
  /// finishes, then the JSON-RPC response as one `message` event.
  ///
  /// The socket is detached from dart:io's response because an open
  /// `HttpResponse` never reports a peer that hung up: `done` stays pending
  /// and a flush after the hang-up never completes. On the raw socket the
  /// peer's close ends the read side, which is the moment the caller stopped
  /// waiting. The body is delimited by closing the connection.
  Future<void> _streamToolsCall(
    HttpRequest request,
    JsonRpcRequest rpcRequest,
    Future<Map<String, dynamic>> pending,
    Completer<void> abandoned,
    String label,
    Stopwatch sw,
  ) async {
    // Detached below; the socket it hands over is destroyed once the reply
    // is out.
    // ignore: close_sinks
    final response = request.response
      ..statusCode = HttpStatus.ok
      ..persistentConnection = false;
    response.headers
      ..contentType = ContentType('text', 'event-stream', charset: 'utf-8')
      ..chunkedTransferEncoding = false
      ..set('Cache-Control', 'no-cache');
    final socket = await response.detachSocket();
    CcMcpLog.i(
      'MCP-HTTP',
      '⇢ $label streaming after ${sw.elapsedMilliseconds}ms',
    );

    var open = true;
    var finished = false;
    void hangUp() {
      if (!open) {
        return;
      }
      open = false;
      if (!finished) {
        CcMcpLog.w(
          'MCP-HTTP',
          '✗ $label caller hung up after ${sw.elapsedMilliseconds}ms',
        );
        if (!abandoned.isCompleted) {
          abandoned.complete();
        }
      }
    }

    void send(String chunk) {
      if (!open) {
        return;
      }
      try {
        socket.add(utf8.encode(chunk));
      } catch (_) {
        hangUp();
      }
    }

    socket.listen(
      (_) {},
      onDone: hangUp,
      onError: (Object _) => hangUp(),
      cancelOnError: true,
    );
    unawaited(socket.done.then((_) {}, onError: (Object _) => hangUp()));

    final meta = rpcRequest.params['_meta'];
    final progressToken = meta is Map ? meta['progressToken'] : null;
    var progress = 0;
    final heartbeat = Timer.periodic(streamHeartbeat, (_) {
      if (progressToken == null) {
        send(': keep-alive\n\n');
        return;
      }
      progress++;
      send(
        _sseMessage({
          'jsonrpc': '2.0',
          'method': 'notifications/progress',
          'params': {
            'progressToken': progressToken,
            'progress': progress,
            'message': 'Still running',
          },
        }),
      );
    });

    Map<String, dynamic> result;
    try {
      result = await pending;
    } catch (e, st) {
      final diagnosticId = _diagnosticId();
      CcMcpLog.e(
        'MCP-HTTP',
        '✗ $label internal error [$diagnosticId]: $e',
        e,
        st,
      );
      result = {
        'jsonrpc': '2.0',
        'id': rpcRequest.id,
        'error': {
          'code': -32603,
          'message': 'Internal error (ref: $diagnosticId)',
        },
      };
    } finally {
      finished = true;
      heartbeat.cancel();
    }

    if (open) {
      send(_sseMessage(result));
      CcMcpLog.d('MCP-HTTP', '← $label ${sw.elapsedMilliseconds}ms (stream)');
    }
    try {
      await socket.flush().timeout(_streamFlushTimeout);
    } catch (_) {
      // The peer is gone or not reading; nothing left to deliver.
    }
    socket.destroy();
  }

  static String _sseMessage(Map<String, dynamic> payload) =>
      'event: message\ndata: ${jsonEncode(payload)}\n\n';

  /// Whether the client takes a streamed reply. The Streamable HTTP transport
  /// requires clients to accept both `application/json` and
  /// `text/event-stream`; one that does not gets plain JSON however long the
  /// call runs.
  static bool _acceptsEventStream(HttpRequest request) =>
      (request.headers[HttpHeaders.acceptHeader] ?? const <String>[]).any(
        (value) => value.toLowerCase().contains('text/event-stream'),
      );

  /// Completes the in-flight call a `notifications/cancelled` names.
  void _cancelCall(HttpRequest request, Object? requestId) {
    if (requestId == null) {
      return;
    }
    final abandoned = _inFlightCalls.remove(_callKey(request, requestId));
    if (abandoned != null && !abandoned.isCompleted) {
      CcMcpLog.i('MCP-HTTP', 'rpc#$requestId cancelled by the caller');
      abandoned.complete();
    }
  }

  /// Identifies a JSON-RPC request within its caller. Request ids are unique
  /// per client, not per server: every agent counts from zero. The MCP session
  /// id names the client when it sends one; otherwise the run secret does.
  static String _callKey(HttpRequest request, Object? id) {
    final caller =
        request.headers.value('Mcp-Session-Id') ??
        request.headers.value(McpCallScope.runGrantHeader) ??
        '';
    return '$caller#${jsonEncode(id)}';
  }
}

/// Who a request proved to be: an agent run ([scope] is its attested grant)
/// or the server owner's tooling ([scope] is null).
final class _Caller {
  const _Caller(this.scope);

  final McpCallScope? scope;
}
