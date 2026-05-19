import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/dedup_interceptor.dart';
import 'package:cc_infra/src/network/retry_interceptor.dart';
import 'package:dio/dio.dart';

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
      headers: {
        'Accept': 'application/json',
      },
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

  if (CcInfraLog.verbose) {
    // Verbose request/response logging with TRUNCATED bodies. The request body
    // is the payload we send — for GraphQL that's the actual query, so an
    // over-expensive batch query is visible at a glance; the response body is
    // GitHub's payload. Bodies are capped (see `_bodyForLog`) so large PR/file
    // payloads can't stall the UI isolate — the reason the previous
    // `LogInterceptor` kept bodies off entirely. Auth headers are never logged.
    // Errors are logged by the wrapper below (in every build, not just debug).
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final body = _bodyForLog(options.data);
          CcInfraLog.info(
            'Dio: → ${options.method} ${options.uri}'
            '${body.isNotEmpty ? '\n  request: $body' : ''}',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          CcInfraLog.info(
            'Dio: ← ${response.statusCode} ${response.requestOptions.uri}'
            '\n  response: ${_bodyForLog(response.data)}',
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
        // Include the (truncated) request + response bodies on every error in
        // every build. The request body is the GraphQL query that failed and
        // the response body is GitHub's reason — a 403 says "secondary rate
        // limit" vs "missing scope", a 504 returns its gateway page — which is
        // what makes an otherwise opaque "bad response" diagnosable.
        final req = _bodyForLog(e.requestOptions.data);
        final resp = _bodyForLog(e.response?.data);
        final detail = '${req.isNotEmpty ? '\n  request: $req' : ''}'
            '${resp.isNotEmpty ? '\n  response: $resp' : ''}';
        if (statusCode != null && (statusCode == 401 || statusCode == 403)) {
          // 401/403 are intentionally passed through untouched so the auth
          // layer can react (token refresh / re-auth) — we only add logging,
          // not control flow. They were previously swallowed with NO logging
          // at all, which made a GitHub GraphQL 403 invisible.
          CcInfraLog.warning(
            'Dio: Auth/forbidden $statusCode on ${e.requestOptions.uri}: '
            '${e.message}$detail',
          );
          handler.next(e);
          return;
        }
        CcInfraLog.error(
          'Dio: Network error ${statusCode ?? ''} on ${e.requestOptions.uri}: '
          '${e.message}$detail',
          e,
        );
        handler.next(e);
      },
    ),
  );

  return dio;
}

/// Renders a request/response [data] payload as a single, log-friendly string,
/// capped at [max] chars. GitHub payloads (PR file lists, batched multi-repo
/// queries, contribution calendars) run to hundreds of KB; logging them whole
/// stalls the UI isolate, so anything past [max] is dropped with a count. Never
/// pass headers here — only bodies, which carry no auth token.
String _bodyForLog(Object? data, {int max = 2000}) {
  if (data == null) {
    return '';
  }
  final text = data is String ? data : data.toString();
  if (text.length <= max) {
    return text;
  }
  return '${text.substring(0, max)}… [+${text.length - max} chars]';
}
