import 'dart:convert';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

const _googleToken = 'https://oauth2.googleapis.com/token';
const _googleRevoke = 'https://oauth2.googleapis.com/revoke';

void _scriptGoogle(
  FakeUpstream upstream, {
  List<String> scopes = googleConnectScopes,
  String aud = 'g-client.apps.googleusercontent.com',
  Map<String, Object?> extraClaims = const {},
}) {
  upstream
    ..on('POST', _googleToken, (call) {
      final form = call.form;
      if (form['client_secret'] != 'goog-secret') {
        return UpstreamResponse.json(401, {'error': 'invalid_client'});
      }
      if (form['grant_type'] == 'refresh_token') {
        if (form['refresh_token'] != '1//refresh') {
          return UpstreamResponse.json(400, {
            'error': 'invalid_grant',
            'error_description': 'Token has been expired or revoked.',
          });
        }
        return UpstreamResponse.json(200, {
          'access_token': 'ya29.refreshed',
          'expires_in': 3599,
          'scope': scopes.join(' '),
          'token_type': 'Bearer',
        });
      }
      if (form['code'] != 'g-code') {
        return UpstreamResponse.json(400, {'error': 'invalid_grant'});
      }
      return UpstreamResponse.json(200, {
        'access_token': 'ya29.access',
        'expires_in': 3599,
        'refresh_token': '1//refresh',
        'scope': scopes.join(' '),
        'token_type': 'Bearer',
        'id_token': fakeJwt({
          'iss': 'https://accounts.google.com',
          'aud': aud,
          'sub': '1170000000001',
          'email': 'person@example.com',
          'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
          ...extraClaims,
        }),
      });
    })
    ..json('POST', _googleRevoke, 200, {});
}

Future<TestResponse> _claim(
  Harness harness,
  ConnectInstallIdentity who,
  ConnectOAuthLane lane, {
  String code = 'g-code',
}) async {
  final flow = await browserFlow(harness, who, lane, code: code);
  return harness.call(
    who,
    'POST',
    '/v1/oauth/${lane.wire}/claim',
    body: OAuthClaimRequest(
      loginId: flow.loginId,
      confirmCode: flow.confirmCode,
      codeVerifier: flow.pkce.verifier,
      workspaceId: 'ws1',
    ).toJson(),
  );
}

Map<String, Object?> _klipyItem(
  Object id, {
  String host = 'static.klipy.com',
}) => {
  'id': id,
  'title': 'cat $id',
  'file': {
    'hd': {
      'gif': {'url': 'https://$host/hd/$id.gif', 'width': 498, 'height': 280},
    },
    'sm': {
      'gif': {'url': 'https://$host/sm/$id.gif', 'width': 220, 'height': 124},
    },
  },
};

void main() {
  late ConnectInstallIdentity a;
  late Harness harness;

  setUp(() async {
    a = await ConnectInstallIdentity.derive(
      masterSeed: seed(1),
      connectUrl: testPublicUrl,
    );
    harness = await Harness.start(allowed: [a]);
  });

  tearDown(() => harness.close());

  group('google', () {
    test('the authorize URL asks for exactly the Connect scopes', () async {
      final pkce = PkcePair.generate();
      final start = await harness.call(
        a,
        'POST',
        '/v1/oauth/google/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: pkce.challenge,
          loginHint: 'person@example.com',
        ).toJson(),
      );
      final url = OAuthStartResponse.fromJson(start.json).authorizeUrl;
      expect(url.host, 'accounts.google.com');
      expect(url.queryParameters['scope'], googleConnectScopes.join(' '));
      expect(url.queryParameters['access_type'], 'offline');
      expect(url.queryParameters['login_hint'], 'person@example.com');
    });

    test('a login hint is only accepted for google', () async {
      final start = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: PkcePair.generate().challenge,
          loginHint: 'person@example.com',
        ).toJson(),
      );
      expect(start.json, {'error': 'invalid_request'});
    });

    test(
      'sign-in seals the refresh token; refresh returns a new access token',
      () async {
        _scriptGoogle(harness.upstream);
        final claim = await _claim(harness, a, ConnectOAuthLane.google);
        expect(claim.status, 200, reason: claim.body);
        final grant = SealedGrant.fromJson(claim.json);
        expect(grant.accessToken, 'ya29.access');
        expect(grant.accountId, '1170000000001');
        expect(grant.accountLogin, 'person@example.com');
        expect(grant.seal, isNot(contains('1//refresh')));
        final refreshed = await harness.call(
          a,
          'POST',
          '/v1/google/refresh',
          body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
        );
        expect(
          SealedGrant.fromJson(refreshed.json).accessToken,
          'ya29.refreshed',
        );
        expect(harness.upstream.callsTo('POST', _googleRevoke), isEmpty);
      },
    );

    test('a widened grant is revoked and refused', () async {
      _scriptGoogle(
        harness.upstream,
        scopes: [
          ...googleConnectScopes,
          'https://www.googleapis.com/auth/drive',
        ],
      );
      final claim = await _claim(harness, a, ConnectOAuthLane.google);
      expect(claim.json, {'error': 'access_denied'});
      final revoke = harness.upstream.callsTo('POST', _googleRevoke).single;
      expect(revoke.form['token'], '1//refresh');
    });

    test('an id token for another client is revoked and refused', () async {
      _scriptGoogle(harness.upstream, aud: 'other.apps.googleusercontent.com');
      final claim = await _claim(harness, a, ConnectOAuthLane.google);
      expect(claim.json, {'error': 'access_denied'});
      expect(harness.upstream.callsTo('POST', _googleRevoke), hasLength(1));
    });

    test(
      'expired, unverified or azp-mismatched id tokens are revoked and refused',
      () async {
        for (final bad in [
          {'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 - 10},
          {'email_verified': false},
          {'azp': 'other.apps.googleusercontent.com'},
        ]) {
          _scriptGoogle(harness.upstream, extraClaims: bad);
          final claim = await _claim(harness, a, ConnectOAuthLane.google);
          expect(claim.json, {'error': 'access_denied'});
        }
        expect(harness.upstream.callsTo('POST', _googleRevoke), hasLength(3));
      },
    );

    test(
      'a rejected code is access_denied and a revoked refresh needs sign-in',
      () async {
        _scriptGoogle(harness.upstream);
        final bad = await _claim(
          harness,
          a,
          ConnectOAuthLane.google,
          code: 'nope',
        );
        expect(bad.json, {'error': 'access_denied'});
        final good = SealedGrant.fromJson(
          (await _claim(harness, a, ConnectOAuthLane.google)).json,
        );
        // Revoke upstream: Google now refuses the refresh token.
        harness.upstream.json('POST', _googleToken, 400, {
          'error': 'invalid_grant',
        });
        final refreshed = await harness.call(
          a,
          'POST',
          '/v1/google/refresh',
          body: SealRequest(seal: good.seal, workspaceId: 'ws1').toJson(),
        );
        expect(refreshed.json, {'error': 'needs_sign_in'});
        expect(refreshed.body, isNot(contains('expired or revoked')));
      },
    );
  });

  group('linear', () {
    test('the claim returns the code for the server to exchange', () async {
      for (final lane in [
        ConnectOAuthLane.linear,
        ConnectOAuthLane.linearApp,
      ]) {
        final claim = await _claim(harness, a, lane, code: 'lin-code');
        expect(claim.status, 200, reason: claim.body);
        final grant = LinearCodeGrant.fromJson(claim.json);
        expect(grant.code, 'lin-code');
        expect(
          grant.redirectUri,
          'https://connect.test/oauth/${lane.wire}/callback',
        );
      }
      expect(
        harness.upstream.calls,
        isEmpty,
        reason: 'Connect holds no Linear secret',
      );
    });

    test('the app actor lane asks for actor=app', () async {
      final start = await harness.call(
        a,
        'POST',
        '/v1/oauth/linear_app/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: PkcePair.generate().challenge,
        ).toJson(),
      );
      final url = OAuthStartResponse.fromJson(start.json).authorizeUrl;
      expect(url.host, 'linear.app');
      expect(url.queryParameters['actor'], 'app');
    });
  });

  group('klipy', () {
    const search = 'https://api.klipy.com/api/v1/klipy-key-123/gifs/search';

    test('search is proxied and normalised to CDN URLs only', () async {
      harness.upstream.json('GET', search, 200, {
        'result': true,
        'data': {
          'data': [
            _klipyItem(1),
            _klipyItem('two'),
            _klipyItem(3, host: 'evil.example'),
            {'id': 4, 'title': 'no file'},
          ],
          'has_next': true,
        },
      });
      final response = await harness.call(
        a,
        'POST',
        '/v1/klipy/search',
        body: const KlipyQuery(
          query: 'cats',
          perPage: 10,
          locale: 'en',
        ).toJson(),
      );
      expect(response.status, 200, reason: response.body);
      final gifs = KlipyGifsResponse.fromJson(response.json).gifs;
      expect(gifs.map((g) => g.id), ['1', 'two']);
      expect(gifs.first.gifUrl, 'https://static.klipy.com/hd/1.gif');
      expect(gifs.first.previewUrl, 'https://static.klipy.com/sm/1.gif');
      expect(gifs.first.width, 498);
      expect(response.body, isNot(contains('klipy-key-123')));
      final call = harness.upstream.callsTo('GET', search).single;
      expect(call.url.queryParameters, {
        'q': 'cats',
        'page': '1',
        'per_page': '10',
        'locale': 'en',
        'format_filter': 'gif',
      });
    });

    test('trending refuses a query; search requires one', () async {
      final trending = await harness.call(
        a,
        'POST',
        '/v1/klipy/trending',
        body: {'q': 'cats'},
      );
      expect(trending.json, {'error': 'invalid_request'});
      final empty = await harness.call(
        a,
        'POST',
        '/v1/klipy/search',
        body: {'q': '  '},
      );
      expect(empty.json, {'error': 'invalid_request'});
      final huge = await harness.call(
        a,
        'POST',
        '/v1/klipy/search',
        body: {'q': 'cats', 'per_page': 500},
      );
      expect(huge.json, {'error': 'invalid_request'});
    });

    test('an answer that echoes the key is never relayed', () async {
      harness.upstream.json('GET', search, 200, {
        'data': {
          'data': [
            {
              ..._klipyItem(1),
              'title': 'see https://api.klipy.com/api/v1/klipy-key-123/x',
            },
          ],
        },
      });
      final response = await harness.call(
        a,
        'POST',
        '/v1/klipy/search',
        body: const KlipyQuery(query: 'cats').toJson(),
      );
      expect(response.json, {'error': 'provider_unavailable'});
      expect(response.body, isNot(contains('klipy-key-123')));
    });

    test('an upstream error body is never relayed', () async {
      harness.upstream.json('GET', search, 500, {'message': 'upstream-detail'});
      final response = await harness.call(
        a,
        'POST',
        '/v1/klipy/search',
        body: const KlipyQuery(query: 'cats').toJson(),
      );
      expect(response.status, 503);
      expect(response.body, isNot(contains('upstream-detail')));
    });

    test('key mode is not proxied', () async {
      final keyMode = await Harness.start(
        allowed: [a],
        env: {'CONNECT_KLIPY_MODE': 'key'},
      );
      addTearDown(keyMode.close);
      final response = await keyMode.call(
        a,
        'POST',
        '/v1/klipy/trending',
        body: const KlipyQuery().toJson(),
      );
      expect(response.json, {'error': 'provider_unavailable'});
      final config = ConnectConfig.fromJson(
        (await keyMode.call(a, 'GET', '/v1/config')).json,
      );
      expect(config.klipy!.mode, KlipyLaneMode.key);
      expect(config.klipy!.appKey, 'klipy-key-123');
    });

    test('a rotation retries the previous key', () async {
      final rotating = await Harness.start(
        allowed: [a],
        env: {
          'CONNECT_KLIPY_APP_KEY': 'klipy-key-new',
          'CONNECT_KLIPY_APP_KEY_PREVIOUS': 'klipy-key-123',
        },
      );
      addTearDown(rotating.close);
      rotating.upstream
        ..json(
          'GET',
          'https://api.klipy.com/api/v1/klipy-key-new/gifs/trending',
          401,
          {'message': 'bad key'},
        )
        ..json(
          'GET',
          'https://api.klipy.com/api/v1/klipy-key-123/gifs/trending',
          200,
          {
            'data': {
              'data': [_klipyItem(7)],
            },
          },
        );
      final response = await rotating.call(
        a,
        'POST',
        '/v1/klipy/trending',
        body: const KlipyQuery().toJson(),
      );
      expect(KlipyGifsResponse.fromJson(response.json).gifs.single.id, '7');
    });

    test('a per-install budget', () async {
      final limited = await Harness.start(
        allowed: [a],
        env: {'CONNECT_RATE_KLIPY_PER_MINUTE': '1'},
      );
      addTearDown(limited.close);
      limited.upstream.json(
        'GET',
        'https://api.klipy.com/api/v1/klipy-key-123/gifs/trending',
        200,
        {
          'data': {'data': <Object?>[]},
        },
      );
      final first = await limited.call(a, 'POST', '/v1/klipy/trending');
      expect(first.status, 200);
      final second = await limited.call(a, 'POST', '/v1/klipy/trending');
      expect(second.json, {'error': 'rate_limited'});
    });

    test('normaliseKlipyResponse tolerates junk', () {
      expect(normaliseKlipyResponse(null), isEmpty);
      expect(normaliseKlipyResponse({'data': 'nope'}), isEmpty);
      expect(
        normaliseKlipyResponse(
          jsonDecode(
                jsonEncode({
                  'data': {
                    'data': [
                      {
                        'id': 9,
                        'title': 't',
                        'file': {
                          'sm': {
                            'webp': {
                              'url': 'https://static.klipy.com/9.webp',
                              'width': 10,
                              'height': 10,
                            },
                          },
                        },
                      },
                    ],
                  },
                }),
              )
              as Map<String, Object?>,
        ).single.gifUrl,
        'https://static.klipy.com/9.webp',
      );
    });
  });
}
