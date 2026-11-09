import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/src/network/forge_http_client_factory.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Captures client configuration and exercises authentication without a native
/// transport.
class _Recorder {
  final List<String?> baseUrls = [];
  final List<ClientSettings> settings = [];
  final List<List<Interceptor>> interceptors = [];
  final Map<String?, RhttpClient> built = {};

  RhttpClient build(
    String? baseUrl,
    ClientSettings clientSettings,
    List<Interceptor> chain,
  ) {
    baseUrls.add(baseUrl);
    settings.add(clientSettings);
    interceptors.add(chain);
    return built.putIfAbsent(
      baseUrl,
      () => TestHttpClient(
        handler: (request) async => httpTextResponse(request, '{}'),
      ),
    );
  }
}

HttpRequest _request({Map<String, String> headers = const {}}) => HttpRequest(
  method: HttpMethod.get,
  url: '/user',
  headers: headers.isEmpty ? null : HttpHeaders.rawMap(headers),
);

void main() {
  group('ForgeHttpClientFactory wiring', () {
    test(
      'each forge is built against its own API base and the forge timeout',
      () async {
        final recorder = _Recorder();
        final factory = ForgeHttpClientFactory(
          tokenLookup: (_) async => 'token',
          buildClient: recorder.build,
        );

        for (final forge in ForgeHost.supported) {
          factory.of(forge);
        }

        expect(recorder.baseUrls, [
          for (final forge in ForgeHost.supported) forge.apiBaseUrl,
        ]);
        for (final settings in recorder.settings) {
          expect(
            settings.timeoutSettings?.connectTimeout,
            const Duration(seconds: 12),
          );
          expect(
            settings.timeoutSettings?.timeout,
            const Duration(seconds: 12),
          );
        }
        for (final chain in recorder.interceptors) {
          expect(chain.single, isA<ForgeAuthInterceptor>());
        }
      },
    );

    test('a guard runs before auth and an observer after it', () {
      final recorder = _Recorder();
      ForgeHttpClientFactory(
        tokenLookup: (_) async => 'token',
        requestGuard: (_, _, _, _) => null,
        onResponse: (_, _, _) {},
        buildClient: recorder.build,
      ).of(ForgeHost.github);

      expect(recorder.interceptors.single.map((i) => i.runtimeType), [
        ForgeRequestGuardInterceptor,
        ForgeAuthInterceptor,
        ForgeResponseObserverInterceptor,
      ]);
    });

    test('the client for a forge is built once and reused; forges do not '
        'share one', () {
      final recorder = _Recorder();
      final factory = ForgeHttpClientFactory(
        tokenLookup: (_) async => 'token',
        buildClient: recorder.build,
      );

      expect(
        identical(factory.of(ForgeHost.github), factory.of(ForgeHost.github)),
        isTrue,
      );
      expect(recorder.baseUrls, hasLength(1));

      expect(
        identical(factory.of(ForgeHost.github), factory.of(ForgeHost.gitlab)),
        isFalse,
      );
      expect(recorder.baseUrls, hasLength(2));
    });
  });

  group('ForgeAuthInterceptor schemes', () {
    ForgeAuthInterceptor forForge(
      ForgeHost forge, {
      String? token,
      String bitbucketEmail = '',
      Future<String?> Function(ForgeHost forge)? lookup,
    }) => ForgeAuthInterceptor(
      forge: forge,
      tokenLookup: lookup ?? (_) async => token,
      bitbucketUsername: () => bitbucketEmail,
    );

    test('GitHub sends a bearer token and its API version', () async {
      final result = await forForge(
        ForgeHost.github,
        token: 'gh-token',
      ).beforeRequest(_request());

      final headers = result.value!.headers!;
      expect(headers[HttpHeaderName.authorization], 'Bearer gh-token');
      expect(headers.toMapList()['X-GitHub-Api-Version'], ['2022-11-28']);
    });

    test('GitLab sends both header forms so either token kind works', () async {
      final result = await forForge(
        ForgeHost.gitlab,
        token: 'gl-token',
      ).beforeRequest(_request());

      final map = result.value!.headers!.toMapList();
      expect(map['Authorization'], ['Bearer gl-token']);
      expect(map['PRIVATE-TOKEN'], ['gl-token']);
    });

    test('Bitbucket sends basic auth built from the account email', () async {
      final result = await forForge(
        ForgeHost.bitbucket,
        token: 'bb-token',
        bitbucketEmail: 'me@example.com',
      ).beforeRequest(_request());

      final auth =
          result.value!.headers![HttpHeaderName.authorization] as String;
      expect(auth, startsWith('Basic '));
      expect(
        utf8.decode(base64Decode(auth.substring('Basic '.length))),
        'me@example.com:bb-token',
      );
    });

    test('no token means no Authorization header at all', () async {
      // Sending an empty credential would turn a "not connected" state into a
      // 401 that looks like a bad token.
      final result = await forForge(ForgeHost.github).beforeRequest(_request());

      final headers = result.value!.headers!;
      expect(headers.containsKey(HttpHeaderName.authorization), isFalse);
      // The API-version header still goes out: it is not a credential.
      expect(headers.toMapList()['X-GitHub-Api-Version'], ['2022-11-28']);
    });

    test(
      'the caller\'s own headers survive, and its API version wins',
      () async {
        final result = await forForge(ForgeHost.github, token: 't')
            .beforeRequest(
              _request(
                headers: {
                  'Accept': 'application/vnd.github.raw',
                  'X-GitHub-Api-Version': '2021-01-01',
                },
              ),
            );

        final map = result.value!.headers!.toMapList();
        expect(map['Accept'], ['application/vnd.github.raw']);
        expect(map['X-GitHub-Api-Version'], ['2021-01-01']);
        expect(map['Authorization'], ['Bearer t']);
      },
    );

    test('the token is read per request, not captured at build time', () async {
      // The whole point of the lazy lookup: a token pasted into Settings must
      // apply to the next call, with no client rebuild and no restart.
      var token = 'first';
      var lookups = 0;
      final auth = forForge(
        ForgeHost.github,
        lookup: (_) async {
          lookups++;
          return token;
        },
      );

      final first = await auth.beforeRequest(_request());
      token = 'second';
      final second = await auth.beforeRequest(_request());

      expect(lookups, 2);
      expect(
        [
          first.value!.headers![HttpHeaderName.authorization],
          second.value!.headers![HttpHeaderName.authorization],
        ],
        ['Bearer first', 'Bearer second'],
      );
    });

    test('a cleared token stops being sent immediately', () async {
      String? token = 'x';
      final auth = ForgeAuthInterceptor(
        forge: ForgeHost.github,
        tokenLookup: (_) async => token,
        bitbucketUsername: () => '',
      );

      await auth.beforeRequest(_request());
      token = null;
      final cleared = await auth.beforeRequest(_request());

      expect(
        cleared.value!.headers!.containsKey(HttpHeaderName.authorization),
        isFalse,
      );
    });

    test(
      'a cancellation and a status failure both travel up untouched',
      () async {
        // Callers catch the status they care about (401/403/404) off the raw
        // RhttpStatusCodeException, so the factory must never reshape one.
        final auth = forForge(ForgeHost.github, token: 't');
        final failure = RhttpStatusCodeException(
          request: _request(),
          statusCode: 404,
          headers: const [],
          body: '{}',
        );

        final result = await auth.onError(failure);
        expect(result.value, isNull, reason: 'the failure is unchanged');

        final cancelled = await auth.onError(RhttpCancelException(_request()));
        expect(cancelled.value, isNull);
      },
    );
  });
  group('ForgeRequestGuardInterceptor', () {
    test('a refused request fails before it is sent', () async {
      final seen = <(String, String, Object?)>[];
      final guard = ForgeRequestGuardInterceptor(
        forge: ForgeHost.github,
        guard: (forge, method, url, body) {
          seen.add((method, url, body));
          return body is Map && body['event'] == 'APPROVE' ? 'no' : null;
        },
      );
      final approve = HttpRequest(
        method: HttpMethod.post,
        url: '/repos/o/r/pulls/1/reviews',
        body: const HttpBody.json({'event': 'APPROVE'}),
      );

      await expectLater(
        guard.beforeRequest(approve),
        throwsA(
          isA<ForgeRequestRefused>().having((e) => e.reason, 'reason', 'no'),
        ),
      );
      expect(seen.single.$1, 'POST');
      expect(seen.single.$3, {'event': 'APPROVE'});

      final comment = HttpRequest(
        method: HttpMethod.post,
        url: '/repos/o/r/pulls/1/reviews',
        body: HttpBody.text(jsonEncode({'event': 'COMMENT'})),
      );
      final result = await guard.beforeRequest(comment);
      expect(result.value, isNull, reason: 'passed through unchanged');
      expect(seen.last.$3, {'event': 'COMMENT'});
    });
  });

  group('ForgeResponseObserverInterceptor', () {
    test('sees successes and status failures, and never alters them', () async {
      final seen = <(int, Map<String, String>)>[];
      final observer = ForgeResponseObserverInterceptor(
        forge: ForgeHost.github,
        observer: (_, status, headers) => seen.add((status, headers)),
      );

      final ok = await observer.afterResponse(
        httpTextResponse(
          _request(),
          '{}',
          headers: const {'x-ratelimit-remaining': '4999'},
        ),
      );
      final failure = await observer.onError(
        RhttpStatusCodeException(
          request: _request(),
          statusCode: 403,
          headers: const [('x-ratelimit-remaining', '0')],
          body: '{}',
        ),
      );

      expect(ok.value, isNull);
      expect(failure.value, isNull);
      expect(seen.map((e) => e.$1), [200, 403]);
      expect(seen.first.$2['x-ratelimit-remaining'], '4999');
      expect(seen.last.$2['x-ratelimit-remaining'], '0');
    });

    test('a throwing observer does not fail the call', () async {
      final observer = ForgeResponseObserverInterceptor(
        forge: ForgeHost.github,
        observer: (_, _, _) => throw StateError('broken'),
      );

      final result = await observer.afterResponse(
        httpTextResponse(_request(), '{}'),
      );

      expect(result.value, isNull);
    });
  });
}
