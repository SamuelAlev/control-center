import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:control_center/features/sandboxing/data/claude_relay/message_request_filter.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/sse.dart';

/// Callbacks used to mirror upstream Anthropic traffic into the relay's output
/// pipeline without changing the bytes sent back to Claude.
///
/// Dart port of the upstream relay's `ProxyCallbacks` (src/proxy.ts).
class ProxyCallbacks {
  /// Creates [ProxyCallbacks].
  const ProxyCallbacks({
    required this.onSseEvent,
    this.onProxyError,
    this.onRequestStart,
    this.onRequestEnd,
    this.onRateLimit,
    this.onRequestBody,
  });

  /// Invoked for each complete SSE event on a `/v1/messages` response. The
  /// `observe` flag is false for filtered internal requests (e.g. Claude's
  /// session-title generation), whose events must not surface as agent output.
  final void Function(SseEvent event, String path, {required bool observe})
      onSseEvent;

  /// Invoked on proxy/forwarding errors.
  final void Function(Object error)? onProxyError;

  /// Invoked when a request starts.
  final void Function(String method, String path)? onRequestStart;

  /// Invoked when a response status is known.
  final void Function(String method, String path, int statusCode)?
      onRequestEnd;

  /// Invoked on 429/529 responses.
  final void Function(int statusCode, String? retryAfter, String path)?
      onRateLimit;

  /// Invoked with the parsed JSON request body for `/v1/messages`. The
  /// `observe` flag mirrors [onSseEvent].
  final void Function(Map<String, Object?> body, String path,
      {required bool observe})? onRequestBody;
}

/// A loopback HTTP proxy that forwards Claude's Anthropic API requests upstream
/// (byte-for-byte) and tees message SSE events to [callbacks].
///
/// Faithful Dart port of the upstream relay's proxy (src/proxy.ts + backends/proxy-backend.ts).
/// Claude is pointed at this proxy via `ANTHROPIC_BASE_URL=http://127.0.0.1:{port}`,
/// which gives the relay access to the same token-level streaming events that
/// `claude -p` sees — without using metered `-p` mode.
class AnthropicProxy {
  /// Creates an [AnthropicProxy]. [upstreamScheme] / [upstreamPort] default to
  /// `https` / 443 in production; tests override them to target a local fake.
  AnthropicProxy(
    this.callbacks, {
    this.upstreamHost = 'api.anthropic.com',
    this.upstreamScheme = 'https',
    this.upstreamPort,
    this.upstreamTimeout = const Duration(seconds: 120),
  });

  /// Output callbacks.
  final ProxyCallbacks callbacks;

  /// Upstream Anthropic host.
  final String upstreamHost;

  /// Upstream scheme (`https` in production).
  final String upstreamScheme;

  /// Upstream port (null → scheme default).
  final int? upstreamPort;

  /// Per-request upstream timeout (also the body-level SSE idle timeout).
  final Duration upstreamTimeout;

  HttpServer? _server;
  // autoUncompress must stay false so SSE bytes are forwarded/parsed verbatim.
  final HttpClient _client = HttpClient()..autoUncompress = false;

  int? _port;

  /// The loopback port the proxy is listening on (after [start]).
  int? get port => _port;

  /// The base URL Claude should be pointed at.
  String get baseUrl => 'http://127.0.0.1:$_port';

  /// Starts the proxy on a random loopback port.
  Future<void> start() async {
    if (_server != null) {
      return;
    }
    final server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0, shared: false);
    _server = server;
    _port = server.port;
    _client.connectionTimeout = const Duration(seconds: 30);
    server.listen(
      _handle,
      onError: (Object e) => callbacks.onProxyError?.call(e),
    );
  }

  /// Stops the proxy and closes the upstream client.
  Future<void> stop() async {
    final server = _server;
    _server = null;
    _port = null;
    try {
      _client.close(force: true);
    } catch (_) {}
    if (server != null) {
      await server.close(force: true);
    }
  }

  Future<void> _handle(HttpRequest clientReq) async {
    final method = clientReq.method;
    final reqPath = clientReq.uri.toString();
    callbacks.onRequestStart?.call(method, reqPath);
    final clientRes = clientReq.response;

    try {
      final bodyBytes = await _collectBody(clientReq);

      var observe = reqPath.startsWith('/v1/messages');
      if (observe && bodyBytes.isNotEmpty) {
        try {
          final decoded = jsonDecode(utf8.decode(bodyBytes));
          if (decoded is Map) {
            final parsedBody = decoded.cast<String, Object?>();
            observe = shouldObserveMessagesRequest(parsedBody);
            callbacks.onRequestBody?.call(parsedBody, reqPath, observe: observe);
          }
        } catch (_) {
          // Non-JSON body — forward unchanged, leave observe as-is.
        }
      }

      final upstreamUri = Uri(
        scheme: upstreamScheme,
        host: upstreamHost,
        port: upstreamPort,
        path: clientReq.uri.path,
        query: clientReq.uri.query.isEmpty ? null : clientReq.uri.query,
      );

      final upstreamReq = await _client.openUrl(method, upstreamUri);
      upstreamReq.followRedirects = false;
      // Forward headers verbatim except hop-by-hop / encoding ones.
      clientReq.headers.forEach((name, values) {
        final lname = name.toLowerCase();
        if (lname == 'host' ||
            lname == 'connection' ||
            lname == 'accept-encoding' ||
            lname == 'content-length' ||
            lname == 'transfer-encoding') {
          return;
        }
        for (final v in values) {
          upstreamReq.headers.add(name, v);
        }
      });
      // Ask upstream for an uncompressed stream so SSE parses cleanly.
      upstreamReq.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      if (bodyBytes.isNotEmpty) {
        upstreamReq.add(bodyBytes);
      }

      final upstreamRes =
          await upstreamReq.close().timeout(upstreamTimeout, onTimeout: () {
        throw TimeoutException(
          'Upstream request timed out after ${upstreamTimeout.inMilliseconds}ms',
        );
      });

      final statusCode = upstreamRes.statusCode;
      callbacks.onRequestEnd?.call(method, reqPath, statusCode);

      if (statusCode == 429 || statusCode == 529) {
        callbacks.onRateLimit?.call(
          statusCode,
          upstreamRes.headers.value('retry-after'),
          reqPath,
        );
      }

      clientRes.statusCode = statusCode;
      upstreamRes.headers.forEach((name, values) {
        final lname = name.toLowerCase();
        if (lname == 'connection' ||
            lname == 'transfer-encoding' ||
            lname == 'content-length') {
          return;
        }
        for (final v in values) {
          clientRes.headers.add(name, v);
        }
      });

      final isMessages = reqPath.startsWith('/v1/messages');
      final contentType =
          upstreamRes.headers.value(HttpHeaders.contentTypeHeader) ?? '';
      final isSse = contentType.contains('text/event-stream');

      if (isMessages && isSse) {
        await _streamSse(upstreamRes, clientRes, reqPath, observe);
      } else {
        await clientRes.addStream(upstreamRes);
        await clientRes.close();
      }
    } catch (e) {
      callbacks.onProxyError?.call(e);
      try {
        if (clientRes.connectionInfo != null) {
          clientRes.statusCode = HttpStatus.badGateway;
          clientRes.headers.contentType = ContentType.json;
          clientRes.write(jsonEncode({
            'error': {'type': 'proxy_error', 'message': '$e'},
          }));
        }
      } catch (_) {}
      try {
        await clientRes.close();
      } catch (_) {}
    }
  }

  Future<void> _streamSse(
    HttpClientResponse upstreamRes,
    HttpResponse clientRes,
    String reqPath,
    bool observe,
  ) async {
    // The upstream relay's proxy wires destroyUpstream() to client-abort / response-close /
    // socket-timeout so a dead caller cannot leave the upstream socket pinned.
    // dart:io's HttpResponse.add() does not throw synchronously when Claude
    // disconnects, so we react to clientRes.done and rearm a body-level idle
    // timeout, then release the upstream subscription (which destroys the
    // not-fully-read connection rather than returning it to the pool).
    var sseBuf = '';
    final done = Completer<void>();
    StreamSubscription<List<int>>? sub;
    Timer? idleTimer;
    var released = false;

    Future<void> release() async {
      if (released) {
        return;
      }
      released = true;
      idleTimer?.cancel();
      try {
        await sub?.cancel();
      } catch (_) {}
      if (!done.isCompleted) {
        done.complete();
      }
    }

    void armIdle() {
      idleTimer?.cancel();
      idleTimer = Timer(upstreamTimeout, () {
        callbacks.onProxyError?.call(TimeoutException(
          'Upstream SSE idle for ${upstreamTimeout.inMilliseconds}ms',
          upstreamTimeout,
        ));
        unawaited(release());
      });
    }

    // Claude (the loopback client) dropping its connection completes/errors
    // clientRes.done early — stop draining upstream when that happens.
    unawaited(clientRes.done
        .then((_) => release())
        .catchError((Object _) => release()));

    armIdle();
    sub = upstreamRes.listen(
      (chunk) {
        if (released) {
          return;
        }
        armIdle();
        try {
          clientRes.add(chunk);
        } catch (_) {
          unawaited(release());
          return;
        }
        sseBuf += utf8.decode(chunk, allowMalformed: true);
        final result = extractSseEvents(sseBuf);
        sseBuf = result.remainder;
        for (final evt in result.complete) {
          callbacks.onSseEvent(evt, reqPath, observe: observe);
        }
      },
      onError: (Object e) {
        callbacks.onProxyError?.call(e);
        unawaited(release());
      },
      onDone: () {
        idleTimer?.cancel();
        if (!released && sseBuf.trim().isNotEmpty) {
          final result = extractSseEvents('$sseBuf\n\n');
          for (final evt in result.complete) {
            callbacks.onSseEvent(evt, reqPath, observe: observe);
          }
        }
        if (!done.isCompleted) {
          done.complete();
        }
      },
      cancelOnError: true,
    );

    await done.future;
    try {
      await clientRes.close();
    } catch (_) {}
  }

  Future<List<int>> _collectBody(HttpRequest req) async {
    // Copy chunks (like the reference's Buffer.concat) so the forwarded body is
    // byte-identical and stable — never an alias into a reused socket buffer.
    // A corrupted body would break Anthropic prompt caching and trigger
    // retries, inflating request volume.
    final builder = BytesBuilder();
    await for (final chunk in req) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
