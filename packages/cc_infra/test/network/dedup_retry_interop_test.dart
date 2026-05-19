import 'dart:typed_data';

import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/dedup_interceptor.dart';
import 'package:cc_infra/src/network/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Counts requests and answers each one from the supplied handler, which sees
/// the request options and the zero-based attempt index.
class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter(this._handler);
  final ResponseBody Function(RequestOptions options, int index) _handler;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = calls++;
    return _handler(options, index);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _body(String json, int status) => ResponseBody.fromString(
  json,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody _tooManyRequests() => _body('{"code":"resource_exhausted"}', 429);

ResponseBody _ok() => _body('{"ok":true}', 200);

void main() {
  // `createDio` stacks RetryInterceptor and DedupInterceptor on every
  // server-side HTTP client, and the two used to deadlock. Dio runs error
  // interceptors in REGISTRATION order, so RetryInterceptor.onError re-fetches
  // from inside itself and never calls `handler.next(err)` — the dedup group is
  // therefore still open when the retry arrives, and the retry (same URI, same
  // Accept, same credential, so the same key) enqueued itself as a waiter on
  // the very request that was waiting for it. Neither future settled, and
  // nothing was logged, because the chain never reached the error-logging
  // interceptor.
  //
  // In the field that read as `subscriptions.usage` blowing its 60s RPC budget
  // on every poll, forever, once the Kimi Code plan started answering 429
  // `resource_exhausted`.
  group('RetryInterceptor + DedupInterceptor', () {
    test('a retryable GET fails instead of deadlocking', () async {
      final adapter = _CountingAdapter((_, _) => _tooManyRequests());
      final dio = createDio()..httpClientAdapter = adapter;

      await expectLater(
        dio
            .getUri<Map<String, dynamic>>(Uri.parse('https://example.test/u'))
            .timeout(const Duration(seconds: 20)),
        throwsA(isA<DioException>()),
      );
      // One initial attempt plus RetryInterceptor's three: proof the retries
      // reached the network rather than being swallowed by the dedup group.
      expect(adapter.calls, 4);
    });

    test('a retried request still recovers on a later attempt', () async {
      final adapter = _CountingAdapter(
        (_, index) => index < 2 ? _tooManyRequests() : _ok(),
      );
      final dio = createDio()..httpClientAdapter = adapter;

      final response = await dio
          .getUri<Map<String, dynamic>>(Uri.parse('https://example.test/u'))
          .timeout(const Duration(seconds: 20));

      expect(response.statusCode, 200);
      expect(adapter.calls, 3);
    });

    test('concurrent identical GETs are still coalesced into one call, and '
        'all of them settle', () async {
      final adapter = _CountingAdapter((_, _) => _ok());
      final dio = createDio()..httpClientAdapter = adapter;

      final responses = await Future.wait([
        for (var i = 0; i < 3; i++)
          dio.getUri<Map<String, dynamic>>(Uri.parse('https://example.test/u')),
      ]).timeout(const Duration(seconds: 20));

      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(adapter.calls, 1, reason: 'coalescing must survive the fix');
    });

    test('coalesced waiters are rejected when the shared request exhausts its '
        'retries', () async {
      final attempts = <Object?>[];
      final adapter = _CountingAdapter((options, _) {
        attempts.add(options.extra[RetryInterceptor.retryCountKey]);
        return _tooManyRequests();
      });
      final dio = createDio()..httpClientAdapter = adapter;

      final outcomes = await Future.wait([
        for (var i = 0; i < 3; i++)
          dio
              .getUri<Map<String, dynamic>>(Uri.parse('https://example.test/u'))
              .then<Object>((r) => r)
              .catchError((Object e) => e),
      ]).timeout(const Duration(seconds: 40));

      expect(outcomes, everyElement(isA<DioException>()));
      // Only the FIRST caller reaches the network while the group is open; the
      // other two wait. When the shared request gives up, its failure is fanned
      // out with `callFollowingErrorInterceptor: true`, which walks each waiter
      // through the error chain from the top — RetryInterceptor included — so
      // each one then runs its own three retries, concurrently with the other's.
      // Four attempts for the original, three per waiter.
      //
      // Pinned rather than endorsed: three callers costing ten requests to an
      // endpoint that just said "slow down" is weak coalescing, but it is
      // pre-existing behaviour and no longer a hang, which is what this file
      // is about.
      expect(attempts.first, isNull, reason: 'the original goes out unmarked');
      expect(
        attempts.sublist(1)..sort((a, b) => (a! as int).compareTo(b! as int)),
        [1, 1, 1, 2, 2, 2, 3, 3, 3],
      );
      expect(adapter.calls, 10);
    });

    test('a re-issue carries the marker DedupInterceptor bails on', () async {
      // Pins the coupling the fix relies on: the dedup guard reads
      // [RetryInterceptor.retryCountKey] off `extra`, so if the retry ever
      // stopped stamping it the deadlock would come back silently.
      final seen = <Object?>[];
      final adapter = _CountingAdapter((options, _) {
        seen.add(options.extra[RetryInterceptor.retryCountKey]);
        return _tooManyRequests();
      });
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(RetryInterceptor(dio: dio));
      dio.interceptors.add(DedupInterceptor(dio));

      await expectLater(
        dio
            .getUri<Map<String, dynamic>>(Uri.parse('https://example.test/u'))
            .timeout(const Duration(seconds: 20)),
        throwsA(isA<DioException>()),
      );
      expect(seen, [null, 1, 2, 3]);
    });
  });
}
