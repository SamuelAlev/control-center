import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Every host Connect ever calls, with the scheme it must use. There is no
/// caller-supplied URL anywhere in Connect: a request to any other host is
/// refused before a socket opens.
const Map<String, String> connectUpstreamHosts = {
  'github.com': 'https',
  'api.github.com': 'https',
  'oauth2.googleapis.com': 'https',
  'slack.com': 'https',
  'api.klipy.com': 'https',
  'cloudkms.googleapis.com': 'https',
  'firestore.googleapis.com': 'https',
  // The GCE/Cloud Run metadata server only speaks plain HTTP, link-local.
  'metadata.google.internal': 'http',
};

/// Upper bound on an upstream response body.
const int upstreamMaxResponseBytes = 256 * 1024;

/// Upper bound on any single upstream call.
const Duration upstreamTimeout = Duration(seconds: 10);

/// One outbound request.
final class UpstreamRequest {
  /// Creates the request.
  const UpstreamRequest(
    this.method,
    this.url, {
    this.headers = const {},
    this.body,
  });

  /// A form-encoded POST.
  factory UpstreamRequest.form(
    Uri url,
    Map<String, String> fields, {
    Map<String, String> headers = const {},
  }) => UpstreamRequest(
    'POST',
    url,
    headers: {
      'content-type': 'application/x-www-form-urlencoded',
      'accept': 'application/json',
      ...headers,
    },
    body: utf8.encode(Uri(queryParameters: fields).query),
  );

  /// A JSON request.
  factory UpstreamRequest.json(
    String method,
    Uri url,
    Object? json, {
    Map<String, String> headers = const {},
  }) => UpstreamRequest(
    method,
    url,
    headers: {
      'content-type': 'application/json',
      'accept': 'application/json',
      ...headers,
    },
    body: utf8.encode(jsonEncode(json)),
  );

  /// `GET`, `POST`, `DELETE`, …
  final String method;

  /// The fixed-host URL.
  final Uri url;

  /// Request headers (lower-case names).
  final Map<String, String> headers;

  /// The body, if any.
  final List<int>? body;
}

/// One upstream answer.
final class UpstreamResponse {
  /// Creates the response.
  const UpstreamResponse(this.status, this.body, {this.headers = const {}});

  /// A JSON answer (tests).
  factory UpstreamResponse.json(int status, Object? json) =>
      UpstreamResponse(status, utf8.encode(jsonEncode(json)));

  /// The HTTP status.
  final int status;

  /// The body bytes (at most [upstreamMaxResponseBytes]).
  final List<int> body;

  /// Response headers (lower-case names, first value).
  final Map<String, String> headers;

  /// The body as text (malformed UTF-8 replaced).
  String get text => utf8.decode(body, allowMalformed: true);

  /// The body as a JSON object, or null when it is not one.
  Map<String, Object?>? get jsonObject {
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Whether [status] is 2xx.
  bool get ok => status >= 200 && status < 300;

  /// Whether the failure is transient on the provider's side.
  bool get isTransient => status == 429 || status >= 500;
}

/// The network failed, timed out, or answered something too large. Always
/// maps to `provider_unavailable`.
final class UpstreamUnavailable implements Exception {
  /// Creates the exception.
  const UpstreamUnavailable(this.reason);

  /// A fixed, secret-free reason.
  final String reason;

  @override
  String toString() => 'UpstreamUnavailable($reason)';
}

/// The one way Connect talks to providers. Tests inject a fake so no test
/// touches the network.
abstract interface class UpstreamHttp {
  /// Sends [request]. Throws [UpstreamUnavailable] on transport failure; any
  /// HTTP status is returned, never thrown.
  Future<UpstreamResponse> send(UpstreamRequest request);

  /// Releases sockets.
  void close();
}

/// [UpstreamHttp] over `dart:io`: fixed hosts only, no redirects, bounded
/// time and size.
final class IoUpstreamHttp implements UpstreamHttp {
  /// Creates the client.
  IoUpstreamHttp({
    Map<String, String> allowedHosts = connectUpstreamHosts,
    Duration timeout = upstreamTimeout,
  }) : _allowed = allowedHosts,
       _timeout = timeout,
       _client = HttpClient()
         ..connectionTimeout = timeout
         ..idleTimeout = const Duration(seconds: 30)
         ..autoUncompress = true
         ..userAgent = 'cc-connect';

  final Map<String, String> _allowed;
  final Duration _timeout;
  final HttpClient _client;

  @override
  Future<UpstreamResponse> send(UpstreamRequest request) async {
    final url = request.url;
    final scheme = _allowed[url.host];
    if (scheme == null || url.scheme != scheme || url.userInfo.isNotEmpty) {
      throw const UpstreamUnavailable('host not allowed');
    }
    try {
      return await _send(request).timeout(_timeout);
    } on TimeoutException {
      throw const UpstreamUnavailable('timeout');
    } on SocketException {
      throw const UpstreamUnavailable('socket');
    } on HandshakeException {
      throw const UpstreamUnavailable('tls');
    } on HttpException {
      throw const UpstreamUnavailable('http');
    } on TlsException {
      throw const UpstreamUnavailable('tls');
    }
  }

  Future<UpstreamResponse> _send(UpstreamRequest request) async {
    final outbound = await _client.openUrl(request.method, request.url);
    outbound
      ..followRedirects = false
      ..persistentConnection = true;
    request.headers.forEach(outbound.headers.set);
    final body = request.body;
    if (body != null) {
      outbound.contentLength = body.length;
      outbound.add(body);
    } else {
      outbound.contentLength = 0;
    }
    final inbound = await outbound.close();
    final declared = inbound.contentLength;
    if (declared > upstreamMaxResponseBytes) {
      await inbound.drain<void>().catchError((_) {});
      throw const UpstreamUnavailable('response too large');
    }
    final bytes = <int>[];
    await for (final chunk in inbound) {
      bytes.addAll(chunk);
      if (bytes.length > upstreamMaxResponseBytes) {
        throw const UpstreamUnavailable('response too large');
      }
    }
    final headers = <String, String>{};
    inbound.headers.forEach((name, values) {
      if (values.isNotEmpty) {
        headers[name.toLowerCase()] = values.first;
      }
    });
    return UpstreamResponse(inbound.statusCode, bytes, headers: headers);
  }

  @override
  void close() => _client.close(force: true);
}
