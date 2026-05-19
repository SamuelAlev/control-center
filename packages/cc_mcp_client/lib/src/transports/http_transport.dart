import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_mcp_client/src/config/mcp_server_config.dart';
import 'package:cc_mcp_client/src/protocol.dart';
import 'package:cc_mcp_client/src/transports/mcp_transport.dart';
import 'package:cc_mcp_client/src/transports/sse_parser.dart';

/// Supplies dynamic auth headers (e.g. a fresh OAuth `Authorization: Bearer`)
/// merged over the config's static headers on every request. Returns an empty
/// map when no auth is configured.
typedef AuthHeaderProvider = Future<Map<String, String>> Function();

/// The Streamable HTTP transport (MCP `2025-03-26`+).
///
/// Each client→server message is a `POST` of a JSON-RPC frame. The server may
/// answer inline as `application/json` (one frame) or as a `text/event-stream`
/// (the reply plus any piggy-backed server→client messages). After the
/// `initialize` round-trip captures an `Mcp-Session-Id`, an optional standalone
/// `GET` SSE stream carries unsolicited server→client notifications
/// (tool-list-changed, etc.). A `401`/`403` is surfaced as an
/// [McpTransportException] so the connection manager can flip the server to
/// `needs_auth`.
class StreamableHttpTransport implements McpTransport {
  /// Creates a [StreamableHttpTransport] for [config] (http config).
  StreamableHttpTransport(this.config, {AuthHeaderProvider? authHeaderProvider})
    : _authHeaderProvider = authHeaderProvider,
      assert(
        config.transport == McpTransportKind.http,
        'StreamableHttpTransport requires an http config',
      );

  /// The server config (url, headers, timeout).
  final McpServerConfig config;
  final AuthHeaderProvider? _authHeaderProvider;

  final _httpClient = HttpClient();
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _done = Completer<void>();
  String? _sessionId;
  bool _serverStreamOpen = false;
  bool _closed = false;

  Uri get _uri => Uri.parse(config.url!);

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> start() async {
    _httpClient.connectionTimeout = const Duration(seconds: 15);
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    if (_closed) {
      throw const McpTransportException('http transport is closed');
    }
    final HttpClientRequest request;
    try {
      request = await _httpClient.postUrl(_uri);
    } on Object catch (e) {
      throw McpTransportException('POST ${config.url} failed', cause: e);
    }
    request.headers
      ..contentType = ContentType('application', 'json', charset: 'utf-8')
      ..set(HttpHeaders.acceptHeader, 'application/json, text/event-stream')
      ..set('MCP-Protocol-Version', McpProtocol.version);
    if (_sessionId != null) {
      request.headers.set('Mcp-Session-Id', _sessionId!);
    }
    await _applyHeaders(request);
    request.add(utf8.encode(jsonEncode(message)));

    final HttpClientResponse response;
    try {
      response = await request.close();
    } on Object catch (e) {
      throw McpTransportException('POST ${config.url} failed', cause: e);
    }

    final sid = response.headers.value('mcp-session-id');
    if (sid != null && sid.isNotEmpty) {
      _sessionId = sid;
    }

    final status = response.statusCode;
    if (status == 401 || status == 403) {
      final wwwAuth = response.headers.value('www-authenticate') ?? '';
      await response.drain<void>();
      throw McpTransportException(
        '$status unauthorized for ${config.url} '
        '(www-authenticate: $wwwAuth)',
      );
    }
    if (status == 202 || status == 204) {
      await response.drain<void>();
      _maybeOpenServerStream();
      return;
    }
    if (status >= 400) {
      final body = await _readBody(response);
      throw McpTransportException('POST ${config.url} → $status: $body');
    }

    final contentType = response.headers.contentType;
    if (contentType?.mimeType == 'text/event-stream') {
      // Drain in the background so `send` returns promptly; frames are routed
      // to `incoming` as the server emits them.
      unawaited(_pumpSse(response));
    } else {
      final body = await _readBody(response);
      if (body.trim().isNotEmpty) {
        _pushFrame(body);
      }
    }
    _maybeOpenServerStream();
  }

  Future<void> _pumpSse(HttpClientResponse response) async {
    try {
      await for (final event in response.transform(sseTransformer())) {
        if (event.data.trim().isEmpty) {
          continue;
        }
        _pushFrame(event.data);
      }
    } on Object {
      // Stream error — the pending request will time out in McpClient.
    }
  }

  void _maybeOpenServerStream() {
    if (_serverStreamOpen || _closed || _sessionId == null) {
      return;
    }
    _serverStreamOpen = true;
    unawaited(_openServerStream());
  }

  Future<void> _openServerStream() async {
    try {
      final request = await _httpClient.getUrl(_uri);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'text/event-stream')
        ..set('MCP-Protocol-Version', McpProtocol.version);
      if (_sessionId != null) {
        request.headers.set('Mcp-Session-Id', _sessionId!);
      }
      await _applyHeaders(request);
      final response = await request.close();
      if (response.statusCode != 200) {
        // Server doesn't support the standalone GET stream — fine.
        await response.drain<void>();
        _serverStreamOpen = false;
        return;
      }
      await _pumpSse(response);
    } on Object {
      // Best-effort; ignore.
    } finally {
      _serverStreamOpen = false;
    }
  }

  void _pushFrame(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (!_incoming.isClosed) {
          _incoming.add(decoded);
        }
      } else if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic> && !_incoming.isClosed) {
            _incoming.add(item);
          }
        }
      }
    } on FormatException {
      // Non-JSON payload — ignore.
    }
  }

  Future<void> _applyHeaders(HttpClientRequest request) async {
    config.headers.forEach(request.headers.set);
    final provider = _authHeaderProvider;
    if (provider != null) {
      final extra = await provider();
      extra.forEach(request.headers.set);
    }
  }

  Future<String> _readBody(HttpClientResponse response) {
    return response.transform(utf8.decoder).join();
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    // Best-effort session termination per the Streamable HTTP spec.
    if (_sessionId != null) {
      try {
        final request = await _httpClient.deleteUrl(_uri);
        request.headers.set('Mcp-Session-Id', _sessionId!);
        await _applyHeaders(request);
        final response = await request.close();
        await response.drain<void>();
      } on Object {
        // Ignore — we're tearing down anyway.
      }
    }
    _httpClient.close(force: true);
    if (!_done.isCompleted) {
      _done.complete();
    }
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }
}

/// The legacy SSE transport (MCP `2024-11-05`).
///
/// A long-lived `GET` opens an event stream; the server's first `endpoint`
/// event names the URL to `POST` client→server messages to, and every
/// subsequent `message` event is a server→client JSON-RPC frame. [start]
/// resolves once the `endpoint` event arrives.
class SseTransport implements McpTransport {
  /// Creates an [SseTransport] for [config] (sse config).
  SseTransport(this.config, {AuthHeaderProvider? authHeaderProvider})
    : _authHeaderProvider = authHeaderProvider,
      assert(
        config.transport == McpTransportKind.sse,
        'SseTransport requires an sse config',
      );

  /// The server config (url, headers, timeout).
  final McpServerConfig config;
  final AuthHeaderProvider? _authHeaderProvider;

  final _httpClient = HttpClient();
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _done = Completer<void>();
  final _endpointReady = Completer<Uri>();
  StreamSubscription<SseEvent>? _sub;
  bool _closed = false;

  Uri get _baseUri => Uri.parse(config.url!);

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> start() async {
    final HttpClientResponse response;
    try {
      final request = await _httpClient.getUrl(_baseUri);
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      await _applyHeaders(request);
      response = await request.close();
    } on Object catch (e) {
      throw McpTransportException('GET ${config.url} (SSE) failed', cause: e);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      await response.drain<void>();
      throw McpTransportException(
        '${response.statusCode} unauthorized for ${config.url}',
      );
    }
    if (response.statusCode != 200) {
      await response.drain<void>();
      throw McpTransportException(
        'GET ${config.url} (SSE) → ${response.statusCode}',
      );
    }
    _sub = response.transform(sseTransformer()).listen(
      _onEvent,
      onError: (_) => _handleClose(),
      onDone: _handleClose,
      cancelOnError: false,
    );
    // Wait for the endpoint event (bounded by the config timeout).
    final timeout = config.timeout.inMilliseconds > 0
        ? config.timeout
        : const Duration(seconds: 30);
    await _endpointReady.future.timeout(
      timeout,
      onTimeout: () =>
          throw const McpTransportException('SSE endpoint event never arrived'),
    );
  }

  void _onEvent(SseEvent event) {
    if (event.event == 'endpoint') {
      if (!_endpointReady.isCompleted) {
        _endpointReady.complete(_baseUri.resolve(event.data.trim()));
      }
      return;
    }
    // `message` (or default) events carry JSON-RPC frames.
    try {
      final decoded = jsonDecode(event.data);
      if (decoded is Map<String, dynamic> && !_incoming.isClosed) {
        _incoming.add(decoded);
      }
    } on FormatException {
      // Ignore non-JSON events.
    }
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    if (_closed) {
      throw const McpTransportException('sse transport is closed');
    }
    final endpoint = await _endpointReady.future;
    try {
      final request = await _httpClient.postUrl(endpoint);
      request.headers.contentType = ContentType(
        'application',
        'json',
        charset: 'utf-8',
      );
      await _applyHeaders(request);
      request.add(utf8.encode(jsonEncode(message)));
      final response = await request.close();
      if (response.statusCode == 401 || response.statusCode == 403) {
        await response.drain<void>();
        throw McpTransportException(
          '${response.statusCode} unauthorized for $endpoint',
        );
      }
      // The actual JSON-RPC reply arrives on the GET event stream; the POST
      // just acknowledges receipt.
      await response.drain<void>();
    } on McpTransportException {
      rethrow;
    } on Object catch (e) {
      throw McpTransportException('POST $endpoint (SSE) failed', cause: e);
    }
  }

  Future<void> _applyHeaders(HttpClientRequest request) async {
    config.headers.forEach(request.headers.set);
    final provider = _authHeaderProvider;
    if (provider != null) {
      final extra = await provider();
      extra.forEach(request.headers.set);
    }
  }

  void _handleClose() {
    if (_closed) {
      return;
    }
    _closed = true;
    if (!_done.isCompleted) {
      _done.complete();
    }
    if (!_endpointReady.isCompleted) {
      _endpointReady.completeError(
        const McpTransportException('SSE stream closed before endpoint'),
      );
    }
    if (!_incoming.isClosed) {
      unawaited(_incoming.close());
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      _httpClient.close(force: true);
      return;
    }
    _closed = true;
    await _sub?.cancel();
    _sub = null;
    _httpClient.close(force: true);
    if (!_done.isCompleted) {
      _done.complete();
    }
    if (!_endpointReady.isCompleted) {
      _endpointReady.completeError(
        const McpTransportException('SSE transport closed'),
      );
    }
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }
}
