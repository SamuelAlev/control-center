import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:cc_infra/src/network/forge_dio_factory.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Captures each request instead of sending it, so the tests assert on the
/// headers and resolved URL the forge would actually have received.
class _CaptureAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CaptureAdapter adapter;

  ForgeDioFactory build({
    Map<ForgeHost, String> tokens = const {},
    String bitbucketEmail = '',
  }) => ForgeDioFactory(
    tokenLookup: (forge) async => tokens[forge],
    bitbucketUsername: () => bitbucketEmail,
  );

  Dio client(ForgeDioFactory factory, ForgeHost forge) {
    final dio = factory.of(forge)..httpClientAdapter = adapter;
    return dio;
  }

  setUp(() => adapter = _CaptureAdapter());

  group('base URLs', () {
    test(
      'each forge resolves a relative path against its own API base',
      () async {
        final factory = build();
        for (final forge in ForgeHost.supported) {
          await client(factory, forge).get<dynamic>('/ping');
        }
        expect(adapter.requests.map((r) => r.uri.toString()), [
          'https://api.github.com/ping',
          'https://gitlab.com/api/v4/ping',
          'https://api.bitbucket.org/2.0/ping',
        ]);
      },
    );

    test('the same client instance is reused per forge', () {
      final factory = build();
      expect(
        identical(factory.of(ForgeHost.github), factory.of(ForgeHost.github)),
        isTrue,
      );
      expect(
        identical(factory.of(ForgeHost.github), factory.of(ForgeHost.gitlab)),
        isFalse,
      );
    });
  });

  group('auth schemes', () {
    test('GitHub sends a bearer token and its API version', () async {
      final factory = build(tokens: {ForgeHost.github: 'gh-token'});
      await client(factory, ForgeHost.github).get<dynamic>('/user');

      final headers = adapter.requests.single.headers;
      expect(headers['Authorization'], 'Bearer gh-token');
      expect(headers['X-GitHub-Api-Version'], '2022-11-28');
    });

    test('GitLab sends both header forms so either token kind works', () async {
      final factory = build(tokens: {ForgeHost.gitlab: 'gl-token'});
      await client(factory, ForgeHost.gitlab).get<dynamic>('/user');

      final headers = adapter.requests.single.headers;
      expect(headers['Authorization'], 'Bearer gl-token');
      expect(headers['PRIVATE-TOKEN'], 'gl-token');
    });

    test('Bitbucket sends basic auth built from the account email', () async {
      final factory = build(
        tokens: {ForgeHost.bitbucket: 'bb-token'},
        bitbucketEmail: 'me@example.com',
      );
      await client(factory, ForgeHost.bitbucket).get<dynamic>('/user');

      final auth = adapter.requests.single.headers['Authorization'] as String;
      expect(auth, startsWith('Basic '));
      expect(
        utf8.decode(base64Decode(auth.substring('Basic '.length))),
        'me@example.com:bb-token',
      );
    });

    test('no token means no Authorization header at all', () async {
      // Sending an empty credential would turn a "not connected" state into a
      // 401 that looks like a bad token.
      final factory = build();
      await client(factory, ForgeHost.github).get<dynamic>('/user');
      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('the token is read per request, not captured at build time', () async {
      // The whole point of the lazy lookup: a token pasted into Settings must
      // apply to the next call, with no client rebuild and no restart.
      var token = 'first';
      final factory = ForgeDioFactory(tokenLookup: (_) async => token);
      final dio = client(factory, ForgeHost.github);

      await dio.get<dynamic>('/one');
      token = 'second';
      await dio.get<dynamic>('/two');

      expect(adapter.requests.map((r) => r.headers['Authorization']), [
        'Bearer first',
        'Bearer second',
      ]);
    });

    test('a cleared token stops being sent immediately', () async {
      String? token = 'x';
      final factory = ForgeDioFactory(tokenLookup: (_) async => token);
      final dio = client(factory, ForgeHost.github);

      await dio.get<dynamic>('/one');
      token = null;
      await dio.get<dynamic>('/two');

      expect(
        adapter.requests.last.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });

  group('error mapping', () {
    test(
      'a failure surfaces as a typed exception, not a raw dio error',
      () async {
        // GitHub's own client has always mapped its errors; doing it in the
        // interceptor gives GitLab and Bitbucket the same typed failures.
        adapter.status = 404;
        final factory = build();
        final dio = client(factory, ForgeHost.gitlab);
        dio.options.validateStatus = (s) => s == 200;

        await expectLater(
          dio.get<dynamic>('/missing'),
          throwsA(
            isA<DioException>().having(
              (e) => e.error,
              'error',
              isA<NetworkException>(),
            ),
          ),
        );
      },
    );

    test('a cancellation passes through untouched', () async {
      // Cancellation is a subscriber standing down, not a forge failure — the
      // PR streams recognise it by type to swallow it quietly.
      final factory = build();
      final dio = client(factory, ForgeHost.github);
      final token = CancelToken()..cancel();

      await expectLater(
        dio.get<dynamic>('/slow', cancelToken: token),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
    });
  });
}
