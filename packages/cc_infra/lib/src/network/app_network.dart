import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/dedup_interceptor.dart';
import 'package:cc_infra/src/network/retry_interceptor.dart';
import 'package:dio/dio.dart';

/// Request-extra key naming the HTTP statuses THIS caller reads as an answer
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
/// It suppresses only the LOG line: the [DioException] still travels the normal
/// path, so the caller's own handling is untouched.
const String expectedStatusesExtra = '__ccExpectedStatuses';

/// Request extras marking [statuses] as expected for one request, so a status
/// the caller reads as an answer is not logged as an error.
///
/// ```dart
/// options: Options(extra: expectStatuses(const [429]))
/// ```
///
/// Merge it into extras you already pass: `{...expectStatuses(const [429]), …}`.
Map<String, dynamic> expectStatuses(Iterable<int> statuses) => {
  expectedStatusesExtra: List<int>.unmodifiable(statuses),
};

/// Creates a configured [Dio] instance.
///
/// `baseUrl` is optional and defaults to an empty string.
/// Authentication headers should be added by callers via `dio.interceptors`.
Dio createDio({String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      // Set Accept here, but never a default Content-Type. Content-Type
      // describes a request *body*; forcing `application/json` onto bodiless
      // GETs makes strict servers (e.g. Cloudflare-fronted feeds like Hacker
      // News' RSS) reject the request with 415 Unsupported Media Type — a
      // browser sends no Content-Type on a GET, which is why those URLs work
      // in a browser but 415 here. Dio's transformer still sets
      // `application/json` automatically for POST/PUT/PATCH requests that
      // carry a Map/List body, so JSON APIs are unaffected; callers needing a
      // different type (e.g. OAuth token endpoints) set `contentType` per
      // request.
      headers: {'Accept': 'application/json'},
    ),
  );

  // Decode large JSON responses on a background isolate so big GitHub payloads
  // (PR file lists with patches, batched multi-repo PR queries, contribution
  // calendars) are parsed off the UI thread and don't drop frames. Small
  // responses stay on the fast main-isolate fused UTF8+JSON decoder, where
  // spawning an isolate would cost more than the parse. 50 KB matches the
  // threshold Flutter uses for the same trade-off. Set explicitly rather than
  // relying on Dio's default so the behaviour is guaranteed across upgrades.
  dio.transformer = FusedTransformer(contentLengthIsolateThreshold: 50 * 1024);

  dio.interceptors.add(RetryInterceptor(dio: dio));
  // Coalesce identical concurrent GETs so duplicate requests (e.g. the PR-list
  // fan-out colliding with the background PR poller, or several widgets
  // watching the same PR) become a single network call.
  dio.interceptors.add(DedupInterceptor(dio));

  if (CcInfraLog.isEnabled(CcInfraLogLevel.debug)) {
    // Debug-tier request/response logging with TRUNCATED bodies. The request
    // body is the payload we send — for GraphQL that's the actual query, so an
    // over-expensive batch query is visible at a glance; the response body is
    // GitHub's payload. Bodies are capped (see `_bodyForLog`) so large PR/file
    // payloads can't stall the UI isolate — the reason the previous
    // `LogInterceptor` kept bodies off entirely. Auth headers are never logged.
    // Errors are logged by the wrapper below (at every level).
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final body = _bodyForLog(options.data);
          CcInfraLog.debug(
            'HTTP → ${options.method} ${options.uri}'
            '${body.isNotEmpty ? ' | request: $body' : ''}',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          CcInfraLog.debug(
            'HTTP ← ${response.statusCode} ${response.requestOptions.uri}'
            ' | response: ${_bodyForLog(response.data)}',
          );
          handler.next(response);
        },
      ),
    );
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException e, handler) {
        final statusCode = e.response?.statusCode;
        if (e.type == DioExceptionType.cancel) {
          // Cancellation is a subscriber standing down (a Riverpod
          // `onDispose` cancelling its in-flight request), not a failure —
          // every client rethrows it by type so the caller can swallow it
          // quietly. Keep the debug-tier log symmetric (every "→" gets a
          // matching inbound line) but never surface it as an error.
          CcInfraLog.debug('HTTP ✕ cancelled ${e.requestOptions.uri}');
          handler.next(e);
          return;
        }
        // Include the (truncated, whitespace-collapsed) request + response
        // bodies on every error in every build, on the SAME line as the status
        // and URL so one failure is one greppable line. The request body is the
        // GraphQL query that failed and the response body is the server's
        // reason — a 403 says "secondary rate limit" vs "missing scope", a 401
        // says "OAuth access token has expired", a 504 returns its gateway page
        // — which is what makes an otherwise opaque "bad response" diagnosable.
        final req = _bodyForLog(e.requestOptions.data);
        final resp = _bodyForLog(e.response?.data);
        final reason = _reasonForLog(e);
        final detail =
            '${reason.isNotEmpty ? ' | $reason' : ''}'
            '${req.isNotEmpty ? ' | request: $req' : ''}'
            '${resp.isNotEmpty ? ' | response: $resp' : ''}';
        if (statusCode != null &&
            _isExpectedStatus(e.requestOptions, statusCode)) {
          // The caller declared this status an ANSWER for this request (see
          // [expectedStatusesExtra]) — it reads the body and turns it into
          // state, so an error line says something is broken when nothing is.
          // Kept at debug: the exchange is still there with logging turned up,
          // and the error itself is forwarded untouched.
          CcInfraLog.debug('HTTP $statusCode ${e.requestOptions.uri}$detail');
          handler.next(e);
          return;
        }
        if (statusCode != null && (statusCode == 401 || statusCode == 403)) {
          // 401/403 are intentionally passed through untouched so the auth
          // layer can react (token refresh / re-auth) — we only add logging,
          // not control flow. They were previously swallowed with NO logging
          // at all, which made a GitHub GraphQL 403 invisible.
          CcInfraLog.warning('HTTP $statusCode ${e.requestOptions.uri}$detail');
          handler.next(e);
          return;
        }
        if (statusCode == 410 &&
            e.requestOptions.uri.queryParameters.containsKey('syncToken')) {
          // Google Calendar answers 410 (`fullSyncRequired`) when an
          // incremental sync token expires — an EXPECTED, self-healing signal
          // the calendar sync catches ([CalendarSyncTokenExpired]) to fall
          // back to a token-minting full sync. Not an error; keep it visible
          // at info so token churn is still diagnosable.
          CcInfraLog.info(
            'HTTP 410 sync token expired on ${e.requestOptions.uri.path} — '
            'caller falls back to a full sync',
          );
          handler.next(e);
          return;
        }
        CcInfraLog.error(
          'HTTP ${statusCode ?? e.type.name} ${e.requestOptions.uri}$detail',
          // The ROOT cause (a SocketException, a HandshakeException), never the
          // DioException itself: both sinks append the error's `toString()` to
          // the line, and a DioException's re-prints the same boilerplate
          // paragraph [_reasonForLog] deliberately drops. Null on a bad
          // response, where the status and the body already say everything.
          e.error,
        );
        handler.next(e);
      },
    ),
  );

  return dio;
}

/// Whether [statusCode] is one the request declared expected via
/// [expectStatuses]. The extras survive a retry (`RetryInterceptor` copies them
/// onto the re-issued request) and a coalesced waiter, so the marker holds for
/// every attempt, not just the first.
bool _isExpectedStatus(RequestOptions options, int statusCode) {
  final expected = options.extra[expectedStatusesExtra];
  return expected is Iterable && expected.contains(statusCode);
}

/// The part of [DioException.message] worth logging, or `''` when there is
/// none.
///
/// Dio's message for a bad response is a fixed four-line paragraph about
/// `validateStatus`, what an HTTP status class means and a link to MDN. It is
/// byte-identical on every failed request, says nothing about THIS one, and
/// buried the parts that do (the URL, the status, the server's own reason)
/// under four lines of noise on every warning and error. The exception types
/// whose message IS specific — timeouts, connection and certificate failures,
/// an unknown wrapped error — keep theirs, whitespace-collapsed onto the one
/// line (an `unknown` wraps an arbitrary error whose `toString()` may not be).
String _reasonForLog(DioException e) {
  if (e.type == DioExceptionType.badResponse) {
    return '';
  }
  final message = e.message ?? '';
  return message.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Renders a request/response [data] payload as a single, log-friendly string,
/// capped at [max] chars. GitHub payloads (PR file lists, batched multi-repo
/// queries, contribution calendars) run to hundreds of KB; logging them whole
/// stalls the UI isolate, so anything past [max] is dropped with a count. Never
/// pass headers here — only bodies, which carry no auth token.
///
/// Internal whitespace is collapsed so one request is one log line: a GraphQL
/// query arrives with a newline per field and a gateway's 504 page is whole
/// HTML, either of which would otherwise smear a single failure across a
/// screenful of log and break line-oriented tooling (`grep`, the log tail).
/// [max] is applied AFTER the collapse so the cap counts content, not
/// indentation.
String _bodyForLog(Object? data, {int max = 2000}) {
  if (data == null) {
    return '';
  }
  final raw = data is String ? data : data.toString();
  final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.length <= max) {
    return text;
  }
  return '${text.substring(0, max)}… [+${text.length - max} chars]';
}
