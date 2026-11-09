import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:cc_domain/core/domain/value_objects/forge_host.dart'
    show gitHubRestApiVersion;

/// One answer from [GitHubRest.send]. [status] is 0 when GitHub could not be
/// reached at all (connection, timeout, unreadable body).
final class GitHubRestResponse {
  /// Creates the response.
  const GitHubRestResponse(this.status, this.json);

  /// The HTTP status, or 0 for a transport failure.
  final int status;

  /// The decoded body, or null when empty or not JSON.
  final Object? json;

  /// Whether GitHub answered 2xx.
  bool get ok => status >= 200 && status < 300;

  /// Whether GitHub was unreachable or failing (transport, 5xx).
  bool get unavailable => status == 0 || status >= 500;
}

/// The few GitHub REST calls `GitHubClients` (and the sign-in lanes beside
/// it) make outside an `RhttpClient`: the App-authenticated `/applications`
/// endpoints, the bare repository and installation reads that bound a mint,
/// and token revocation. One transport, one header set, one API version,
/// never following redirects.
final class GitHubRest {
  /// Creates the transport.
  GitHubRest({io.HttpClient? httpClient, this.timeout = _defaultTimeout})
    : _http = httpClient ?? (io.HttpClient()..connectionTimeout = timeout);

  static const Duration _defaultTimeout = Duration(seconds: 12);
  static const int _maxBodyBytes = 4 * 1024 * 1024;

  /// Bound on one request and its body.
  final Duration timeout;

  final io.HttpClient _http;

  /// Sends [method] [path] (with [query]) to `api.github.com`, authenticated
  /// by a [bearer] token or an OAuth app's [basic] client credentials, with
  /// [body] as JSON. Never throws for a GitHub answer or transport failure.
  Future<GitHubRestResponse> send(
    String method,
    String path, {
    Map<String, String>? query,
    String? bearer,
    ({String clientId, String clientSecret})? basic,
    Object? body,
  }) async {
    try {
      final request = await _http
          .openUrl(method, Uri.https('api.github.com', path, query))
          .timeout(timeout);
      request.followRedirects = false;
      request.headers
        ..set(io.HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(io.HttpHeaders.userAgentHeader, 'control-center')
        ..set('X-GitHub-Api-Version', gitHubRestApiVersion);
      if (bearer != null) {
        request.headers.set(
          io.HttpHeaders.authorizationHeader,
          'Bearer $bearer',
        );
      } else if (basic != null) {
        final pair = '${basic.clientId}:${basic.clientSecret}';
        request.headers.set(
          io.HttpHeaders.authorizationHeader,
          'Basic ${base64Encode(utf8.encode(pair))}',
        );
      }
      if (body != null) {
        request.headers.contentType = io.ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(timeout);
      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        bytes.addAll(chunk);
        if (bytes.length > _maxBodyBytes) {
          return const GitHubRestResponse(0, null);
        }
      }
      Object? json;
      if (bytes.isNotEmpty) {
        try {
          json = jsonDecode(utf8.decode(bytes, allowMalformed: true));
        } on FormatException {
          json = null;
        }
      }
      return GitHubRestResponse(response.statusCode, json);
    } on Object {
      return const GitHubRestResponse(0, null);
    }
  }

  /// Closes the transport. Calls after this fail as unreachable.
  void close() => _http.close(force: true);
}
