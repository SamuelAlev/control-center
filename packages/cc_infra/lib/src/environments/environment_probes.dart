import 'dart:async';
import 'dart:io';

/// Asks [uri] for its HTTP status. Null when nothing HTTP answers.
typedef EnvironmentHttpProbe = Future<int?> Function(Uri uri);

/// Whether a TCP connection to [host]:[port] succeeds.
typedef EnvironmentTcpProbe = Future<bool> Function(String host, int port);

/// Whether anything listens on [port] on 127.0.0.1 or ::1.
typedef EnvironmentListenerProbe = Future<bool> Function(int port);

/// One HTTP GET, never through a proxy and never following a redirect.
///
/// Any response counts, because a 302 or a 404 still proves HTTP is there.
/// Anything else (a refused connection, a database greeting, silence) is null.
Future<int?> probeHttpStatus(
  Uri uri, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final client = HttpClient()
    ..connectionTimeout = timeout
    ..findProxy = (_) => 'DIRECT';
  try {
    final request = await client.getUrl(uri).timeout(timeout);
    request.followRedirects = false;
    final response = await request.close().timeout(timeout);
    unawaited(response.drain<void>().catchError((Object _) {}));
    return response.statusCode;
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}

/// Whether a TCP connection to [host]:[port] succeeds within [timeout].
Future<bool> probeTcpConnect(
  String host,
  int port, {
  Duration timeout = const Duration(milliseconds: 500),
}) async {
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.destroy();
    return true;
  } on Object {
    return false;
  }
}

/// Whether anything accepts connections on [port] over loopback.
///
/// This connects rather than binds: with `SO_REUSEADDR` a bind on 127.0.0.1
/// can succeed beside a wildcard listener, which would call a taken port free.
Future<bool> probeLoopbackListener(int port) async {
  final answers = await Future.wait([
    probeTcpConnect('127.0.0.1', port),
    probeTcpConnect('::1', port),
  ]);
  return answers.contains(true);
}
