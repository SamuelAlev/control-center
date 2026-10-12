import 'dart:convert';
import 'dart:math';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:rhttp/rhttp.dart';

/// Full-jitter source for retry backoff.
final Random _jitter = Random();

/// Re-issues one attempt of [request].
///
/// Defaults to [HttpRequest.send], i.e. the request's OWN client, settings and
/// interceptor chain — which is what makes a retry indistinguishable from a
/// first attempt to every interceptor (auth refreshes the token, dedup
/// recognises its own re-issue, the logger traces each attempt). Injectable so
/// the retry semantics can be exercised without a native transport.
typedef RetrySend = Future<HttpResponse> Function(HttpRequest request);

Future<HttpResponse> _sendThroughRequestChain(HttpRequest request) =>
    request.send();

/// Retries transient failures with exponential backoff and acts as a GitHub
/// rate-limit circuit breaker.
///
/// GitHub primary limit is HTTP 403 with `x-ratelimit-remaining: 0` (not 429);
/// secondary is 403 + `retry-after`. Once seen, further requests fail fast
/// until reset — stops a resubscribe storm from deepening the limit. Breaker
/// is per-client (one instance per `createHttpClient` client), not shared
/// across tokens.
class RetryInterceptor extends Interceptor {
  /// Creates a [RetryInterceptor].
  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxRetryAfter = const Duration(seconds: 10),
    RetrySend? send,
  }) : _send = send ?? _sendThroughRequestChain;

  final RetrySend _send;

  /// Where the attempt counter is parked on a re-issued request.
  ///
  /// Public because `DedupInterceptor` has to recognise a retry: its insert in
  /// `additionalData` is how a re-issued request is kept out of the in-flight
  /// group its own original request is still holding open (a self-join there is
  /// a deadlock), and how the logger and the dedup fan-out know that an
  /// intermediate attempt's failure is not the request's outcome.
  static const String retryCountKey = 'retryCount';

  /// The maximum number of retry attempts.
  final int maxRetries;

  /// The base delay between retries, doubled on each attempt.
  final Duration baseDelay;

  /// Longest `retry-after` this interceptor will wait; longer abandons and
  /// surfaces the error. Honouring unbounded hints (e.g. 3600s × retries) hid
  /// the failure from timeouts and from 60s `repo/call` budgets. Clamping sleep
  /// still burns the budget; past this ceiling the hint is for the caller.
  /// Ten seconds keeps 3×ceiling under 30s inside a 60s handler.
  final Duration maxRetryAfter;

  /// The instant the current rate-limit window ends, or `null` when the circuit
  /// is closed. While set and in the future, outgoing requests short-circuit.
  DateTime? _rateLimitedUntil;

  /// Guards the "circuit opened" log so it fires once per window, not per
  /// short-circuited request (a storm would otherwise flood the log too).
  bool _loggedOpen = false;

  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
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
        // Thrown rather than routed through the error chain (there is no such
        // route from `beforeRequest`): the caller still gets a real
        // status failure carrying GitHub's rate-limit shape, so
        // `mapHttpException` classifies it as `rate_limited` exactly like the
        // 403 the API itself would have answered with — and no request leaves
        // the machine. The circuit-open warning above names the window once;
        // a per-request line for each short-circuit is what the "log once"
        // guard exists to avoid.
        throw _circuitOpenError(request, until);
      }
      // The window elapsed — close the circuit and resume normal traffic.
      _rateLimitedUntil = null;
      _loggedOpen = false;
    }
    return Interceptor.next();
  }

  @override
  Future<InterceptorResult<HttpResponse>> afterResponse(
    HttpResponse response,
  ) async {
    // `x-ratelimit-remaining` counts down on EVERY GitHub response, so the
    // window is learned from a success that exhausts the budget too — not only
    // from the rejecting error. Unlike the old behaviour, a successful response
    // is delivered immediately (never held hostage for `retry-after` seconds);
    // throttling is deferred to the breaker, which gates the NEXT request.
    _recordRateLimit(response.headers, response.statusCode);
    return Interceptor.next();
  }

  @override
  Future<InterceptorResult<RhttpException>> onError(
    RhttpException exception,
  ) async {
    _recordRateLimitFromException(exception);

    final request = exception.request;
    if (request.additionalData.containsKey(retryCountKey)) {
      // A re-issued attempt's own failure: the attempt loop below owns the
      // decision, not this interceptor's error leg.
      return Interceptor.next();
    }
    if (!_shouldRetry(exception)) {
      return Interceptor.next();
    }

    var error = exception;
    var attempt = 0;
    while (attempt < maxRetries) {
      final delay = _delayFor(attempt, error);
      if (delay == null) {
        // The hint was past [maxRetryAfter]: give up now, with the ORIGINAL
        // request attached so the dedup fan-out clears its group and the
        // logger reports the failure once.
        return Interceptor.next(httpExceptionFor(error, request));
      }
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      // The marker is what tells every later interceptor (and this one) that
      // this is a re-issue; `copyWith` carries `additionalData` forward, so the
      // dedup stamp and the caller's expected-status marker survive.
      final retryRequest = request.copyWith()
        ..additionalData[retryCountKey] = attempt + 1;
      attempt++;

      try {
        return Interceptor.resolve(await _send(retryRequest));
      } on RhttpCancelException {
        // A cancellation is the caller standing down, not a transient failure.
        rethrow;
      } on RhttpException catch (e) {
        _recordRateLimitFromException(e);
        error = e;
        if (!_shouldRetry(e)) {
          return Interceptor.next(httpExceptionFor(e, request));
        }
      }
    }
    return Interceptor.next(httpExceptionFor(error, request));
  }

  /// The delay before the next attempt, or `null` when the server's own
  /// `retry-after` hint is past [maxRetryAfter] and retrying is not worth the
  /// caller's time.
  Duration? _delayFor(int attempt, RhttpException error) {
    final retryAfter = error is RhttpStatusCodeException
        ? _headerValue(error.headers, 'retry-after')
        : null;
    if (retryAfter == null) {
      // Full jitter on the computed backoff: without it, N requests that fail
      // together retry together forever.
      final target = baseDelay * (1 << attempt);
      return Duration(
        microseconds:
            (target.inMicroseconds * (0.5 + _jitter.nextDouble() * 0.5))
                .round(),
      );
    }
    // A server's explicit hint is honored exactly — jittering it would
    // second-guess the only party that knows when it will be ready — but only
    // up to [maxRetryAfter]. Past that the wait is worth less to the caller
    // than the answer; see the field's own note.
    final hinted = Duration(
      seconds: int.tryParse(retryAfter) ?? baseDelay.inSeconds,
    );
    if (hinted > maxRetryAfter) {
      CcInfraLog.warning(
        'RetryInterceptor: ${error.request.url} asked for a '
        '${hinted.inSeconds}s retry-after, past the ${maxRetryAfter.inSeconds}s '
        'ceiling — not retrying, so the caller learns it is rate-limited now '
        'instead of waiting out the window',
      );
      return null;
    }
    return hinted;
  }

  /// A `429`/`5xx`/timeout is transient and worth retrying. A `403` is NOT: a
  /// GitHub rate limit never clears within a few retries and retrying only
  /// deepens it — the circuit breaker handles that case instead. Nor is a
  /// cancellation, a connection refused, or an invalid certificate: none of
  /// them gets better by asking again immediately.
  bool _shouldRetry(RhttpException error) {
    if (error is RhttpCancelException) {
      return false;
    }
    if (error is RhttpTimeoutException) {
      return true;
    }
    final status = error is RhttpStatusCodeException ? error.statusCode : null;
    return status == 429 || (status != null && status >= 500 && status < 600);
  }

  /// Opens (or extends) the breaker window from GitHub rate-limit headers.
  /// Called on the success path, the error path and every retry attempt.
  void _recordRateLimitFromException(RhttpException error) {
    if (error is RhttpStatusCodeException) {
      _recordRateLimit(error.headers, error.statusCode);
    }
  }

  void _recordRateLimit(List<(String, String)>? headers, int? statusCode) {
    if (headers == null) {
      return;
    }
    final remainingRaw = _headerValue(headers, 'x-ratelimit-remaining');
    final remaining = remainingRaw == null ? null : int.tryParse(remainingRaw);
    final retryAfter = _headerValue(headers, 'retry-after');

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
  DateTime? _windowEnd(List<(String, String)> headers) {
    final reset = _headerValue(headers, 'x-ratelimit-reset');
    if (reset != null) {
      final epoch = int.tryParse(reset);
      if (epoch != null) {
        return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
      }
    }
    final retryAfter = _headerValue(headers, 'retry-after');
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
  RhttpStatusCodeException _circuitOpenError(
    HttpRequest request,
    DateTime until,
  ) {
    final resetEpoch = (until.millisecondsSinceEpoch ~/ 1000).toString();
    return RhttpStatusCodeException(
      request: request,
      statusCode: 403,
      headers: [
        ('x-ratelimit-remaining', '0'),
        ('x-ratelimit-reset', resetEpoch),
        ('content-type', 'application/json'),
      ],
      body: jsonEncode({
        'message':
            'API rate limit exceeded '
            '(rate-limit circuit breaker; no request sent).',
      }),
    );
  }
}

/// The first value of [name] on [headers] (case-insensitive), or `null`.
String? _headerValue(List<(String, String)>? headers, String name) {
  if (headers == null) {
    return null;
  }
  final lower = name.toLowerCase();
  for (final (key, value) in headers) {
    if (key.toLowerCase() == lower) {
      return value;
    }
  }
  return null;
}
