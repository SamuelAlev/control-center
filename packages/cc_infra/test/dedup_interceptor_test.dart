import 'dart:async';

import 'package:cc_infra/src/network/dedup_interceptor.dart';
import 'package:cc_infra/src/network/retry_interceptor.dart';
// rhttp ships an interceptor of its own with the same name as the cc_infra
// one this file uses; hide it so the local class is unambiguous.
import 'package:rhttp/rhttp.dart' hide RetryInterceptor;
import 'package:test/test.dart';

/// Pins [DedupInterceptor]'s contract directly: what makes two GETs the same
/// request, who gets parked, who settles the group, and what a coalesced
/// waiter receives.
///
/// The interceptor is driven through rhttp's own `Interceptor` contract rather
/// than over a socket, because every assertion here is about the decision the
/// interceptor makes — no request is ever sent. A `beforeRequest` that parks
/// (a coalesced waiter) never completes on its own, so the tests that expect a
/// request to flow add a short timeout: timing out there IS the assertion.

HttpRequest _request({
  String url = 'https://api.test/usage',
  Map<String, String> headers = const {},
  HttpMethod method = HttpMethod.get,
  CancelToken? cancelToken,
  HttpExpectBody expectBody = HttpExpectBody.text,
}) => HttpRequest(
  method: method,
  url: url,
  headers: headers.isEmpty ? null : HttpHeaders.rawMap(headers),
  cancelToken: cancelToken,
  expectBody: expectBody,
);

/// The response for [request] — the SAME request object that opened the group,
/// which is how the interceptor finds the slot to settle.
HttpTextResponse _ok(HttpRequest request) => HttpTextResponse(
  remoteIp: null,
  request: request,
  version: HttpVersion.http1_1,
  statusCode: 200,
  headers: const [],
  body: '{"ok":true}',
);

RhttpStatusCodeException _failure(HttpRequest request) =>
    RhttpStatusCodeException(
      request: request,
      statusCode: 500,
      headers: const [],
      body: 'boom',
    );

/// Asserts that [future] does NOT park (a parked waiter never settles) and lets
/// the request flow unchanged.
Future<void> _expectFlows(Future<InterceptorResult<HttpRequest>> future) async {
  final result = await future.timeout(const Duration(seconds: 1));
  expect(result, isA<InterceptorNextResult<HttpRequest>>());
  expect(result.value, isNull, reason: 'an uncoalesced request is unchanged');
}

void main() {
  group('DedupInterceptor identity', () {
    test('identical UNAUTHENTICATED gets coalesce onto one group', () async {
      final dedup = DedupInterceptor();
      final original = _request();
      await dedup.beforeRequest(original);

      final waiter = dedup.beforeRequest(_request());
      await dedup.afterResponse(_ok(original));

      final settled = await waiter;
      expect(settled, isA<InterceptorResolveResult<HttpRequest>>());
      expect(
        (settled as InterceptorResolveResult<HttpRequest>).response.statusCode,
        200,
      );
    });

    test('requests differing only by credential are NOT coalesced', () async {
      // A per-credential fan-out is the case that broke this. Three Claude
      // subscriptions asking `/api/oauth/usage` at the same moment share a URL
      // and differ only by bearer — and the key did not include the bearer, so
      // all three got the FIRST account's numbers. The symptom was three
      // accounts reporting identical usage, with nothing in any log to say why.
      final dedup = DedupInterceptor();
      for (final token in const ['a', 'b', 'c']) {
        await _expectFlows(
          dedup.beforeRequest(
            _request(headers: {'Authorization': 'Bearer $token'}),
          ),
        );
      }
    });

    test('an x-api-key is part of the identity too', () async {
      final dedup = DedupInterceptor();
      await _expectFlows(
        dedup.beforeRequest(_request(headers: {'x-api-key': 'k1'})),
      );
      await _expectFlows(
        dedup.beforeRequest(_request(headers: {'x-api-key': 'k2'})),
      );
    });

    test('two calls with the SAME credential still coalesce', () async {
      final dedup = DedupInterceptor();
      final original = _request(headers: {'Authorization': 'Bearer same'});
      await dedup.beforeRequest(original);

      final waiter = dedup.beforeRequest(
        _request(headers: {'Authorization': 'Bearer same'}),
      );
      await dedup.afterResponse(_ok(original));

      expect(await waiter, isA<InterceptorResolveResult<HttpRequest>>());
    });

    test('the resolved URL, the expected body type and the acceptance are all '
        'part of the identity', () async {
      final dedup = DedupInterceptor();
      final original = _request();
      await dedup.beforeRequest(original);

      await _expectFlows(
        dedup.beforeRequest(_request(url: 'https://api.test/other')),
      );
      await _expectFlows(
        dedup.beforeRequest(_request(expectBody: HttpExpectBody.bytes)),
      );
      await _expectFlows(
        dedup.beforeRequest(_request(headers: {'Accept': 'text/html'})),
      );
    });

    test('a configured base URL is part of the identity', () async {
      final dedup = DedupInterceptor();
      HttpRequest onBase(String baseUrl) => HttpRequest(
        method: HttpMethod.get,
        url: '/usage',
        settings: ClientSettings(baseUrl: baseUrl),
      );

      // `/usage` on one base URL is not the same request as `/usage` on
      // another, nor as the absolute form of either.
      await dedup.beforeRequest(onBase('https://api.test'));
      await _expectFlows(dedup.beforeRequest(onBase('https://other.test')));
      await _expectFlows(dedup.beforeRequest(_request()));
    });
  });

  group('DedupInterceptor eligibility', () {
    test('a non-GET is never coalesced', () async {
      final dedup = DedupInterceptor();
      await dedup.beforeRequest(_request(method: HttpMethod.post));
      await _expectFlows(
        dedup.beforeRequest(_request(method: HttpMethod.post)),
      );
    });

    test('a request carrying its own cancel token is never coalesced '
        '(a cancel must not affect another caller)', () async {
      final dedup = DedupInterceptor();
      await dedup.beforeRequest(_request(cancelToken: CancelToken()));
      await _expectFlows(
        dedup.beforeRequest(_request(cancelToken: CancelToken())),
      );
    });

    test(
      'a streamed response is never coalesced (one stream, one reader)',
      () async {
        final dedup = DedupInterceptor();
        await dedup.beforeRequest(_request(expectBody: HttpExpectBody.stream));
        await _expectFlows(
          dedup.beforeRequest(_request(expectBody: HttpExpectBody.stream)),
        );
      },
    );

    test(
      'a retry re-issue never joins the group its own original holds open',
      () async {
        // The deadlock this interceptor was fixed for: the retry would park on
        // the very request that is waiting for it, and nothing would settle.
        final dedup = DedupInterceptor();
        await dedup.beforeRequest(_request());

        final reissue = _request()
          ..additionalData[RetryInterceptor.retryCountKey] = 1;
        await _expectFlows(dedup.beforeRequest(reissue));
      },
    );
  });

  group('DedupInterceptor fan-out', () {
    test(
      'a coalesced waiter gets the response against its OWN request',
      () async {
        final dedup = DedupInterceptor();
        final original = _request();
        final waiterRequest = _request();
        await dedup.beforeRequest(original);

        final waiter = dedup.beforeRequest(waiterRequest);
        await dedup.afterResponse(_ok(original));

        final response =
            (await waiter as InterceptorResolveResult<HttpRequest>).response;
        expect(response.request, same(waiterRequest));
        expect(response.statusCode, 200);
      },
    );

    test('the group is cleared once it settles, so the next identical request '
        'is a new original instead of a hang', () async {
      final dedup = DedupInterceptor();
      final original = _request();
      await dedup.beforeRequest(original);
      await dedup.afterResponse(_ok(original));

      await _expectFlows(dedup.beforeRequest(_request()));
    });

    test('a failure settles every waiter with it, re-attributed to the '
        'waiter\'s request', () async {
      final dedup = DedupInterceptor();
      final original = _request();
      final waiterRequest = _request();
      await dedup.beforeRequest(original);

      final waiter = dedup.beforeRequest(waiterRequest);

      final failure = expectLater(
        waiter,
        throwsA(
          isA<RhttpStatusCodeException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.request, 'request', same(waiterRequest)),
        ),
      );
      await dedup.onError(_failure(original));
      await failure;
    });

    test(
      'an intermediate retry attempt does NOT settle the group\'s waiters',
      () async {
        // The group belongs to the ORIGINAL request. A re-issue failing is not
        // the outcome while the retry loop is still deciding, so the waiter must
        // stay parked until the original's error leg runs.
        final dedup = DedupInterceptor();
        final original = _request();
        await dedup.beforeRequest(original);

        final waiter = dedup.beforeRequest(_request());
        final reissue = _request()
          ..additionalData[RetryInterceptor.retryCountKey] = 1;
        await dedup.onError(_failure(reissue));

        var settled = false;
        waiter
            .then((_) => settled = true, onError: (Object _) => settled = true)
            .ignore();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(settled, isFalse, reason: 'the waiter is still parked');

        await dedup.onError(_failure(original));
        await expectLater(waiter, throwsA(isA<RhttpStatusCodeException>()));
      },
    );

    test(
      'two waiters and the failure all settle — no unhandled async error',
      () async {
        final unhandled = <Object>[];
        await runZonedGuarded(() async {
          final dedup = DedupInterceptor();
          final original = _request();
          await dedup.beforeRequest(original);
          final waiters = [
            expectLater(
              dedup.beforeRequest(_request()),
              throwsA(isA<RhttpStatusCodeException>()),
            ),
            expectLater(
              dedup.beforeRequest(_request()),
              throwsA(isA<RhttpStatusCodeException>()),
            ),
          ];

          await dedup.onError(_failure(original));
          await Future.wait(waiters);
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }, (error, _) => unhandled.add(error));

        expect(unhandled, isEmpty);
      },
    );
  });
}
