import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/network/retry_interceptor.dart';
// rhttp ships an interceptor of its own with the same name as the cc_infra
// one this file uses; hide it so the local class is unambiguous.
import 'package:rhttp/rhttp.dart' hide RetryInterceptor;
import 'package:test/test.dart';

/// Pins [RetryInterceptor]'s semantics against a scripted transport: how many
/// attempts a failure earns, how long each waits, when a `retry-after` hint is
/// honored or refused, and when the rate-limit circuit opens and closes.
///
/// The transport is the interceptor's `send` seam rather than a socket: the
/// retry logic is pure decision-making over exceptions and headers, and every
/// assertion below is about that decision. The default seam —
/// [HttpRequest.send], i.e. the request's own client and interceptor chain — is
/// the production path, exercised end to end by the server smoke test.

HttpRequest _request([String url = 'https://example.test/x']) =>
    HttpRequest(method: HttpMethod.get, url: url);

HttpTextResponse _ok(HttpRequest request) => HttpTextResponse(
  remoteIp: null,
  request: request,
  version: HttpVersion.http1_1,
  statusCode: 200,
  headers: const [],
  body: '{"ok":true}',
);

RhttpStatusCodeException _status(
  HttpRequest request,
  int statusCode, {
  Map<String, String> headers = const {},
}) => RhttpStatusCodeException(
  request: request,
  statusCode: statusCode,
  headers: [for (final entry in headers.entries) (entry.key, entry.value)],
  body: '',
);

int _attemptOf(HttpRequest request) =>
    request.additionalData[RetryInterceptor.retryCountKey] as int;

void main() {
  group('RetryInterceptor attempts', () {
    test('retries a timeout and resolves with the server answer', () async {
      final sent = <HttpRequest>[];
      var calls = 0;
      final retry = RetryInterceptor(
        baseDelay: const Duration(milliseconds: 1),
        send: (request) async {
          sent.add(request);
          calls++;
          if (calls < 2) {
            throw RhttpTimeoutException(request);
          }
          return _ok(request);
        },
      );

      final result = await retry.onError(RhttpTimeoutException(_request()));

      expect(
        (result as InterceptorResolveResult<RhttpException>)
            .response
            .statusCode,
        200,
      );
      expect(calls, 2);
      expect(sent.map(_attemptOf), [1, 2]);
    });

    test('stops after maxRetries and hands the caller a failure', () async {
      final sent = <HttpRequest>[];
      final original = _request();
      final retry = RetryInterceptor(
        maxRetries: 2,
        baseDelay: const Duration(milliseconds: 1),
        send: (request) async {
          sent.add(request);
          throw RhttpTimeoutException(request);
        },
      );

      final result = await retry.onError(RhttpTimeoutException(original));

      expect(result, isA<InterceptorNextResult<RhttpException>>());
      expect(sent.map(_attemptOf), [1, 2]);
      // The failure the caller sees must name the caller's OWN request: the
      // dedup fan-out and the logger both key their behaviour off
      // `exception.request`, and a re-issued request carries the retry marker
      // they deliberately stand down for.
      expect(result.value!.request, same(original));
    });

    test('a 404 is not retried', () async {
      var calls = 0;
      final retry = RetryInterceptor(
        baseDelay: const Duration(milliseconds: 1),
        send: (request) async {
          calls++;
          return _ok(request);
        },
      );

      final result = await retry.onError(_status(_request(), 404));

      expect(result.value, isNull, reason: 'the failure travels unchanged');
      expect(calls, 0);
    });

    test('a cancellation is not retried', () async {
      var calls = 0;
      final retry = RetryInterceptor(
        baseDelay: const Duration(milliseconds: 1),
        send: (request) async {
          calls++;
          return _ok(request);
        },
      );

      await retry.onError(RhttpCancelException(_request()));

      expect(calls, 0);
    });

    test('a connection failure is not retried', () async {
      var calls = 0;
      final retry = RetryInterceptor(
        baseDelay: const Duration(milliseconds: 1),
        send: (request) async {
          calls++;
          return _ok(request);
        },
      );

      await retry.onError(RhttpConnectionException(_request(), 'refused'));

      expect(calls, 0);
    });

    test(
      'a 429 then a 200: one retry, and the retry-after is honored',
      () async {
        var calls = 0;
        final retry = RetryInterceptor(
          baseDelay: const Duration(milliseconds: 1),
          send: (request) async {
            calls++;
            if (calls == 1) {
              throw _status(request, 429, headers: {'retry-after': '1'});
            }
            return _ok(request);
          },
        );

        final start = DateTime.now();
        final result = await retry.onError(_status(_request(), 429));

        expect(
          (result as InterceptorResolveResult<RhttpException>)
              .response
              .statusCode,
          200,
        );
        // One attempt failed with the hint, the second answered.
        expect(calls, 2);
        expect(
          DateTime.now().difference(start).inMilliseconds,
          greaterThanOrEqualTo(900),
        );
      },
    );

    test('a retry-after with a non-numeric value falls back to baseDelay '
        'seconds', () async {
      var calls = 0;
      final retry = RetryInterceptor(
        // `soon` parses as 0 seconds, so the retry is immediate.
        baseDelay: const Duration(milliseconds: 1),
        send: (request) async {
          calls++;
          return _ok(request);
        },
      );

      final start = DateTime.now();
      final result = await retry.onError(
        _status(_request(), 429, headers: {'retry-after': 'soon'}),
      );

      expect(
        (result as InterceptorResolveResult<RhttpException>)
            .response
            .statusCode,
        200,
      );
      expect(calls, 1);
      expect(DateTime.now().difference(start).inMilliseconds, lessThan(500));
    });

    test('a retry-after past the ceiling gives up NOW instead of waiting it '
        'out', () async {
      // `api.anthropic.com/api/oauth/usage` answers a stale token with
      // `429 retry-after: 3600`. Honouring that literally slept an hour, three
      // times over, inside a handler with a 60s budget — invisibly, because the
      // sleep sits BETWEEN requests where no per-request timeout reaches it.
      var calls = 0;
      final retry = RetryInterceptor(
        maxRetryAfter: const Duration(seconds: 10),
        send: (request) async {
          calls++;
          return _ok(request);
        },
      );

      final start = DateTime.now();
      final result = await retry.onError(
        _status(_request(), 429, headers: {'retry-after': '3600'}),
      );

      expect(result.value, isNotNull);
      expect(calls, 0, reason: 'no retry was attempted');
      expect(
        DateTime.now().difference(start).inSeconds,
        lessThan(2),
        reason: 'the caller learns it is rate-limited immediately',
      );
    });

    test('a hint AT the ceiling is still honoured', () async {
      // The clamp must not turn every rate-limit hint into a hard failure —
      // ordinary 1-10s hints are exactly what retrying is for.
      var calls = 0;
      final retry = RetryInterceptor(
        maxRetryAfter: const Duration(seconds: 1),
        send: (request) async {
          calls++;
          return _ok(request);
        },
      );

      final result = await retry.onError(
        _status(_request(), 429, headers: {'retry-after': '1'}),
      );

      expect(
        (result as InterceptorResolveResult<RhttpException>)
            .response
            .statusCode,
        200,
      );
      expect(calls, 1);
    });

    test('exponential backoff grows, with full jitter', () async {
      var calls = 0;
      final retry = RetryInterceptor(
        maxRetries: 3,
        baseDelay: const Duration(milliseconds: 50),
        send: (request) async {
          calls++;
          throw RhttpTimeoutException(request);
        },
      );

      final start = DateTime.now();
      await retry.onError(RhttpTimeoutException(_request()));
      final elapsed = DateTime.now().difference(start);

      expect(calls, 3);
      // The unjittered targets are base * (1 + 2 + 4) = 350ms. FULL JITTER
      // sleeps in [50%, 100%] of each target, so the total lands in
      // [175ms, 350ms] — the jitter is what stops N requests that failed
      // together from retrying in lockstep forever, so the floor is half the
      // nominal by design, not by accident.
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(150));
      // A generous ceiling: proves the backoff is still BOUNDED (a regression
      // that dropped the cap or the jitter's upper half would blow past it).
      expect(elapsed.inMilliseconds, lessThan(2000));
    });
  });

  group('RetryInterceptor rate-limit circuit breaker', () {
    test('a successful response is delivered immediately, and a spent budget '
        'arms the breaker for the NEXT request', () async {
      var calls = 0;
      final futureReset =
          DateTime.now()
              .add(const Duration(seconds: 30))
              .millisecondsSinceEpoch ~/
          1000;
      final retry = RetryInterceptor(
        baseDelay: const Duration(milliseconds: 1),
        send: (request) async {
          calls++;
          return _ok(request);
        },
      );

      final start = DateTime.now();
      final response = HttpTextResponse(
        remoteIp: null,
        request: _request(),
        version: HttpVersion.http1_1,
        statusCode: 200,
        headers: [
          ('x-ratelimit-remaining', '0'),
          ('x-ratelimit-reset', '$futureReset'),
        ],
        body: '{"ok":true}',
      );
      final passed = await retry.afterResponse(response);

      // The successful response is NOT held for the window; the breaker gates
      // the NEXT request instead.
      expect(passed.value, isNull);
      expect(DateTime.now().difference(start).inMilliseconds, lessThan(200));

      await expectLater(
        retry.beforeRequest(_request()),
        throwsA(
          isA<RhttpStatusCodeException>().having(
            (e) => e.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
      expect(calls, 0, reason: 'the breaker must not hit the network');
    });

    test('the synthetic short-circuit reads as a rate limit, not an auth '
        'failure', () async {
      final futureReset =
          DateTime.now()
              .add(const Duration(seconds: 30))
              .millisecondsSinceEpoch ~/
          1000;
      final headers = [
        ('x-ratelimit-remaining', '0'),
        ('x-ratelimit-reset', '$futureReset'),
      ];

      // A 403 rate-limit error arms the breaker and is not retried.
      var calls = 0;
      final armed =
          await RetryInterceptor(
            baseDelay: const Duration(milliseconds: 1),
            send: (request) async {
              calls++;
              return _ok(request);
            },
          ).onError(
            _status(
              _request(),
              403,
              headers: {
                'x-ratelimit-remaining': '0',
                'x-ratelimit-reset': '$futureReset',
              },
            ),
          );
      expect(armed.value, isNull);
      expect(calls, 0);

      final retry = RetryInterceptor();
      await retry.afterResponse(
        HttpTextResponse(
          remoteIp: null,
          request: _request(),
          version: HttpVersion.http1_1,
          statusCode: 200,
          headers: headers,
          body: '',
        ),
      );

      Object? thrown;
      try {
        await retry.beforeRequest(_request());
      } on RhttpException catch (e) {
        thrown = e;
      }
      expect(thrown, isA<RhttpStatusCodeException>());
      // The whole point of the synthetic failure's shape: the caller's mapper
      // reads it as a rate limit, exactly like the API's own 403.
      expect(mapHttpException(thrown! as RhttpException).code, 'rate_limited');
    });

    test('a budget that is not spent leaves the circuit closed', () async {
      final retry = RetryInterceptor();

      for (final headers in const [
        {'x-ratelimit-remaining': '10'},
        {'x-ratelimit-remaining': 'plenty'},
        <String, String>{},
      ]) {
        await retry.afterResponse(
          HttpTextResponse(
            remoteIp: null,
            request: _request(),
            version: HttpVersion.http1_1,
            statusCode: 200,
            headers: [
              for (final entry in headers.entries) (entry.key, entry.value),
            ],
            body: '',
          ),
        );
        final result = await retry.beforeRequest(_request());
        expect(result.value, isNull, reason: 'no short-circuit');
      }
    });

    test('an elapsed window closes the circuit again', () async {
      final retry = RetryInterceptor();
      final pastReset =
          DateTime.now()
              .subtract(const Duration(minutes: 1))
              .millisecondsSinceEpoch ~/
          1000;

      await retry.afterResponse(
        HttpTextResponse(
          remoteIp: null,
          request: _request(),
          version: HttpVersion.http1_1,
          statusCode: 200,
          headers: [
            ('x-ratelimit-remaining', '0'),
            ('x-ratelimit-reset', '$pastReset'),
          ],
          body: '',
        ),
      );

      final result = await retry.beforeRequest(_request());
      expect(result.value, isNull);
    });
  });
}
