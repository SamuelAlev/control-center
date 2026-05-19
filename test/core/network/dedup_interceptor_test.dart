import 'dart:convert';

import 'package:control_center/core/network/dedup_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DedupInterceptor', () {
    late Dio dio;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.interceptors.add(DedupInterceptor(dio));
    });

    test(
      'coalesces identical concurrent GET requests into a single call',
      timeout: const Timeout.factor(2),
      () async {
        var networkCallCount = 0;
        dio.httpClientAdapter = _Adapter((options) {
          networkCallCount++;
          return _jsonResponse({'call': networkCallCount});
        });

        final results = await Future.wait([
          dio.get<Map<String, dynamic>>('/test'),
          dio.get<Map<String, dynamic>>('/test'),
          dio.get<Map<String, dynamic>>('/test'),
        ]);

        expect(networkCallCount, 1);
        for (final r in results) {
          expect(r.data!['call'], 1);
        }
      },
    );

    test(
      'different URIs are not coalesced',
      timeout: const Timeout.factor(2),
      () async {
        var callCount = 0;
        dio.httpClientAdapter = _Adapter((options) {
          callCount++;
          return _jsonResponse({'call': callCount});
        });

        final results = await Future.wait([
          dio.get<Map<String, dynamic>>('/a'),
          dio.get<Map<String, dynamic>>('/b'),
        ]);

        expect(callCount, 2);
        expect(results[0].data!['call'], 1);
        expect(results[1].data!['call'], 2);
      },
    );

    test(
      'different Accept headers are not coalesced',
      timeout: const Timeout.factor(2),
      () async {
        var callCount = 0;
        dio.httpClientAdapter = _Adapter((options) {
          callCount++;
          return _jsonResponse({'call': callCount});
        });

        final results = await Future.wait([
          dio.get<Map<String, dynamic>>(
            '/test',
            options: Options(headers: {'Accept': 'application/json'}),
          ),
          dio.get<Map<String, dynamic>>(
            '/test',
            options: Options(headers: {'Accept': 'text/html'}),
          ),
        ]);

        expect(callCount, 2);
        expect(results[0].data!['call'], 1);
        expect(results[1].data!['call'], 2);
      },
    );

    test(
      'non-GET requests pass through without coalescing',
      timeout: const Timeout.factor(2),
      () async {
        var callCount = 0;
        dio.httpClientAdapter = _Adapter((options) {
          callCount++;
          return _jsonResponse({'call': callCount});
        });

        final results = await Future.wait([
          dio.post<Map<String, dynamic>>('/test'),
          dio.post<Map<String, dynamic>>('/test'),
        ]);

        expect(callCount, 2);
        expect(results[0].data!['call'], 1);
        expect(results[1].data!['call'], 2);
      },
    );

    test(
      'request with CancelToken bypasses coalescing',
      timeout: const Timeout.factor(2),
      () async {
        var callCount = 0;
        dio.httpClientAdapter = _Adapter((options) {
          callCount++;
          return _jsonResponse({'call': callCount});
        });

        await Future.wait([
          dio.get<Map<String, dynamic>>('/test', cancelToken: CancelToken()),
          dio.get<Map<String, dynamic>>('/test', cancelToken: CancelToken()),
        ]);

        expect(callCount, 2);
      },
    );

    test(
      'sequential identical requests are not coalesced (first finishes before second)',
      timeout: const Timeout.factor(2),
      () async {
        var callCount = 0;
        dio.httpClientAdapter = _Adapter((options) {
          callCount++;
          return _jsonResponse({'call': callCount});
        });

        final r1 = await dio.get<Map<String, dynamic>>('/test');
        final r2 = await dio.get<Map<String, dynamic>>('/test');

        expect(callCount, 2);
        expect(r1.data!['call'], 1);
        expect(r2.data!['call'], 2);
      },
    );

    test(
      'coalesced waiters receive their own RequestOptions',
      timeout: const Timeout.factor(2),
      () async {
        dio.httpClientAdapter = _Adapter((options) {
          return _jsonResponse({'ok': true});
        });

        final results = await Future.wait([
          dio.get<Map<String, dynamic>>('/test'),
          dio.get<Map<String, dynamic>>('/test'),
        ]);

        expect(results.length, 2);
        expect(results[0].requestOptions.path, '/test');
        expect(results[1].requestOptions.path, '/test');
      },
    );

    test(
      'coalesced waiters share the same response data',
      timeout: const Timeout.factor(2),
      () async {
        dio.httpClientAdapter = _Adapter((options) {
          return _jsonResponse({'shared': true});
        });

        final results = await Future.wait([
          dio.get<Map<String, dynamic>>('/test'),
          dio.get<Map<String, dynamic>>('/test'),
        ]);

        expect(results[0].data!['shared'], true);
        expect(results[1].data!['shared'], true);
      },
    );

    test(
      'different response types are not coalesced',
      timeout: const Timeout.factor(2),
      () async {
        var callCount = 0;
        dio.httpClientAdapter = _Adapter((options) {
          callCount++;
          return _jsonResponse({'call': callCount});
        });

        await Future.wait([
          dio.get<Map<String, dynamic>>(
            '/test',
            options: Options(responseType: ResponseType.json),
          ),
          dio.get<String>(
            '/test',
            options: Options(responseType: ResponseType.plain),
          ),
        ]);

        expect(callCount, 2);
      },
    );
  });
}

/// Returns a JSON [ResponseBody] with the given [statusCode].
ResponseBody _jsonResponse(Map<String, dynamic> data, [int statusCode = 200]) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      'content-type': ['application/json'],
    },
  );
}

/// A sync-callback adapter. The callback may return [ResponseBody] or throw.
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
