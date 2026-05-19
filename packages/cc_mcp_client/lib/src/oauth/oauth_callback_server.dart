import 'dart:async';
import 'dart:io';

/// The authorization code (and echoed state) captured from an OAuth redirect.
class OAuthCallbackResult {
  /// Creates an [OAuthCallbackResult].
  const OAuthCallbackResult({this.code, this.state, this.error});

  /// The authorization code, on success.
  final String? code;

  /// The state nonce echoed by the server (must match the request).
  final String? state;

  /// The `error` query param, when the user denied or the server failed.
  final String? error;
}

/// A short-lived loopback HTTP server that captures the OAuth redirect.
///
/// Binds `127.0.0.1` on [port] and answers a single `GET` to [path] with a
/// small success page, completing [result] with the captured `code`/`state`.
/// The caller starts it, builds the authorization URL pointing at
/// [redirectUri], opens the user's browser, awaits [result], then [close]s.
class OAuthCallbackServer {
  /// Creates an [OAuthCallbackServer].
  OAuthCallbackServer({this.port = 33418, this.path = '/callback'});

  /// The loopback port to bind.
  final int port;

  /// The callback path to match.
  final String path;

  HttpServer? _server;
  final _result = Completer<OAuthCallbackResult>();

  /// The full loopback redirect URI the authorization request must use.
  String get redirectUri => 'http://127.0.0.1:$port$path';

  /// Resolves with the captured code/state (or error) once the browser hits
  /// the callback.
  Future<OAuthCallbackResult> get result => _result.future;

  /// Binds the server. Throws if the port is unavailable.
  Future<void> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server = server;
    server.listen(_handle, onError: (_) {});
  }

  void _handle(HttpRequest request) {
    if (request.uri.path != path) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
      return;
    }
    final params = request.uri.queryParameters;
    final result = OAuthCallbackResult(
      code: params['code'],
      state: params['state'],
      error: params['error'],
    );
    final ok = result.error == null && (result.code?.isNotEmpty ?? false);
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(_page(ok: ok, error: result.error))
      ..close();
    if (!_result.isCompleted) {
      _result.complete(result);
    }
  }

  /// Waits up to [timeout] for the callback, then closes the server.
  Future<OAuthCallbackResult> waitForCallback({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    try {
      return await _result.future.timeout(timeout);
    } finally {
      await close();
    }
  }

  /// Closes the server. Idempotent.
  Future<void> close() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
    if (!_result.isCompleted) {
      _result.complete(const OAuthCallbackResult(error: 'callback server closed'));
    }
  }

  static String _page({required bool ok, String? error}) {
    final title = ok ? 'Authorization complete' : 'Authorization failed';
    final body = ok
        ? 'You can close this tab and return to Control Center.'
        : 'Authorization failed${error != null ? ': $error' : ''}. '
              'You can close this tab and try again.';
    return '<!doctype html><html><head><meta charset="utf-8">'
        '<title>$title</title></head>'
        '<body style="font-family:system-ui;padding:3rem;text-align:center">'
        '<h2>$title</h2><p>$body</p></body></html>';
  }
}
