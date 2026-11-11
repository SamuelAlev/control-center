import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

const _scoped = 'https://api.github.com/applications/Iv23test/token/scoped';
const _appMint = 'https://api.github.com/app/installations/77/access_tokens';
const _exchange = 'https://github.com/login/oauth/access_token';

/// Scripts `acme/api` (the person can push), the App's installation on
/// `acme`, user children and installation tokens.
void _scriptAcme(FakeUpstream upstream) {
  const installation = {
    'id': 77,
    'app_id': 4242,
    'target_type': 'Organization',
    'account': {'id': 500, 'login': 'acme'},
    'suspended_at': null,
  };
  var children = 0;
  upstream
    ..json('GET', 'https://api.github.com/user/installations', 200, {
      'total_count': 1,
      'installations': [installation],
    })
    ..json('GET', 'https://api.github.com/repos/acme/api', 200, {
      'id': 9001,
      'private': true,
      'owner': {'id': 500, 'login': 'acme'},
      'permissions': {'admin': false, 'push': true, 'pull': true},
    })
    ..json(
      'GET',
      'https://api.github.com/repos/acme/api/installation',
      200,
      installation,
    )
    ..on('POST', _scoped, (call) {
      children++;
      return UpstreamResponse.json(200, {
        'token': 'ghu_child_$children',
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 8))
            .toIso8601String(),
        'installation': {
          'permissions': call.json['permissions'],
          'repository_selection': 'selected',
        },
      });
    })
    ..on(
      'POST',
      _appMint,
      (call) => UpstreamResponse.json(201, {
        'token': 'ghs_bot',
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
        'permissions': call.json['permissions'],
        'repository_selection': 'selected',
        'repositories': [
          {'id': 9001},
        ],
      }),
    );
}

Future<TestResponse> _mint(
  Harness harness,
  ConnectInstallIdentity who,
  String seal, {
  GitHubTokenScope scope = GitHubTokenScope.read,
  GitHubMintActor actor = GitHubMintActor.user,
}) => harness.call(
  who,
  'POST',
  '/v1/github/scope',
  body: GitHubScopeRequest(
    seal: seal,
    workspaceId: 'ws1',
    repoId: 9001,
    repoOwner: 'acme',
    repoName: 'api',
    scope: scope.wire,
    actor: actor,
  ).toJson(),
);

Future<TestResponse> _refresh(
  Harness harness,
  ConnectInstallIdentity who,
  String seal,
) => harness.call(
  who,
  'POST',
  '/v1/github/refresh',
  body: SealRequest(seal: seal, workspaceId: 'ws1').toJson(),
);

List<Map<String, Object?>> _lines(Harness harness, String event) => [
  for (final line in harness.logs)
    if (jsonDecode(line) case final Map<String, Object?> json
        when json['event'] == event)
      json,
];

List<Object?> _hits(Harness harness) => [
  for (final line in _lines(harness, 'ratelimit.hit')) line['bucket'],
];

/// Starts a login and follows the provider's redirect; returns the login id
/// and the `/done` cookie.
Future<({String loginId, String cookie, PkcePair pkce})> _authorized(
  Harness harness,
  ConnectInstallIdentity who,
  ConnectOAuthLane lane, {
  Map<String, String> startHeaders = const {},
}) async {
  final pkce = PkcePair.generate();
  final start = await harness.call(
    who,
    'POST',
    '/v1/oauth/${lane.wire}/start',
    body: OAuthStartRequest(
      workspaceId: 'ws1',
      codeChallenge: pkce.challenge,
    ).toJson(),
    extraHeaders: startHeaders,
  );
  expect(start.status, 200, reason: start.body);
  final started = OAuthStartResponse.fromJson(start.json);
  final callback = await harness.browser(
    '/oauth/${lane.firstCallbackSegment}/callback?code=gh-code&state='
    '${started.authorizeUrl.queryParameters['state']}',
  );
  expect(callback.status, 303);
  return (loginId: started.loginId, cookie: cookieFrom(callback)!, pkce: pkce);
}

void main() {
  late ConnectInstallIdentity a;
  late ConnectInstallIdentity b;

  setUpAll(() async {
    a = await ConnectInstallIdentity.derive(
      masterSeed: seed(1),
      connectUrl: testPublicUrl,
    );
    b = await ConnectInstallIdentity.derive(
      masterSeed: seed(2),
      connectUrl: testPublicUrl,
    );
  });

  Future<(Harness, FakeGitHub)> start([
    Map<String, String> env = const {},
  ]) async {
    final harness = await Harness.start(allowed: [a, b], env: env);
    addTearDown(harness.close);
    final github = FakeGitHub(harness.upstream);
    _scriptAcme(harness.upstream);
    return (harness, github);
  }

  group('consent before the code', () {
    test('GitHub asks for the account picker', () async {
      final (harness, _) = await start();
      final start_ = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: PkcePair.generate().challenge,
        ).toJson(),
      );
      final url = OAuthStartResponse.fromJson(start_.json).authorizeUrl;
      expect(url.queryParameters['prompt'], 'select_account');
    });

    test('the consent page says what the server gets, with no code or link, '
        'for every lane', () async {
      final (harness, _) = await start();
      for (final lane in [
        ConnectOAuthLane.github,
        ConnectOAuthLane.google,
        ConnectOAuthLane.linear,
        ConnectOAuthLane.linearApp,
      ]) {
        final login = await _authorized(harness, a, lane);
        final consent = await harness.browser(
          '/oauth/${lane.wire}/done',
          cookie: login.cookie,
        );
        expect(consent.status, 200);
        final body = consent.body;
        expect(
          body,
          contains(const HtmlEscape().convert(consentScopeFor(lane))),
        );
        expect(body, contains('Connect cannot tell who runs that server'));
        expect(body, contains('If someone sent you this link'));
        expect(body, contains('value="continue"'));
        expect(body, contains('value="cancel"'));
        expect(
          body,
          contains('action="https://connect.test/oauth/${lane.wire}/done"'),
        );
        expect(confirmCodeFrom(body), isNull);
        expect(body, isNot(contains('oauth-done')));
        expect(body, isNot(contains('another network')));
      }
      expect(
        consentScopeFor(ConnectOAuthLane.github),
        contains('every repository'),
      );
      expect(
        consentScopeFor(ConnectOAuthLane.github),
        contains('every organization'),
      );
      expect(consentScopeFor(ConnectOAuthLane.slack), contains('bot'));
      expect(consentScopeFor(ConnectOAuthLane.google), contains('calendar'));
    });

    test('continue shows the code with the warning and no "type it where '
        'asked"', () async {
      final (harness, _) = await start();
      final flow = await browserFlow(harness, a, ConnectOAuthLane.github);
      expect(flow.done.status, 200);
      expect(flow.done.body, contains('Type it only where you started'));
      expect(flow.done.body, contains('Anyone who gets it'));
      expect(flow.done.body, contains('Nobody will ever ask you for it'));
      expect(flow.done.body, isNot(contains('where Control Center asks')));
      expect(
        flow.done.header('content-security-policy'),
        contains("form-action 'none'"),
      );
    });

    test(
      'cancel burns the login, so the provider code is never exchanged',
      () async {
        final (harness, _) = await start();
        final login = await _authorized(harness, a, ConnectOAuthLane.github);
        final cancelled = await harness.consent(
          ConnectOAuthLane.github,
          'cancel',
          cookie: login.cookie,
        );
        expect(cancelled.status, 200);
        expect(cancelled.body, contains('Sign-in cancelled'));
        expect(cancelled.body, contains('never be exchanged'));
        expect(confirmCodeFrom(cancelled.body), isNull);
        final again = await harness.consent(
          ConnectOAuthLane.github,
          'continue',
          cookie: login.cookie,
        );
        expect(confirmCodeFrom(again.body), isNull);
        expect(
          (await harness.browser(
            '/oauth/github/done',
            cookie: login.cookie,
          )).status,
          400,
        );
        final claim = await harness.call(
          a,
          'POST',
          '/v1/oauth/github/claim',
          body: OAuthClaimRequest(
            loginId: login.loginId,
            confirmCode: 'AAAAAAAA',
            codeVerifier: login.pkce.verifier,
            workspaceId: 'ws1',
          ).toJson(),
        );
        expect(claim.json, {'error': 'stale_request'});
        expect(harness.upstream.callsTo('POST', _exchange), isEmpty);
        expect(_lines(harness, 'oauth.cancelled'), hasLength(1));
      },
    );

    test('a cross-site, cookieless or unknown post shows nothing and spends '
        'nothing', () async {
      final (harness, _) = await start();
      final login = await _authorized(harness, a, ConnectOAuthLane.github);
      for (final refused in [
        await harness.consent(
          ConnectOAuthLane.github,
          'continue',
          cookie: login.cookie,
          fetchSite: 'cross-site',
        ),
        await harness.consent(
          ConnectOAuthLane.github,
          'continue',
          cookie: login.cookie,
          fetchSite: 'same-site',
        ),
        await harness.consent(ConnectOAuthLane.github, 'continue'),
        await harness.consent(
          ConnectOAuthLane.github,
          'approve',
          cookie: login.cookie,
        ),
        await harness.consent(
          ConnectOAuthLane.google,
          'continue',
          cookie: login.cookie,
        ),
      ]) {
        expect(refused.status, 400);
        expect(confirmCodeFrom(refused.body), isNull);
      }
      expect(_lines(harness, 'oauth.done_refused').map((l) => l['reason']), [
        'cross_site',
        'cross_site',
        'login_unknown',
        'action',
        'login_unknown',
      ]);
      final done = await harness.consent(
        ConnectOAuthLane.github,
        'continue',
        cookie: login.cookie,
      );
      expect(confirmCodeFrom(done.body), isNotNull);
    });

    test('a post must prove it came from this page: a foreign Origin, a '
        'cross-site fetch or neither header is refused', () async {
      final (harness, _) = await start();
      final login = await _authorized(harness, a, ConnectOAuthLane.github);
      Future<TestResponse> post({String? fetchSite, String? origin}) =>
          harness.consent(
            ConnectOAuthLane.github,
            'continue',
            cookie: login.cookie,
            fetchSite: fetchSite,
            origin: origin,
          );
      for (final refused in [
        await post(origin: 'https://evil.test'),
        await post(origin: 'http://connect.test'),
        await post(origin: 'https://connect.test.evil.test'),
        await post(origin: 'null'),
        await post(fetchSite: 'same-origin', origin: 'https://evil.test'),
        await post(fetchSite: 'cross-site', origin: testPublicUrl),
        await post(fetchSite: 'cross-site'),
        await post(),
      ]) {
        expect(refused.status, 400);
        expect(confirmCodeFrom(refused.body), isNull);
      }
      expect(_lines(harness, 'oauth.done_refused').map((l) => l['reason']), [
        'origin',
        'origin',
        'origin',
        // `Origin: null` names no origin, and no fetch metadata came with it.
        'no_origin',
        'origin',
        'cross_site',
        'cross_site',
        'no_origin',
      ]);
      for (final line in harness.logs) {
        expect(line, isNot(contains(login.cookie)));
      }
      // Each refusal left the login and its form token as they were.
      final byOrigin = await post(origin: testPublicUrl);
      expect(confirmCodeFrom(byOrigin.body), isNotNull);
    });

    test('a same-origin post is admitted with either proof', () async {
      final (harness, _) = await start();
      final first = await _authorized(harness, a, ConnectOAuthLane.github);
      final byFetchSite = await harness.consent(
        ConnectOAuthLane.github,
        'continue',
        cookie: first.cookie,
      );
      expect(confirmCodeFrom(byFetchSite.body), isNotNull);
      final second = await _authorized(harness, b, ConnectOAuthLane.github);
      final byOrigin = await harness.consent(
        ConnectOAuthLane.github,
        'continue',
        cookie: second.cookie,
        fetchSite: null,
        origin: '$testPublicUrl/',
      );
      expect(confirmCodeFrom(byOrigin.body), isNotNull);
      expect(_lines(harness, 'oauth.done_refused'), isEmpty);
    });

    // Chrome and Firefox send `Origin: null` with a form post from a page
    // whose referrer policy is `no-referrer`, and the real origin under
    // `same-origin`. Both always add `Sec-Fetch-Site: same-origin`.
    test('what a browser sends from the consent page is admitted: the page '
        'asks for its real origin, and a withheld one rests on fetch '
        'metadata', () async {
      final (harness, _) = await start();
      final login = await _authorized(harness, a, ConnectOAuthLane.github);
      final page = await harness.browser(
        '/oauth/github/done',
        cookie: login.cookie,
      );
      expect(page.status, 200);
      expect(page.header('referrer-policy'), 'same-origin');
      // Every other page keeps the base policy.
      final expired = await harness.browser('/oauth/github/done');
      expect(expired.status, 400);
      expect(expired.header('referrer-policy'), 'no-referrer');
      for (final origin in [testPublicUrl, 'null']) {
        final done = await harness.consent(
          ConnectOAuthLane.github,
          'continue',
          cookie: login.cookie,
          origin: origin,
        );
        expect(confirmCodeFrom(done.body), isNotNull, reason: origin);
        expect(done.header('referrer-policy'), 'no-referrer');
      }
      expect(_lines(harness, 'oauth.done_refused'), isEmpty);
      // A withheld origin proves nothing next to a cross-site fetch.
      final crossSite = await harness.consent(
        ConnectOAuthLane.github,
        'continue',
        cookie: login.cookie,
        fetchSite: 'cross-site',
        origin: 'null',
      );
      expect(crossSite.status, 400);
      expect(confirmCodeFrom(crossSite.body), isNull);
      expect(_lines(harness, 'oauth.done_refused').map((l) => l['reason']), [
        'cross_site',
      ]);
    });

    test('signed machine endpoints ignore Origin and fetch metadata', () async {
      final (harness, _) = await start();
      final started = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: PkcePair.generate().challenge,
        ).toJson(),
        extraHeaders: {
          'origin': 'https://evil.test',
          'sec-fetch-site': 'cross-site',
        },
      );
      expect(started.status, 200);
      final ready = await harness.raw('GET', '/readyz');
      expect(ready.status, 200);
      expect(_lines(harness, 'oauth.done_refused'), isEmpty);
    });

    test(
      'a post without the page\'s token is refused and leaves the login',
      () async {
        final (harness, _) = await start();
        final login = await _authorized(harness, a, ConnectOAuthLane.github);
        final page = await harness.browser(
          '/oauth/github/done',
          cookie: login.cookie,
        );
        final token = consentTokenFrom(page.body)!;
        expect(token, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
        for (final wrong in ['', 'A' * 43, '${token.substring(1)}A', 'short']) {
          for (final action in ['continue', 'cancel']) {
            final refused = await harness.consent(
              ConnectOAuthLane.github,
              action,
              cookie: login.cookie,
              token: wrong,
            );
            expect(refused.status, 400, reason: '$action with "$wrong"');
            expect(confirmCodeFrom(refused.body), isNull);
          }
        }
        expect(
          _lines(harness, 'oauth.done_refused').map((l) => l['reason']),
          everyElement('token'),
        );
        expect(_lines(harness, 'oauth.cancelled'), isEmpty);
        final done = await harness.consent(
          ConnectOAuthLane.github,
          'continue',
          cookie: login.cookie,
          token: token,
        );
        expect(confirmCodeFrom(done.body), isNotNull);
        // Single use: the same token answers once.
        final replay = await harness.consent(
          ConnectOAuthLane.github,
          'cancel',
          cookie: login.cookie,
          token: token,
        );
        expect(replay.status, 400);
        expect(_lines(harness, 'oauth.cancelled'), isEmpty);
        final cancel = await harness.consent(
          ConnectOAuthLane.github,
          'cancel',
          cookie: login.cookie,
        );
        expect(cancel.body, contains('Sign-in cancelled'));
        for (final line in harness.logs) {
          expect(line, isNot(contains(token)));
        }
      },
    );

    test('the page says when the browser is on another network than the '
        'start, and changes nothing else', () async {
      final (harness, _) = await start({'CONNECT_TRUST_PROXY': '1'});
      final login = await _authorized(
        harness,
        a,
        ConnectOAuthLane.github,
        startHeaders: {'x-forwarded-for': '203.0.113.5'},
      );
      Future<TestResponse> consentFrom(String address) => harness.raw(
        'GET',
        '/oauth/github/done',
        headers: {
          'cookie': '__Host-cc_connect=${login.cookie}',
          'x-forwarded-for': address,
        },
      );
      final near = await consentFrom('203.0.113.77');
      expect(near.status, 200);
      expect(near.body, isNot(contains('another network')));
      final far = await consentFrom('198.51.100.7');
      expect(far.status, 200);
      expect(far.body, contains('started from another network'));
      expect(far.body, contains('also what phishing looks like'));
      final done = await harness.consent(
        ConnectOAuthLane.github,
        'continue',
        cookie: login.cookie,
      );
      expect(confirmCodeFrom(done.body), isNotNull);
    });

    test('one address has a capped number of logins outstanding', () async {
      final (harness, _) = await start({
        'CONNECT_RATE_LOGINS_IP_PER_10_MINUTES': '2',
      });
      Future<TestResponse> start_(ConnectInstallIdentity who) => harness.call(
        who,
        'POST',
        '/v1/oauth/github/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: PkcePair.generate().challenge,
        ).toJson(),
      );
      expect((await start_(a)).status, 200);
      expect((await start_(b)).status, 200);
      expect((await start_(a)).json, {'error': 'rate_limited'});
      expect(_hits(harness), ['logins_ip']);
    });
  });

  group('the shared bot (as: app)', () {
    for (final listed in [false, true]) {
      test('every scope and actor, ${listed ? 'listed' : 'unlisted'} install: '
          'no pull request or contents write as the bot unless listed, '
          'refused before GitHub is asked', () async {
        final (harness, _) = await start({
          if (listed) 'CONNECT_GITHUB_REVIEW_BOT_INSTALLS': a.installId,
        });
        final grant = await signInGitHub(harness, a);
        for (final scope in GitHubTokenScope.values) {
          for (final actor in GitHubMintActor.values) {
            final before = harness.upstream.calls.length;
            final response = await _mint(
              harness,
              a,
              grant.seal,
              scope: scope,
              actor: actor,
            );
            final botMay =
                scope.connectBotMayHold ||
                (listed && scope == GitHubTokenScope.bot);
            final what = '${scope.wire} as ${actor.wire}';
            if (actor == GitHubMintActor.app && !botMay) {
              expect(response.json, {'error': 'needs_requester'}, reason: what);
              expect(harness.upstream.calls.length, before, reason: what);
            } else {
              expect(response.status, 200, reason: '$what: ${response.body}');
              final token = GitHubScopedToken.fromJson(response.json);
              expect(token.grantedScope, scope.wire, reason: what);
              expect(
                token.accessToken,
                startsWith(actor == GitHubMintActor.app ? 'ghs_' : 'ghu_'),
                reason: what,
              );
            }
          }
        }
        final botPermissions = [
          for (final call in harness.upstream.callsTo('POST', _appMint))
            call.json['permissions']! as Map,
        ];
        expect(botPermissions, hasLength(listed ? 4 : 3));
        for (final permissions in botPermissions) {
          expect(permissions['contents'], isNot('write'));
          if (!listed) {
            expect(permissions['pull_requests'], isNot('write'));
          }
        }
        expect(
          botPermissions.any((p) => p['pull_requests'] == 'write'),
          listed,
        );
      });
    }

    test('another install is not listed by someone else\'s listing', () async {
      final (harness, _) = await start({
        'CONNECT_GITHUB_REVIEW_BOT_INSTALLS': a.installId,
      });
      final grant = await signInGitHub(harness, b);
      final response = await _mint(
        harness,
        b,
        grant.seal,
        scope: GitHubTokenScope.bot,
        actor: GitHubMintActor.app,
      );
      expect(response.json, {'error': 'needs_requester'});
      expect(harness.upstream.callsTo('POST', _appMint), isEmpty);
    });

    test('the listing refuses * and installs the allow list refuses', () async {
      for (final listing in ['*', b.installId]) {
        await expectLater(
          Harness.start(
            allowed: [a],
            env: {'CONNECT_GITHUB_REVIEW_BOT_INSTALLS': listing},
          ),
          throwsA(isA<ConnectConfigException>()),
        );
      }
    });
  });

  group('retire', () {
    Future<TestResponse> retire(
      Harness harness,
      ConnectInstallIdentity who,
      String seal, {
      String workspaceId = 'ws1',
      Map<String, String> headers = const {},
    }) => harness.call(
      who,
      'POST',
      connectInstallRetirePath,
      body: SealRequest(seal: seal, workspaceId: workspaceId).toJson(),
      extraHeaders: headers,
    );

    test('a retired install is refused on every route, for good', () async {
      final (harness, _) = await start();
      final grant = await signInGitHub(harness, a);
      final before = harness.upstream.calls.length;
      final retired = await retire(harness, a, grant.seal);
      expect(retired.json, {'ok': true});
      expect(harness.upstream.calls, hasLength(before), reason: 'no upstream');
      expect(_lines(harness, 'install.retired'), hasLength(1));
      for (final call in [
        await harness.call(a, 'GET', '/v1/config'),
        await _refresh(harness, a, grant.seal),
        await retire(harness, a, grant.seal),
      ]) {
        expect(call.json, {'error': 'install_blocked'});
      }
      expect(
        harness.upstream
            .callsTo('POST', _exchange)
            .where((c) => c.form['grant_type'] == 'refresh_token'),
        isEmpty,
      );
      expect((await harness.call(b, 'GET', '/v1/config')).status, 200);
    });

    test('retire needs a seal of the signing install', () async {
      final (harness, github) = await start();
      final ofA = await signInGitHub(harness, a);
      github.userId = 2002;
      final ofB = await signInGitHub(harness, b);
      final unsigned = await harness.raw(
        'POST',
        connectInstallRetirePath,
        body: utf8.encode(
          jsonEncode(SealRequest(seal: ofA.seal, workspaceId: 'ws1')),
        ),
      );
      expect(unsigned.status, isNot(200));
      for (final body in <Map<String, Object?>>[
        {},
        {'install_id': b.installId},
        {'seal': '', 'workspace_id': 'ws1'},
      ]) {
        final response = await harness.call(
          a,
          'POST',
          connectInstallRetirePath,
          body: body,
        );
        expect(response.json, {'error': 'invalid_request'}, reason: '$body');
      }
      for (final denied in [
        await retire(harness, a, ofB.seal),
        await retire(harness, a, ofA.seal, workspaceId: 'ws2'),
        await retire(harness, a, 'v1.e30.AAAA'),
      ]) {
        expect(denied.json, {'error': 'access_denied'});
      }
      final bindings = harness.service.context.bindings;
      expect(await bindings.isRetired(a.installId), isFalse);
      expect(await bindings.isRetired(b.installId), isFalse);
      expect(_lines(harness, 'install.retired'), isEmpty);
    });

    test('retire takes a seal of any lane and generation', () async {
      final (harness, _) = await start();
      final seal = await harness.service.context.sealer.seal(
        provider: ConnectProvider.google,
        accountId: 'g-sub',
        appId: 'retired-client',
        generation: 1,
        binding: SealBinding(installId: a.installId, workspaceId: 'ws7'),
        payload: const {'refresh': 'r'},
      );
      expect((await retire(harness, a, seal, workspaceId: 'ws7')).json, {
        'ok': true,
      });
      expect((await harness.call(a, 'GET', '/v1/config')).json, {
        'error': 'install_blocked',
      });
    });

    test('retire has its own budget per address, an IPv6 /48', () async {
      final (harness, github) = await start({
        'CONNECT_RATE_RETIRE_IP_PER_HOUR': '1',
        'CONNECT_TRUST_PROXY': '1',
      });
      final ofA = await signInGitHub(harness, a);
      github.userId = 2002;
      final ofB = await signInGitHub(harness, b);
      expect(
        (await retire(
          harness,
          a,
          ofA.seal,
          headers: {'x-forwarded-for': '2001:db8:7:1::5'},
        )).json,
        {'ok': true},
      );
      expect(
        (await retire(
          harness,
          b,
          ofB.seal,
          headers: {'x-forwarded-for': '2001:db8:7:2::5'},
        )).json,
        {'error': 'rate_limited'},
      );
      expect(_hits(harness), ['retire_ip']);
      expect(
        (await retire(
          harness,
          b,
          ofB.seal,
          headers: {'x-forwarded-for': '2001:db8:8:1::5'},
        )).json,
        {'ok': true},
      );
    });

    test('retire releases the install\'s Slack teams and only those', () async {
      final (harness, _) = await start();
      final grant = await signInGitHub(harness, a);
      final bindings = harness.service.context.bindings;
      SlackTeamBinding team(String id, ConnectInstallIdentity who) =>
          SlackTeamBinding(
            teamId: id,
            installId: who.installId,
            botId: 'B$id',
            botUserId: 'U$id',
            appId: 'A0TEST',
            boundAt: DateTime.utc(2026, 11, 10),
          );
      await bindings.bindSlack(team('T0ONE', a));
      await bindings.bindSlack(team('T0TWO', a));
      await bindings.bindSlack(team('T0OTHER', b));
      expect((await retire(harness, a, grant.seal)).json, {'ok': true});
      expect(await bindings.slack('T0ONE', fresh: true), isNull);
      expect(await bindings.slack('T0TWO', fresh: true), isNull);
      expect(
        (await bindings.slack('T0OTHER', fresh: true))?.installId,
        b.installId,
      );
      final released = _lines(harness, 'slack.released');
      expect(released, hasLength(2));
      expect(released.map((l) => l['reason']), everyElement('retired'));
    });

    test('a full retired set refuses loudly and retires nothing', () async {
      final dir = await Directory.systemTemp.createTemp('cc_retired');
      addTearDown(() => dir.delete(recursive: true));
      File('${dir.path}/bindings.json').writeAsStringSync(
        jsonEncode({
          'slack': <String, Object?>{},
          'retired': [for (var i = 0; i < maxRetiredInstalls; i++) 'i$i'],
        }),
      );
      final harness = await Harness.start(
        allowed: [a],
        bindings: await FileBindingStore.open(dir.path),
      );
      addTearDown(harness.close);
      FakeGitHub(harness.upstream);
      final grant = await signInGitHub(harness, a);
      final refused = await retire(harness, a, grant.seal);
      expect(refused.json, {'error': 'provider_unavailable'});
      final line = _lines(harness, 'install.retire_refused').single;
      expect(line['level'], 'error');
      expect(line['reason'], 'retired_set_full');
      expect((await harness.call(a, 'GET', '/v1/config')).status, 200);
    });

    test('a child record never opens as a grant, nor a grant as a child '
        'record', () async {
      final sealer = CredentialSealer(
        connectOrigin: testPublicUrl,
        cipher: LocalAeadSealCipher(
          SecretSource.value('K', 'k1:${base64.encode(List.filled(32, 9))}'),
        ),
        log: ConnectLog(sink: (_) {}),
      );
      const binding = SealBinding(installId: 'install-a', workspaceId: 'ws1');
      Future<String> make(SealKind kind) => sealer.seal(
        provider: ConnectProvider.github,
        accountId: '1001',
        appId: '4242',
        generation: 2,
        binding: binding,
        payload: {'access': 'ghu_x', 'refresh': 'ghr_x'},
        kind: kind,
      );
      final child = await make(SealKind.childRecord);
      final grant = await make(SealKind.grant);
      final denied = throwsA(
        isA<ConnectException>().having(
          (e) => e.code,
          'code',
          ConnectErrorCode.accessDenied,
        ),
      );
      await expectLater(
        sealer.open(child, provider: ConnectProvider.github, binding: binding),
        denied,
      );
      await expectLater(
        sealer.open(
          grant,
          provider: ConnectProvider.github,
          binding: binding,
          kind: SealKind.childRecord,
        ),
        denied,
      );
      final opened = await sealer.open(
        child,
        provider: ConnectProvider.github,
        binding: binding,
        kind: SealKind.childRecord,
      );
      expect(opened.text('access'), 'ghu_x');
    });
  });

  group('GitHub token budgets', () {
    test('per account: children and refreshes stop at the limit, the '
        'disconnect never does', () async {
      final (harness, _) = await start({
        'CONNECT_RATE_GITHUB_TOKENS_ACCOUNT_PER_HOUR': '3',
      });
      final grant = await signInGitHub(harness, a);
      expect((await _mint(harness, a, grant.seal)).status, 200);
      expect(
        (await _mint(
          harness,
          a,
          grant.seal,
          scope: GitHubTokenScope.review,
        )).status,
        200,
      );
      final scopedBefore = harness.upstream.callsTo('POST', _scoped).length;
      expect(
        (await _mint(
          harness,
          a,
          grant.seal,
          scope: GitHubTokenScope.write,
        )).json,
        {'error': 'rate_limited'},
      );
      expect(
        harness.upstream.callsTo('POST', _scoped),
        hasLength(scopedBefore),
      );
      expect((await _refresh(harness, a, grant.seal)).json, {
        'error': 'rate_limited',
      });
      expect(_hits(harness), everyElement('github_account'));
      // The grant is intact: reads on the parent still work.
      final listed = await harness.call(
        a,
        'POST',
        '/v1/github/installations',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(listed.status, 200, reason: listed.body);
      harness.upstream.json(
        'DELETE',
        'https://api.github.com/applications/Iv23test/token',
        204,
        null,
      );
      final revoked = await harness.call(
        a,
        'POST',
        '/v1/github/revoke',
        body: GitHubRevokeRequest(
          workspaceId: 'ws1',
          seal: grant.seal,
        ).toJson(),
      );
      expect(revoked.json, {'ok': true});
    });

    test('per address: a claim past the limit is refused without spending '
        'the login', () async {
      final (harness, github) = await start({
        'CONNECT_RATE_GITHUB_TOKENS_IP_PER_HOUR': '1',
      });
      await signInGitHub(harness, a);
      github.userId = 2002;
      final flow = await browserFlow(harness, b, ConnectOAuthLane.github);
      Future<TestResponse> claim() => harness.call(
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
      expect((await claim()).json, {'error': 'rate_limited'});
      expect((await claim()).json, {'error': 'rate_limited'});
      expect(harness.upstream.callsTo('POST', _exchange), hasLength(1));
      expect(_hits(harness), everyElement('github_address'));
    });

    test('one install spending its share of an account leaves the '
        'account\'s other installs their own', () async {
      final (harness, _) = await start({
        'CONNECT_RATE_GITHUB_TOKENS_ACCOUNT_PER_HOUR': '2',
      });
      final onA = await signInGitHub(harness, a);
      expect((await _mint(harness, a, onA.seal)).status, 200);
      expect((await _refresh(harness, a, onA.seal)).json, {
        'error': 'rate_limited',
      });
      final onB = await signInGitHub(harness, b);
      expect(onB.accountId, onA.accountId);
      final refreshed = await _refresh(harness, b, onB.seal);
      expect(refreshed.status, 200, reason: refreshed.body);
      expect(_hits(harness), ['github_account']);
    });

    test('the account-wide ceiling holds across installs', () async {
      final (harness, _) = await start({
        'CONNECT_RATE_GITHUB_TOKENS_ACCOUNT_PER_HOUR': '2',
        'CONNECT_RATE_GITHUB_TOKENS_ACCOUNT_CEILING_PER_HOUR': '3',
      });
      final onA = await signInGitHub(harness, a);
      expect((await _mint(harness, a, onA.seal)).status, 200);
      final onB = await signInGitHub(harness, b);
      final scopedBefore = harness.upstream.callsTo('POST', _scoped).length;
      expect((await _mint(harness, b, onB.seal)).json, {
        'error': 'rate_limited',
      });
      expect(
        harness.upstream.callsTo('POST', _scoped),
        hasLength(scopedBefore),
      );
      expect(_hits(harness), ['github_account_ceiling']);
    });

    test(
      'a sign-in past the account budget is revoked upstream and refused',
      () async {
        final (harness, _) = await start({
          'CONNECT_RATE_GITHUB_TOKENS_ACCOUNT_PER_HOUR': '1',
        });
        harness.upstream.json(
          'DELETE',
          'https://api.github.com/applications/Iv23test/token',
          204,
          null,
        );
        await signInGitHub(harness, a);
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
        expect(claim.json, {'error': 'rate_limited'});
        expect(_hits(harness), ['github_account']);
        final deleted = harness.upstream.callsTo(
          'DELETE',
          'https://api.github.com/applications/Iv23test/token',
        );
        expect(deleted, hasLength(1));
        expect(claim.body, isNot(contains('seal')));
      },
    );

    test('past the App-wide ceiling refreshes and children wait', () async {
      final (harness, github) = await start({
        'CONNECT_RATE_GITHUB_TOKEN_CEILING_PER_HOUR': '1',
      });
      final first = await signInGitHub(harness, a);
      github.userId = 2002;
      final second = await signInGitHub(harness, b);
      expect(second.accountId, '2002');
      expect((await _refresh(harness, a, first.seal)).status, 200);
      expect((await _mint(harness, b, second.seal)).json, {
        'error': 'rate_limited',
      });
      expect(_hits(harness), ['github_ceiling']);
      expect(harness.upstream.callsTo('POST', _scoped), isEmpty);
    });

    test('sign-ins have a ceiling of their own: saturated, they leave '
        'refreshes alone', () async {
      final (harness, github) = await start({
        'CONNECT_RATE_GITHUB_EXCHANGE_CEILING_PER_HOUR': '1',
      });
      final first = await signInGitHub(harness, a);
      github.userId = 2002;
      final flow = await browserFlow(harness, b, ConnectOAuthLane.github);
      final claim = await harness.call(
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
      expect(claim.json, {'error': 'rate_limited'});
      expect(
        harness.upstream
            .callsTo('POST', _exchange)
            .where((c) => c.form['grant_type'] != 'refresh_token'),
        hasLength(1),
      );
      final refreshed = await _refresh(harness, a, first.seal);
      expect(refreshed.status, 200, reason: refreshed.body);
      expect((await _mint(harness, a, first.seal)).status, 200);
      expect(_hits(harness), ['github_exchange_ceiling']);
    });

    test('bot tokens have a budget per install', () async {
      final (harness, github) = await start({
        'CONNECT_RATE_GITHUB_APP_MINTS_INSTALL_PER_HOUR': '1',
      });
      final grant = await signInGitHub(harness, a);
      Future<TestResponse> bot(ConnectInstallIdentity who, String seal) =>
          _mint(harness, who, seal, actor: GitHubMintActor.app);
      expect((await bot(a, grant.seal)).status, 200);
      expect((await bot(a, grant.seal)).json, {'error': 'rate_limited'});
      expect(harness.upstream.callsTo('POST', _appMint), hasLength(1));
      github.userId = 2002;
      final other = await signInGitHub(harness, b);
      expect((await bot(b, other.seal)).status, 200);
      expect(_hits(harness), ['github_app_install']);
    });

    test(
      'bot tokens count against the asking person across installs',
      () async {
        final (harness, github) = await start({
          'CONNECT_RATE_GITHUB_APP_MINTS_ACCOUNT_PER_HOUR': '1',
        });
        Future<TestResponse> bot(ConnectInstallIdentity who, String seal) =>
            _mint(harness, who, seal, actor: GitHubMintActor.app);
        final onA = await signInGitHub(harness, a);
        final onB = await signInGitHub(harness, b);
        expect((await bot(a, onA.seal)).status, 200);
        final before = harness.upstream.calls.length;
        expect((await bot(b, onB.seal)).json, {'error': 'rate_limited'});
        expect(harness.upstream.calls, hasLength(before));
        github.userId = 2002;
        final other = await signInGitHub(harness, b);
        expect((await bot(b, other.seal)).status, 200);
        expect(_hits(harness), ['github_app_account']);
      },
    );

    test('the App-wide bot ceiling refuses before GitHub is asked', () async {
      final (harness, github) = await start({
        'CONNECT_RATE_GITHUB_APP_CEILING_PER_HOUR': '1',
      });
      Future<TestResponse> bot(ConnectInstallIdentity who, String seal) =>
          _mint(harness, who, seal, actor: GitHubMintActor.app);
      final onA = await signInGitHub(harness, a);
      github.userId = 2002;
      final onB = await signInGitHub(harness, b);
      expect((await bot(a, onA.seal)).status, 200);
      final before = harness.upstream.calls.length;
      expect((await bot(b, onB.seal)).json, {'error': 'rate_limited'});
      expect(harness.upstream.calls, hasLength(before));
      expect(_hits(harness), ['github_app_ceiling']);
    });

    test('one account holding many live children is logged', () async {
      final (harness, _) = await start({'CONNECT_GITHUB_TOKEN_CAP_WARN': '1'});
      final grant = await signInGitHub(harness, a);
      await _mint(harness, a, grant.seal);
      expect(_lines(harness, 'github.token_cap'), isEmpty);
      await _mint(harness, a, grant.seal, scope: GitHubTokenScope.review);
      final line = _lines(harness, 'github.token_cap').single;
      expect(line['github_user_id'], 1001);
      expect(line['count'], 2);
    });
  });

  test('Klipy has a budget per address across installs', () async {
    final (harness, _) = await start({'CONNECT_RATE_KLIPY_IP_PER_MINUTE': '1'});
    harness.upstream.json(
      'GET',
      'https://api.klipy.com/api/v1/klipy-key-123/gifs/trending',
      200,
      {
        'result': true,
        'data': {'data': <Object?>[], 'has_next': false},
      },
    );
    Future<TestResponse> trending(ConnectInstallIdentity who) => harness.call(
      who,
      'POST',
      '/v1/klipy/trending',
      body: const KlipyQuery().toJson(),
    );
    expect((await trending(a)).status, 200);
    expect((await trending(b)).json, {'error': 'rate_limited'});
    expect(_hits(harness), ['klipy_ip']);
  });

  test(
    'a forwarded header while no proxy is trusted is reported once',
    () async {
      final (harness, _) = await start();
      for (var i = 0; i < 2; i++) {
        await harness.call(
          a,
          'GET',
          '/v1/config',
          extraHeaders: {'x-forwarded-for': '203.0.113.5'},
        );
      }
      final lines = _lines(harness, 'config.trust_proxy_unset');
      expect(lines, hasLength(1));
      expect(lines.single['level'], 'warn');
    },
  );
}
