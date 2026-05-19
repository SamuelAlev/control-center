import 'dart:convert';

import 'package:cc_infra/src/network/retry_interceptor.dart';
import 'package:crypto/crypto.dart';
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
///  * **Never a [RetryInterceptor] re-issue.** See [_isCoalescable] — that one
///    is a deadlock, not an optimisation.
///
/// The first request of a group flows through the full interceptor chain
/// (auth, retry, logging) via `handler.next`; its outcome — success OR failure
/// — is fanned out to the coalesced waiters from [onResponse]/[onError]. This
/// avoids re-issuing the request (which raced under dio 5.x: a coalesced
/// waiter could attach to an already-settled in-flight future and never
/// resolve) and never creates a second unlistened error future (the regression
/// that once crashed the zone-less `cc_server` on a 415 feed).
class DedupInterceptor extends Interceptor {
  /// Creates a [DedupInterceptor]. The optional [dio] argument is accepted for
  /// backward compatibility with earlier call sites and is otherwise unused —
  /// the interceptor drives coalesced waiters from [onResponse]/[onError]
  /// rather than re-issuing through a [Dio] instance.
  DedupInterceptor([Dio? dio]);

  /// Pending coalescable groups keyed by
  /// `(URI, Accept, responseType, credential)`.
  ///
  /// Per INSTANCE, and that matters: `createDio` builds a fresh interceptor per
  /// client, so two clients never share a group. Isolation BETWEEN identities
  /// therefore comes from having separate clients (one `ForgeDioFactory` per
  /// acting user); the credential in the key is what protects a client that
  /// legitimately serves several credentials — one usage service reading three
  /// Claude subscriptions, say.
  final Map<String, _InFlight> _inFlight = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isCoalescable(options)) {
      handler.next(options);
      return;
    }

    final key = _keyFor(options);
    // Stamp it. Interceptors further down the chain MUTATE headers — the forge
    // factory adds `Authorization` after this one runs — so recomputing the key
    // in onResponse would derive a different string, fail to clear the
    // in-flight slot, and leave the next identical request enqueued on an
    // entry that will never complete. That is a hang, not a slow request.
    options.extra[_keyExtra] = key;
    final existing = _inFlight[key];
    if (existing != null) {
      // Piggy-back on the in-flight request: defer this waiter until the
      // original settles (onResponse/onError fan the outcome out).
      existing.enqueue(options, handler);
      return;
    }

    // First request of this group: let it flow through the full chain (auth,
    // retry, …) by calling handler.next. onResponse/onError below fan the
    // outcome out to this caller and any coalesced waiters, then clear the slot.
    _inFlight[key] = _InFlight(original: options);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final key = _storedKey(response.requestOptions);
    final pending = _inFlight.remove(key);
    pending?.completeWith(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final key = _storedKey(err.requestOptions);
    final pending = _inFlight.remove(key);
    pending?.failWith(err);
    handler.next(err);
  }

  bool _isCoalescable(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') {
      return false;
    }
    if (options.cancelToken != null) {
      return false;
    }
    // A request [RetryInterceptor] re-issued must NEVER be coalesced, and this
    // is a deadlock rather than a missed optimisation. Dio runs error
    // interceptors in REGISTRATION order and `createDio` registers retry first,
    // so `RetryInterceptor.onError` re-fetches from inside itself without ever
    // calling `handler.next(err)`. This interceptor's [onError] therefore has
    // not run, the group is still open, and the retry — same URI, same Accept,
    // same credential, so the same key — enqueues itself as a waiter on the
    // very request that is waiting for it. Neither future ever settles, and
    // nothing is logged, because the chain never reaches the error-logging
    // interceptor.
    //
    // Measured against an endpoint that always answers 429: plain dio fails in
    // 41ms, retry-alone in 4.4s after 4 attempts, dedup-alone in 2ms — and the
    // production pair hung forever after a single network hit. In the field
    // that read as `subscriptions.usage` blowing its 60s RPC budget on every
    // poll once the Kimi Code plan started answering 429 `resource_exhausted`.
    if (options.extra.containsKey(RetryInterceptor.retryCountKey)) {
      return false;
    }
    return true;
  }

  /// Where the request's key is parked for the response/error legs.
  static const String _keyExtra = '__ccDedupKey';

  /// The key stamped on the way in, falling back to a fresh computation for a
  /// response that never passed through [onRequest] (a resolved-early
  /// interceptor upstream).
  String _storedKey(RequestOptions options) =>
      options.extra[_keyExtra] as String? ?? _keyFor(options);

  String _keyFor(RequestOptions options) {
    final accept = options.headers['Accept']?.toString() ?? '';
    final responseType = options.responseType.name;
    // The CREDENTIAL is part of the identity of a GET, not an incidental
    // header. Same URL + different token is a different question with a
    // different answer, and coalescing the two hands the second caller the
    // first one's data. That stayed invisible while every endpoint was read
    // once per machine; a per-account fan-out (three Claude subscriptions
    // asking `/api/oauth/usage` at once) made all three report identical usage.
    //
    // Hashed, never included verbatim: this key is held in a map, and a bearer
    // token has no business sitting in one.
    final credential = _credentialFingerprint(options);
    return '${options.uri}::$accept::$responseType::$credential';
  }

  /// A short, non-reversible stand-in for whatever authenticates this request.
  static String _credentialFingerprint(RequestOptions options) {
    final parts = <String>[];
    for (final name in const ['Authorization', 'authorization', 'x-api-key']) {
      final value = options.headers[name];
      if (value != null) {
        parts.add('$name=$value');
      }
    }
    if (parts.isEmpty) {
      return '';
    }
    return sha256
        .convert(utf8.encode(parts.join('&')))
        .toString()
        .substring(0, 16);
  }
}

/// The in-flight state for one coalesced group: the original request's options
/// plus the queue of coalesced waiters. The original caller is driven by the
/// normal dio chain (`handler.next` → `onResponse`/`onError`); only the
/// COALESCED waiters are completed here.
class _InFlight {
  _InFlight({required this.original});

  final RequestOptions original;
  final List<(RequestOptions, RequestInterceptorHandler)> _waiters = [];

  void enqueue(RequestOptions options, RequestInterceptorHandler handler) {
    _waiters.add((options, handler));
  }

  /// Success: clone the response against each waiter's own requestOptions so
  /// every caller carries its own request, sharing the read-only body/headers.
  void completeWith(Response<dynamic> response) {
    for (final (options, handler) in _waiters) {
      handler.resolve(_cloneFor(response, options));
    }
    _waiters.clear();
  }

  /// Failure: reject each waiter with a DioException scoped to its own
  /// requestOptions, invoking the following error interceptors so the waiter
  /// traverses the same path the original did. `handler.reject` completes the
  /// waiter's request completer exactly once — the rejection reaches the
  /// waiter's caller and never surfaces as an unhandled async error.
  void failWith(DioException err) {
    for (final (options, handler) in _waiters) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: err.response != null
              ? _cloneFor(err.response!, options)
              : null,
          type: err.type,
          error: err.error,
          stackTrace: err.stackTrace,
          message: err.message,
        ),
        true,
      );
    }
    _waiters.clear();
  }

  Response<dynamic> _cloneFor(Response<dynamic> resp, RequestOptions options) {
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
}
