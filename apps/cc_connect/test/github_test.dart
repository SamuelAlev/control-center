import 'dart:convert';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

const _writePermissions = {
  'metadata': 'read',
  'contents': 'write',
  'pull_requests': 'write',
};

void _scriptInstallations(FakeUpstream upstream, {String role = 'admin'}) {
  upstream
    ..json('GET', 'https://api.github.com/user/installations', 200, {
      'total_count': 3,
      'installations': [
        {
          'id': 77,
          'app_id': 4242,
          'target_type': 'Organization',
          'account': {'id': 500, 'login': 'acme'},
          'suspended_at': null,
        },
        {
          'id': 78,
          'app_id': 4242,
          'target_type': 'User',
          'account': {'id': 1001, 'login': 'octo'},
          'suspended_at': null,
        },
        {
          'id': 79,
          'app_id': 9999,
          'target_type': 'Organization',
          'account': {'id': 600, 'login': 'other'},
          'suspended_at': null,
        },
      ],
    })
    ..json('GET', 'https://api.github.com/repos/acme/api', 200, {
      'id': 9001,
      'private': true,
      'owner': {'id': 500, 'login': 'acme'},
      'permissions': {
        'admin': false,
        'maintain': false,
        'push': true,
        'triage': true,
        'pull': true,
      },
    })
    ..json('GET', 'https://api.github.com/repos/acme/docs', 200, {
      'id': 9002,
      'private': true,
      'owner': {'id': 500, 'login': 'acme'},
      'permissions': {'push': false, 'triage': false, 'pull': true},
    })
    ..json('GET', 'https://api.github.com/repos/octo/dotfiles', 200, {
      'id': 9003,
      'private': false,
      'owner': {'id': 1001, 'login': 'octo'},
      'permissions': {'admin': true, 'push': true, 'pull': true},
    })
    ..json('GET', 'https://api.github.com/orgs/acme/memberships/octo', 200, {
      'role': role,
      'state': 'active',
    })
    ..on(
      'POST',
      'https://api.github.com/applications/Iv23test/token/scoped',
      (call) => UpstreamResponse.json(200, {
        'token': 'ghu_child_${call.json['repository_ids']}',
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 8))
            .toIso8601String(),
        'installation': {
          'permissions': call.json['permissions'],
          'repository_selection': 'selected',
        },
      }),
    );
}

Map<String, Object?> _scopeBody(
  String seal, {
  required int repoId,
  required String owner,
  required String name,
  required String scope,
  String workspaceId = 'ws1',
}) => GitHubScopeRequest(
  seal: seal,
  workspaceId: workspaceId,
  repoId: repoId,
  repoOwner: owner,
  repoName: name,
  scope: scope,
).toJson();

void main() {
  late ConnectInstallIdentity a;
  late ConnectInstallIdentity b;
  late Harness harness;
  late FakeGitHub github;

  setUp(() async {
    a = await ConnectInstallIdentity.derive(
      masterSeed: seed(1),
      connectUrl: testPublicUrl,
    );
    b = await ConnectInstallIdentity.derive(
      masterSeed: seed(2),
      connectUrl: testPublicUrl,
    );
    harness = await Harness.start(allowed: [a, b]);
    github = FakeGitHub(harness.upstream);
  });

  tearDown(() => harness.close());

  group('sign-in', () {
    test('start builds a URL every server accepts', () async {
      final pkce = PkcePair.generate();
      final start = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: pkce.challenge,
        ).toJson(),
      );
      expect(start.status, 200);
      final response = OAuthStartResponse.fromJson(start.json);
      validateAuthorizeUrl(
        lane: ConnectOAuthLane.github,
        url: response.authorizeUrl,
        connectBaseUrl: testPublicUrl,
        expectedClientId: 'Iv23test',
        codeChallenge: pkce.challenge,
      );
      expect(response.authorizeUrl.queryParameters['state']!.length, 43);
      expect(isLoginId(response.loginId), isTrue);
    });

    test('start → callback → done → claim returns a sealed grant', () async {
      final grant = await signInGitHub(harness, a);
      expect(grant.accessToken, 'ghu_access1');
      expect(grant.accountId, '1001');
      expect(grant.accountLogin, 'octo');
      expect(grant.appId, '4242');
      expect(grant.seal, startsWith('v1.'));
      expect(grant.seal, isNot(contains('ghr_')));
      final exchange = harness.upstream.callsTo(
        'POST',
        'https://github.com/login/oauth/access_token',
      );
      expect(exchange, hasLength(1));
      expect(exchange.single.form['client_secret'], 'gh-secret-2');
      expect(exchange.single.form['code_verifier'], isNotEmpty);
      expect(
        exchange.single.form['redirect_uri'],
        'https://connect.test/oauth/github/callback',
      );
    });

    test(
      'a claim before the provider redirected back spends no attempt',
      () async {
        final pkce = PkcePair.generate();
        final start = await harness.call(
          a,
          'POST',
          '/v1/oauth/github/start',
          body: OAuthStartRequest(
            workspaceId: 'ws1',
            codeChallenge: pkce.challenge,
          ).toJson(),
        );
        final started = OAuthStartResponse.fromJson(start.json);
        for (var i = 0; i < 8; i++) {
          final early = await harness.call(
            a,
            'POST',
            '/v1/oauth/github/claim',
            body: OAuthClaimRequest(
              loginId: started.loginId,
              confirmCode: 'ZZZZZZZZ',
              codeVerifier: pkce.verifier,
              workspaceId: 'ws1',
            ).toJson(),
          );
          expect(early.json, {'error': 'code_mismatch'});
        }
        // The login is intact: the provider's redirect still lands.
        final state = started.authorizeUrl.queryParameters['state']!;
        final callback = await harness.browser(
          '/oauth/github/callback?code=gh-code&state=$state',
        );
        expect(callback.status, 303);
      },
    );

    test('a start naming another flow or an installation is refused', () async {
      final pkce = PkcePair.generate();
      for (final extra in [
        {'purpose': 'install_github_app'},
        {'installation_id': 7},
      ]) {
        final start = await harness.call(
          a,
          'POST',
          '/v1/oauth/github/start',
          body: {
            ...OAuthStartRequest(
              workspaceId: 'ws1',
              codeChallenge: pkce.challenge,
            ).toJson(),
            ...extra,
          },
        );
        expect(start.json, {'error': 'invalid_request'});
      }
    });

    test('a wrong confirm code five times burns the login', () async {
      final flow = await browserFlow(harness, a, ConnectOAuthLane.github);
      for (var i = 0; i < 5; i++) {
        final wrong = await harness.call(
          a,
          'POST',
          '/v1/oauth/github/claim',
          body: OAuthClaimRequest(
            loginId: flow.loginId,
            confirmCode: 'ZZZZZZZZ',
            codeVerifier: flow.pkce.verifier,
            workspaceId: 'ws1',
          ).toJson(),
        );
        expect(wrong.status, 403);
        expect(wrong.json, {'error': 'code_mismatch'});
      }
      final right = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/claim',
        body: OAuthClaimRequest(
          loginId: flow.loginId,
          confirmCode: flow.confirmCode,
          codeVerifier: flow.pkce.verifier,
          workspaceId: 'ws1',
        ).toJson(),
      );
      expect(right.json, {'error': 'stale_request'});
      expect(
        harness.upstream.callsTo(
          'POST',
          'https://github.com/login/oauth/access_token',
        ),
        isEmpty,
      );
    });

    test('a wrong PKCE verifier is refused', () async {
      final flow = await browserFlow(harness, a, ConnectOAuthLane.github);
      final claim = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/claim',
        body: OAuthClaimRequest(
          loginId: flow.loginId,
          confirmCode: flow.confirmCode,
          codeVerifier: PkcePair.generate().verifier,
          workspaceId: 'ws1',
        ).toJson(),
      );
      expect(claim.json, {'error': 'code_mismatch'});
    });

    test('a refused exchange logs why, never the code', () async {
      harness.upstream
          .json('POST', 'https://github.com/login/oauth/access_token', 200, {
            'error': 'bad_verification_code',
            'error_description': 'The code passed is incorrect or expired.',
          });
      final flow = await browserFlow(harness, a, ConnectOAuthLane.github);
      final claim = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/claim',
        body: OAuthClaimRequest(
          loginId: flow.loginId,
          confirmCode: flow.confirmCode,
          codeVerifier: flow.pkce.verifier,
          workspaceId: 'ws1',
        ).toJson(),
      );
      expect(claim.json, {'error': 'needs_sign_in'});
      final failed = harness.logs.singleWhere(
        (l) => l.contains('"oauth.claim_failed"'),
      );
      expect(
        failed,
        contains(
          'bad_verification_code:The_code_passed_is_incorrect_or_expired.',
        ),
      );
      expect(failed, isNot(contains('gh-code')));
    });

    test('an App with token expiry off is named in the log', () async {
      harness.upstream.json(
        'POST',
        'https://github.com/login/oauth/access_token',
        200,
        {'access_token': 'ghu_forever', 'token_type': 'bearer'},
      );
      final flow = await browserFlow(harness, a, ConnectOAuthLane.github);
      final claim = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/claim',
        body: OAuthClaimRequest(
          loginId: flow.loginId,
          confirmCode: flow.confirmCode,
          codeVerifier: flow.pkce.verifier,
          workspaceId: 'ws1',
        ).toJson(),
      );
      expect(claim.json, {'error': 'needs_sign_in'});
      expect(
        harness.logs.singleWhere((l) => l.contains('"oauth.claim_failed"')),
        contains('github_token_expiry_off'),
      );
    });

    test('another install cannot claim (or burn) a login', () async {
      final flow = await browserFlow(harness, a, ConnectOAuthLane.github);
      for (var i = 0; i < 6; i++) {
        final stolen = await harness.call(
          b,
          'POST',
          '/v1/oauth/github/claim',
          body: OAuthClaimRequest(
            loginId: flow.loginId,
            confirmCode: flow.confirmCode,
            codeVerifier: flow.pkce.verifier,
            workspaceId: 'ws1',
          ).toJson(),
        );
        expect(stolen.json, {'error': 'code_mismatch'});
      }
      final own = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/claim',
        body: OAuthClaimRequest(
          loginId: flow.loginId,
          confirmCode: flow.confirmCode,
          codeVerifier: flow.pkce.verifier,
          workspaceId: 'ws1',
        ).toJson(),
      );
      expect(own.status, 200);
    });

    test('a callback state works once', () async {
      final pkce = PkcePair.generate();
      final start = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: pkce.challenge,
        ).toJson(),
      );
      final state = OAuthStartResponse.fromJson(
        start.json,
      ).authorizeUrl.queryParameters['state'];
      final first = await harness.browser(
        '/oauth/github/callback?code=gh-code&state=$state',
      );
      expect(first.status, 303);
      expect(
        first.header('location'),
        'https://connect.test/oauth/github/done',
      );
      final second = await harness.browser(
        '/oauth/github/callback?code=gh-code&state=$state',
      );
      expect(second.status, 400);
      expect(second.body, isNot(contains('gh-code')));
    });

    test('a provider error shows a static page and burns the login', () async {
      final pkce = PkcePair.generate();
      final start = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: pkce.challenge,
        ).toJson(),
      );
      final started = OAuthStartResponse.fromJson(start.json);
      final state = started.authorizeUrl.queryParameters['state'];
      final page = await harness.browser(
        '/oauth/github/callback?error=access_denied'
        '&error_description=%3Cscript%3Ealert(1)%3C/script%3E&state=$state',
      );
      expect(page.status, 400);
      expect(page.body, isNot(contains('script>')));
      expect(page.body, isNot(contains('alert')));
    });
  });

  group('/done', () {
    test('is hardened static HTML', () async {
      final flow = await browserFlow(harness, a, ConnectOAuthLane.github);
      final done = flow.done;
      expect(done.status, 200);
      final csp = done.header('content-security-policy')!;
      expect(csp, contains("default-src 'none'"));
      expect(csp, contains('style-src $pageStyleHash'));
      expect(csp, contains("frame-ancestors 'none'"));
      expect(csp, contains("base-uri 'none'"));
      expect(csp, contains("form-action 'none'"));
      expect(done.header('referrer-policy'), 'no-referrer');
      expect(done.header('x-content-type-options'), 'nosniff');
      expect(done.header('cache-control'), 'no-store');
      expect(done.header('access-control-allow-origin'), isNull);
      expect(done.body, isNot(contains('<script')));
      expect(done.body, contains('oauth-done?login_id='));
      expect(done.body, isNot(contains('gh-code')));
    });

    test('needs the login cookie', () async {
      await browserFlow(harness, a, ConnectOAuthLane.github);
      final noCookie = await harness.browser('/oauth/github/done');
      expect(noCookie.status, 400);
      expect(confirmCodeFrom(noCookie.body), isNull);
      final forged = await harness.browser(
        '/oauth/github/done',
        cookie: b64url(randomBytes(32)),
      );
      expect(confirmCodeFrom(forged.body), isNull);
    });

    test(
      'the callback cookie is __Host-, Secure, HttpOnly, SameSite=Lax',
      () async {
        final pkce = PkcePair.generate();
        final start = await harness.call(
          a,
          'POST',
          '/v1/oauth/github/start',
          body: OAuthStartRequest(
            workspaceId: 'ws1',
            codeChallenge: pkce.challenge,
          ).toJson(),
        );
        final state = OAuthStartResponse.fromJson(
          start.json,
        ).authorizeUrl.queryParameters['state'];
        final callback = await harness.browser(
          '/oauth/github/callback?code=gh-code&state=$state',
        );
        final cookie = callback.headers['set-cookie']!.single;
        expect(cookie, startsWith('__Host-cc_connect='));
        expect(cookie, contains('Secure'));
        expect(cookie, contains('HttpOnly'));
        expect(cookie, contains('SameSite=Lax'));
        expect(cookie, contains('Path=/'));
        expect(cookie, isNot(contains('Domain')));
      },
    );

    test(
      'loopback http uses plain cc_connect without Secure so WebKit keeps it',
      () async {
        const loopbackUrl = 'http://127.0.0.1:8790';
        final local = await ConnectInstallIdentity.derive(
          masterSeed: seed(1),
          connectUrl: loopbackUrl,
        );
        final loopback = await Harness.start(
          allowed: [local],
          env: {'CONNECT_PUBLIC_URL': loopbackUrl},
        );
        addTearDown(loopback.close);
        final pkce = PkcePair.generate();
        final start = await loopback.call(
          local,
          'POST',
          '/v1/oauth/github/start',
          body: OAuthStartRequest(
            workspaceId: 'ws1',
            codeChallenge: pkce.challenge,
          ).toJson(),
        );
        final started = OAuthStartResponse.fromJson(start.json);
        final state = started.authorizeUrl.queryParameters['state']!;
        final callback = await loopback.raw(
          'GET',
          '/oauth/github/callback?code=gh-code&state=$state',
        );
        final setCookie = callback.headers['set-cookie']!.single;
        expect(setCookie, startsWith('cc_connect='));
        expect(setCookie, isNot(contains('Secure')));
        expect(setCookie, contains('HttpOnly'));
        final value = RegExp(
          'cc_connect=([^;]+)',
        ).firstMatch(setCookie)!.group(1)!;
        final done = await loopback.raw(
          'GET',
          '/oauth/github/done',
          headers: {'cookie': 'cc_connect=$value'},
        );
        expect(done.status, 200);
        expect(confirmCodeFrom(done.body), isNotNull);
      },
    );
  });

  group('seals', () {
    test('another install cannot use a seal', () async {
      final grant = await signInGitHub(harness, a);
      final stolen = await harness.call(
        b,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(stolen.status, 403);
      expect(stolen.json, {'error': 'access_denied'});
      // Nothing was spent upstream.
      expect(github.issued, 1);
    });

    test('another workspace cannot use a seal', () async {
      final grant = await signInGitHub(harness, a);
      final moved = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws2').toJson(),
      );
      expect(moved.json, {'error': 'access_denied'});
    });

    test('an edited header fails to decrypt', () async {
      final grant = await signInGitHub(harness, a);
      final parts = grant.seal.split('.');
      final header =
          jsonDecode(utf8.decode(unb64url(parts[1]))) as Map<String, Object?>;
      header['a'] = '2002';
      final forged =
          'v1.${b64url(utf8.encode(jsonEncode(header)))}.${parts[2]}';
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: forged, workspaceId: 'ws1').toJson(),
      );
      expect(response.json, {'error': 'access_denied'});
    });

    test('a google route refuses a github seal', () async {
      final grant = await signInGitHub(harness, a);
      final response = await harness.call(
        a,
        'POST',
        '/v1/google/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(response.json, {'error': 'access_denied'});
    });
  });

  group('refresh', () {
    test('rotates and replays the handoff for a retried old seal', () async {
      final first = await signInGitHub(harness, a);
      final refreshed = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: first.seal, workspaceId: 'ws1').toJson(),
      );
      expect(refreshed.status, 200);
      final second = SealedGrant.fromJson(refreshed.json);
      expect(second.accessToken, 'ghu_access2');
      expect(second.seal, isNot(first.seal));
      expect(github.issued, 2);

      // The response was "lost": the server retries with the old seal.
      final retried = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: first.seal, workspaceId: 'ws1').toJson(),
      );
      expect(retried.status, 200);
      final replayed = SealedGrant.fromJson(retried.json);
      expect(replayed.seal, second.seal);
      expect(replayed.accessToken, 'ghu_access2');
      expect(github.issued, 2, reason: 'no second upstream rotation');

      // The handoff never helps another install.
      final stolen = await harness.call(
        b,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: first.seal, workspaceId: 'ws1').toJson(),
      );
      expect(stolen.json, {'error': 'access_denied'});
    });

    test('invalid_grant answers needs_sign_in', () async {
      final grant = await signInGitHub(harness, a);
      github.liveRefresh.clear();
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(response.status, 401);
      expect(response.json, {'error': 'needs_sign_in'});
    });

    test('a 503 answers provider_unavailable, never needs_sign_in', () async {
      final grant = await signInGitHub(harness, a);
      github.failStatus = 503;
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(response.status, 503);
      expect(response.json, {'error': 'provider_unavailable'});
      expect(response.body, isNot(contains('down')));
      // The refresh token was not spent: it works once GitHub recovers.
      github.failStatus = null;
      final retry = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(retry.status, 200);
    });

    test('invalid_client retries once with the previous secret', () async {
      final grant = await signInGitHub(harness, a);
      github.acceptedSecrets = {'gh-secret-1'};
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(response.status, 200);
      final secrets = [
        for (final call in harness.upstream.callsTo(
          'POST',
          'https://github.com/login/oauth/access_token',
        ))
          call.form['client_secret'],
      ];
      expect(secrets.skip(1), ['gh-secret-2', 'gh-secret-1']);
      // Re-sealed under the current generation.
      final newSeal = SealedGrant.fromJson(response.json).seal;
      final header = jsonDecode(utf8.decode(unb64url(newSeal.split('.')[1])));
      expect((header as Map)['g'], 2);
      expect(response.body, isNot(contains('echo-me-not')));
    });

    test('both secrets refused answers provider_unavailable', () async {
      final grant = await signInGitHub(harness, a);
      github.acceptedSecrets = {};
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(response.json, {'error': 'provider_unavailable'});
    });

    test(
      'a lock left by a holder that died lapses instead of wedging',
      () async {
        final grant = await signInGitHub(harness, a);
        // A rotation that never finished: its lease outlives it by its TTL
        // only.
        await harness.service.context.state.set(
          'lock:${sealDigest(grant.seal)}',
          'dead-holder',
          const Duration(seconds: 1),
        );
        final refreshed = await harness.call(
          a,
          'POST',
          '/v1/github/refresh',
          body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
        );
        expect(refreshed.status, 200, reason: refreshed.body);
        expect(github.issued, 2);
      },
    );

    test(
      'seals below min_seal_generation or of a retired app need sign-in',
      () async {
        final grant = await signInGitHub(harness, a);
        final bumped = await Harness.start(
          allowed: [a],
          env: {'CONNECT_GITHUB_MIN_SEAL_GENERATION': '3'},
          upstream: harness.upstream,
        );
        final retired = await Harness.start(
          allowed: [a],
          env: {'CONNECT_GITHUB_APP_ID': '4343'},
          upstream: harness.upstream,
        );
        addTearDown(bumped.close);
        addTearDown(retired.close);
        for (final other in [bumped, retired]) {
          final response = await other.call(
            a,
            'POST',
            '/v1/github/refresh',
            body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
          );
          expect(response.json, {'error': 'needs_sign_in'});
        }
      },
    );
  });

  group('a rotation the state store half-fails', () {
    late FlakyStateStore state;
    late Harness flaky;
    late FakeGitHub flakyGitHub;

    setUp(() async {
      state = FlakyStateStore();
      flaky = await Harness.start(allowed: [a], state: state);
      flakyGitHub = FakeGitHub(flaky.upstream);
    });

    tearDown(() => flaky.close());

    test(
      'still answers the rotated seal when the handoff cannot be written',
      () async {
        final grant = await signInGitHub(flaky, a);
        state.failSets.add('handoff:');
        final refreshed = await flaky.call(
          a,
          'POST',
          '/v1/github/refresh',
          body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
        );
        // The old refresh token is spent: the answer is the only copy of
        // the grant, so it must arrive.
        expect(refreshed.status, 200, reason: refreshed.body);
        final next = SealedGrant.fromJson(refreshed.json);
        expect(next.accessToken, 'ghu_access2');
        expect(flakyGitHub.issued, 2);
        expect(
          flaky.logs.any((l) => l.contains('seal.handoff_unsaved')),
          isTrue,
        );
        // And it works.
        state.failSets.clear();
        final again = await flaky.call(
          a,
          'POST',
          '/v1/github/refresh',
          body: SealRequest(seal: next.seal, workspaceId: 'ws1').toJson(),
        );
        expect(again.status, 200);
      },
    );

    test('a failed unlock never fails a finished rotation', () async {
      final grant = await signInGitHub(flaky, a);
      state.failDeletes.add('lock:');
      final refreshed = await flaky.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(refreshed.status, 200, reason: refreshed.body);
    });
  });

  group('scope', () {
    setUp(() => _scriptInstallations(harness.upstream));

    test('a role GitHub demoted mints the lower scope at once', () async {
      final grant = await signInGitHub(harness, a);
      await harness.call(
        a,
        'POST',
        '/v1/github/authorize_server',
        body: GitHubAuthorizeServerRequest(
          seal: grant.seal,
          workspaceId: 'ws1',
          installationId: 77,
        ).toJson(),
      );
      Future<String> mint() async => GitHubScopedToken.fromJson(
        (await harness.call(
          a,
          'POST',
          '/v1/github/scope',
          body: _scopeBody(
            grant.seal,
            repoId: 9001,
            owner: 'acme',
            name: 'api',
            scope: 'write',
          ),
        )).json,
      ).grantedScope;
      expect(await mint(), 'write');
      // Demoted to read on GitHub: the very next mint sees it, not a
      // five-minute-old copy of the role.
      harness.upstream.json(
        'GET',
        'https://api.github.com/repos/acme/api',
        200,
        {
          'id': 9001,
          'private': true,
          'owner': {'id': 500, 'login': 'acme'},
          'permissions': {'push': false, 'triage': false, 'pull': true},
        },
      );
      expect(await mint(), 'read');
    });

    test('an unbound organization installation is refused', () async {
      final grant = await signInGitHub(harness, a);
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/scope',
        body: _scopeBody(
          grant.seal,
          repoId: 9001,
          owner: 'acme',
          name: 'api',
          scope: 'write',
        ),
      );
      expect(response.status, 409);
      expect(response.json, {'error': 'installation_bound_elsewhere'});
      expect(
        harness.upstream.callsTo(
          'POST',
          'https://api.github.com/applications/Iv23test/token/scoped',
        ),
        isEmpty,
      );
    });

    test(
      'an org admin authorizes the server, then mints are clamped',
      () async {
        final grant = await signInGitHub(harness, a);
        final authorize = await harness.call(
          a,
          'POST',
          '/v1/github/authorize_server',
          body: GitHubAuthorizeServerRequest(
            seal: grant.seal,
            workspaceId: 'ws1',
            installationId: 77,
          ).toJson(),
        );
        expect(authorize.status, 200);
        expect(authorize.json['ok'], isTrue);

        final write = await harness.call(
          a,
          'POST',
          '/v1/github/scope',
          body: _scopeBody(
            grant.seal,
            repoId: 9001,
            owner: 'acme',
            name: 'api',
            scope: 'write',
          ),
        );
        expect(write.status, 200);
        final token = GitHubScopedToken.fromJson(write.json);
        expect(token.grantedScope, 'write');
        expect(token.installationId, 77);
        expect(token.updatedSeal, isEmpty);
        final mint = harness.upstream
            .callsTo(
              'POST',
              'https://api.github.com/applications/Iv23test/token/scoped',
            )
            .single;
        expect(mint.json, {
          'access_token': 'ghu_access1',
          'target_id': 500,
          'repository_ids': [9001],
          'permissions': _writePermissions,
        });
        expect(
          mint.request.headers['authorization'],
          'Basic ${base64.encode(utf8.encode('Iv23test:gh-secret-2'))}',
        );

        // A pull-only role asking for write gets read.
        final clamped = await harness.call(
          a,
          'POST',
          '/v1/github/scope',
          body: _scopeBody(
            grant.seal,
            repoId: 9002,
            owner: 'acme',
            name: 'docs',
            scope: 'write',
          ),
        );
        expect(GitHubScopedToken.fromJson(clamped.json).grantedScope, 'read');

        // Another server is still refused on the same installation.
        final other = await signInGitHub(harness, b);
        final refused = await harness.call(
          b,
          'POST',
          '/v1/github/scope',
          body: _scopeBody(
            other.seal,
            repoId: 9001,
            owner: 'acme',
            name: 'api',
            scope: 'read',
          ),
        );
        expect(refused.json, {'error': 'installation_bound_elsewhere'});

        // The audit line carries numeric ids only.
        final audit = harness.logs.firstWhere(
          (l) => l.contains('github.scope'),
        );
        expect(audit, contains('"repo_id":9001'));
        expect(audit, isNot(contains('ghu_')));
        expect(audit, isNot(contains(a.installId)));
      },
    );

    test('a non-admin cannot authorize a server', () async {
      _scriptInstallations(harness.upstream, role: 'member');
      final grant = await signInGitHub(harness, a);
      final authorize = await harness.call(
        a,
        'POST',
        '/v1/github/authorize_server',
        body: GitHubAuthorizeServerRequest(
          seal: grant.seal,
          workspaceId: 'ws1',
          installationId: 77,
        ).toJson(),
      );
      expect(authorize.json, {'error': 'access_denied'});
    });

    test('a personal installation auto-binds its own account', () async {
      final grant = await signInGitHub(harness, a);
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/scope',
        body: _scopeBody(
          grant.seal,
          repoId: 9003,
          owner: 'octo',
          name: 'dotfiles',
          scope: 'read',
        ),
      );
      expect(response.status, 200);
      final binding = await harness.service.context.bindings.github(78);
      expect(binding!.installIds, {a.installId});
    });

    test('a repo id that does not match is refused', () async {
      final grant = await signInGitHub(harness, a);
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/scope',
        body: _scopeBody(
          grant.seal,
          repoId: 1,
          owner: 'octo',
          name: 'dotfiles',
          scope: 'read',
        ),
      );
      expect(response.json, {'error': 'access_denied'});
    });

    test('path-traversal segments are refused before any call', () async {
      final grant = await signInGitHub(harness, a);
      final before = harness.upstream.calls.length;
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/scope',
        body: _scopeBody(
          grant.seal,
          repoId: 9001,
          owner: '..',
          name: 'api',
          scope: 'read',
        ),
      );
      expect(response.json, {'error': 'invalid_request'});
      expect(harness.upstream.calls.length, before);
    });

    test(
      'a parent near expiry is refreshed and the new seal returned',
      () async {
        final grant = await signInGitHub(harness, a);
        // The next sign-in issues a parent that expires in 10 minutes: under
        // the 65-minute floor a child token needs.
        github.codeExpiresIn = 600;
        final short = await signInGitHub(harness, a);
        expect(short.seal, isNot(grant.seal));
        final personal = await harness.call(
          a,
          'POST',
          '/v1/github/scope',
          body: _scopeBody(
            short.seal,
            repoId: 9003,
            owner: 'octo',
            name: 'dotfiles',
            scope: 'read',
          ),
        );
        expect(personal.status, 200);
        final token = GitHubScopedToken.fromJson(personal.json);
        expect(token.updatedSeal, isNotEmpty);
        // The retried old seal replays the rotated one.
        final retried = await harness.call(
          a,
          'POST',
          '/v1/github/refresh',
          body: SealRequest(seal: short.seal, workspaceId: 'ws1').toJson(),
        );
        expect(SealedGrant.fromJson(retried.json).seal, token.updatedSeal);
      },
    );
  });

  group('installation flows', () {
    setUp(() => _scriptInstallations(harness.upstream));

    test('install/start → GitHub setup redirect binds the server', () async {
      final grant = await signInGitHub(harness, a);
      final start = await harness.call(
        a,
        'POST',
        '/v1/github/install/start',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(start.status, 200);
      final install = GitHubInstallStartResponse.fromJson(start.json);
      expect(install.installUrl.path, '/apps/cc-test/installations/new');
      final ticket = install.installUrl.queryParameters['state'];
      final setup = await harness.browser(
        '/oauth/github/setup?installation_id=77&setup_action=install'
        '&state=$ticket',
      );
      expect(setup.status, 200);
      expect(setup.body, contains('GitHub App installed'));
      expect(setup.header('content-security-policy'), isNotNull);
      final binding = await harness.service.context.bindings.github(77);
      expect(binding!.installIds, {a.installId});
      final reused = await harness.browser(
        '/oauth/github/setup?installation_id=77&setup_action=install'
        '&state=$ticket',
      );
      expect(reused.status, 400);
    });

    test('a ticket held by a since-blocked server binds nothing', () async {
      final blocked = await Harness.start(
        allowed: [a, b],
        env: {'CONNECT_DENY_INSTALLS': b.installId},
      );
      addTearDown(blocked.close);
      _scriptInstallations(blocked.upstream);
      final ticket = 't' * 43;
      await blocked.service.context.state.set(
        'ticket:$ticket',
        jsonEncode({
          'install_id': b.installId,
          'workspace_id': 'ws1',
          'seal': 'v1.unused.unused',
        }),
        const Duration(minutes: 15),
      );
      final setup = await blocked.browser(
        '/oauth/github/setup?installation_id=77&setup_action=install'
        '&state=$ticket',
      );
      expect(setup.status, 403);
      expect(await blocked.service.context.bindings.github(77), isNull);
    });

    test('install/start hands back the seal it rotates; setup never rotates '
        '(the browser redirect cannot return a seal)', () async {
      github.codeExpiresIn = 600;
      final grant = await signInGitHub(harness, a);
      final start = await harness.call(
        a,
        'POST',
        '/v1/github/install/start',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(start.status, 200);
      final install = GitHubInstallStartResponse.fromJson(start.json);
      expect(install.updatedSeal, isNotEmpty);
      expect(install.updatedSeal, isNot(grant.seal));
      final issued = github.issued;

      final setup = await harness.browser(
        '/oauth/github/setup?installation_id=77&setup_action=install'
        '&state=${install.installUrl.queryParameters['state']}',
      );
      expect(setup.body, contains('GitHub App installed'));
      expect(github.issued, issued, reason: 'no refresh token spent in setup');

      // The seal the server adopted keeps working afterwards.
      final refreshed = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(
          seal: install.updatedSeal,
          workspaceId: 'ws1',
        ).toJson(),
      );
      expect(refreshed.status, 200);
    });

    test('installations lists views for the person', () async {
      final grant = await signInGitHub(harness, a);
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/installations',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(response.status, 200);
      final views = GitHubInstallationsResponse.fromJson(
        response.json,
      ).installations;
      expect(views.map((v) => v.installationId), [77, 78]);
      expect(views.first.callerIsAdmin, isTrue);
      expect(views.first.boundHere, isFalse);
      expect(views.last.boundHere, isTrue);
    });

    test('a scoped token is revoked only with a seal of the account it was '
        'minted for', () async {
      harness.upstream.json(
        'DELETE',
        'https://api.github.com/applications/Iv23test/token',
        204,
        null,
      );
      final octo = await signInGitHub(harness, a);
      final minted = GitHubScopedToken.fromJson(
        (await harness.call(
          a,
          'POST',
          '/v1/github/scope',
          body: _scopeBody(
            octo.seal,
            repoId: 9003,
            owner: 'octo',
            name: 'dotfiles',
            scope: 'read',
          ),
        )).json,
      );
      // Another person signs in on the same server.
      github
        ..userId = 2002
        ..login = 'hubot';
      final hubot = await signInGitHub(harness, a);
      expect(hubot.accountId, '2002');
      Future<Map<String, Object?>> revokeWith(String seal) async =>
          (await harness.call(
            a,
            'POST',
            '/v1/github/revoke',
            body: GitHubRevokeRequest(
              workspaceId: 'ws1',
              seal: seal,
              scopedToken: minted.accessToken,
            ).toJson(),
          )).json;
      expect(await revokeWith(hubot.seal), {'error': 'access_denied'});
      expect(
        harness.upstream.callsTo(
          'DELETE',
          'https://api.github.com/applications/Iv23test/token',
        ),
        isEmpty,
      );
      expect(await revokeWith(octo.seal), {'ok': true});
      expect(
        harness.upstream.callsTo(
          'DELETE',
          'https://api.github.com/applications/Iv23test/token',
        ),
        hasLength(1),
      );
    });

    test(
      'organization lookups run in parallel, at most eight at once',
      () async {
        final orgs = [for (var i = 0; i < 20; i++) 'org$i'];
        harness.upstream.json(
          'GET',
          'https://api.github.com/user/installations',
          200,
          {
            'installations': [
              for (var i = 0; i < orgs.length; i++)
                {
                  'id': 1000 + i,
                  'app_id': 4242,
                  'target_type': 'Organization',
                  'account': {'id': 5000 + i, 'login': orgs[i]},
                  'suspended_at': null,
                },
            ],
          },
        );
        var inFlight = 0;
        var peak = 0;
        for (final org in orgs) {
          harness.upstream.on(
            'GET',
            'https://api.github.com/orgs/$org/memberships/octo',
            (_) async {
              inFlight++;
              peak = inFlight > peak ? inFlight : peak;
              await Future<void>.delayed(const Duration(milliseconds: 20));
              inFlight--;
              return UpstreamResponse.json(200, {
                'role': 'admin',
                'state': 'active',
              });
            },
          );
        }
        final grant = await signInGitHub(harness, a);
        final listed = await harness.call(
          a,
          'POST',
          '/v1/github/installations',
          body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
        );
        expect(listed.status, 200, reason: listed.body);
        final views = GitHubInstallationsResponse.fromJson(listed.json);
        expect(views.installations, hasLength(orgs.length));
        expect(views.installations.every((v) => v.callerIsAdmin), isTrue);
        expect(peak, greaterThan(1));
        expect(peak, lessThanOrEqualTo(8));
      },
    );

    test('revoke deletes the grant or one scoped token', () async {
      harness.upstream
        ..json(
          'DELETE',
          'https://api.github.com/applications/Iv23test/grant',
          204,
          null,
        )
        ..json(
          'DELETE',
          'https://api.github.com/applications/Iv23test/token',
          204,
          null,
        );
      final grant = await signInGitHub(harness, a);
      final minted = GitHubScopedToken.fromJson(
        (await harness.call(
          a,
          'POST',
          '/v1/github/scope',
          body: _scopeBody(
            grant.seal,
            repoId: 9003,
            owner: 'octo',
            name: 'dotfiles',
            scope: 'read',
          ),
        )).json,
      );
      // Another server holding its own grant cannot revoke a's child.
      final other = await signInGitHub(harness, b);
      final foreign = await harness.call(
        b,
        'POST',
        '/v1/github/revoke',
        body: GitHubRevokeRequest(
          workspaceId: 'ws1',
          seal: other.seal,
          scopedToken: minted.accessToken,
        ).toJson(),
      );
      expect(foreign.json, {'error': 'access_denied'});
      // A token never minted here is nothing to revoke.
      final unknown = await harness.call(
        a,
        'POST',
        '/v1/github/revoke',
        body: GitHubRevokeRequest(
          workspaceId: 'ws1',
          seal: grant.seal,
          scopedToken: 'ghu_never_minted',
        ).toJson(),
      );
      expect(unknown.json, {'ok': true});
      expect(
        harness.upstream.callsTo(
          'DELETE',
          'https://api.github.com/applications/Iv23test/token',
        ),
        isEmpty,
      );
      final scoped = await harness.call(
        a,
        'POST',
        '/v1/github/revoke',
        body: GitHubRevokeRequest(
          workspaceId: 'ws1',
          seal: grant.seal,
          scopedToken: minted.accessToken,
        ).toJson(),
      );
      expect(scoped.json, {'ok': true});
      expect(
        harness.upstream
            .callsTo(
              'DELETE',
              'https://api.github.com/applications/Iv23test/token',
            )
            .single
            .json,
        {'access_token': minted.accessToken},
      );
      final full = await harness.call(
        a,
        'POST',
        '/v1/github/revoke',
        body: GitHubRevokeRequest(
          workspaceId: 'ws1',
          seal: grant.seal,
        ).toJson(),
      );
      expect(full.json, {'ok': true});
      expect(
        harness.upstream
            .callsTo(
              'DELETE',
              'https://api.github.com/applications/Iv23test/grant',
            )
            .single
            .json,
        {'access_token': 'ghu_access1'},
      );
    });
  });
}
