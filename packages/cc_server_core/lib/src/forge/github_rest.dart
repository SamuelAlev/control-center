import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:cc_domain/core/domain/value_objects/forge_host.dart'
    show gitHubRestApiVersion;
import 'package:cc_host/cc_host.dart' show CcHostLog;

/// One answer from [GitHubRest.send]. [status] is 0 when GitHub could not be
/// reached at all (connection, timeout, unreadable body).
final class GitHubRestResponse {
  /// Creates the response.
  const GitHubRestResponse(this.status, this.json, {this.headers = const {}});

  /// The HTTP status, or 0 for a transport failure.
  final int status;

  /// The decoded body, or null when empty or not JSON.
  final Object? json;

  /// The response headers, names lower-cased (repeated values joined with
  /// `,`). Empty for a transport failure.
  final Map<String, String> headers;

  /// Whether GitHub answered 2xx.
  bool get ok => status >= 200 && status < 300;

  /// Whether GitHub was unreachable or failing (transport, 5xx).
  bool get unavailable => status == 0 || status >= 500;
}

/// The few GitHub REST calls `GitHubClients` (and the sign-in lanes beside
/// it) make outside an `RhttpClient`: the App-authenticated `/applications`
/// endpoints, the bare repository and installation reads that bound a mint,
/// and token revocation. One transport, one header set, one API version,
/// never following redirects. Not final so a test can stand in for GitHub.
class GitHubRest {
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
          CcHostLog.warning(
            'github: $method ${_template(path)} answered more than '
            '$_maxBodyBytes bytes; treated as unreached',
          );
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
      final headers = <String, String>{};
      response.headers.forEach(
        (name, values) => headers[name.toLowerCase()] = values.join(','),
      );
      return GitHubRestResponse(response.statusCode, json, headers: headers);
    } on Object catch (e) {
      // Reported as status 0 (GitHub not reached); the endpoint and the
      // error's type say why without the request's credential.
      CcHostLog.warning(
        'github: $method ${_template(path)} did not reach GitHub '
        '(${e.runtimeType})',
      );
      return const GitHubRestResponse(0, null);
    }
  }

  /// Closes the transport. Calls after this fail as unreachable.
  void close() => _http.close(force: true);

  /// [path] with numeric segments as `{n}`: what a log line names it by.
  static String _template(String path) =>
      path.replaceAll(RegExp(r'/\d+'), '/{n}');
}
