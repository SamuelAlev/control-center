import 'dart:convert';

import 'package:control_center/core/network/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RetryInterceptor', () {
    test(
      'retries on connection timeout and succeeds',
      timeout: const Timeout.factor(2),
      () async {
        var attempt = 0;
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            maxRetries: 3,
            baseDelay: Duration.zero,
          ),
        );
        dio.httpClientAdapter = _Adapter((options) {
          attempt++;
          if (attempt == 1) {
            throw DioException(
              type: DioExceptionType.connectionTimeout,
              requestOptions: options,
            );
          }
          return _jsonResponse({'result': 'ok'});
        });

        final response = await dio.get<Map<String, dynamic>>('/test');
        expect(response.data!['result'], 'ok');
      },
    );

    test(
      'retries on receive timeout and succeeds',
      timeout: const Timeout.factor(2),
      () async {
        var attempt = 0;
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            maxRetries: 3,
            baseDelay: Duration.zero,
          ),
        );
        dio.httpClientAdapter = _Adapter((options) {
          attempt++;
          if (attempt == 1) {
            throw DioException(
              type: DioExceptionType.receiveTimeout,
              requestOptions: options,
            );
          }
          return _jsonResponse({'result': 'ok'});
        });

        final response = await dio.get<Map<String, dynamic>>('/test');
        expect(response.data!['result'], 'ok');
      },
    );

    test(
      'retries on 500 server error and succeeds',
      timeout: const Timeout.factor(2),
      () async {
        var attempt = 0;
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            maxRetries: 3,
            baseDelay: Duration.zero,
          ),
        );
        dio.httpClientAdapter = _Adapter((options) {
          attempt++;
          if (attempt == 1) {
            return _jsonResponse({'message': 'error'}, statusCode: 500);
          }
          return _jsonResponse({'result': 'recovered'});
        });

        final response = await dio.get<Map<String, dynamic>>('/test');
        expect(response.data!['result'], 'recovered');
      },
    );

    test(
      'retries on 429 rate limit and succeeds',
      timeout: const Timeout.factor(2),
      () async {
        var attempt = 0;
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            maxRetries: 3,
            baseDelay: Duration.zero,
          ),
        );
        dio.httpClientAdapter = _Adapter((options) {
          attempt++;
          if (attempt == 1) {
            return _jsonResponse({'message': 'rate limited'}, statusCode: 429);
          }
          return _jsonResponse({'result': 'ok'});
        });

        final response = await dio.get<Map<String, dynamic>>('/test');
        expect(response.data!['result'], 'ok');
      },
    );

    test(
      'does not retry on 400 client error',
      timeout: const Timeout.factor(2),
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            maxRetries: 3,
            baseDelay: Duration.zero,
          ),
        );
        dio.httpClientAdapter = _Adapter((options) {
          return _jsonResponse({'message': 'bad request'}, statusCode: 400);
        });

        expect(
          () => dio.get<Map<String, dynamic>>('/test'),
          throwsA(isA<DioException>()),
        );
      },
    );

    test(
      'does not retry on 404',
      timeout: const Timeout.factor(2),
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            maxRetries: 3,
            baseDelay: Duration.zero,
          ),
        );
        dio.httpClientAdapter = _Adapter((options) {
          return _jsonResponse({'message': 'not found'}, statusCode: 404);
        });

        expect(
          () => dio.get<Map<String, dynamic>>('/test'),
          throwsA(isA<DioException>()),
        );
      },
    );

    test(
      'does not retry on 403',
      timeout: const Timeout.factor(2),
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            maxRetries: 3,
            baseDelay: Duration.zero,
          ),
        );
        dio.httpClientAdapter = _Adapter((options) {
          return _jsonResponse({'message': 'forbidden'}, statusCode: 403);
        });

        expect(
          () => dio.get<Map<String, dynamic>>('/test'),
          throwsA(isA<DioException>()),
        );
      },
    );

    test(
      'stops retrying after maxRetries is reached',
      timeout: const Timeout.factor(2),
      () async {
        var attemptCount = 0;
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            maxRetries: 2,
            baseDelay: Duration.zero,
          ),
        );
        dio.httpClientAdapter = _Adapter((options) {
          attemptCount++;
          throw DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: options,
          );
        });

        try {
          await dio.get<dynamic>('/test');
          fail('Should have thrown');
        } on DioException {
          // 1 original + 2 retries = 3 adapter calls
          expect(attemptCount, 3);
        }
      },
    );

    test(
      'retry count resets for a new request',
      timeout: const Timeout.factor(2),
      () async {
        var attemptCount = 0;
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.interceptors.add(
          RetryInterceptor(
            dio: dio,
            maxRetries: 1,
            baseDelay: Duration.zero,
          ),
        );
        dio.httpClientAdapter = _Adapter((options) {
          attemptCount++;
          // Fail on first attempt of each request, succeed on second
          if (attemptCount == 1 || attemptCount == 3) {
            throw DioException(
              type: DioExceptionType.connectionTimeout,
              requestOptions: options,
            );
          }
          return _jsonResponse({'attempt': attemptCount});
        });

        final r1 = await dio.get<Map<String, dynamic>>('/test');
        expect(r1.data!['attempt'], 2);

        final r2 = await dio.get<Map<String, dynamic>>('/test');
        expect(r2.data!['attempt'], 4);
      },
    );
  });
}

/// Returns a JSON [ResponseBody].
ResponseBody _jsonResponse(
  Map<String, dynamic> data, {
  int statusCode = 200,
}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      'content-type': ['application/json'],
    },
  );
}

/// A sync-callback adapter that preserves [RequestOptions] for error paths.
class _Adapter implements HttpClientAdapter {
  _Adapter(this._onFetch);
  final ResponseBody Function(RequestOptions options) _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      _onFetch(options);

  @override
  void close({bool force = false}) {}
}
