import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_harness_runtime/src/providers/sse.dart';

/// An HTTP error from an LLM provider, carrying the status code and raw body so
/// the provider can classify it (rate-limit / auth / overloaded).
class ProviderHttpException implements Exception {
  /// Creates a provider HTTP error.
  ProviderHttpException(this.statusCode, this.body, {this.retryAfter});

  /// HTTP status code.
  final int statusCode;

  /// Raw response body (usually a small JSON error envelope).
  final String body;

  /// The server's `Retry-After` hint, when present (seconds or an HTTP date).
  final Duration? retryAfter;

  @override
  String toString() => 'ProviderHttpException($statusCode): $body';
}

/// Parses a `Retry-After` header value (delta-seconds or an HTTP date) into a
/// [Duration] from now, or null when absent/unparseable. Clamped to ≤5 min so a
/// pathological server hint can't stall a run indefinitely.
Duration? parseRetryAfter(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final seconds = int.tryParse(value.trim());
  if (seconds != null) {
    return Duration(seconds: seconds.clamp(0, 300));
  }
  try {
    final until = HttpDate.parse(value);
    final delta = until.difference(DateTime.now());
    if (delta.isNegative) {
      return Duration.zero;
    }
    return delta > const Duration(minutes: 5)
        ? const Duration(minutes: 5)
        : delta;
  } on Object {
    return null;
  }
}

/// Idle-timeouts [source] without arming a fresh [Timer] per event.
///
/// `Stream.timeout` cancels and re-creates its timer on EVERY event. An SSE
/// body delivers thousands of chunks per turn, so that is thousands of timer
/// allocations and timer-heap re-orderings per turn on the isolate that also
/// has to answer RPCs. One periodic tick comparing against a stopwatch detects
/// the same wedge at a fixed cost; detection granularity is one tick, which is
/// irrelevant against a 120s idle window.
///
/// The error shape is deliberately identical to `Stream.timeout`'s so the
/// upstream retryable-error mapping is unchanged.
Stream<T> idleGuarded<T>(Stream<T> source, Duration idle) {
  final tick = idle ~/ 8 < const Duration(seconds: 1)
      ? const Duration(seconds: 1)
      : idle ~/ 8;
  late StreamController<T> controller;
  StreamSubscription<T>? sub;
  Timer? ticker;
  final since = Stopwatch();

  void stop() {
    ticker?.cancel();
    ticker = null;
    since.stop();
  }

  controller = StreamController<T>(
    onListen: () {
      since
        ..reset()
        ..start();
      ticker = Timer.periodic(tick, (_) {
        if (since.elapsed < idle) {
          return;
        }
        stop();
        controller.addError(
          TimeoutException('No stream event', idle),
          StackTrace.current,
        );
        sub?.cancel();
        controller.close();
      });
      sub = source.listen(
        (event) {
          since.reset();
          controller.add(event);
        },
        onError: (Object e, StackTrace s) {
          stop();
          controller.addError(e, s);
        },
        onDone: () {
          stop();
          controller.close();
        },
      );
    },
    onPause: () => sub?.pause(),
    onResume: () => sub?.resume(),
    onCancel: () async {
      stop();
      await sub?.cancel();
      sub = null;
    },
  );
  return controller.stream;
}

/// Thin streaming HTTP client for LLM providers, built on `dart:io` so it works
/// in the pure-Dart server binary (no Flutter, no dio interceptors that would
/// buffer or retry a streaming response).
class ProviderHttp {
  /// Creates a [ProviderHttp] with an optional connection and idle timeout.
  ///
  /// [idleTimeout] bounds inactivity on a streaming response: if no bytes arrive
  /// for this long the stream errors (retryably) instead of hanging the run
  /// forever. It resets on every chunk, so a long but progressing stream is
  /// fine; only a genuinely wedged connection trips it.
  ProviderHttp({Duration? connectTimeout, Duration? idleTimeout})
    : _connectTimeout = connectTimeout ?? const Duration(seconds: 60),
      _idleTimeout = idleTimeout ?? const Duration(seconds: 120);

  /// The process-wide client every provider and OAuth broker shares by default.
  ///
  /// A provider is constructed per dispatch AND per subagent spawn, so a
  /// per-provider [HttpClient] means 1–3 fresh TLS handshakes to the same API
  /// host per run and a pile of idle keep-alive sockets waiting to time out.
  /// One shared client keeps the connection pool warm across runs. Callers that
  /// genuinely need different timeouts still construct their own.
  static final ProviderHttp shared = ProviderHttp();

  final Duration _connectTimeout;
  final Duration _idleTimeout;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30);

  /// POSTs [body] as JSON to [uri] and parses the response as Server-Sent
  /// Events. Throws [ProviderHttpException] on a non-2xx response (after
  /// reading the error body) and propagates socket errors.
  Stream<SseMessage> postSse(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async* {
    final request = await _client.postUrl(uri).timeout(_connectTimeout);
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    headers.forEach(request.headers.set);
    request.add(utf8.encode(jsonEncode(body)));
    // Bound the wait for response headers as well as the initial connect.
    final response = await request.close().timeout(_idleTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = await response.transform(utf8.decoder).join();
      throw ProviderHttpException(
        response.statusCode,
        errorBody,
        retryAfter: parseRetryAfter(response.headers.value('retry-after')),
      );
    }

    // Idle-timeout the body: resets on every chunk, so a slow-but-progressing
    // stream is fine and only a wedged connection trips it. The error surfaces
    // through parseSse's onError and is mapped to a retryable LlmError upstream.
    yield* parseSse(idleGuarded(response, _idleTimeout));
  }

  /// POSTs [body] as JSON to [uri] and returns the decoded JSON response (no
  /// streaming). Throws [ProviderHttpException] on a non-2xx response.
  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    final request = await _client.postUrl(uri).timeout(_connectTimeout);
    request.headers.contentType = ContentType.json;
    headers.forEach(request.headers.set);
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close().timeout(_idleTimeout);
    final text = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_idleTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderHttpException(response.statusCode, text);
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// POSTs [fields] as `application/x-www-form-urlencoded` to [uri] and returns
  /// the decoded JSON response (used by OAuth token endpoints). Throws
  /// [ProviderHttpException] on a non-2xx response.
  Future<Map<String, dynamic>> postForm(
    Uri uri, {
    Map<String, String> headers = const {},
    required Map<String, String> fields,
  }) async {
    final request = await _client.postUrl(uri).timeout(_connectTimeout);
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
    );
    headers.forEach(request.headers.set);
    final encoded = fields.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}='
              '${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    request.add(utf8.encode(encoded));
    final response = await request.close().timeout(_idleTimeout);
    final text = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_idleTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderHttpException(response.statusCode, text);
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// GETs [uri] and returns the decoded JSON response. Throws
  /// [ProviderHttpException] on a non-2xx response.
  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    final request = await _client.getUrl(uri).timeout(_connectTimeout);
    headers.forEach(request.headers.set);
    final response = await request.close().timeout(_idleTimeout);
    final text = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_idleTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderHttpException(response.statusCode, text);
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// Closes the underlying client.
  void close() => _client.close(force: true);
}

/// Re-authorizing SSE, layered over [ProviderHttp.postSse].
///
/// An extension rather than a method so test doubles that stub `postSse` keep
/// exercising this logic for free.
extension ProviderHttpAuthRetry on ProviderHttp {
  /// Opens the SSE stream for [body], re-authorizing once on a 401.
  ///
  /// [headers] builds the request headers; on a 401 it is called again with
  /// `force: true` — asking an OAuth credential to re-mint its bearer rather
  /// than re-read the one the server just rejected — and the request is retried
  /// exactly once. The retry cannot duplicate output: [ProviderHttp.postSse]
  /// reads a non-2xx body *in place of* the event stream, so the failure always
  /// arrives before the first event.
  ///
  /// The returned stream has already produced its first frame, so awaiting this
  /// call is what surfaces an auth failure; every other error still arrives on
  /// the stream as before.
  Future<Stream<SseMessage>> postSseReauthorizing(
    Uri uri, {
    required Future<Map<String, String>> Function({bool force}) headers,
    required Map<String, dynamic> body,
    bool retryOnUnauthorized = true,
  }) async {
    var forced = false;
    while (true) {
      final events = StreamIterator(
        postSse(
          uri,
          headers: await headers(force: forced),
          body: body,
        ),
      );
      try {
        final hasFirst = await events.moveNext();
        return _replay(events, hasFirst);
      } on ProviderHttpException catch (e) {
        await events.cancel();
        if (forced || !retryOnUnauthorized || e.statusCode != 401) {
          rethrow;
        }
        forced = true;
      } on Object {
        await events.cancel();
        rethrow;
      }
    }
  }

  /// Replays the already-fetched first frame, then the rest of [events].
  static Stream<SseMessage> _replay(
    StreamIterator<SseMessage> events,
    bool hasFirst,
  ) async* {
    try {
      var more = hasFirst;
      while (more) {
        yield events.current;
        more = await events.moveNext();
      }
    } finally {
      // The consumer breaks out of its loop at `[DONE]`; without this the
      // underlying HTTP subscription would stay open for the whole run.
      await events.cancel();
    }
  }
}
