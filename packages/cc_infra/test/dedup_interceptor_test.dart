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

    // The key must survive interceptors that MUTATE headers after this one
    // runs — the forge factory adds `Authorization` further down the chain.
    // Recomputing it on the way out derives a different string, the in-flight
    // slot is never cleared, and the NEXT identical request enqueues on an
    // entry nothing will ever complete. The symptom is a hang, not a wrong
    // answer, which is why it showed up as a 30s test timeout.
    test('a later interceptor adding auth does not strand the in-flight slot',
        () async {
      final seen = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.httpClientAdapter = _RecordingAdapter(seen);
      dio.interceptors.add(DedupInterceptor(dio));
      // Registered AFTER dedup, exactly like ForgeDioFactory.
      var token = 'first';
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'Bearer $token';
            handler.next(options);
          },
        ),
      );

      await dio.get<dynamic>('/user');
      token = 'second';
      // Without the fix this second call never completes.
      await dio.get<dynamic>('/user').timeout(const Duration(seconds: 5));
      token = 'third';
      await dio.get<dynamic>('/user').timeout(const Duration(seconds: 5));

      expect(seen, ['Bearer first', 'Bearer second', 'Bearer third']);
    });

    // A per-credential fan-out is the case that broke this. Three Claude
    // subscriptions asking `/api/oauth/usage` at the same moment share a URL
    // and differ only by bearer — and the key did not include the bearer, so
    // all three got the FIRST account's numbers. The symptom was three
    // accounts reporting identical usage, with nothing in any log to say why.
    test('requests differing only by credential are NOT coalesced', () async {
      final seen = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.httpClientAdapter = _RecordingAdapter(seen);
      dio.interceptors.add(DedupInterceptor(dio));

      await Future.wait([
        dio.get<dynamic>(
          '/usage',
          options: Options(headers: {'Authorization': 'Bearer a'}),
        ),
        dio.get<dynamic>(
          '/usage',
          options: Options(headers: {'Authorization': 'Bearer b'}),
        ),
        dio.get<dynamic>(
          '/usage',
          options: Options(headers: {'Authorization': 'Bearer c'}),
        ),
      ]);

      expect(seen.length, 3, reason: 'one network call per credential');
      expect(seen.toSet(), {'Bearer a', 'Bearer b', 'Bearer c'});
    });

    test('an x-api-key is part of the identity too', () async {
      final seen = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.httpClientAdapter = _RecordingAdapter(seen, header: 'x-api-key');
      dio.interceptors.add(DedupInterceptor(dio));

      await Future.wait([
        dio.get<dynamic>('/m', options: Options(headers: {'x-api-key': 'k1'})),
        dio.get<dynamic>('/m', options: Options(headers: {'x-api-key': 'k2'})),
      ]);
      expect(seen.length, 2);
    });

    test('identical UNAUTHENTICATED gets still coalesce', () async {
      // The optimisation this interceptor exists for must survive the fix.
      final seen = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.httpClientAdapter = _RecordingAdapter(seen);
      dio.interceptors.add(DedupInterceptor(dio));

      await Future.wait([
        dio.get<dynamic>('/public'),
        dio.get<dynamic>('/public'),
        dio.get<dynamic>('/public'),
      ]);
      expect(seen.length, 1);
    });

    test('two calls with the SAME credential still coalesce', () async {
      final seen = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.httpClientAdapter = _RecordingAdapter(seen);
      dio.interceptors.add(DedupInterceptor(dio));

      await Future.wait([
        dio.get<dynamic>(
          '/usage',
          options: Options(headers: {'Authorization': 'Bearer same'}),
        ),
        dio.get<dynamic>(
          '/usage',
          options: Options(headers: {'Authorization': 'Bearer same'}),
        ),
      ]);
      expect(seen.length, 1);
    });
    test('a rejected coalescable GET rejects the caller without leaking an '
        'unhandled async error', () async {
      // Regression: a feed returning 415 crashed the headless cc_server. The
      // interceptor attached the in-flight cleanup as a SECOND, unlistened
      // listener on the request future, so the rejection re-surfaced as an
      // unhandled async error and killed the zone-less server — even though
      // the caller's own onError handled it.
      final unhandled = <Object>[];
      await runZonedGuarded(() async {
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
        dio.httpClientAdapter = _StubAdapter(415);
        dio.interceptors.add(DedupInterceptor(dio));

        // Two concurrent identical GETs coalesce onto one network call.
        final calls = [dio.get<dynamic>('/feed'), dio.get<dynamic>('/feed')];
        for (final call in calls) {
          await expectLater(call, throwsA(isA<DioException>()));
        }
        // Give any stray (unlistened) future a turn to surface its error.
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (error, _) => unhandled.add(error));

      expect(
        unhandled,
        isEmpty,
        reason:
            'the in-flight cleanup must not re-propagate the rejection on a '
            'second, unlistened future',
      );
    });

    test(
      'a successful coalescable GET resolves all coalesced callers',
      () async {
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
      },
    );
  });
}

/// Records the credential each request actually reached the network with, and
/// holds the response until every caller has been dispatched — so a coalesced
/// waiter cannot be mistaken for a second network call.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.seen, {this.header = 'Authorization'});

  final List<String> seen;
  final String header;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add('${options.headers[header]}');
    // Yield, so concurrent callers are all in flight before any resolves.
    await Future<void>.delayed(Duration.zero);
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
