import 'package:cc_infra/src/network/dedup_interceptor.dart';
import 'package:cc_infra/src/network/retry_interceptor.dart';
// rhttp ships an interceptor of its own with the same name as the cc_infra
// one this file uses; hide it so the local class is unambiguous.
import 'package:rhttp/rhttp.dart' hide RetryInterceptor;
import 'package:test/test.dart';

/// Pins the interaction between [RetryInterceptor] and [DedupInterceptor] — the
/// pair `createHttpClient` stacks on every client (retry first, then dedup:
/// `sharedHttpInterceptors`).
///
/// These two used to deadlock: the retry re-issued from inside its own error
/// leg while the dedup group was still open, so the re-issue (same URL, same
/// Accept, same credential, so the same key) parked on the very request that
/// was waiting for it. Neither future settled and nothing was logged. In the
/// field that read as `subscriptions.usage` blowing its 60s RPC budget on every
/// poll, forever, once a Kimi Code plan started answering 429
/// `resource_exhausted`.
///
/// [_Chain] runs the interceptors through rhttp's OWN pipeline contract —
/// `beforeRequest` in list order, then the transport, then
/// `afterResponse`/`onError` in list order, where a resolve short-circuits and
/// an error result keeps its value — against a scripted transport, which is
/// what makes the pair testable without a socket.

HttpRequest _request([String url = 'https://example.test/u']) => HttpRequest(
  method: HttpMethod.get,
  url: url,
  expectBody: HttpExpectBody.text,
);

HttpTextResponse _ok(HttpRequest request) => HttpTextResponse(
  remoteIp: null,
  request: request,
  version: HttpVersion.http1_1,
  statusCode: 200,
  headers: const [],
  body: '{"ok":true}',
);

RhttpStatusCodeException _tooManyRequests(HttpRequest request) =>
    RhttpStatusCodeException(
      request: request,
      statusCode: 429,
      headers: const [('content-type', 'application/json')],
      body: '{"code":"resource_exhausted"}',
    );

class _Chain {
  _Chain(this.interceptors, this.transport);

  final List<Interceptor> interceptors;
  final Future<HttpResponse> Function(HttpRequest request) transport;

  Future<HttpResponse> run(HttpRequest request) async {
    var current = request;
    for (final interceptor in interceptors) {
      final result = await interceptor.beforeRequest(current);
      if (result is InterceptorResolveResult<HttpRequest>) {
        return result.response;
      }
      current = result.value ?? current;
    }

    try {
      var response = await transport(current);
      for (final interceptor in interceptors) {
        final result = await interceptor.afterResponse(response);
        if (result is InterceptorResolveResult<HttpResponse>) {
          return result.response;
        }
        response = result.value ?? response;
      }
      return response;
    } on RhttpException catch (error) {
      RhttpException current = error;
      for (final interceptor in interceptors) {
        final result = await interceptor.onError(current);
        if (result is InterceptorResolveResult<RhttpException>) {
          return result.response;
        }
        current = result.value ?? current;
      }
      throw current;
    }
  }
}

/// Builds the production pair: retry BEFORE dedup (the order
/// `sharedHttpInterceptors` installs), with the retry re-issuing through the
/// chain exactly as `HttpRequest.send` does.
(_Chain, List<HttpRequest> Function()) _productionChain(
  Future<HttpResponse> Function(HttpRequest request, int attempt) handler,
) {
  final attempts = <HttpRequest>[];
  late final _Chain chain;
  final retry = RetryInterceptor(
    baseDelay: const Duration(milliseconds: 1),
    send: (request) => chain.run(request),
  );
  chain = _Chain([retry, DedupInterceptor()], (request) {
    final attempt = attempts.length;
    attempts.add(request);
    return handler(request, attempt);
  });
  return (chain, () => attempts);
}

void main() {
  test('a retryable GET fails instead of deadlocking', () async {
    final (chain, attempts) = _productionChain((request, _) async {
      throw _tooManyRequests(request);
    });

    await expectLater(
      chain.run(_request()).timeout(const Duration(seconds: 20)),
      throwsA(isA<RhttpStatusCodeException>()),
    );
    // One initial attempt plus the retry's three: proof the retries reached the
    // transport rather than being swallowed by the dedup group.
    expect(attempts(), hasLength(4));
  });

  test('a retried request still recovers on a later attempt', () async {
    final (chain, attempts) = _productionChain((request, attempt) async {
      if (attempt < 2) {
        throw _tooManyRequests(request);
      }
      return _ok(request);
    });

    final response = await chain
        .run(_request())
        .timeout(const Duration(seconds: 20));

    expect(response.statusCode, 200);
    expect(attempts(), hasLength(3));
  });

  test('concurrent identical GETs are coalesced into one call, and all of them '
      'settle', () async {
    final (chain, attempts) = _productionChain(
      (request, _) async => _ok(request),
    );

    final responses = await Future.wait([
      for (var i = 0; i < 3; i++)
        chain.run(_request()).timeout(const Duration(seconds: 20)),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(attempts(), hasLength(1), reason: 'coalescing must hold');
  });

  test('waiters are rejected when the shared request exhausts its retries — '
      'and only the original retries', () async {
    final (chain, attempts) = _productionChain((request, _) async {
      throw _tooManyRequests(request);
    });

    final outcomes = await Future.wait([
      for (var i = 0; i < 3; i++)
        chain
            .run(_request())
            .then<Object>((r) => r)
            .catchError((Object e) => e)
            .timeout(const Duration(seconds: 40)),
    ]);

    for (final outcome in outcomes) {
      expect(outcome, isA<RhttpStatusCodeException>());
      expect((outcome as RhttpStatusCodeException).statusCode, 429);
    }
    // Four attempts total: the original's one plus its three retries. The two
    // coalesced waiters inherit that outcome instead of running retries of
    // their own — three callers costing ten requests to an endpoint that just
    // said "slow down" is not coalescing, it is amplification.
    expect(attempts(), hasLength(4));
    expect(
      attempts().map((r) => r.additionalData[RetryInterceptor.retryCountKey]),
      [null, 1, 2, 3],
    );
  });

  test('a re-issue carries the marker DedupInterceptor bails on', () async {
    // Pins the coupling the fix relies on: the dedup guard reads
    // [RetryInterceptor.retryCountKey] off `additionalData`, so if the retry
    // ever stopped stamping it the deadlock would come back silently.
    final (chain, attempts) = _productionChain((request, _) async {
      throw _tooManyRequests(request);
    });

    await expectLater(
      chain.run(_request()).timeout(const Duration(seconds: 20)),
      throwsA(isA<RhttpStatusCodeException>()),
    );

    expect(
      attempts().map((r) => r.additionalData[RetryInterceptor.retryCountKey]),
      [null, 1, 2, 3],
    );
  });
}
