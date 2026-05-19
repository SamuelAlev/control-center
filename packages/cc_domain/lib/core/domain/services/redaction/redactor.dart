import 'dart:convert';

/// The marker substituted for a redacted value.
const String kRedacted = '[REDACTED]';

/// An immutable snapshot of an HTTP request, the unit a [Redactor] and the
/// cassette matcher operate on.
class RequestSnapshot {
  /// Creates a [RequestSnapshot].
  const RequestSnapshot({
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
  });

  /// HTTP method (upper-case).
  final String method;

  /// Full request URL.
  final String url;

  /// Request headers, lower-cased keys by convention.
  final Map<String, String> headers;

  /// Request body as a string (empty when none).
  final String body;

  /// Returns a copy with the given overrides.
  RequestSnapshot copyWith({
    String? method,
    String? url,
    Map<String, String>? headers,
    String? body,
  }) => RequestSnapshot(
    method: method ?? this.method,
    url: url ?? this.url,
    headers: headers ?? this.headers,
    body: body ?? this.body,
  );

  /// Serializes to a cassette JSON map.
  Map<String, dynamic> toJson() => {
    'method': method,
    'url': url,
    'headers': headers,
    'body': body,
  };

  /// Reads a snapshot from a cassette JSON map.
  static RequestSnapshot fromJson(Map<String, dynamic> json) => RequestSnapshot(
    method: json['method'] as String,
    url: json['url'] as String,
    headers: (json['headers'] as Map).map(
      (k, v) => MapEntry(k as String, '$v'),
    ),
    body: json['body'] as String? ?? '',
  );
}

/// An immutable snapshot of an HTTP response.
class ResponseSnapshot {
  /// Creates a [ResponseSnapshot].
  const ResponseSnapshot({
    required this.status,
    required this.headers,
    required this.body,
    this.bodyEncoding = 'text',
  });

  /// HTTP status code.
  final int status;

  /// Response headers.
  final Map<String, String> headers;

  /// Response body — UTF-8 text, or base64 when [bodyEncoding] is `base64`.
  final String body;

  /// Either `text` or `base64`.
  final String bodyEncoding;

  /// Returns a copy with the given overrides.
  ResponseSnapshot copyWith({
    int? status,
    Map<String, String>? headers,
    String? body,
    String? bodyEncoding,
  }) => ResponseSnapshot(
    status: status ?? this.status,
    headers: headers ?? this.headers,
    body: body ?? this.body,
    bodyEncoding: bodyEncoding ?? this.bodyEncoding,
  );

  /// Serializes to a cassette JSON map.
  Map<String, dynamic> toJson() => {
    'status': status,
    'headers': headers,
    'body': body,
    if (bodyEncoding != 'text') 'bodyEncoding': bodyEncoding,
  };

  /// Reads a snapshot from a cassette JSON map.
  static ResponseSnapshot fromJson(Map<String, dynamic> json) =>
      ResponseSnapshot(
        status: (json['status'] as num).toInt(),
        headers: (json['headers'] as Map).map(
          (k, v) => MapEntry(k as String, '$v'),
        ),
        body: json['body'] as String? ?? '',
        bodyEncoding: json['bodyEncoding'] as String? ?? 'text',
      );
}

/// Transforms request/response snapshots before they are written to a cassette,
/// scrubbing sensitive material. Composable: combine narrow transforms (header
/// allow-lists, URL query scrubbing, body JSON rewrites) with [Redactor.compose]
/// into one redactor. Reusable beyond cassettes — e.g. for log scrubbing.
abstract interface class Redactor {
  /// Redacts a request snapshot.
  RequestSnapshot redactRequest(RequestSnapshot snapshot);

  /// Redacts a response snapshot.
  ResponseSnapshot redactResponse(ResponseSnapshot snapshot);

  /// Composes [redactors] left-to-right into one. Request transforms apply in
  /// order; response transforms likewise.
  static Redactor compose(Iterable<Redactor> redactors) =>
      _ComposedRedactor(redactors.toList(growable: false));

  /// The standard redactor: keep an allow-list of request/response headers,
  /// scrub sensitive URL query params and (optionally) rewrite the request
  /// body JSON.
  static Redactor defaults({
    List<String>? requestHeaderAllowList,
    List<String>? responseHeaderAllowList,
    List<String>? redactQueryParams,
    Object? Function(Object? parsed)? bodyTransform,
  }) => compose([
    HeaderRedactor.request(allow: requestHeaderAllowList),
    HeaderRedactor.response(allow: responseHeaderAllowList),
    UrlQueryRedactor(redactQueryParams),
    if (bodyTransform != null) BodyRedactor(bodyTransform),
  ]);
}

/// Default request headers worth keeping (everything else is dropped).
const List<String> kDefaultRequestHeaderAllowList = ['content-type', 'accept'];

/// Default response headers worth keeping.
const List<String> kDefaultResponseHeaderAllowList = ['content-type'];

/// Headers always replaced with [kRedacted] when present in the allow-list.
const List<String> kDefaultRedactHeaders = [
  'authorization',
  'cookie',
  'proxy-authorization',
  'set-cookie',
  'x-api-key',
  'x-amz-security-token',
  'x-goog-api-key',
];

/// Query params whose values are scrubbed from URLs.
const List<String> kDefaultRedactQueryParams = [
  'access_token',
  'api-key',
  'api_key',
  'apikey',
  'code',
  'key',
  'signature',
  'sig',
  'token',
  'x-amz-credential',
  'x-amz-security-token',
  'x-amz-signature',
];

/// Keeps only allow-listed headers, redacting the values of sensitive ones.
class HeaderRedactor implements Redactor {
  /// A redactor that only touches request headers.
  const HeaderRedactor.request({List<String>? allow, List<String>? redact})
    : _allow = allow ?? kDefaultRequestHeaderAllowList,
      _redact = redact ?? kDefaultRedactHeaders,
      _side = _Side.request;

  /// A redactor that only touches response headers.
  const HeaderRedactor.response({List<String>? allow, List<String>? redact})
    : _allow = allow ?? kDefaultResponseHeaderAllowList,
      _redact = redact ?? kDefaultRedactHeaders,
      _side = _Side.response;

  final List<String> _allow;
  final List<String> _redact;
  final _Side _side;

  Map<String, String> _apply(Map<String, String> headers) {
    final allow = _allow.map((h) => h.toLowerCase()).toSet();
    final redact = _redact.map((h) => h.toLowerCase()).toSet();
    final out = <String, String>{};
    for (final entry in headers.entries) {
      final name = entry.key.toLowerCase();
      if (!allow.contains(name)) {
        continue;
      }
      out[name] = redact.contains(name) ? kRedacted : entry.value;
    }
    final keys = out.keys.toList()..sort();
    return {for (final k in keys) k: out[k]!};
  }

  @override
  RequestSnapshot redactRequest(RequestSnapshot s) =>
      _side == _Side.request ? s.copyWith(headers: _apply(s.headers)) : s;

  @override
  ResponseSnapshot redactResponse(ResponseSnapshot s) =>
      _side == _Side.response ? s.copyWith(headers: _apply(s.headers)) : s;
}

enum _Side { request, response }

/// Scrubs sensitive query-param values (and any user:password) from request
/// URLs.
class UrlQueryRedactor implements Redactor {
  /// Creates a [UrlQueryRedactor]; [params] defaults to
  /// [kDefaultRedactQueryParams].
  UrlQueryRedactor([List<String>? params])
    : _params = (params ?? kDefaultRedactQueryParams)
          .map((p) => p.toLowerCase())
          .toSet();

  final Set<String> _params;

  @override
  RequestSnapshot redactRequest(RequestSnapshot s) {
    final uri = Uri.tryParse(s.url);
    if (uri == null) {
      return s;
    }
    var changed = false;
    final params = <String, List<String>>{};
    uri.queryParametersAll.forEach((key, values) {
      if (_params.contains(key.toLowerCase())) {
        params[key] = [kRedacted];
        changed = true;
      } else {
        params[key] = values;
      }
    });
    // userInfo must be a valid URI component, so percent-encode the marker
    // (`[`/`]` are not allowed raw); it decodes back to [kRedacted] on read.
    var userInfo = uri.userInfo;
    if (userInfo.isNotEmpty) {
      userInfo = Uri.encodeComponent(kRedacted);
      changed = true;
    }
    if (!changed) {
      return s;
    }
    final redacted = uri.replace(
      queryParameters: params.isEmpty ? null : params,
      userInfo: userInfo.isEmpty ? null : userInfo,
    );
    return s.copyWith(url: redacted.toString());
  }

  @override
  ResponseSnapshot redactResponse(ResponseSnapshot s) => s;
}

/// Rewrites the request body JSON through [transform] (a no-op when the body is
/// not valid JSON).
class BodyRedactor implements Redactor {
  /// Creates a [BodyRedactor].
  const BodyRedactor(this.transform);

  /// Maps the parsed JSON body to a redacted JSON value.
  final Object? Function(Object? parsed) transform;

  @override
  RequestSnapshot redactRequest(RequestSnapshot s) {
    if (s.body.isEmpty) {
      return s;
    }
    Object? parsed;
    try {
      parsed = jsonDecode(s.body);
    } catch (_) {
      return s;
    }
    return s.copyWith(body: jsonEncode(transform(parsed)));
  }

  @override
  ResponseSnapshot redactResponse(ResponseSnapshot s) => s;
}

class _ComposedRedactor implements Redactor {
  const _ComposedRedactor(this._redactors);

  final List<Redactor> _redactors;

  @override
  RequestSnapshot redactRequest(RequestSnapshot snapshot) =>
      _redactors.fold(snapshot, (acc, r) => r.redactRequest(acc));

  @override
  ResponseSnapshot redactResponse(ResponseSnapshot snapshot) =>
      _redactors.fold(snapshot, (acc, r) => r.redactResponse(acc));
}
