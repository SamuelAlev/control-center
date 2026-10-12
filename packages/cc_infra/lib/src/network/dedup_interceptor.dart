import 'dart:async';
import 'dart:convert';

import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/network/retry_interceptor.dart';
import 'package:crypto/crypto.dart';
// rhttp ships an interceptor of its own with the same name as the cc_infra
// one this file uses; hide it so the local class is unambiguous.
import 'package:rhttp/rhttp.dart' hide RetryInterceptor;

/// Coalesces identical concurrent GET requests into one network call.
///
/// Only: GET; no [CancelToken] (cancel must not affect coalesced waiters);
/// never a [RetryInterceptor] re-issue (it would wait on the group its own
/// original request is still holding open — see [_isCoalescable]).
///
/// The FIRST request of a group runs the whole chain; its outcome settles every
/// coalesced waiter from [afterResponse]/[onError], which is where the fan-out
/// happens because it is the only place that knows the group is finished.
///
/// The waiters are parked in [beforeRequest] until then. A waiter that is
/// parked inherits the original's response (cloned onto its OWN request) or its
/// failure, re-attributed to the waiter's request — what it does NOT do is
/// re-run the network call, which is the whole point of the interceptor.
class DedupInterceptor extends Interceptor {
  /// Creates a [DedupInterceptor].
  DedupInterceptor();

  /// Pending coalescable groups keyed by `(URL, query, expectBody, method,
  /// Accept, credential)`.
  ///
  /// Per INSTANCE, and that matters: `createHttpClient` builds a fresh
  /// interceptor per client, so two clients never share a group. Isolation
  /// BETWEEN identities therefore comes from having separate clients (one
  /// `ForgeHttpClientFactory` per acting user); the credential in the key is
  /// what protects a client that legitimately serves several credentials — one
  /// usage service reading three Claude subscriptions, say.
  final Map<String, _InFlight> _inFlight = {};

  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    if (!_isCoalescable(request)) {
      return Interceptor.next();
    }

    final key = _keyFor(request);
    // Stamp it. Interceptors downstream (and the retry's re-issue) carry
    // `additionalData` forward through `copyWith` while the URL, headers and
    // body can change, so the stamp — not a recomputation — is what identifies
    // this request's group on the way out. Without it a retried or otherwise
    // re-derived request would miss the slot and the next identical caller
    // would enqueue on an entry that is never completed: a hang, not a slow
    // request.
    request.additionalData[_keyExtra] = key;
    final existing = _inFlight[key];
    if (existing == null) {
      // First request of this group: let it flow through the full chain (auth,
      // retry, …) and settle the group from its own response/error legs.
      _inFlight[key] = _InFlight();
      return Interceptor.next();
    }

    // Piggy-back on the in-flight request: park until the original settles.
    final outcome = await existing.settled;
    final failure = outcome.error;
    if (failure == null) {
      return Interceptor.resolve(_cloneFor(outcome.response!, request));
    }
    throw httpExceptionFor(failure, request);
  }

  @override
  Future<InterceptorResult<HttpResponse>> afterResponse(
    HttpResponse response,
  ) async {
    final key = _storedKey(response.request);
    if (key != null) {
      _inFlight.remove(key)?.complete(response);
    }
    return Interceptor.next();
  }

  @override
  Future<InterceptorResult<RhttpException>> onError(
    RhttpException exception,
  ) async {
    final request = exception.request;
    if (request.additionalData.containsKey(RetryInterceptor.retryCountKey)) {
      // A retry attempt: its failure is not the group's outcome — the retry
      // loop decides whether another attempt follows, and the ORIGINAL
      // request's error leg settles the waiters when the attempts run out.
      return Interceptor.next();
    }
    final key = _storedKey(request);
    if (key != null) {
      _inFlight.remove(key)?.fail(exception);
    }
    return Interceptor.next();
  }

  bool _isCoalescable(HttpRequest request) {
    if (request.method.value.toUpperCase() != 'GET') {
      return false;
    }
    if (request.cancelToken != null) {
      return false;
    }
    // Never coalesce a [RetryInterceptor] re-issue: the re-issued request
    // belongs to the group its original is still holding open, and joining it
    // would park the retry on the very request that is waiting for it — the
    // deadlock this interceptor was fixed for.
    if (request.additionalData.containsKey(RetryInterceptor.retryCountKey)) {
      return false;
    }
    // A streamed body can only be listened to once, so two callers cannot share
    // one response. Every streaming GET carries its own consume path (a
    // download with progress, say) and is not a candidate for coalescing.
    if (request.expectBody == HttpExpectBody.stream) {
      return false;
    }
    return true;
  }

  /// Where the request's key is parked for the response/error legs.
  static const String _keyExtra = '__ccDedupKey';

  /// The key stamped on the way in, or `null` for a request that was not
  /// coalesced (a re-issue, a non-GET, a request with its own cancel token).
  String? _storedKey(HttpRequest request) =>
      request.additionalData[_keyExtra] as String?;

  String _keyFor(HttpRequest request) {
    final base = request.settings?.baseUrl ?? '';
    final query =
        request.queryRaw?.map((part) => '${part.$1}=${part.$2}').join('&') ??
        request.query?.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join('&') ??
        '';
    final accept = _headerValue(request.headers, 'accept') ?? '';
    // The CREDENTIAL is part of the identity of a GET, not an incidental
    // header. Same URL + different token is a different question with a
    // different answer, and coalescing the two hands the second caller the
    // first one's data. That stayed invisible while every endpoint was read
    // once per machine; a per-account fan-out (three Claude subscriptions
    // asking `/api/oauth/usage` at once) made all three report identical usage.
    //
    // The shared chain runs the caller's auth interceptor BEFORE this one, so
    // the credential is already on the request when the key is computed.
    //
    // Hashed, never included verbatim: this key is held in a map, and a bearer
    // token has no business sitting in one.
    final credential = _credentialFingerprint(request.headers);
    return '$base${request.url}::$query::${request.expectBody.name}::'
        '${request.method.value}::$accept::$credential';
  }

  /// A short, non-reversible stand-in for whatever authenticates this request.
  static String _credentialFingerprint(HttpHeaders? headers) {
    if (headers == null) {
      return '';
    }
    final parts = <String>[];
    for (final entry in headers.toMapList().entries) {
      final name = entry.key.toLowerCase();
      if (name == 'authorization' || name == 'x-api-key') {
        for (final value in entry.value) {
          parts.add('$name=$value');
        }
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

  /// Success: clone the response against the waiter's own request so every
  /// caller carries its own request, sharing the read-only body/headers.
  static HttpResponse _cloneFor(HttpResponse source, HttpRequest request) {
    return switch (source) {
      HttpTextResponse(
        :final remoteIp,
        :final version,
        :final statusCode,
        :final headers,
        :final body,
      ) =>
        HttpTextResponse(
          remoteIp: remoteIp,
          request: request,
          version: version,
          statusCode: statusCode,
          headers: headers,
          body: body,
        ),
      HttpBytesResponse(
        :final remoteIp,
        :final version,
        :final statusCode,
        :final headers,
        :final body,
      ) =>
        HttpBytesResponse(
          remoteIp: remoteIp,
          request: request,
          version: version,
          statusCode: statusCode,
          headers: headers,
          body: body,
        ),
      HttpStreamResponse(
        :final remoteIp,
        :final version,
        :final statusCode,
        :final headers,
        :final body,
      ) =>
        HttpStreamResponse(
          remoteIp: remoteIp,
          request: request,
          version: version,
          statusCode: statusCode,
          headers: headers,
          body: body,
        ),
    };
  }
}

/// The first value of [name] on [headers] (case-insensitive), or `null`.
String? _headerValue(HttpHeaders? headers, String name) {
  if (headers == null) {
    return null;
  }
  final lower = name.toLowerCase();
  for (final entry in headers.toMapList().entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value.isEmpty ? null : entry.value.first;
    }
  }
  return null;
}

/// The in-flight state for one coalesced group: a single settle point that
/// every coalesced waiter awaits.
///
/// The original caller is driven by the request's own chain (the network call
/// it already started); only the COALESCED waiters are completed here. The
/// outcome carries either a response or a failure — never an error VALUE — so a
/// failure cannot surface as an unhandled async error on a future nobody
/// listens to.
class _InFlight {
  final Completer<_Outcome> _settled = Completer<_Outcome>();

  Future<_Outcome> get settled => _settled.future;

  void complete(HttpResponse response) {
    if (!_settled.isCompleted) {
      _settled.complete(_Outcome(null, response));
    }
  }

  void fail(RhttpException error) {
    if (!_settled.isCompleted) {
      _settled.complete(_Outcome(error, null));
    }
  }
}

/// One coalesced group's outcome: exactly one of [error]/[response] is set.
class _Outcome {
  const _Outcome(this.error, this.response);

  final RhttpException? error;
  final HttpResponse? response;
}
