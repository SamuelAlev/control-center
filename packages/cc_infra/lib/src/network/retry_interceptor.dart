import 'dart:async';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:dio/dio.dart';

/// A Dio interceptor that (1) retries transient failures with exponential
/// backoff and (2) acts as a **rate-limit circuit breaker** for GitHub.
///
/// GitHub signals its PRIMARY rate limit with an HTTP `403` (not `429`) carrying
/// `x-ratelimit-remaining: 0` and an `x-ratelimit-reset` epoch; its SECONDARY
/// (abuse) limit is a `403` with a `retry-after`. Once either is seen, the
/// breaker records the reset instant and **fails every further request FAST —
/// without a network call — until that instant**. This is what stops a
/// resubscribe storm (e.g. Riverpod re-running a `watchDiff` provider on error)
/// from hammering GitHub and deepening the limit: the first rejected call
/// teaches the breaker the window; the rest short-circuit locally, and the
/// window then elapses on its own so the API recovers.
///
/// The breaker state is per-[Dio] instance — i.e. per GitHub client. The
/// primary limit is really per-token, so a limit hit by one GitHub client is
/// not (yet) shared with a sibling client on a different [Dio]; each learns the
/// window independently on its own first `403`. That is enough to stop the
/// reported storm, which loops a single client (the PR-review diff path).
class RetryInterceptor extends Interceptor {
  /// Creates a [RetryInterceptor] with the given [Dio] instance.
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
  }) : _dio = dio;

  final Dio _dio;

  /// The maximum number of retry attempts.
  final int maxRetries;

  /// The base delay between retries, doubled on each attempt.
  final Duration baseDelay;

  /// The instant the current rate-limit window ends, or `null` when the circuit
  /// is closed. While set and in the future, outgoing requests short-circuit.
  DateTime? _rateLimitedUntil;

  /// Guards the "circuit opened" log so it fires once per window, not per
  /// short-circuited request (a storm would otherwise flood the log too).
  bool _loggedOpen = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final until = _rateLimitedUntil;
    if (until != null) {
      final now = DateTime.now();
      if (now.isBefore(until)) {
        if (!_loggedOpen) {
          _loggedOpen = true;
          CcInfraLog.warning(
            'RetryInterceptor: rate-limit circuit OPEN — failing GitHub '
            'requests fast for ~${until.difference(now).inSeconds}s (until '
            '$until) instead of calling the API. This breaks a resubscribe '
            'storm and lets the rate-limit window recover.',
          );
        }
        handler.reject(_circuitOpenError(options, until));
        return;
      }
      // The window elapsed — close the circuit and resume normal traffic.
      _rateLimitedUntil = null;
      _loggedOpen = false;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // `x-ratelimit-remaining` counts down on EVERY GitHub response, so the
    // window is learned from a success that exhausts the budget too — not only
    // from the rejecting error. Unlike the old behaviour, a successful response
    // is delivered immediately (never held hostage for `retry-after` seconds);
    // throttling is deferred to the breaker, which gates the NEXT request.
    _recordRateLimit(response.headers, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    _recordRateLimit(err.response?.headers, err.response?.statusCode);

    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    final retryAfter = err.response?.headers.value('retry-after');
    Duration delay;
    if (retryAfter != null) {
      delay = Duration(
        seconds: int.tryParse(retryAfter) ?? baseDelay.inSeconds,
      );
    } else {
      delay = baseDelay * (1 << retryCount);
    }
    await Future<void>.delayed(delay);

    final options = err.requestOptions.copyWith(
      extra: {...err.requestOptions.extra, 'retryCount': retryCount + 1},
    );

    try {
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// A `429`/`5xx`/timeout is transient and worth retrying. A `403` is NOT: a
  /// GitHub rate limit never clears within a few retries, and retrying only
  /// deepens it — the circuit breaker handles that case instead.
  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    final status = err.response?.statusCode;
    return status == 429 || (status != null && status >= 500 && status < 600);
  }

  /// Opens (or extends) the breaker window from GitHub rate-limit headers.
  /// Called on both the success and error paths.
  void _recordRateLimit(Headers? headers, int? statusCode) {
    if (headers == null) {
      return;
    }
    final remainingRaw = headers.value('x-ratelimit-remaining');
    final remaining = remainingRaw == null ? null : int.tryParse(remainingRaw);
    final retryAfter = headers.value('retry-after');

    // Primary limit: the budget is exhausted (`remaining == 0`). Secondary
    // (abuse) limit: a 403 with a `retry-after` and no remaining-budget header.
    final primaryExhausted = remaining != null && remaining <= 0;
    final secondaryLimit = statusCode == 403 && retryAfter != null;
    if (!primaryExhausted && !secondaryLimit) {
      return;
    }

    final until = _windowEnd(headers);
    if (until == null) {
      return;
    }
    // Extend, never shorten, an existing window.
    final current = _rateLimitedUntil;
    if (current == null || until.isAfter(current)) {
      _rateLimitedUntil = until;
      _loggedOpen = false;
    }
  }

  /// Resolves when the rate-limit window ends from `x-ratelimit-reset` (epoch
  /// seconds) or `retry-after` (delta seconds), falling back to a conservative
  /// minute when a limit is signalled without a usable hint.
  DateTime? _windowEnd(Headers headers) {
    final reset = headers.value('x-ratelimit-reset');
    if (reset != null) {
      final epoch = int.tryParse(reset);
      if (epoch != null) {
        return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
      }
    }
    final retryAfter = headers.value('retry-after');
    if (retryAfter != null) {
      final secs = int.tryParse(retryAfter);
      if (secs != null) {
        return DateTime.now().add(Duration(seconds: secs));
      }
    }
    return DateTime.now().add(const Duration(seconds: 60));
  }

  /// The synthetic failure returned while the circuit is open. It mirrors a
  /// GitHub rate-limit rejection (403 + `x-ratelimit-remaining: 0` + reset) so
  /// the error mapper classifies it as `rate_limited`, identical to a real one.
  DioException _circuitOpenError(RequestOptions options, DateTime until) {
    final resetEpoch = (until.millisecondsSinceEpoch ~/ 1000).toString();
    return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      error: 'GitHub rate-limit circuit open until $until',
      response: Response<Object?>(
        requestOptions: options,
        statusCode: 403,
        headers: Headers.fromMap({
          'x-ratelimit-remaining': const ['0'],
          'x-ratelimit-reset': [resetEpoch],
        }),
        data: const {
          'message':
              'API rate limit exceeded '
              '(rate-limit circuit breaker; no request sent).',
        },
      ),
    );
  }
}
