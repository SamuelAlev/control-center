import 'dart:typed_data';

import 'package:cc_infra/src/network/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _ScriptingAdapter implements HttpClientAdapter {
  _ScriptingAdapter(this._handler);
  final ResponseBody Function(RequestOptions, int) _handler;
  int _call = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = _call;
    _call++;
    return _handler(options, index);
  }

  int get callCount => _call;

  @override
  void close({bool force = false}) {}
}

ResponseBody _ok() => ResponseBody.fromString(
  '{"ok":true}',
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

DioException _err(
  RequestOptions options, {
  DioExceptionType type = DioExceptionType.connectionTimeout,
  int? status,
  Map<String, List<String>>? headers,
}) => DioException(
  requestOptions: options,
  type: type,
  response: status == null
      ? null
      : Response(
          requestOptions: options,
          statusCode: status,
          data: '',
          headers: Headers.fromMap(headers ?? const {}),
        ),
);

void main() {
  group('RetryInterceptor', () {
    test('resolves on first success without retry', () async {
      final dio = Dio();
      final adapter = _ScriptingAdapter((_, _) => _ok());
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(dio: dio, baseDelay: const Duration(milliseconds: 1)),
      );

      final response = await dio.get<String>('/x');
      expect(response.statusCode, 200);
      expect(adapter.callCount, 1);
    });

    test('retries on connectionTimeout then succeeds', () async {
      final dio = Dio();
      final adapter = _ScriptingAdapter(
        (options, index) => index < 2 ? throw _err(options) : _ok(),
      );
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(dio: dio, baseDelay: const Duration(milliseconds: 1)),
      );

      final response = await dio.get<String>('/x');
      expect(response.statusCode, 200);
      expect(adapter.callCount, 3);
    });

    test('stops retrying after maxRetries and propagates the error', () async {
      final dio = Dio();
      final adapter = _ScriptingAdapter((options, _) => throw _err(options));
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 2,
          baseDelay: const Duration(milliseconds: 1),
        ),
      );

      await expectLater(dio.get<String>('/x'), throwsA(isA<DioException>()));
      // 1 initial + 2 retries = 3 fetch calls.
      expect(adapter.callCount, 3);
    });

    test('retries on 429 with retry-after header', () async {
      final dio = Dio();
      final adapter = _ScriptingAdapter((options, index) {
        if (index == 0) {
          throw _err(
            options,
            type: DioExceptionType.badResponse,
            status: 429,
            headers: const {
              'retry-after': ['1'],
            },
          );
        }
        return _ok();
      });
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 1),
        ),
      );

      final response = await dio.get<String>('/x');
      expect(response.statusCode, 200);
      expect(adapter.callCount, 2);
    });

    test('retries on 5xx server error', () async {
      final dio = Dio();
      final adapter = _ScriptingAdapter((options, index) {
        if (index == 0) {
          throw _err(options, type: DioExceptionType.badResponse, status: 503);
        }
        return _ok();
      });
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 1),
        ),
      );

      final response = await dio.get<String>('/x');
      expect(response.statusCode, 200);
      expect(adapter.callCount, 2);
    });

    test('does not retry on 4xx client error', () async {
      final dio = Dio();
      final adapter = _ScriptingAdapter(
        (options, _) => throw _err(
          options,
          type: DioExceptionType.badResponse,
          status: 404,
        ),
      );
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 1),
        ),
      );

      await expectLater(dio.get<String>('/x'), throwsA(isA<DioException>()));
      expect(adapter.callCount, 1);
    });

    test('exponential backoff doubles delay each retry', () async {
      final dio = Dio();
      final adapter = _ScriptingAdapter((options, _) => throw _err(options));
      dio.httpClientAdapter = adapter;
      final start = DateTime.now();
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 50),
        ),
      );

      await expectLater(dio.get<String>('/x'), throwsA(isA<DioException>()));
      final elapsed = DateTime.now().difference(start);
      // base * (1 + 2 + 4) = 7 * 50ms = 350ms minimum.
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(300));
    });

    test(
      'retry-after with non-numeric falls back to baseDelay seconds',
      () async {
        final dio = Dio();
        final adapter = _ScriptingAdapter((options, index) {
          if (index == 0) {
            throw _err(
              options,
              type: DioExceptionType.badResponse,
              status: 429,
              headers: const {
                'retry-after': ['soon'],
              },
            );
          }
          return _ok();
        });
        dio.httpClientAdapter = adapter;
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            maxRetries: 3,
            // small so retry-after='soon' (parsed as 0 seconds) resolves quickly.
            baseDelay: const Duration(milliseconds: 1),
          ),
        );

        final response = await dio.get<String>('/x');
        expect(response.statusCode, 200);
        expect(adapter.callCount, 2);
      },
    );

    test('retry-after with numeric value is honored as delay', () async {
      final dio = Dio();
      final adapter = _ScriptingAdapter((options, index) {
        if (index == 0) {
          throw _err(
            options,
            type: DioExceptionType.badResponse,
            status: 503,
            headers: const {
              'retry-after': ['1'],
            },
          );
        }
        return _ok();
      });
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 1),
        ),
      );

      final start = DateTime.now();
      final response = await dio.get<String>('/x');
      final elapsed = DateTime.now().difference(start);

      expect(response.statusCode, 200);
      expect(adapter.callCount, 2);
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(900));
    });

    test('receiveTimeout is retried', () async {
      final dio = Dio();
      final adapter = _ScriptingAdapter(
        (options, index) => index < 1
            ? throw _err(options, type: DioExceptionType.receiveTimeout)
            : _ok(),
      );
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 1),
        ),
      );

      final response = await dio.get<String>('/x');
      expect(response.statusCode, 200);
      expect(adapter.callCount, 2);
    });

    test('cancel error is not retried (propagated immediately)', () async {
      final dio = Dio();
      final adapter = _ScriptingAdapter(
        (options, _) => throw _err(options, type: DioExceptionType.cancel),
      );
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 1),
        ),
      );

      await expectLater(dio.get<String>('/x'), throwsA(isA<DioException>()));
      expect(adapter.callCount, 1);
    });

    test('onResponse: x-ratelimit-remaining=0 delivers the 200 immediately '
        '(no hostage delay)', () async {
      final dio = Dio();
      final adapter = _ScriptingAdapter(
        (_, _) => ResponseBody.fromString(
          '{"ok":true}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
            'x-ratelimit-remaining': ['0'],
            'retry-after': ['1'],
          },
        ),
      );
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(dio: dio, baseDelay: const Duration(milliseconds: 1)),
      );

      final start = DateTime.now();
      final response = await dio.get<String>('/x');
      final elapsed = DateTime.now().difference(start);

      // The successful response is NOT held for `retry-after`; the breaker
      // gates the NEXT request instead.
      expect(response.statusCode, 200);
      expect(elapsed.inMilliseconds, lessThan(500));
    });

    test('circuit breaker: after remaining=0 the NEXT request short-circuits '
        'without a network call', () async {
      final dio = Dio();
      var networkCalls = 0;
      final futureReset =
          DateTime.now()
              .add(const Duration(seconds: 30))
              .millisecondsSinceEpoch ~/
          1000;
      final adapter = _ScriptingAdapter((_, _) {
        networkCalls++;
        return ResponseBody.fromString(
          '{"ok":true}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
            'x-ratelimit-remaining': ['0'],
            'x-ratelimit-reset': ['$futureReset'],
          },
        );
      });
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(dio: dio, baseDelay: const Duration(milliseconds: 1)),
      );

      // First call exhausts the budget and arms the breaker.
      final first = await dio.get<String>('/x');
      expect(first.statusCode, 200);
      expect(networkCalls, 1);

      // Second call must be rejected LOCALLY as a rate limit — no fetch.
      await expectLater(
        dio.get<String>('/x'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
      expect(networkCalls, 1, reason: 'the breaker must not hit the network');
    });

    test('circuit breaker: a 403 rate-limit error arms the breaker and is not '
        'retried', () async {
      final dio = Dio();
      var networkCalls = 0;
      final futureReset =
          DateTime.now()
              .add(const Duration(seconds: 30))
              .millisecondsSinceEpoch ~/
          1000;
      final adapter = _ScriptingAdapter((options, _) {
        networkCalls++;
        throw _err(
          options,
          type: DioExceptionType.badResponse,
          status: 403,
          headers: {
            'x-ratelimit-remaining': ['0'],
            'x-ratelimit-reset': ['$futureReset'],
          },
        );
      });
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 1),
        ),
      );

      await expectLater(dio.get<String>('/x'), throwsA(isA<DioException>()));
      // 403 is not retried (1 call only), and the window is now armed.
      expect(networkCalls, 1);

      await expectLater(dio.get<String>('/x'), throwsA(isA<DioException>()));
      expect(networkCalls, 1, reason: 'breaker short-circuits the next call');
    });

    test(
      'onResponse: x-ratelimit-remaining>0 passes through immediately',
      () async {
        final dio = Dio();
        final adapter = _ScriptingAdapter(
          (_, _) => ResponseBody.fromString(
            '{"ok":true}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
              'x-ratelimit-remaining': ['10'],
            },
          ),
        );
        dio.httpClientAdapter = adapter;
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            baseDelay: const Duration(milliseconds: 1),
          ),
        );

        final start = DateTime.now();
        await dio.get<String>('/x');
        final elapsed = DateTime.now().difference(start);
        expect(elapsed.inMilliseconds, lessThan(200));
      },
    );

    test(
      'onResponse: no rate-limit header passes through immediately',
      () async {
        final dio = Dio();
        final adapter = _ScriptingAdapter((_, _) => _ok());
        dio.httpClientAdapter = adapter;
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            baseDelay: const Duration(milliseconds: 1),
          ),
        );

        final start = DateTime.now();
        await dio.get<String>('/x');
        final elapsed = DateTime.now().difference(start);
        expect(elapsed.inMilliseconds, lessThan(200));
      },
    );

    test(
      'onResponse: non-numeric x-ratelimit-remaining passes through',
      () async {
        final dio = Dio();
        final adapter = _ScriptingAdapter(
          (_, _) => ResponseBody.fromString(
            '{"ok":true}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
              'x-ratelimit-remaining': ['plenty'],
            },
          ),
        );
        dio.httpClientAdapter = adapter;
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            baseDelay: const Duration(milliseconds: 1),
          ),
        );

        final start = DateTime.now();
        await dio.get<String>('/x');
        final elapsed = DateTime.now().difference(start);
        expect(elapsed.inMilliseconds, lessThan(200));
      },
    );
  });
}
