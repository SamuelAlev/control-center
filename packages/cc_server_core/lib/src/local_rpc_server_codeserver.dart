part of 'local_rpc_server.dart';

extension _CodeServerMethods on LocalRpcServer {
  Future<void> _serveCodeServerProxy(HttpRequest request) async {
    final res = request.response;
    final lookup = codeServerLookup;
    if (lookup == null) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }

    final segments = request.uri.path.substring('/proxy/vscode/'.length);
    final slash = segments.indexOf('/');
    final sid = slash < 0 ? segments : segments.substring(0, slash);
    final rest = slash < 0 ? '' : segments.substring(slash);
    if (sid.isEmpty) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    final session = lookup(sid);
    if (session == null) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    if (rest == '/__cc_open__') {
      await _handleCodeServerOpenReport(request, res, sid);
      return;
    }

    if (rest == '/__cc_commands__') {
      await _handleCodeServerCommandStream(res, sid);
      return;
    }

    final upstreamBase = 'http://127.0.0.1:${session.port}';
    final upstreamPath = rest.isEmpty ? '/' : rest;
    final upstreamUri = Uri.parse('$upstreamBase$upstreamPath');
    final target = request.uri.query.isEmpty
        ? upstreamUri
        : upstreamUri.replace(query: request.uri.query);

    if (WebSocketTransformer.isUpgradeRequest(request)) {
      await _bridgeCodeServerWebSocket(request, sid, target);
      return;
    }

    await _forwardCodeServerHttp(request, res, target);
  }

  static const int _maxOpenReportBytes = 64 * 1024;

  Future<String?> _readTextBodyCapped(
    HttpRequest request, {
    required int maxBytes,
    required Duration timeout,
  }) async {
    final buffer = BytesBuilder(copy: false);
    try {
      await for (final chunk in request.timeout(timeout)) {
        buffer.add(chunk);
        if (buffer.length > maxBytes) {
          return null;
        }
      }
    } on TimeoutException {
      return null;
    }
    return utf8.decode(buffer.takeBytes(), allowMalformed: true);
  }

  Future<void> _handleCodeServerOpenReport(
    HttpRequest request,
    HttpResponse res,
    String sid,
  ) async {
    try {
      if (request.method == 'POST') {
        final body = await _readTextBodyCapped(
          request,
          maxBytes: _maxOpenReportBytes,
          timeout: const Duration(seconds: 5),
        );
        if (body == null) {
          res.statusCode = HttpStatus.badRequest;
          await res.close();
          return;
        }
        final decoded = body.isEmpty ? null : jsonDecode(body);
        if (decoded is Map) {
          final path = decoded['path'];
          if (path is String && path.isNotEmpty) {
            if (decoded['type'] == 'dirty') {
              codeServerReportDirty?.call(sid, path, decoded['dirty'] == true);
            } else {
              final rawLine = decoded['line'];
              final line = rawLine is num ? rawLine.toInt() : null;
              codeServerReport?.call(sid, path, line);
            }
          }
        }
      }
    } catch (_) {
      // Best-effort — a malformed report never breaks the editor.
    }
    res.statusCode = HttpStatus.noContent;
    res.headers.set('Access-Control-Allow-Origin', '*');
    await res.close();
  }

  Future<void> _handleCodeServerCommandStream(
    HttpResponse res,
    String sid,
  ) async {
    final resolver = codeServerCommandStream;
    if (resolver == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    res.statusCode = HttpStatus.ok;
    res.headers
      ..set(HttpHeaders.contentTypeHeader, 'text/event-stream')
      ..set(HttpHeaders.cacheControlHeader, 'no-cache')
      ..set('Connection', 'keep-alive')
      ..set('Access-Control-Allow-Origin', '*');
    final sub = resolver(sid).listen((cmd) {
      try {
        res.write('data: ${jsonEncode(cmd)}\n\n');
      } catch (_) {
        // Socket gone — the done handler / error path tears down.
      }
    }, onError: (_) {});
    try {
      await res.done;
    } catch (_) {
      // Client hung up — fall through to cancel + close.
    } finally {
      await sub.cancel();
      try {
        await res.close();
      } catch (_) {
        // Already closed.
      }
    }
  }

  Future<void> _forwardCodeServerHttp(
    HttpRequest request,
    HttpResponse res,
    Uri target,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..autoUncompress = false
      ..userAgent = 'control-center-vscode-proxy';
    try {
      final upstreamReq = await client.openUrl(request.method, target);
      request.headers.forEach((name, values) {
        if (_isHopByHopHeader(name) || name == 'host') {
          return;
        }
        upstreamReq.headers.set(name, values.join(', '));
      });
      upstreamReq.headers.set('X-Forwarded-Proto', 'http');
      upstreamReq.headers.set(
        'X-Forwarded-Host',
        request.headers.value('host') ?? '',
      );
      await request
          .cast<List<int>>()
          .pipe(upstreamReq)
          .timeout(const Duration(seconds: 30));
      final upstream = await upstreamReq.close().timeout(
        const Duration(seconds: 30),
      );

      res.statusCode = upstream.statusCode;
      upstream.headers.forEach((name, values) {
        if (_isHopByHopHeader(name)) {
          return;
        }
        if (name.toLowerCase() == 'x-frame-options') {
          return;
        }
        if (name.toLowerCase() == 'content-security-policy') {
          res.headers.set(name, _relaxCspForFraming(values.join(', ')));
          return;
        }
        res.headers.set(name, values.join(', '));
      });
      res.headers.removeAll('x-frame-options');
      await upstream.cast<List<int>>().pipe(res);
    } catch (e) {
      _w('VS Code proxy HTTP forward failed for $target: $e');
      await _closeProxy(res, HttpStatus.badGateway);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _bridgeCodeServerWebSocket(
    HttpRequest request,
    String sid,
    Uri target,
  ) async {
    final wsTarget = target.replace(
      scheme: target.scheme == 'https' ? 'wss' : 'ws',
    );
    WebSocket? clientSocket;
    WebSocket? upstreamSocket;
    try {
      clientSocket = await WebSocketTransformer.upgrade(request);
      final offered = request.headers.value('sec-websocket-protocol');
      final upstreamUri = wsTarget.toString();
      upstreamSocket = offered == null
          ? await WebSocket.connect(upstreamUri)
          : await WebSocket.connect(
              upstreamUri,
              protocols: offered
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            );
      clientSocket.listen(
        upstreamSocket.add,
        onDone: () => upstreamSocket?.close(),
        onError: (Object e) => upstreamSocket?.close(),
        cancelOnError: true,
      );
      upstreamSocket.listen(
        clientSocket.add,
        onDone: () => clientSocket?.close(),
        onError: (Object e) => clientSocket?.close(),
        cancelOnError: true,
      );
    } catch (e) {
      _w('VS Code proxy WS bridge failed for $wsTarget: $e');
      await clientSocket?.close();
      await upstreamSocket?.close();
    }
  }

  bool _isHopByHopHeader(String name) {
    switch (name.toLowerCase()) {
      case 'connection':
      case 'keep-alive':
      case 'proxy-authenticate':
      case 'proxy-authorization':
      case 'te':
      case 'trailers':
      case 'transfer-encoding':
      case 'upgrade':
        return true;
      default:
        return false;
    }
  }

  String _relaxCspForFraming(String csp) {
    final kept = csp
        .split(';')
        .map((d) => d.trim())
        .where(
          (d) => d.isNotEmpty && !d.toLowerCase().startsWith('frame-ancestors'),
        )
        .join('; ');
    final ancestors = _frameAncestorSources();
    return kept.isEmpty
        ? 'frame-ancestors $ancestors'
        : '$kept; frame-ancestors $ancestors';
  }

  String _frameAncestorSources() {
    final sources = <String>{
      "'self'",
      'http://localhost:*',
      'https://localhost:*',
      'http://127.0.0.1:*',
      'https://127.0.0.1:*',
      ...allowedOrigins,
    };
    return sources.join(' ');
  }
}
