import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/sandboxing/domain_matcher.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config.dart';

/// In-process HTTP/HTTPS proxy used by the native sandbox to enforce a
/// per-domain allowlist on outbound traffic.
///
/// Listens on `127.0.0.1:0` (random free port) so multiple Flutter processes
/// can run side-by-side. Handles plain HTTP via direct request forwarding and
/// HTTPS via the CONNECT verb — for CONNECT we accept the TCP stream, validate
/// the SNI host against the allow/deny lists and stream bytes both ways
/// without inspecting the payload.
///
/// The proxy is shared by every sandbox session in the process; filtering is
/// driven by the [NetworkConfig] of the *current* session, which the manager
/// updates via [updateConfig] before each `wrap()`.
class SandboxHttpProxy {
  SandboxHttpProxy._(this._server);

  final HttpServer _server;
  /// The active filtering rules.
  ///
  /// `const NetworkConfig()` is permissive — the shared sandbox proxies are
  /// configured through [updateConfig] before anything can reach them, and
  /// several callers rely on that default. A proxy whose policy is known up
  /// front should pass it to `start(network: …)` instead of starting open and
  /// closing a few statements later; the rig launch does exactly that.
  NetworkConfig _network = const NetworkConfig();
  String? _parentProxy;

  /// One long-lived upstream client for the whole proxy.
  ///
  /// A fresh `HttpClient()` per request, closed with `force: true` right after,
  /// meant no connection reuse at all: every proxied request paid a fresh TCP
  /// (and TLS) handshake to a host the previous request had just finished
  /// talking to. Closed in [close].
  final HttpClient _upstreamClient = HttpClient();

  /// Port the proxy is listening on. Threaded into the sandbox via
  /// `HTTP_PROXY=http://127.0.0.1:<port>`.
  int get port => _server.port;

  /// Starts an HTTP proxy bound to `127.0.0.1` on an OS-assigned port.
  static Future<SandboxHttpProxy> start({NetworkConfig? network}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final proxy = SandboxHttpProxy._(server);
    if (network != null) {
      proxy._network = network;
    }
    proxy._listen();
    return proxy;
  }

  /// Updates the active filtering rules. Affects only requests started after
  /// the call returns.
  void updateConfig({required NetworkConfig network, String? parentProxy}) {
    _network = network;
    _parentProxy = parentProxy;
  }

  /// Closes the listener, the upstream connection pool and any in-flight
  /// tunnels.
  Future<void> close() async {
    _upstreamClient.close(force: true);
    await _server.close(force: true);
  }

  void _listen() {
    _server.listen((request) {
      if (request.method == 'CONNECT') {
        unawaited(_handleConnect(request));
      } else {
        unawaited(_handleHttp(request));
      }
    }, onError: (_) {});
  }

  Future<void> _handleConnect(HttpRequest request) async {
    // The CONNECT target is in the request URI as "host:port".
    final target = request.uri.toString();
    final parts = target.split(':');
    if (parts.length != 2) {
      await _denyAndClose(request, 'malformed CONNECT target');
      return;
    }
    final host = parts[0];
    final port = int.tryParse(parts[1]) ?? 443;
    if (!_isAllowed(host)) {
      await _denyAndClose(request, 'host $host not allowed');
      return;
    }
    final socket = await request.response.detachSocket(writeHeaders: false);
    try {
      final Socket upstream = _parentProxy != null
          ? await _connectThroughParent(host, port)
          : await Socket.connect(host, port);
      socket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
      await socket.flush();
      _pipeBidirectional(socket, upstream);
    } catch (e) {
      try {
        socket.write('HTTP/1.1 502 Bad Gateway\r\n\r\n');
        await socket.flush();
        await socket.close();
      } on Object {
        // The client vanished while we were failing; nothing left to tell.
      }
    }
  }

  Future<void> _handleHttp(HttpRequest request) async {
    final uri = request.uri;
    final host = uri.host;
    if (host.isEmpty || !_isAllowed(host)) {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.headers.contentType = ContentType.text;
      request.response.write('Blocked by sandbox: $host');
      await request.response.close();
      return;
    }
    try {
      final upstream = await _upstreamClient.openUrl(request.method, uri);
      request.headers.forEach((name, values) {
        if (_isHopByHop(name)) {
          return;
        }
        for (final v in values) {
          upstream.headers.add(name, v);
        }
      });
      await upstream.addStream(request);
      final upstreamResp = await upstream.close();
      request.response.statusCode = upstreamResp.statusCode;
      upstreamResp.headers.forEach((name, values) {
        if (_isHopByHop(name)) {
          return;
        }
        for (final v in values) {
          request.response.headers.add(name, v);
        }
      });
      await upstreamResp.pipe(request.response);
    } catch (e) {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('Bad gateway: $e');
      await request.response.close();
    }
  }

  Future<void> _denyAndClose(HttpRequest request, String reason) async {
    request.response.statusCode = HttpStatus.forbidden;
    request.response.headers.contentType = ContentType.text;
    request.response.write('Blocked by sandbox: $reason');
    await request.response.close();
  }

  Future<Socket> _connectThroughParent(String host, int port) async {
    final uri = Uri.parse(_parentProxy!);
    final socket = await Socket.connect(uri.host, uri.port);
    socket.write('CONNECT $host:$port HTTP/1.1\r\nHost: $host:$port\r\n\r\n');
    await socket.flush();
    // Read status line; on success Continue with the tunnel.
    final completer = Completer<void>();
    // Accumulate bytes and scan only the NEW tail for the header terminator.
    // Re-running `String.fromCharCodes` over the whole accumulated buffer on
    // every chunk was O(n²) in the handshake bytes.
    final headerBuf = BytesBuilder(copy: false);
    var scanned = 0;
    late StreamSubscription<Uint8List> sub;
    sub = socket.listen((data) {
      headerBuf.add(data);
      // Overlap by 3 so a terminator split across two chunks is still seen.
      final bytes = headerBuf.toBytes();
      final from = scanned < 3 ? 0 : scanned - 3;
      final headerEnd = _indexOfCrlfCrlf(bytes, from);
      scanned = bytes.length;
      if (headerEnd != -1) {
        sub.cancel();
        final headers = String.fromCharCodes(bytes, 0, headerEnd);
        if (!headers.startsWith('HTTP/1.1 200')) {
          completer.completeError(StateError('parent proxy refused: $headers'));
        } else {
          completer.complete();
        }
        return;
      }
      // A peer that never sends the terminator must not be able to buffer
      // without bound; a CONNECT response header is well under 16 KB.
      if (bytes.length > 65536) {
        sub.cancel();
        completer.completeError(
          StateError('parent proxy sent no CONNECT response header'),
        );
      }
    }, onError: completer.completeError);
    await completer.future;
    return socket;
  }

  /// Index of the first `\r\n\r\n` at or after [from], or -1.
  static int _indexOfCrlfCrlf(Uint8List bytes, int from) {
    for (var i = from; i + 3 < bytes.length; i++) {
      if (bytes[i] == 0x0D &&
          bytes[i + 1] == 0x0A &&
          bytes[i + 2] == 0x0D &&
          bytes[i + 3] == 0x0A) {
        return i;
      }
    }
    return -1;
  }

  void _pipeBidirectional(Socket a, Socket b) {
    // Both `done` futures need a listener BEFORE any write: a peer that
    // resets mid-tunnel reports the failure there, and an unobserved `done`
    // error is an unhandled async exception that takes down the whole
    // process — one RST on one tunnel killed the server hosting the proxy.
    unawaited(a.done.catchError((_) {}));
    unawaited(b.done.catchError((_) {}));
    void forward(Socket from, Socket to) {
      from.listen(
        (chunk) {
          try {
            to.add(chunk);
          } on Object {
            // Write side already gone; the other direction's onDone/onError
            // tears the tunnel down.
          }
        },
        onError: (_) {},
        onDone: () {
          try {
            unawaited(to.close().catchError((_) {}));
          } on Object {
            // Already closed.
          }
        },
        cancelOnError: false,
      );
    }

    forward(a, b);
    forward(b, a);
  }

  bool _isAllowed(String host) {
    if (matchesAny(host, _network.deniedDomains)) {
      return false;
    }
    if (_network.allowAll) {
      return true;
    }
    return matchesAny(host, _network.allowedDomains);
  }

  static bool _isHopByHop(String name) {
    switch (name.toLowerCase()) {
      case 'connection':
      case 'keep-alive':
      case 'proxy-authenticate':
      case 'proxy-authorization':
      case 'te':
      case 'trailer':
      case 'transfer-encoding':
      case 'upgrade':
        return true;
      default:
        return false;
    }
  }
}
