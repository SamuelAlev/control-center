import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cc_rpc/cc_rpc.dart'
    show
        LocalResourceProxy,
        RemoteResources,
        RemoteResourceResponse,
        RemoteResourceSocket;

/// Opens a capability-scoped loopback facade for the current encrypted session.
Future<LocalResourceProxy> createLocalResourceProxy(
  RemoteResources Function() resources,
) async {
  final listener = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final random = Random.secure();
  final nonce = base64UrlEncode(
    List<int>.generate(32, (_) => random.nextInt(256)),
  ).replaceAll('=', '');
  final proxy = _LoopbackResourceProxy(
    listener,
    '/_cc_resource/$nonce/',
    resources,
  );
  proxy.start();
  return proxy;
}

// Served only from the session capability and inserted before code-server JS.
// Native WebSocket uses the local listener; this translates root-relative
// code-server sockets to that listener, never to a remote host.
const _nativeWebSocketShim = r'''
(() => {
  const Native = window.WebSocket;
  const root = location.pathname.match(/^(.*\/proxy\/vscode\/[^/]+\/)/)?.[1];
  if (!root) return;
  const cap = root.substring(0, root.indexOf('/proxy/vscode/') + 1);
  window.WebSocket = class extends Native {
    constructor(input, protocols) {
      const uri = new URL(String(input), location.href);
      if (uri.host !== location.host ||
          !['ws:', 'wss:', 'http:', 'https:'].includes(uri.protocol)) {
        throw new DOMException('Only local encrypted resources are available', 'SecurityError');
      }
      const path = uri.pathname.startsWith('/proxy/vscode/')
        ? cap + uri.pathname.substring(1)
        : uri.pathname.startsWith(root)
          ? uri.pathname
          : root + uri.pathname.replace(/^\//, '');
      if (!path.startsWith(root)) {
        throw new DOMException('Socket outside code-server session', 'SecurityError');
      }
      uri.pathname = path;
      uri.protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
      super(uri.href, protocols);
    }
  };
})();
''';

/// Dart's local WebSocket reports 1005 when its peer closes without a status
/// and 1006 for an abnormal disconnect. Neither is a legal close frame.
/// Retain application codes (including code-server's 4001/4002) verbatim.
int _nativeResourceCloseCode(int? code) => switch (code) {
  null || 1005 => WebSocketStatus.normalClosure,
  1006 || 1015 => WebSocketStatus.internalServerError,
  _ => code,
};

class _LoopbackResourceProxy implements LocalResourceProxy {
  _LoopbackResourceProxy(this._listener, this._prefix, this._resources);

  final HttpServer _listener;
  final String _prefix;
  final RemoteResources Function() _resources;
  final Set<RemoteResourceResponse> _responses = {};
  final Map<RemoteResourceSocket, Future<void> Function()> _sockets = {};
  final Set<Socket> _httpSockets = {};
  late final StreamSubscription<HttpRequest> _subscription;
  bool _closed = false;

  @override
  Uri get baseUri => Uri(
    scheme: 'http',
    host: '127.0.0.1',
    port: _listener.port,
    path: _prefix,
  );

  void start() {
    _subscription = _listener.listen((request) => unawaited(_serve(request)));
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _subscription.cancel();
    await _listener.close(force: true);
    // Detached HTTP responses are no longer owned by HttpServer.close().
    for (final socket in _httpSockets.toList()) {
      socket.destroy();
    }
    await Future.wait([
      for (final response in _responses) response.close(),
      for (final closeSocket in _sockets.values) closeSocket(),
    ]);
    _responses.clear();
    _sockets.clear();
    _httpSockets.clear();
  }

  Future<void> _serve(HttpRequest request) async {
    final expectedHost = '127.0.0.1:${_listener.port}';
    final raw = request.uri.toString();
    final origin = request.headers.value('origin');
    if (_closed ||
        request.connectionInfo?.remoteAddress.address != '127.0.0.1' ||
        request.headers.value(HttpHeaders.hostHeader) != expectedHost ||
        (origin != null && origin != baseUri.origin)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    if (raw == '${_prefix}_cc_native_ws_shim.js') {
      request.response.headers.contentType = ContentType(
        'application',
        'javascript',
      );
      request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      request.response.write(_nativeWebSocketShim);
      await request.response.close();
      return;
    }
    final route = _resourceRoute(request, raw);
    if (route == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final uri = Uri.parse('/$route');
    final headers = <String, List<String>>{};
    request.headers.forEach((name, values) {
      if (!const {
        'host',
        'connection',
        'upgrade',
        'transfer-encoding',
        'content-length',
        'proxy-authorization',
        'proxy-authenticate',
      }.contains(name.toLowerCase())) {
        headers[name] = values;
      }
    });
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      await _serveSocket(request, uri, headers);
      return;
    }
    RemoteResourceResponse? upstream;
    Future<void>? closing;
    Future<void> closeUpstream() =>
        closing ??= upstream?.close() ?? Future<void>.value();
    var responseStarted = false;
    try {
      upstream = await _resources().request(
        request.method,
        uri,
        headers: headers,
        body: request,
      );
      if (_closed) {
        await upstream.close();
        request.response.statusCode = HttpStatus.serviceUnavailable;
        responseStarted = true;
        await request.response.close();
        return;
      }
      _responses.add(upstream);
      final contentType =
          upstream.headers.entries
              .where((entry) => entry.key.toLowerCase() == 'content-type')
              .firstOrNull
              ?.value
              .firstOrNull ??
          '';
      final inject =
          uri.path.startsWith('/proxy/vscode/') &&
          contentType.toLowerCase().startsWith('text/html') &&
          request.method != 'HEAD' &&
          upstream.statusCode == 200;
      final location = upstream.headers.entries
          .where((entry) => entry.key.toLowerCase() == 'location')
          .firstOrNull
          ?.value
          .firstOrNull;
      final redirect = location == null ? null : _redirect(location, uri);
      if (location != null && redirect == null) {
        request.response.statusCode = HttpStatus.badGateway;
        responseStarted = true;
        await request.response.close();
        return;
      }
      request.response.statusCode = upstream.statusCode;
      for (final entry in upstream.headers.entries) {
        if (const {
              'connection',
              'upgrade',
              'transfer-encoding',
              'content-length',
              'keep-alive',
              'proxy-authenticate',
              'proxy-authorization',
              'te',
              'trailers',
              'location',
            }.contains(entry.key.toLowerCase()) ||
            (inject && entry.key.toLowerCase() == 'content-encoding')) {
          continue;
        }
        for (final value in entry.value) {
          request.response.headers.add(entry.key, value);
        }
      }
      if (inject) {
        // dart:io adds X-Frame-Options: SAMEORIGIN to every HttpResponse.
        // The server already stripped the editor's frame restriction; remove
        // the local default too, or its nested extension-host iframe is blocked
        // when the app shell and this loopback facade use different ports.
        request.response.headers.removeAll('x-frame-options');
      }
      if (redirect != null) {
        request.response.headers.set('location', redirect);
      }
      request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      final length = upstream.headers.entries
          .where((entry) => entry.key.toLowerCase() == 'content-length')
          .firstOrNull
          ?.value
          .firstOrNull;
      if (!inject && length != null) {
        final parsed = int.tryParse(length);
        if (parsed != null && parsed >= 0) {
          request.response.contentLength = parsed;
        }
      }
      // A detached socket lets us observe the browser's FIN while an upstream
      // body is idle. HttpResponse.done/addStream cannot observe that FIN until
      // the producer finishes, leaking the encrypted resource lane otherwise.
      // A terminal chunk is required for unknown lengths: close-delimited HTTP
      // would turn an interrupted encrypted download into apparent success.
      final hasBody =
          request.method != 'HEAD' &&
          upstream.statusCode >= 200 &&
          upstream.statusCode != HttpStatus.noContent &&
          upstream.statusCode != HttpStatus.notModified;
      request.response.headers.chunkedTransferEncoding =
          hasBody && request.response.headers.contentLength < 0;
      request.response.persistentConnection = false;
      responseStarted = true;
      await _streamDetached(
        request.response,
        !hasBody
            ? const Stream<List<int>>.empty()
            : inject
            ? _htmlWithShim(
                upstream.body,
                cspNonce: _nonceFromPolicy(upstream.headers),
              )
            : upstream.body,
        closeUpstream,
      );
    } catch (_) {
      if (!responseStarted) {
        try {
          request.response.statusCode = HttpStatus.badGateway;
          await request.response.close();
        } catch (_) {}
      }
    } finally {
      if (upstream != null) {
        _responses.remove(upstream);
        await closeUpstream();
      }
    }
  }

  Future<void> _streamDetached(
    HttpResponse response,
    Stream<List<int>> body,
    Future<void> Function() abortUpstream,
  ) async {
    final encoded = response.headers.chunkedTransferEncoding
        ? _chunkedBody(body)
        : body;
    final socket = await response.detachSocket();
    _httpSockets.add(socket);
    final disconnected = Completer<void>();
    void signalDisconnect() {
      if (!disconnected.isCompleted) {
        disconnected.complete();
      }
    }

    final incoming = socket.listen(
      (_) {},
      onDone: signalDisconnect,
      onError: (Object _) => signalDisconnect(),
      cancelOnError: true,
    );
    try {
      if (_closed) {
        return;
      }
      await Future.any<void>([
        socket.addStream(encoded),
        disconnected.future.then((_) => abortUpstream()),
      ]);
      if (!disconnected.isCompleted) {
        await socket.flush();
        await socket.close();
      }
    } finally {
      _httpSockets.remove(socket);
      socket.destroy();
      await incoming.cancel();
    }
  }

  Stream<List<int>> _chunkedBody(Stream<List<int>> source) async* {
    await for (final chunk in source) {
      if (chunk.isEmpty) {
        continue;
      }
      yield ascii.encode('${chunk.length.toRadixString(16)}\r\n');
      yield chunk;
      yield const [13, 10];
    }
    // Only successful upstream completion emits the HTTP end marker.
    yield const [48, 13, 10, 13, 10];
  }

  String? _resourceRoute(HttpRequest request, String raw) {
    if (raw.startsWith(_prefix)) {
      final route = raw.substring(_prefix.length);
      return route.isEmpty ||
              route.startsWith('/') ||
              route.contains('#') ||
              route.startsWith('_cc_resource/')
          ? null
          : route;
    }
    // code-server uses root-relative assets. A same-origin iframe's Referer
    // carries the unguessable capability and its session; never grant this
    // branch to unrelated browser pages or an uncapable direct HTTP request.
    final referer = Uri.tryParse(
      request.headers.value(HttpHeaders.refererHeader) ?? '',
    );
    if (referer == null ||
        referer.scheme != 'http' ||
        referer.host != '127.0.0.1' ||
        referer.port != _listener.port ||
        !referer.path.startsWith('${_prefix}proxy/vscode/')) {
      return null;
    }
    final session = referer.path
        .substring('${_prefix}proxy/vscode/'.length)
        .split('/')
        .first;
    if (session.isEmpty || raw.startsWith('//') || raw.contains('#')) {
      return null;
    }
    final sessionRoot = 'proxy/vscode/$session/';
    if (raw.startsWith('/proxy/vscode/')) {
      return raw.startsWith('/$sessionRoot') ? raw.substring(1) : null;
    }
    return '$sessionRoot${raw.startsWith('/') ? raw.substring(1) : raw}';
  }

  String? _redirect(String value, Uri requested) {
    final parsed = Uri.tryParse(value);
    if (parsed == null || parsed.hasScheme || parsed.hasAuthority) {
      return null;
    }
    if (parsed.path.startsWith('/')) {
      final root = requested.path.startsWith('/proxy/vscode/')
          ? 'proxy/vscode/${requested.pathSegments[2]}/'
          : '';
      final target = parsed.path.startsWith('/proxy/vscode/')
          ? parsed.path.substring(1)
          : '$root${parsed.path.substring(1)}';
      return baseUri
          .replace(
            path: '$_prefix$target',
            query: parsed.hasQuery ? parsed.query : null,
            fragment: parsed.hasFragment ? parsed.fragment : null,
          )
          .toString();
    }
    final resolved = baseUri
        .resolveUri(Uri.parse(requested.toString().substring(1)))
        .resolveUri(parsed);
    return resolved.path.startsWith(_prefix) ? resolved.toString() : null;
  }

  // A CSP nonce is an untrusted header value until its base64 alphabet has
  // been checked. The resulting value is safe in a quoted HTML attribute.
  String? _nonceFromPolicy(Map<String, List<String>> headers) {
    final policy =
        headers.entries
            .where(
              (entry) => entry.key.toLowerCase() == 'content-security-policy',
            )
            .firstOrNull
            ?.value
            .join(';') ??
        '';
    final directives = policy.split(RegExp(r'[;,]')).map((s) => s.trim());
    String? script;
    String? scriptElement;
    for (final directive in directives) {
      if (directive.startsWith('script-src-elem ')) {
        scriptElement = directive;
      }
      if (directive.startsWith('script-src ')) {
        script = directive;
      }
    }
    final effective = scriptElement ?? script;
    return effective == null
        ? null
        : RegExp(
            r"'nonce-([A-Za-z0-9+/_=-]+)'",
          ).firstMatch(effective)?.group(1);
  }

  String? _nonceFromHtml(String scriptTag) {
    final match = RegExp(
      r'''(?:^|\s)nonce\s*=\s*(?:\"([A-Za-z0-9+/_=-]+)\"|'([A-Za-z0-9+/_=-]+)'|([A-Za-z0-9+/_=-]+))''',
      caseSensitive: false,
    ).firstMatch(scriptTag);
    return match?.group(1) ?? match?.group(2) ?? match?.group(3);
  }

  Stream<List<int>> _htmlWithShim(
    Stream<Uint8List> source, {
    String? cspNonce,
  }) async* {
    final initial = BytesBuilder(copy: false);
    final iterator = StreamIterator(source);
    try {
      while (await iterator.moveNext()) {
        initial.add(iterator.current);
        if (initial.length > 65536) {
          throw const FormatException('Code-server HTML head too large');
        }
        final bytes = initial.toBytes();
        final html = utf8.decode(bytes, allowMalformed: true);
        final match = RegExp(
          r'<head(?:\s[^>]*)?>',
          caseSensitive: false,
        ).firstMatch(html);
        if (match == null) {
          continue;
        }
        final firstScript = RegExp(
          r'<script\b[^>]*>',
          caseSensitive: false,
        ).firstMatch(html.substring(match.end));
        final headEnd = RegExp(
          r'</head\s*>',
          caseSensitive: false,
        ).firstMatch(html.substring(match.end));
        if (cspNonce == null && firstScript == null && headEnd == null) {
          continue;
        }
        final nonce =
            cspNonce ??
            (firstScript == null
                ? null
                : _nonceFromHtml(firstScript.group(0)!));
        final attribute = nonce == null ? '' : ' nonce="$nonce"';
        final offset = utf8.encode(html.substring(0, match.end)).length;
        yield Uint8List.sublistView(bytes, 0, offset);
        yield utf8.encode(
          '<script$attribute src="${_prefix}_cc_native_ws_shim.js"></script>',
        );
        yield Uint8List.sublistView(bytes, offset);
        while (await iterator.moveNext()) {
          yield iterator.current;
        }
        return;
      }
      throw const FormatException('Code-server HTML has no head');
    } finally {
      await iterator.cancel();
    }
  }

  Future<void> _serveSocket(
    HttpRequest request,
    Uri uri,
    Map<String, List<String>> headers,
  ) async {
    RemoteResourceSocket? remote;
    WebSocket? local;
    Future<void>? closingRemote;
    Future<void> closeRemote([
      int code = WebSocketStatus.normalClosure,
      String reason = '',
    ]) {
      // RemoteResourceSocket.close delegates directly to its callback; it
      // does not coalesce repeated closes.
      return closingRemote ??= remote!.close(code, reason);
    }

    try {
      final protocols =
          request.headers['sec-websocket-protocol']
              ?.expand((value) => value.split(','))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];
      remote = await _resources().connectWebSocket(
        uri,
        headers: headers,
        protocols: protocols,
      );
      if (remote.protocol.isNotEmpty && !protocols.contains(remote.protocol)) {
        throw const FormatException('Unrequested websocket protocol');
      }
      _sockets[remote] = closeRemote;
      local = await WebSocketTransformer.upgrade(
        request,
        protocolSelector: (requested) =>
            remote!.protocol.isEmpty ? null : remote.protocol,
      );
      final socket = local;
      final peer = remote;
      var transferFailed = false;
      void closeFromLocal(int code, String reason) {
        unawaited(closeRemote(code, reason).catchError((Object _) {}));
      }

      final inbound = socket
          .asyncMap((message) => peer.send(message as Object))
          .listen(
            (_) {},
            onDone: () => closeFromLocal(
              _nativeResourceCloseCode(socket.closeCode),
              socket.closeReason ?? '',
            ),
            onError: (Object _) {
              transferFailed = true;
              closeFromLocal(
                WebSocketStatus.internalServerError,
                'Encrypted resource transfer failed',
              );
            },
          );
      var remoteEnded = false;
      try {
        await for (final message in peer.incoming) {
          await socket.addStream(Stream<Object>.value(message));
        }
        remoteEnded = true;
      } catch (_) {
        transferFailed = true;
      } finally {
        await inbound.cancel();
        // An upstream EOF is already a close; sending a default close back
        // would race the original local close (and can affect the next socket).
        if (!remoteEnded && closingRemote == null) {
          await closeRemote(
            transferFailed
                ? WebSocketStatus.internalServerError
                : _nativeResourceCloseCode(socket.closeCode),
            transferFailed
                ? 'Encrypted resource transfer failed'
                : socket.closeReason ?? '',
          );
        }
        if (closingRemote != null) {
          await closingRemote;
        }
        await socket.close(
          transferFailed
              ? WebSocketStatus.internalServerError
              : _nativeResourceCloseCode(peer.closeCode),
          transferFailed
              ? 'Encrypted resource transfer failed'
              : peer.closeReason ?? '',
        );
      }
    } catch (_) {
      if (local == null) {
        request.response.statusCode = HttpStatus.badGateway;
        try {
          await request.response.close();
        } catch (_) {}
      } else {
        await local.close(WebSocketStatus.internalServerError);
      }
    } finally {
      if (remote != null) {
        _sockets.remove(remote);
        if (local == null) {
          await closeRemote();
        }
      }
    }
  }
}
