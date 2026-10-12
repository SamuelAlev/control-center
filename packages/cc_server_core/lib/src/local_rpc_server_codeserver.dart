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

    if (rest == '/__cc_open__' || rest == '/__cc_commands__') {
      // These belong exclusively to the server-launched extension's private
      // bridge, never to a client-visible proxy capability.
      await _closeProxy(res, HttpStatus.forbidden);
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
              final window = decoded['window'];
              codeServerReport?.call(
                sid,
                path,
                line,
                window is String && window.isNotEmpty ? window : null,
              );
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
      ..chunkedTransferEncoding = false;
    res.persistentConnection = false;
    // HttpResponse.done only settles when the response producer finishes.
    // Own this close-delimited SSE socket so an idle extension disconnect
    // immediately cancels its command subscription instead of leaking it.
    final socket = await res.detachSocket();
    if (_server == null) {
      socket.destroy();
      return;
    }
    _editorCommandSockets.add(socket);
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    final incoming = socket.listen(
      (_) {},
      onDone: finish,
      onError: (Object _) => finish(),
      cancelOnError: true,
    );
    Future<void> flush() =>
        socket.flush().then<void>((_) {}, onError: (Object _) => finish());
    late final StreamSubscription<Map<String, dynamic>> commands;
    try {
      socket.write(': connected\n\n');
      await flush();
      commands = resolver(sid).listen(
        (command) {
          try {
            socket.write('data: ${jsonEncode(command)}\n\n');
            commands.pause(flush());
          } catch (_) {
            finish();
          }
        },
        onDone: finish,
        onError: (Object _) => finish(),
      );
      try {
        await done.future;
      } finally {
        await commands.cancel();
      }
    } finally {
      _editorCommandSockets.remove(socket);
      socket.destroy();
      await incoming.cancel();
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
    final transfer = _resourceTransfers[request];
    if (transfer != null) {
      unawaited(
        transfer.cancelled.then((_) {
          if (transfer.isCancelled) client.close(force: true);
        }),
      );
    }
    try {
      final upstreamReq = await client.openUrl(request.method, target);
      upstreamReq.followRedirects = false;
      request.headers.forEach((name, values) {
        if (_isHopByHopHeader(name) ||
            name == 'host' ||
            name.startsWith('x-cc-')) {
          return;
        }
        upstreamReq.headers.set(name, values.join(', '));
      });
      upstreamReq.headers.set('X-Forwarded-Proto', 'http');
      upstreamReq.headers.set(
        'X-Forwarded-Host',
        request.headers.value('host') ?? '',
      );
      await upstreamReq
          .addStream(request.cast<List<int>>())
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
      await _withResourceCancellation(
        request,
        upstream.cast<List<int>>(),
      ).pipe(res);
    } catch (e) {
      if (transfer?.isCancelled ?? false) return;
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
      final offered = request.headers.value('sec-websocket-protocol');
      final protocols = offered
          ?.split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      upstreamSocket = await WebSocket.connect(
        wsTarget.toString(),
        protocols: protocols,
        compression: CompressionOptions.compressionOff,
      );
      final selected = upstreamSocket.protocol;
      clientSocket = await WebSocketTransformer.upgrade(
        request,
        protocolSelector: (_) => selected,
        compression: CompressionOptions.compressionOff,
      );
      Future<void> forward(WebSocket from, WebSocket to) async {
        try {
          // addStream propagates socket backpressure; listen(to.add) does not.
          await to.addStream(from);
        } finally {
          final code = from.closeCode;
          await to.close(
            code == null || code == 1005 || code == 1006 || code == 1015
                ? WebSocketStatus.goingAway
                : code,
            from.closeReason,
          );
        }
      }

      await Future.wait([
        forward(clientSocket, upstreamSocket),
        forward(upstreamSocket, clientSocket),
      ]);
    } catch (_) {
      _w('VS Code proxy WebSocket bridge closed');
      if (clientSocket == null) {
        await _closeProxy(request.response, HttpStatus.badGateway);
      }
    } finally {
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
