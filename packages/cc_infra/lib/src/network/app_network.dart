import 'dart:convert';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/dedup_interceptor.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/network/retry_interceptor.dart';
// rhttp ships an interceptor of its own with the same name as the cc_infra
// one this file uses; hide it so the local class is unambiguous.
import 'package:rhttp/rhttp.dart' hide RetryInterceptor;

/// Request-metadata key naming the HTTP statuses THIS caller reads as an answer
/// rather than as a failure. Set it with [expectStatuses].
///
/// Some endpoints report a fact through a status code the caller then turns
/// into ordinary state: Kimi's `/usages` answers a spent plan with a `429`
/// carrying `resource_exhausted`, which `SubscriptionUsageService` reads as an
/// `exhausted` snapshot — the pill's whole job. Logging that at error level
/// puts a red line (and the credential-shaped body next to it) in the log on
/// every poll for a condition nothing is wrong about, which trains the operator
/// to ignore the lane where the real failures land.
///
/// It suppresses only the LOG line: the [RhttpStatusCodeException] still
/// travels the normal path, so the caller's own handling is untouched.
const String expectedStatusesExtra = '__ccExpectedStatuses';

/// Request metadata ([BaseHttpRequest.additionalData]) marking [statuses] as
/// expected for one request, so a status the caller reads as an answer is not
/// logged as an error.
///
/// ```dart
/// final response = await client.send(
///   BaseHttpRequest(
///     method: HttpMethod.get,
///     url: '/usages',
///     headers: HttpHeaders.rawMap({'Authorization': 'Bearer $token'}),
///     expectBody: HttpExpectBody.text,
///   )..additionalData.addAll(expectStatuses(const [429])),
/// );
/// ```
///
/// The marker is request metadata, not a header: it never reaches the wire.
/// It survives a retry (the re-issued request copies `additionalData`) and a
/// coalesced waiter.
Map<String, dynamic> expectStatuses(Iterable<int> statuses) => {
  expectedStatusesExtra: List<int>.unmodifiable(statuses),
};

/// The timeouts the shared clients apply when the caller configures none.
///
/// Connection and total request deadlines are both 30 seconds. Callers can
/// supply their own [TimeoutSettings], including no total deadline for large
/// streaming downloads.
const TimeoutSettings kDefaultHttpTimeoutSettings = TimeoutSettings(
  connectTimeout: Duration(seconds: 30),
  timeout: Duration(seconds: 30),
);

/// The trust store the shared clients use when the caller configures none.
///
/// Platform roots include locally trusted certificates, such as corporate
/// certificate authorities. Certificate verification remains enabled.
const TlsSettings kDefaultTlsSettings = TlsSettings(
  rootCertSource: RootCertSource.platform,
);

/// Creates a configured [RhttpClient] — the shared transport every cc_infra
/// HTTP client is built on.
///
/// The returned client is SYNCHRONOUS to construct (`RhttpClient.createSync`),
/// so it can be built in a field initializer, but the native library must have
/// been loaded first: call `await initializeRhttp()` (from `cc_natives`) once
/// per isolate before the first client is created.
///
/// `baseUrl`, when given, is merged into [settings]; [settings] is therefore
/// immutable and configured once, and `baseUrl` cannot be mutated afterwards.
///
/// The interceptor chain, in order:
/// 1. [HttpRequestNormalizer] — absolute URLs win over `baseUrl`, and absent
///    `Accept: application/json` is defaulted.
/// 2. [interceptors] — the caller's own, e.g. the forge factory's auth, which
///    therefore runs BEFORE deduplication and is part of the request identity.
/// 3. [RetryInterceptor] — transient-failure retries plus the GitHub
///    rate-limit circuit breaker.
/// 4. [DedupInterceptor] — identity-sensitive coalescing of concurrent GETs.
/// 5. [HttpLogInterceptor] — request/response traces at debug and one failure
///    line per request at the level its status deserves.
RhttpClient createHttpClient({
  String? baseUrl,
  ClientSettings settings = const ClientSettings(),
  List<Interceptor> interceptors = const [],
}) {
  return RhttpClient.createSync(
    settings: httpClientSettings(baseUrl: baseUrl, settings: settings),
    interceptors: sharedHttpInterceptors(interceptors: interceptors),
  );
}

/// [settings] plus the cc_infra defaults for whatever it leaves unset.
///
/// Only UNSET fields are filled, so a caller's [ClientSettings] is never
/// second-guessed — a client's own timeouts, trust store and User-Agent win
/// (see [kDefaultHttpTimeoutSettings] and [kDefaultTlsSettings]).
ClientSettings httpClientSettings({
  String? baseUrl,
  ClientSettings settings = const ClientSettings(),
}) {
  var configured = settings;
  if (baseUrl != null) {
    configured = configured.copyWith(baseUrl: baseUrl);
  }
  if (configured.timeoutSettings == null) {
    configured = configured.copyWith(
      timeoutSettings: kDefaultHttpTimeoutSettings,
    );
  }
  if (configured.tlsSettings == null) {
    configured = configured.copyWith(tlsSettings: kDefaultTlsSettings);
  }
  if (configured.userAgent == null) {
    // reqwest sends no User-Agent by default; GitHub rejects such requests.
    // Set it once on the native client, not by copying every request's headers.
    configured = configured.copyWith(
      userAgent:
          'ControlCenter/1.0 (+https://github.com/SamuelAlev/control-center)',
    );
  }
  return configured;
}

/// The interceptor chain every shared client runs, in order:
/// [HttpRequestNormalizer], then [interceptors] — the caller's own, e.g. the
/// forge factory's auth, which therefore runs BEFORE deduplication and is part
/// of the request identity — then [RetryInterceptor], then [DedupInterceptor],
/// then [HttpLogInterceptor].
List<Interceptor> sharedHttpInterceptors({
  List<Interceptor> interceptors = const [],
}) => [
  HttpRequestNormalizer(),
  ...interceptors,
  RetryInterceptor(),
  DedupInterceptor(),
  HttpLogInterceptor(),
];

/// Normalizes an outgoing request so every cc_infra client agrees on what the
/// wire URL is, and applies the shared default headers.
///
/// 1. **An absolute URL wins over `baseUrl`.** Pagination follows absolute
///    `next` links, and downloads may target another host. Relative URLs are
///    joined to the base with duplicate slashes collapsed and dot segments
///    resolved.
/// 2. **`Accept: application/json` is defaulted**, never a `Content-Type`.
///    `Content-Type` describes a request *body*; forcing `application/json`
///    onto bodiless GETs makes strict servers (e.g. Cloudflare-fronted feeds
///    like Hacker News' RSS) reject the request with 415 Unsupported Media
///    Type — a browser sends no `Content-Type` on a GET, which is why those
///    URLs work in a browser. rhttp sets `application/json` itself for a
///    [HttpBody.json] body, so JSON APIs are unaffected.
class HttpRequestNormalizer extends Interceptor {
  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    var outgoing = request;

    final settings = outgoing.settings;
    final baseUrl = settings?.baseUrl;
    if (baseUrl != null && baseUrl.isNotEmpty) {
      outgoing = outgoing.copyWith(
        url: _joinedUrl(baseUrl, outgoing.url),
        // Per-request: the client's own settings are immutable and untouched,
        // and the URL is already absolute by now, so leaving baseUrl in place
        // would prefix it a second time.
        settings: settings!.copyWith(baseUrl: null),
      );
    }

    if (!_hasHeader(outgoing.headers, 'accept')) {
      outgoing = outgoing.copyWith(
        headers: (outgoing.headers ?? HttpHeaders.empty).copyWithRaw(
          name: 'Accept',
          value: 'application/json',
        ),
      );
    }

    return Interceptor.next(identical(outgoing, request) ? null : outgoing);
  }
}

/// Joins relative [url] onto [baseUrl], collapsing duplicate slashes after the
/// scheme and resolving dot segments. Absolute HTTP(S) URLs ignore the base.
String _joinedUrl(String baseUrl, String url) {
  if (_absoluteUrlPattern.hasMatch(url)) {
    return url;
  }
  var combined = '$baseUrl$url';
  final parts = combined.split(':/');
  if (parts.length == 2) {
    combined = '${parts[0]}:/${parts[1].replaceAll('//', '/')}';
  }
  return Uri.parse(combined).normalizePath().toString();
}

final RegExp _absoluteUrlPattern = RegExp(r'^https?:');

/// Logs every request/response at debug level and every failure once, at the
/// level its status deserves.
///
/// The levels are deliberate: a cancellation is a subscriber standing down, a
/// status the caller declared via [expectStatuses] is an ANSWER, a Google
/// Calendar `410` on a `syncToken` request is a self-healing full-sync signal,
/// a `401`/`403` is the auth layer's business, and everything else is an error
/// with the server's own words attached.
///
/// It sits LAST in the shared chain so the line it logs is the FINAL failure —
/// after [RetryInterceptor] has exhausted its attempts — and it stays silent
/// for a retry's intermediate failures, which the retry loop owns: one network
/// request, one failure line.
class HttpLogInterceptor extends Interceptor {
  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    if (!CcInfraLog.isEnabled(CcInfraLogLevel.debug)) {
      return Interceptor.next();
    }
    // TRUNCATED bodies: the request body is the payload we send — for GraphQL
    // that's the actual query, so an over-expensive batch query is visible at
    // a glance — and it is capped (see [_collapse]) so large PR/file payloads
    // can't stall the UI isolate. Auth headers are never logged.
    final body = _collapse(_requestBody(request.body));
    CcInfraLog.debug(
      'HTTP → ${request.method.value} ${_urlOf(request)}'
      '${body.isNotEmpty ? ' | request: $body' : ''}',
    );
    return Interceptor.next();
  }

  @override
  Future<InterceptorResult<HttpResponse>> afterResponse(
    HttpResponse response,
  ) async {
    if (!CcInfraLog.isEnabled(CcInfraLogLevel.debug)) {
      return Interceptor.next();
    }
    CcInfraLog.debug(
      'HTTP ← ${response.statusCode} ${_urlOf(response.request)}'
      ' | response: ${_collapse(_responseBody(response))}',
    );
    return Interceptor.next();
  }

  @override
  Future<InterceptorResult<RhttpException>> onError(
    RhttpException exception,
  ) async {
    final request = exception.request;
    if (exception is RhttpCancelException) {
      // Cancellation is a subscriber standing down (a Riverpod `onDispose`
      // cancelling its in-flight request), not a failure — every client
      // rethrows it by type so the caller can swallow it quietly. Keep the
      // debug-tier log symmetric (every "→" gets a matching inbound line) but
      // never surface it as an error.
      CcInfraLog.debug('HTTP ✕ cancelled ${_urlOf(request)}');
      return Interceptor.next();
    }

    if (request.additionalData.containsKey(RetryInterceptor.retryCountKey)) {
      // Only log the final request outcome, not failures the retry loop handles.
      return Interceptor.next();
    }

    final statusCode = exception is RhttpStatusCodeException
        ? exception.statusCode
        : null;
    // Include the (truncated, whitespace-collapsed) request + response bodies
    // on every error in every build, on the SAME line as the status and URL so
    // one failure is one greppable line. The request body is the GraphQL query
    // that failed and the response body is the server's reason — a 403 says
    // "secondary rate limit" vs "missing scope", a 401 says "OAuth access
    // token has expired", a 504 returns its gateway page — which is what makes
    // an otherwise opaque failure diagnosable.
    final reason = httpExceptionReason(exception);
    final req = _collapse(_requestBody(request.body));
    final resp = _collapse(
      exception is RhttpStatusCodeException
          ? _collapseBody(exception.body)
          : '',
    );
    final detail =
        '${reason != null ? ' | $reason' : ''}'
        '${req.isNotEmpty ? ' | request: $req' : ''}'
        '${resp.isNotEmpty ? ' | response: $resp' : ''}';
    final kind = statusCode?.toString() ?? _kindOf(exception);
    final line = 'HTTP $kind ${_urlOf(request)}$detail';

    if (statusCode != null && _isExpectedStatus(request, statusCode)) {
      // The caller declared this status an ANSWER for this request (see
      // [expectedStatusesExtra]) — it reads the body and turns it into state,
      // so an error line says something is broken when nothing is. Kept at
      // debug: the exchange is still there with logging turned up, and the
      // error itself is forwarded untouched.
      CcInfraLog.debug(line);
      return Interceptor.next();
    }
    if (statusCode == 401 || statusCode == 403) {
      // The auth layer handles token refresh or re-authentication; logging must
      // leave the error untouched.
      CcInfraLog.warning(line);
      return Interceptor.next();
    }
    if (statusCode == 410 && _hasSyncToken(request)) {
      // Google Calendar answers 410 (`fullSyncRequired`) when an incremental
      // sync token expires — an EXPECTED, self-healing signal the calendar
      // sync catches to fall back to a token-minting full sync. Not an error;
      // keep it visible at info so token churn is still diagnosable. The body
      // is left off: the whole exchange carries nothing more than the path the
      // caller already knew.
      CcInfraLog.info(
        'HTTP 410 sync token expired on ${_pathOf(request)} — '
        'caller falls back to a full sync',
      );
      return Interceptor.next();
    }
    CcInfraLog.error(line, _rootCause(exception));
    return Interceptor.next();
  }
}

/// Whether [statusCode] is one the request declared expected via
/// [expectStatuses]. The metadata survives a retry (`RetryInterceptor` copies
/// it onto the re-issued request), so the marker holds for every attempt, not
/// just the first.
bool _isExpectedStatus(HttpRequest request, int statusCode) {
  final expected = request.additionalData[expectedStatusesExtra];
  return expected is Iterable && expected.contains(statusCode);
}

/// Whether the request carries a Google Calendar `syncToken` (in either the
/// typed query map or the raw pair list).
bool _hasSyncToken(HttpRequest request) =>
    request.query?.containsKey('syncToken') == true ||
    (request.queryRaw?.any((part) => part.$1 == 'syncToken') ?? false);

/// The URL a request will actually hit, base URL included.
String _urlOf(HttpRequest request) =>
    '${request.settings?.baseUrl ?? ''}${request.url}';

/// The path of a request, for log lines that name the endpoint alone.
String _pathOf(HttpRequest request) =>
    Uri.tryParse(request.url)?.path ?? request.url;

/// A short, loggable name for a failure that never produced a status.
String _kindOf(RhttpException exception) => switch (exception) {
  RhttpCancelException() => 'cancelled',
  RhttpTimeoutException() => 'timeout',
  RhttpRedirectException() => 'redirect',
  RhttpInvalidCertificateException() => 'invalid_certificate',
  RhttpConnectionException() => 'connection',
  RhttpClientDisposedException() => 'client_disposed',
  RhttpInterceptorException() => 'interceptor_error',
  RhttpUnknownException() => 'unknown_error',
  RhttpStatusCodeException() => 'status',
  _ => 'error',
};

/// The ROOT cause worth handing to the log sink, or `null`.
///
/// An [RhttpInterceptorException] wraps an arbitrary error (a token lookup that
/// threw, say) which the log line does not otherwise show; for every other
/// failure the line already says everything the exception knows, and passing
/// the exception itself would only append its class name and URL a second time.
Object? _rootCause(RhttpException exception) =>
    exception is RhttpInterceptorException ? exception.error : null;

/// The request body as text — the payload we actually send.
String _requestBody(HttpBody? body) => switch (body) {
  null => '',
  HttpBodyText(:final text) => text,
  HttpBodyJson(:final json) => _encode(json),
  HttpBodyForm(:final form) => _encode(form),
  HttpBodyBytes(:final bytes) => '<${bytes.length} bytes>',
  HttpBodyBytesStream(:final length) =>
    length == null ? '<bytes stream>' : '<bytes stream: $length bytes>',
  HttpBodyMultipart(:final parts) => '<multipart: ${parts.length} part(s)>',
};

/// The response body as text. A stream is NOT read: it is the caller's to
/// consume, and logging it would either stall on it or steal it.
String _responseBody(HttpResponse response) => switch (response) {
  HttpTextResponse(:final body) => body,
  HttpBytesResponse(:final body) => '<${body.length} bytes>',
  HttpStreamResponse() => '',
};

String _encode(Object? value) {
  try {
    return jsonEncode(value);
  } on Object {
    // A log line must never be the reason a request fails.
    return value.toString();
  }
}

/// Renders a raw error body (text, or bytes decoded leniently).
String _collapseBody(Object? body) => switch (body) {
  String body => body,
  List<int> bytes when bytes.isNotEmpty => utf8.decode(
    bytes,
    allowMalformed: true,
  ),
  _ => '',
};

/// Renders a payload as a single, log-friendly string, capped at 2000 chars.
///
/// GitHub payloads (PR file lists, batched multi-repo queries, contribution
/// calendars) run to hundreds of KB; logging them whole stalls the UI isolate,
/// so anything past the cap is dropped with a count. Internal whitespace is
/// collapsed so one request is one log line: a GraphQL query arrives with a
/// newline per field and a gateway's 504 page is whole HTML, either of which
/// would otherwise smear a single failure across a screenful of log and break
/// line-oriented tooling (`grep`, the log tail). The cap is applied AFTER the
/// collapse so it counts content, not indentation.
String _collapse(String payload, {int max = 2000}) {
  final text = payload.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.length <= max) {
    return text;
  }
  return '${text.substring(0, max)}… [+${text.length - max} chars]';
}

/// Whether [headers] carries [name], case-insensitively.
bool _hasHeader(HttpHeaders? headers, String name) {
  if (headers == null) {
    return false;
  }
  final lower = name.toLowerCase();
  return headers.toMapList().keys.any((key) => key.toLowerCase() == lower);
}
