import 'dart:async';
import 'dart:typed_data';

import 'package:cc_infra/src/network/dedup_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// A fixed-status adapter — every request resolves with [statusCode] and an
/// empty body, so Dio's default `validateStatus` rejects a 4xx as a
/// `DioException`.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('', statusCode);

  @override
  void close({bool force = false}) {}
}

void main() {
  group('DedupInterceptor', () {
    test(
      'a rejected coalescable GET rejects the caller without leaking an '
      'unhandled async error',
      () async {
        // Regression: a feed returning 415 crashed the headless cc_server. The
        // interceptor attached the in-flight cleanup as a SECOND, unlistened
        // listener on the request future, so the rejection re-surfaced as an
        // unhandled async error and killed the zone-less server — even though
        // the caller's own onError handled it.
        final unhandled = <Object>[];
        await runZonedGuarded(
          () async {
            final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
            dio.httpClientAdapter = _StubAdapter(415);
            dio.interceptors.add(DedupInterceptor(dio));

            // Two concurrent identical GETs coalesce onto one network call.
            final calls = [
              dio.get<dynamic>('/feed'),
              dio.get<dynamic>('/feed'),
            ];
            for (final call in calls) {
              await expectLater(call, throwsA(isA<DioException>()));
            }
            // Give any stray (unlistened) future a turn to surface its error.
            await Future<void>.delayed(const Duration(milliseconds: 20));
          },
          (error, _) => unhandled.add(error),
        );

        expect(
          unhandled,
          isEmpty,
          reason:
              'the in-flight cleanup must not re-propagate the rejection on a '
              'second, unlistened future',
        );
      },
    );

    test('a successful coalescable GET resolves all coalesced callers', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.httpClientAdapter = _StubAdapter(200);
      dio.interceptors.add(DedupInterceptor(dio));

      final results = await Future.wait([
        dio.get<dynamic>('/feed'),
        dio.get<dynamic>('/feed'),
      ]);

      for (final r in results) {
        expect(r.statusCode, 200);
      }
    });
  });
}
