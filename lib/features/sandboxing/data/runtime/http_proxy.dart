import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:control_center/features/sandboxing/data/runtime/domain_matcher.dart';
import 'package:control_center/features/sandboxing/data/runtime/sandbox_config.dart';

/// In-process HTTP/HTTPS proxy used by the native sandbox to enforce a
/// per-domain allowlist on outbound traffic.
///
/// Listens on `127.0.0.1:0` (random free port) so multiple Flutter processes
/// can run side-by-side. Handles plain HTTP via direct request forwarding and
/// HTTPS via the CONNECT verb — for CONNECT we accept the TCP stream, validate
/// the SNI host against the allow/deny lists, and stream bytes both ways
/// without inspecting the payload.
///
/// The proxy is shared by every sandbox session in the process; filtering is
/// driven by the [NetworkConfig] of the *current* session, which the manager
/// updates via [updateConfig] before each `wrap()`.
class SandboxHttpProxy {
  SandboxHttpProxy._(this._server);

  final HttpServer _server;
  NetworkConfig _network = const NetworkConfig();
  String? _parentProxy;

  /// Port the proxy is listening on. Threaded into the sandbox via
  /// `HTTP_PROXY=http://127.0.0.1:<port>`.
  int get port => _server.port;

  /// Starts an HTTP proxy bound to `127.0.0.1` on an OS-assigned port.
  static Future<SandboxHttpProxy> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final proxy = SandboxHttpProxy._(server);
    proxy._listen();
    return proxy;
  }

  /// Updates the active filtering rules. Affects only requests started after
  /// the call returns.
  void updateConfig({required NetworkConfig network, String? parentProxy}) {
    _network = network;
    _parentProxy = parentProxy;
  }

  /// Closes the listener and any in-flight tunnels.
  Future<void> close() async {
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
      socket.write('HTTP/1.1 502 Bad Gateway\r\n\r\n');
      await socket.flush();
      await socket.close();
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
    final client = HttpClient();
    try {
      final upstream = await client.openUrl(request.method, uri);
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
    } finally {
      client.close(force: true);
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
    final headerBuf = <int>[];
    late StreamSubscription<Uint8List> sub;
    sub = socket.listen((data) {
      headerBuf.addAll(data);
      final str = String.fromCharCodes(headerBuf);
      final headerEnd = str.indexOf('\r\n\r\n');
      if (headerEnd != -1) {
        sub.cancel();
        final headers = str.substring(0, headerEnd);
        if (!headers.startsWith('HTTP/1.1 200')) {
          completer.completeError(StateError('parent proxy refused: $headers'));
        } else {
          completer.complete();
        }
      }
    }, onError: completer.completeError);
    await completer.future;
    return socket;
  }

  void _pipeBidirectional(Socket a, Socket b) {
    a.listen(b.add, onError: (_) {}, onDone: () => b.close(), cancelOnError: false);
    b.listen(a.add, onError: (_) {}, onDone: () => a.close(), cancelOnError: false);
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
