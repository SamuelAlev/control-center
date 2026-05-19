import 'package:dio/dio.dart';

/// Coalesces identical concurrent GET requests into a single network call.
///
/// When two or more requests sharing the same `(method, URI, Accept)` are in
/// flight at the same time, only the first reaches the network; the others
/// resolve from that same response. This removes duplicate GitHub calls that
/// otherwise arise when several providers/widgets ask for the same resource
/// simultaneously — e.g. the PR-list fan-out colliding with the background PR
/// poller's `listOpenPullRequestsPage`, or multiple widgets watching the same
/// PR-detail family at once.
///
/// Only safe, side-effect-free requests are coalesced:
///  * **GET only** — never mutations.
///  * **Requests without a [CancelToken] only.** A coalesced waiter must never
///    be cancelled because an unrelated caller cancelled the shared request
///    (and vice-versa), so any request carrying a cancel token bypasses
///    coalescing entirely. Those are already covered by the app-level SWR cache.
///
/// The interceptor must be constructed with the same [Dio] it is attached to:
/// the first request of a group is re-issued via [Dio.fetch] so it flows back
/// through the full interceptor chain (auth, retry, logging). A marker in
/// [RequestOptions.extra] prevents the re-issued request from being coalesced
/// again, so there is no recursion.
class DedupInterceptor extends Interceptor {
  /// Creates a [DedupInterceptor] bound to [_dio] (the instance it is added to).
  DedupInterceptor(this._dio);

  final Dio _dio;
  final Map<String, Future<Response<dynamic>>> _inFlight = {};

  static const _markerKey = '__dedup_origin';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (!_isCoalescable(options)) {
      handler.next(options);
      return;
    }

    final key = _keyFor(options);
    final existing = _inFlight[key];
    if (existing != null) {
      // Piggy-back on the in-flight request. Clone the response so each waiter
      // carries its own requestOptions; the body/headers are shared (read-only).
      existing.then(
        (resp) => handler.resolve(_cloneFor(resp, options)),
        onError: (Object e, _) => handler.reject(_asDioException(e, options)),
      );
      return;
    }

    // First request of this group: re-issue it through the whole chain (so it
    // still picks up auth + retry) with a marker so it is not re-coalesced.
    final marked = options.copyWith(
      extra: {...options.extra, _markerKey: true},
    );
    final future = _dio.fetch<dynamic>(marked);
    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    future.then(
      (resp) => handler.resolve(resp),
      onError: (Object e, _) => handler.reject(_asDioException(e, options)),
    );
  }

  bool _isCoalescable(RequestOptions options) {
    if (options.extra[_markerKey] == true) {
      return false;
    }
    if (options.method.toUpperCase() != 'GET') {
      return false;
    }
    if (options.cancelToken != null) {
      return false;
    }
    return true;
  }

  String _keyFor(RequestOptions options) {
    final accept = options.headers['Accept']?.toString() ?? '';
    final responseType = options.responseType.name;
    return '${options.uri}::$accept::$responseType';
  }

  Response<dynamic> _cloneFor(
    Response<dynamic> resp,
    RequestOptions options,
  ) {
    return Response<dynamic>(
      requestOptions: options,
      data: resp.data,
      statusCode: resp.statusCode,
      statusMessage: resp.statusMessage,
      headers: resp.headers,
      isRedirect: resp.isRedirect,
      redirects: resp.redirects,
      extra: resp.extra,
    );
  }

  DioException _asDioException(Object e, RequestOptions options) {
    if (e is DioException) {
      return e;
    }
    return DioException(requestOptions: options, error: e);
  }
}
