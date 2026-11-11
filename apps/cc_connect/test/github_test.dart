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

void _scriptInstallations(FakeUpstream upstream) {
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
  GitHubMintActor actor = GitHubMintActor.user,
}) => GitHubScopeRequest(
  seal: seal,
  workspaceId: workspaceId,
  repoId: repoId,
  repoOwner: owner,
  repoName: name,
  scope: scope,
  actor: actor,
).toJson();

/// The App's installation on `acme`, as `GET /repos/{o}/{r}/installation`
/// and `GET /users/{o}/installation` answer it.
const _acmeInstallation = {
  'id': 77,
  'app_id': 4242,
  'target_type': 'Organization',
  'account': {'id': 500, 'login': 'acme'},
  'suspended_at': null,
};

/// Scripts the App side of an `as: app` mint: the repo's installation and
/// an access token answering [repositories] (default: just the asked repo).
void _scriptAppMint(FakeUpstream upstream, {List<int>? repositories}) {
  upstream
    ..json(
      'GET',
      'https://api.github.com/repos/acme/api/installation',
      200,
      _acmeInstallation,
    )
    ..on(
      'POST',
      'https://api.github.com/app/installations/77/access_tokens',
      (call) => UpstreamResponse.json(201, {
        'token': 'ghs_bot_${call.json['repository_ids']}',
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
        'permissions': call.json['permissions'],
        'repository_selection': 'selected',
        'repositories': [
          for (final id in repositories ?? call.json['repository_ids']! as List)
            {'id': id},
        ],
      }),
    )
    ..json('DELETE', 'https://api.github.com/installation/token', 204, null);
}

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
      final consent = flow.consent;
      final consentPolicy = consent.header('content-security-policy')!;
      expect(consentPolicy, contains("default-src 'none'"));
      expect(consentPolicy, contains("form-action 'self'"));
      expect(consentPolicy, isNot(contains("form-action 'none'")));
      // The one page whose form posts back: it sends its origin to itself.
      expect(consent.header('referrer-policy'), 'same-origin');
      expect(consent.header('x-frame-options'), 'DENY');
      expect(consent.body, isNot(contains('<script')));
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
        final consent = await loopback.raw(
          'GET',
          '/oauth/github/done',
          headers: {'cookie': 'cc_connect=$value'},
        );
        expect(consent.status, 200);
        expect(
          consent.body,
          contains('action="$loopbackUrl/oauth/github/done"'),
        );
        final done = await loopback.raw(
          'POST',
          '/oauth/github/done',
          headers: {
            'cookie': 'cc_connect=$value',
            'content-type': 'application/x-www-form-urlencoded',
            'origin': loopbackUrl,
          },
          body: utf8.encode(
            'action=continue&token=${consentTokenFrom(consent.body)}',
          ),
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

    test('any server a member signs in on mints against an org installation, '
        'clamped to their role', () async {
      final grant = await signInGitHub(harness, a);
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
      expect(write.status, 200, reason: write.body);
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

      // A second server mints on the same installation with no admin step:
      // the organization's install is its consent.
      final other = await signInGitHub(harness, b);
      final second = await harness.call(
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
      expect(second.status, 200, reason: second.body);
      expect(GitHubScopedToken.fromJson(second.json).installationId, 77);

      // No organization-admin lookup gates a mint.
      expect(
        harness.upstream.callsTo(
          'GET',
          'https://api.github.com/orgs/acme/memberships/octo',
        ),
        isEmpty,
      );

      // The audit line carries numeric ids only.
      final audit = harness.logs.firstWhere((l) => l.contains('github.mint'));
      expect(audit, contains('"repo_id":9001'));
      expect(audit, isNot(contains('ghu_')));
      expect(audit, isNot(contains(a.installId)));
    });

    test('a person\'s token answer proves its coverage', () async {
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
      final token = GitHubScopedToken.fromJson(response.json);
      expect(token.accessToken, startsWith('ghu_'));
      expect(token.repositorySelection, 'selected');
      expect(token.repositoryIds, [9001]);
      expect(token.permissions, _writePermissions);
      expect(
        scopedTokenMatches(
          {
            'permissions': token.permissions,
            'repository_selection': token.repositorySelection,
            'repositories': token.repositoryIds,
          },
          repoId: 9001,
          permissions: GitHubTokenScope.write.permissions,
        ),
        isTrue,
      );
    });

    test('a live child for the same repository and permissions is reused, '
        'until it is revoked', () async {
      harness.upstream.json(
        'DELETE',
        'https://api.github.com/applications/Iv23test/token',
        204,
        null,
      );
      final grant = await signInGitHub(harness, a);
      Future<GitHubScopedToken> mint(String scope) async =>
          GitHubScopedToken.fromJson(
            (await harness.call(
              a,
              'POST',
              '/v1/github/scope',
              body: _scopeBody(
                grant.seal,
                repoId: 9001,
                owner: 'acme',
                name: 'api',
                scope: scope,
              ),
            )).json,
          );
      int children() => harness.upstream
          .callsTo(
            'POST',
            'https://api.github.com/applications/Iv23test/token/scoped',
          )
          .length;

      final first = await mint('write');
      final second = await mint('write');
      expect(second.accessToken, first.accessToken);
      expect(children(), 1);
      expect(
        harness.logs.where((l) => l.contains('"reused":true')),
        hasLength(1),
      );

      // Other permissions are another child.
      await mint('read');
      expect(children(), 2);

      final revoked = await harness.call(
        a,
        'POST',
        '/v1/github/revoke',
        body: GitHubRevokeRequest(
          workspaceId: 'ws1',
          seal: grant.seal,
          scopedToken: first.accessToken,
        ).toJson(),
      );
      expect(revoked.json, {'ok': true});
      await mint('write');
      expect(children(), 3, reason: 'a revoked child is never handed out');
    });

    test('a personal installation mints for its account', () async {
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
      expect(response.status, 200, reason: response.body);
      expect(GitHubScopedToken.fromJson(response.json).installationId, 78);
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

  group('bot mint (as: app)', () {
    setUp(() async {
      // An install the operator listed for review-bot tokens.
      await harness.close();
      harness = await Harness.start(
        allowed: [a, b],
        env: {'CONNECT_GITHUB_REVIEW_BOT_INSTALLS': a.installId},
      );
      github = FakeGitHub(harness.upstream);
      _scriptInstallations(harness.upstream);
    });

    Future<TestResponse> mintAsApp(
      String seal, {
      int repoId = 9001,
      String name = 'api',
      String scope = 'bot',
    }) => harness.call(
      a,
      'POST',
      '/v1/github/scope',
      body: _scopeBody(
        seal,
        repoId: repoId,
        owner: 'acme',
        name: name,
        scope: scope,
        actor: GitHubMintActor.app,
      ),
    );

    test(
      'mints a one-repository installation token clamped to the human',
      () async {
        _scriptAppMint(harness.upstream);
        final grant = await signInGitHub(harness, a);
        final response = await mintAsApp(grant.seal);
        expect(response.status, 200, reason: response.body);
        final token = GitHubScopedToken.fromJson(response.json);
        expect(token.accessToken, startsWith('ghs_'));
        expect(token.grantedScope, 'bot');
        expect(token.installationId, 77);
        expect(token.repositorySelection, 'selected');
        expect(token.repositoryIds, [9001]);
        expect(token.permissions, GitHubTokenScope.bot.permissions);
        final mint = harness.upstream
            .callsTo(
              'POST',
              'https://api.github.com/app/installations/77/access_tokens',
            )
            .single;
        expect(mint.json, {
          'repository_ids': [9001],
          'permissions': GitHubTokenScope.bot.permissions,
        });
        // Signed by the App, never the person's token.
        expect(mint.request.headers['authorization'], startsWith('Bearer ey'));
        // The person's own token read the repository first.
        expect(
          harness.upstream.callsTo(
            'GET',
            'https://api.github.com/repos/acme/api',
          ),
          isNotEmpty,
        );
        // No user child was minted.
        expect(
          harness.upstream.callsTo(
            'POST',
            'https://api.github.com/applications/Iv23test/token/scoped',
          ),
          isEmpty,
        );
      },
    );

    test('the shared App\'s bot never pushes: a write is needs_requester '
        'before GitHub is asked anything', () async {
      _scriptAppMint(harness.upstream);
      final grant = await signInGitHub(harness, a);
      final before = harness.upstream.calls.length;
      final response = await mintAsApp(grant.seal, scope: 'write');
      expect(response.status, 403);
      expect(response.json, {'error': 'needs_requester'});
      expect(harness.upstream.calls.length, before);
    });

    test('a pull-only human gets a read bot token', () async {
      harness.upstream
        ..json(
          'GET',
          'https://api.github.com/repos/acme/docs/installation',
          200,
          _acmeInstallation,
        )
        ..on(
          'POST',
          'https://api.github.com/app/installations/77/access_tokens',
          (call) => UpstreamResponse.json(201, {
            'token': 'ghs_docs',
            'permissions': call.json['permissions'],
            'repository_selection': 'selected',
            'repositories': [
              {'id': 9002},
            ],
          }),
        );
      final grant = await signInGitHub(harness, a);
      final response = await mintAsApp(grant.seal, repoId: 9002, name: 'docs');
      expect(response.status, 200, reason: response.body);
      expect(GitHubScopedToken.fromJson(response.json).grantedScope, 'read');
    });

    test(
      'a repository the human cannot see is refused before any mint',
      () async {
        _scriptAppMint(harness.upstream);
        harness.upstream.json(
          'GET',
          'https://api.github.com/repos/acme/secret',
          404,
          {'message': 'Not Found'},
        );
        final grant = await signInGitHub(harness, a);
        final response = await mintAsApp(
          grant.seal,
          repoId: 9009,
          name: 'secret',
        );
        expect(response.json, {'error': 'access_denied'});
        expect(
          harness.upstream.callsTo(
            'POST',
            'https://api.github.com/app/installations/77/access_tokens',
          ),
          isEmpty,
        );
      },
    );

    test(
      'a token covering more than the one repository is revoked and refused',
      () async {
        _scriptAppMint(harness.upstream, repositories: [9001, 9002]);
        final grant = await signInGitHub(harness, a);
        final response = await mintAsApp(grant.seal);
        expect(response.json, {'error': 'access_denied'});
        final revoke = harness.upstream
            .callsTo('DELETE', 'https://api.github.com/installation/token')
            .single;
        expect(revoke.request.headers['authorization'], contains('ghs_bot_'));
      },
    );

    test(
      'a repository left out of the installation is repo_not_selected',
      () async {
        harness.upstream
          ..json(
            'GET',
            'https://api.github.com/repos/acme/api/installation',
            404,
            {'message': 'Not Found'},
          )
          ..json(
            'GET',
            'https://api.github.com/users/acme/installation',
            200,
            _acmeInstallation,
          );
        final grant = await signInGitHub(harness, a);
        final response = await mintAsApp(grant.seal);
        expect(response.json, {'error': 'repo_not_selected'});
      },
    );

    test('an owner without the App is not_installed', () async {
      harness.upstream
        ..json(
          'GET',
          'https://api.github.com/repos/acme/api/installation',
          404,
          {'message': 'Not Found'},
        )
        ..json('GET', 'https://api.github.com/users/acme/installation', 404, {
          'message': 'Not Found',
        });
      final grant = await signInGitHub(harness, a);
      final response = await mintAsApp(grant.seal);
      expect(response.json, {'error': 'not_installed'});
    });

    test('a request without `as` is refused', () async {
      final grant = await signInGitHub(harness, a);
      final body = _scopeBody(
        grant.seal,
        repoId: 9001,
        owner: 'acme',
        name: 'api',
        scope: 'read',
      )..remove('as');
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/scope',
        body: body,
      );
      expect(response.json, {'error': 'invalid_request'});
    });
  });

  group('installation flows', () {
    setUp(() => _scriptInstallations(harness.upstream));

    test('the setup redirect records nothing and says what happened', () async {
      final installed = await harness.browser(
        '/oauth/github/setup?installation_id=77&setup_action=install',
      );
      expect(installed.status, 200);
      expect(installed.body, contains('GitHub App installed'));
      expect(installed.header('content-security-policy'), isNotNull);

      final requested = await harness.browser(
        '/oauth/github/setup?setup_action=request',
      );
      expect(requested.body, contains('Installation requested'));

      final updated = await harness.browser(
        '/oauth/github/setup?installation_id=77&setup_action=update',
      );
      expect(updated.body, contains('Installation updated'));
      expect(harness.upstream.calls, isEmpty, reason: 'setup calls nothing');
    });

    test('install/start and authorize_server are gone', () async {
      final grant = await signInGitHub(harness, a);
      for (final path in [
        '/v1/github/install/start',
        '/v1/github/authorize_server',
      ]) {
        final response = await harness.call(
          a,
          'POST',
          path,
          body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
        );
        expect(response.status, 404, reason: path);
      }
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
      expect(views.map((v) => v.accountLogin), ['acme', 'octo']);
      expect(views.every((v) => !v.suspended), isTrue);
      expect(
        harness.upstream.callsTo(
          'GET',
          'https://api.github.com/orgs/acme/memberships/octo',
        ),
        isEmpty,
        reason: 'listing makes no organization-admin lookups',
      );
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

    test('revoke ends this sign-in only, or one scoped token', () async {
      harness.upstream.on(
        'DELETE',
        'https://api.github.com/applications/Iv23test/token',
        (call) {
          github.liveAccess.remove(call.json['access_token']);
          return UpstreamResponse.json(204, null);
        },
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
      // A second child, then a disconnect: the sign-in's own token and its
      // recorded children are revoked, never the person's whole grant.
      final second = GitHubScopedToken.fromJson(
        (await harness.call(
          a,
          'POST',
          '/v1/github/scope',
          body: _scopeBody(
            grant.seal,
            repoId: 9001,
            owner: 'acme',
            name: 'api',
            scope: 'read',
          ),
        )).json,
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
      final deleted = [
        for (final call in harness.upstream.callsTo(
          'DELETE',
          'https://api.github.com/applications/Iv23test/token',
        ))
          call.json['access_token'],
      ];
      // The disconnect spent the refresh token once and deleted what that
      // gave back, then the sign-in's own token, then its children.
      expect(deleted, hasLength(4));
      expect(deleted[0], minted.accessToken);
      expect(deleted[1], startsWith('ghu_access'));
      expect(deleted[1], isNot(anyOf(grant.accessToken, other.accessToken)));
      expect(deleted.sublist(2), [grant.accessToken, second.accessToken]);
      expect(github.liveAccess, isNot(contains(deleted[1])));
      expect(
        harness.upstream.callsTo(
          'DELETE',
          'https://api.github.com/applications/Iv23test/grant',
        ),
        isEmpty,
      );
      expect(
        harness.upstream
            .callsTo('POST', 'https://github.com/login/oauth/access_token')
            .where((c) => c.form['grant_type'] == 'refresh_token'),
        hasLength(1),
      );
      // A copy of the seal kept from before the disconnect is dead.
      final copy = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(copy.json, {'error': 'needs_sign_in'});
      // b's sign-in for the same person keeps working.
      expect(github.liveAccess, contains(other.accessToken));
      expect(github.liveAccess, isNot(contains(grant.accessToken)));
      final stillThere = await harness.call(
        b,
        'POST',
        '/v1/github/installations',
        body: SealRequest(seal: other.seal, workspaceId: 'ws1').toJson(),
      );
      expect(stillThere.status, 200, reason: stillThere.body);
      final line = harness.logs
          .map((l) => jsonDecode(l) as Map<String, Object?>)
          .firstWhere((l) => l['event'] == 'grant.revoked');
      expect(line['scope'], 'token');
      expect(line['reason'], 'refresh_spent');
      expect(line['count'], 1);
      expect(line['hashed_token'], githubHashedToken(grant.accessToken));
    });
  });
}
