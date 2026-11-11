import 'dart:convert';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

import 'support/harness.dart';

const _team = 'T0TEAM';
const _user = 'U0USER';
const _botUser = 'U0BOT';
const _bot = 'B0BOT';

/// Scripts Slack's OIDC, bot install and auth endpoints.
final class _FakeSlack {
  _FakeSlack(this.upstream) {
    upstream
      ..on('POST', 'https://slack.com/api/openid.connect.token', (call) {
        if (call.form['code'] != 'oidc-code') {
          return UpstreamResponse.json(200, {
            'ok': false,
            'error': 'invalid_code',
          });
        }
        return UpstreamResponse.json(200, {
          'ok': true,
          'access_token': 'xoxp-oidc-user',
          'id_token': fakeJwt({
            'iss': 'https://slack.com',
            'aud': '111.222',
            'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300,
            'nonce': nonce,
            'sub': _user,
            'https://slack.com/team_id': team,
          }),
        });
      })
      ..on('POST', 'https://slack.com/api/oauth.v2.access', (call) async {
        final form = call.form;
        if (form['grant_type'] == 'refresh_token') {
          if (!liveRefresh.remove(form['refresh_token'])) {
            return UpstreamResponse.json(200, {
              'ok': false,
              'error': 'invalid_refresh_token',
            });
          }
          return UpstreamResponse.json(200, {
            'ok': true,
            'access_token': _issue(),
            'refresh_token': _refresh(),
            'expires_in': 43200,
            'token_type': 'bot',
          });
        }
        if (form['code'] != 'bot-code') {
          return UpstreamResponse.json(200, {
            'ok': false,
            'error': 'invalid_code',
          });
        }
        activeExchanges++;
        if (activeExchanges > maxConcurrentExchanges) {
          maxConcurrentExchanges = activeExchanges;
        }
        await Future<void>.delayed(exchangeDelay);
        activeExchanges--;
        return UpstreamResponse.json(200, {
          'ok': true,
          'app_id': 'A0TEST',
          'access_token': _issue(),
          'refresh_token': _refresh(),
          'expires_in': 43200,
          'token_type': 'bot',
          'scope': slackBotScopes.join(','),
          'bot_user_id': _botUser,
          'team': {'id': team, 'name': 'Acme'},
          'authed_user': {'id': _user},
          'is_enterprise_install': false,
        });
      })
      ..on('POST', 'https://slack.com/api/auth.test', (call) {
        final token = (call.request.headers['authorization'] ?? '')
            .replaceFirst('Bearer ', '');
        if (!liveAccess.contains(token)) {
          return UpstreamResponse.json(200, {
            'ok': false,
            'error': 'invalid_auth',
          });
        }
        return UpstreamResponse.json(200, {
          'ok': true,
          'team_id': team,
          'user_id': _botUser,
          'bot_id': _bot,
        });
      })
      ..on('POST', 'https://slack.com/api/users.info', (call) {
        final token = (call.request.headers['authorization'] ?? '')
            .replaceFirst('Bearer ', '');
        if (!liveAccess.contains(token)) {
          return UpstreamResponse.json(200, {
            'ok': false,
            'error': 'invalid_auth',
          });
        }
        return UpstreamResponse.json(200, {
          'ok': true,
          'user': {
            'id': call.form['user'],
            'team_id': team,
            'is_admin': installerIsAdmin,
            'is_owner': false,
          },
        });
      })
      ..on('POST', 'https://slack.com/api/auth.revoke', (call) {
        final token = (call.request.headers['authorization'] ?? '')
            .replaceFirst('Bearer ', '');
        revoked.add(token);
        liveAccess.remove(token);
        return UpstreamResponse.json(200, {'ok': true, 'revoked': true});
      });
  }

  final FakeUpstream upstream;
  String nonce = '';
  String team = _team;
  bool installerIsAdmin = true;
  int issued = 0;
  Duration exchangeDelay = Duration.zero;
  int activeExchanges = 0;
  int maxConcurrentExchanges = 0;
  final Set<String> liveAccess = {};
  final Set<String> liveRefresh = {};
  final List<String> revoked = [];

  String _issue() {
    issued++;
    final token = 'xoxe.xoxb-$issued-access';
    liveAccess.add(token);
    return token;
  }

  String _refresh() {
    final token = 'xoxe-1-refresh$issued';
    liveRefresh.add(token);
    return token;
  }

  int get botExchanges => upstream
      .callsTo('POST', 'https://slack.com/api/oauth.v2.access')
      .where((c) => c.form['code'] != null)
      .length;
}

/// Starts a Slack sign-in and runs the OIDC hop. Returns the hop's answer
/// and the next state (when Slack is sent on to the bot install).
Future<({String loginId, PkcePair pkce, TestResponse oidc, String? botState})>
_slackOidc(
  Harness harness,
  _FakeSlack slack,
  ConnectInstallIdentity who,
) async {
  final pkce = PkcePair.generate();
  final start = await harness.call(
    who,
    'POST',
    '/v1/oauth/slack/start',
    body: OAuthStartRequest(
      workspaceId: 'ws1',
      codeChallenge: pkce.challenge,
    ).toJson(),
  );
  expect(start.status, 200, reason: start.body);
  final started = OAuthStartResponse.fromJson(start.json);
  final query = started.authorizeUrl.queryParameters;
  expect(started.authorizeUrl.host, 'slack.com');
  expect(started.authorizeUrl.path, '/openid/connect/authorize');
  slack.nonce = query['nonce']!;
  final oidc = await harness.browser(
    '/oauth/slack_oidc/callback?code=oidc-code&state=${query['state']}',
  );
  final location = oidc.header('location');
  return (
    loginId: started.loginId,
    pkce: pkce,
    oidc: oidc,
    botState: location == null
        ? null
        : Uri.parse(location).queryParameters['state'],
  );
}

Future<SealedGrant> _signInSlack(
  Harness harness,
  _FakeSlack slack,
  ConnectInstallIdentity who,
) async {
  final hop = await _slackOidc(harness, slack, who);
  expect(hop.oidc.status, 303);
  final bot = Uri.parse(hop.oidc.header('location')!);
  expect(bot.host, 'slack.com');
  expect(bot.path, '/oauth/v2/authorize');
  expect(bot.queryParameters['team'], slack.team);
  expect(
    bot.queryParameters['redirect_uri'],
    'https://connect.test/oauth/slack/callback',
  );
  final callback = await harness.browser(
    '/oauth/slack/callback?code=bot-code&state=${hop.botState}',
  );
  expect(callback.status, 303);
  final done = await _codePage(harness, callback);
  final claim = await harness.call(
    who,
    'POST',
    '/v1/oauth/slack/claim',
    body: OAuthClaimRequest(
      loginId: hop.loginId,
      confirmCode: confirmCodeFrom(done.body)!,
      codeVerifier: hop.pkce.verifier,
      workspaceId: 'ws1',
    ).toJson(),
  );
  expect(claim.status, 200, reason: claim.body);
  return SealedGrant.fromJson(claim.json);
}

/// The consent page for the login [callback] completed, then the code page
/// after continue.
Future<TestResponse> _codePage(Harness harness, TestResponse callback) async {
  final cookie = cookieFrom(callback);
  final consent = await harness.browser('/oauth/slack/done', cookie: cookie);
  expect(consent.status, 200);
  expect(consent.body, contains('install the Control Center bot'));
  return harness.consent(
    ConnectOAuthLane.slack,
    'continue',
    cookie: cookie,
    token: consentTokenFrom(consent.body),
  );
}

/// Sends a Slack-signed request to a hook.
Future<TestResponse> _hook(
  Harness harness,
  String path,
  List<int> body, {
  String secret = 'signing-secret',
  DateTime? at,
  String contentType = 'application/json',
}) {
  final timestamp = '${(at ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000}';
  final mac = crypto.Hmac(
    crypto.sha256,
    utf8.encode(secret),
  ).convert([...utf8.encode('v0:$timestamp:'), ...body]);
  return harness.raw(
    'POST',
    path,
    headers: {
      'content-type': contentType,
      'x-slack-request-timestamp': timestamp,
      'x-slack-signature': 'v0=$mac',
    },
    body: body,
  );
}

Future<TestResponse> _event(
  Harness harness,
  Map<String, Object?> event, {
  String eventId = 'Ev001',
  String appId = 'A0TEST',
  String team = _team,
  String? authorizedTeam,
  String secret = 'signing-secret',
  DateTime? eventTime,
  Map<String, Object?> envelope = const {},
}) => _hook(
  harness,
  '/v1/hooks/slack/events',
  utf8.encode(
    jsonEncode({
      'type': 'event_callback',
      'api_app_id': appId,
      'team_id': team,
      'authorizations': [
        {
          'team_id': authorizedTeam ?? team,
          'user_id': _botUser,
          'is_bot': true,
        },
      ],
      'event_id': eventId,
      'event_time':
          (eventTime ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000,
      'event': event,
      ...envelope,
    }),
  ),
  secret: secret,
);

Future<List<Map<String, Object?>>> _poll(
  Harness harness,
  ConnectInstallIdentity who,
) async {
  final response = await harness.call(who, 'POST', '/v1/events/poll');
  expect(response.status, 200, reason: response.body);
  return [
    for (final item in response.json['events']! as List)
      item as Map<String, Object?>,
  ];
}

void main() {
  late ConnectInstallIdentity a;
  late ConnectInstallIdentity b;
  late Harness harness;
  late _FakeSlack slack;

  setUp(() async {
    a = await ConnectInstallIdentity.derive(
      masterSeed: seed(1),
      connectUrl: testPublicUrl,
    );
    b = await ConnectInstallIdentity.derive(
      masterSeed: seed(2),
      connectUrl: testPublicUrl,
    );
    harness = await Harness.start(
      allowed: [a, b],
      pollTimeout: const Duration(milliseconds: 400),
      env: {'CONNECT_SLACK_SIGNING_SECRET_PREVIOUS': 'old-signing-secret'},
    );
    slack = _FakeSlack(harness.upstream);
  });

  tearDown(() => harness.close());

  group('sign-in', () {
    test('OIDC pre-check, bot install, claim and binding', () async {
      final grant = await _signInSlack(harness, slack, a);
      expect(grant.teamId, _team);
      expect(grant.teamName, 'Acme');
      expect(grant.botUserId, _botUser);
      expect(grant.botId, _bot);
      expect(grant.authedUserId, _user);
      expect(grant.accessToken, startsWith('xoxe.xoxb-'));
      expect(grant.seal, isNot(contains('xoxe-1-')));
      final binding = await harness.service.context.bindings.slack(_team);
      expect(binding!.installId, a.installId);
      expect(binding.botId, _bot);
    });

    test(
      'a team bound elsewhere stops at the pre-check, before oauth.v2.access',
      () async {
        await _signInSlack(harness, slack, a);
        expect(slack.botExchanges, 1);
        final hop = await _slackOidc(harness, slack, b);
        expect(hop.oidc.status, 409);
        expect(hop.oidc.body, contains('connected to another server'));
        expect(hop.botState, isNull);
        expect(slack.botExchanges, 1, reason: "a's bot token was not rotated");
        // The login is burned.
        final claim = await harness.call(
          b,
          'POST',
          '/v1/oauth/slack/claim',
          body: OAuthClaimRequest(
            loginId: hop.loginId,
            confirmCode: 'AAAAAAAA',
            codeVerifier: hop.pkce.verifier,
            workspaceId: 'ws1',
          ).toJson(),
        );
        expect(claim.json, {'error': 'stale_request'});
      },
    );

    test('the bound install can sign in again', () async {
      await _signInSlack(harness, slack, a);
      final again = await _signInSlack(harness, slack, a);
      expect(again.teamId, _team);
    });

    test(
      'a first connection by a non-admin is refused and its token revoked',
      () async {
        slack.installerIsAdmin = false;
        final hop = await _slackOidc(harness, slack, a);
        final callback = await harness.browser(
          '/oauth/slack/callback?code=bot-code&state=${hop.botState}',
        );
        final done = await _codePage(harness, callback);
        final claim = await harness.call(
          a,
          'POST',
          '/v1/oauth/slack/claim',
          body: OAuthClaimRequest(
            loginId: hop.loginId,
            confirmCode: confirmCodeFrom(done.body)!,
            codeVerifier: hop.pkce.verifier,
            workspaceId: 'ws1',
          ).toJson(),
        );
        expect(claim.json, {'error': 'not_admin'});
        expect(slack.revoked, hasLength(1));
        expect(
          await harness.service.context.bindings.slack(_team, fresh: true),
          isNull,
        );
      },
    );

    test('a reconnect by the bound install needs no admin', () async {
      await _signInSlack(harness, slack, a);
      slack.installerIsAdmin = false;
      final again = await _signInSlack(harness, slack, a);
      expect(again.teamId, _team);
    });

    test('a sign-in another install started and left open blocks nobody: '
        'the pre-check reserves nothing', () async {
      final hostile = await _slackOidc(harness, slack, b);
      expect(hostile.oidc.status, 303);
      expect(
        await harness.service.context.state.get('slackclaim:$_team'),
        isNull,
      );
      final grant = await _signInSlack(harness, slack, a);
      expect(grant.teamId, _team);
      expect(slack.botExchanges, 1);
    });

    test(
      'a claim while another exchange for the team runs is refused as '
      'busy without spending the login, and succeeds once it is done',
      () async {
        final hop = await _slackOidc(harness, slack, a);
        final callback = await harness.browser(
          '/oauth/slack/callback?code=bot-code&state=${hop.botState}',
        );
        final done = await _codePage(harness, callback);
        final state = harness.service.context.state;
        await state.set(
          'slackclaim:$_team',
          'exchanging:someone-else',
          const Duration(minutes: 2),
        );
        Future<TestResponse> claim() => harness.call(
          a,
          'POST',
          '/v1/oauth/slack/claim',
          body: OAuthClaimRequest(
            loginId: hop.loginId,
            confirmCode: confirmCodeFrom(done.body)!,
            codeVerifier: hop.pkce.verifier,
            workspaceId: 'ws1',
          ).toJson(),
        );
        final busy = await claim();
        expect(busy.json, {'error': 'rate_limited'});
        expect(slack.botExchanges, 0);
        expect(
          await state.get('slackclaim:$_team'),
          'exchanging:someone-else',
          reason: "the other exchange's mark is untouched",
        );
        expect(
          harness.logs.any((l) => l.contains('"slack_exchange_busy"')),
          isTrue,
        );
        await state.delete('slackclaim:$_team');
        final retried = await claim();
        expect(retried.status, 200, reason: retried.body);
        expect(slack.botExchanges, 1);
        expect(await state.get('slackclaim:$_team'), isNull);
      },
    );

    test(
      'of two logins claiming one team at once, every exchange ran alone',
      () async {
        Future<Future<TestResponse> Function()> ready() async {
          final hop = await _slackOidc(harness, slack, a);
          final callback = await harness.browser(
            '/oauth/slack/callback?code=bot-code&state=${hop.botState}',
          );
          final done = await _codePage(harness, callback);
          return () => harness.call(
            a,
            'POST',
            '/v1/oauth/slack/claim',
            body: OAuthClaimRequest(
              loginId: hop.loginId,
              confirmCode: confirmCodeFrom(done.body)!,
              codeVerifier: hop.pkce.verifier,
              workspaceId: 'ws1',
            ).toJson(),
          );
        }

        final first = await ready();
        final second = await ready();
        slack.exchangeDelay = const Duration(milliseconds: 200);
        final answers = await Future.wait([first(), second()]);
        expect(
          answers.map((r) => r.status == 200 ? 'ok' : r.json['error']),
          unorderedEquals(['ok', 'rate_limited']),
        );
        expect(slack.maxConcurrentExchanges, 1);
        expect(
          slack.botExchanges,
          answers.where((r) => r.status == 200).length,
        );
      },
    );

    test('an OIDC token with the wrong nonce is declined', () async {
      final pkce = PkcePair.generate();
      final start = await harness.call(
        a,
        'POST',
        '/v1/oauth/slack/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: pkce.challenge,
        ).toJson(),
      );
      final state = OAuthStartResponse.fromJson(
        start.json,
      ).authorizeUrl.queryParameters['state'];
      slack.nonce = 'not-the-nonce';
      final oidc = await harness.browser(
        '/oauth/slack_oidc/callback?code=oidc-code&state=$state',
      );
      expect(oidc.status, 400);
      expect(slack.botExchanges, 0);
    });

    test('a bot install for a different team is revoked and refused', () async {
      final hop = await _slackOidc(harness, slack, a);
      slack.team = 'T0OTHER';
      final callback = await harness.browser(
        '/oauth/slack/callback?code=bot-code&state=${hop.botState}',
      );
      final done = await _codePage(harness, callback);
      final claim = await harness.call(
        a,
        'POST',
        '/v1/oauth/slack/claim',
        body: OAuthClaimRequest(
          loginId: hop.loginId,
          confirmCode: confirmCodeFrom(done.body)!,
          codeVerifier: hop.pkce.verifier,
          workspaceId: 'ws1',
        ).toJson(),
      );
      expect(claim.json, {'error': 'needs_sign_in'});
      expect(slack.revoked, hasLength(1));
      expect(await harness.service.context.bindings.slack('T0OTHER'), isNull);
    });

    test(
      'switching teams to a team bound elsewhere never revokes the victim team',
      () async {
        slack.team = 'T0VICTIM';
        await _signInSlack(harness, slack, b);
        slack.team = 'T0FREE';
        final hop = await _slackOidc(harness, slack, a);
        slack.team = 'T0VICTIM';
        final callback = await harness.browser(
          '/oauth/slack/callback?code=bot-code&state=${hop.botState}',
        );
        final done = await _codePage(harness, callback);
        final claim = await harness.call(
          a,
          'POST',
          '/v1/oauth/slack/claim',
          body: OAuthClaimRequest(
            loginId: hop.loginId,
            confirmCode: confirmCodeFrom(done.body)!,
            codeVerifier: hop.pkce.verifier,
            workspaceId: 'ws1',
          ).toJson(),
        );
        expect(claim.json, {'error': 'needs_sign_in'});
        expect(slack.revoked, isEmpty);
        expect(
          (await harness.service.context.bindings.slack('T0VICTIM'))?.installId,
          b.installId,
        );
      },
    );
  });

  group('refresh and revoke', () {
    test('another install\'s seal is refused as a seal, before the team\'s '
        'binding is looked at', () async {
      final grant = await _signInSlack(harness, slack, a);
      final refreshed = await harness.call(
        b,
        'POST',
        '/v1/slack/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(refreshed.json, {'error': 'access_denied'});
    });

    test('refresh rotates for the bound install only', () async {
      final grant = await _signInSlack(harness, slack, a);
      final refreshed = await harness.call(
        a,
        'POST',
        '/v1/slack/refresh',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(refreshed.status, 200, reason: refreshed.body);
      final next = SealedGrant.fromJson(refreshed.json);
      expect(next.accessToken, isNot(grant.accessToken));
      expect(next.teamId, _team);
      expect(next.botId, _bot);
    });

    test(
      'app_uninstalled releases the team; refresh then needs sign-in',
      () async {
        final grant = await _signInSlack(harness, slack, a);
        final hook = await _event(harness, {
          'type': 'app_uninstalled',
        }, eventId: 'EvGone');
        expect(hook.status, 200);
        expect(
          await harness.service.context.bindings.slack(_team, fresh: true),
          isNull,
        );
        final refreshed = await harness.call(
          a,
          'POST',
          '/v1/slack/refresh',
          body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
        );
        expect(refreshed.json, {'error': 'needs_sign_in'});
        // Now another server may bind the team.
        final other = await _signInSlack(harness, slack, b);
        expect(other.teamId, _team);
      },
    );

    test(
      'an uninstall older than the binding, or seen twice, frees nothing',
      () async {
        final before = DateTime.now().subtract(const Duration(minutes: 2));
        await _signInSlack(harness, slack, a);
        await _event(
          harness,
          {'type': 'app_uninstalled'},
          eventId: 'EvOld',
          eventTime: before,
        );
        expect(
          (await harness.service.context.bindings.slack(
            _team,
            fresh: true,
          ))?.installId,
          a.installId,
        );
        // Released once, rebound, then the same event redelivered.
        await _event(harness, {'type': 'app_uninstalled'}, eventId: 'EvGone');
        await _signInSlack(harness, slack, b);
        await _event(harness, {'type': 'app_uninstalled'}, eventId: 'EvGone');
        expect(
          (await harness.service.context.bindings.slack(
            _team,
            fresh: true,
          ))?.installId,
          b.installId,
        );
      },
    );

    test(
      'the binding keeps the bot user Slack names in tokens_revoked',
      () async {
        await _signInSlack(harness, slack, a);
        final bound = await harness.service.context.bindings.slack(
          _team,
          fresh: true,
        );
        expect(bound?.botUserId, _botUser);
      },
    );

    test('tokens_revoked frees the team only for its own bot user', () async {
      await _signInSlack(harness, slack, a);
      Future<String?> boundInstall() async =>
          (await harness.service.context.bindings.slack(
            _team,
            fresh: true,
          ))?.installId;
      // A person's token, then another bot user: nothing to free.
      await _event(harness, {
        'type': 'tokens_revoked',
        'tokens': {
          'oauth': [_user],
        },
      }, eventId: 'EvOauth');
      await _event(harness, {
        'type': 'tokens_revoked',
        'tokens': {
          'bot': ['U0OTHERBOT'],
        },
      }, eventId: 'EvOtherBot');
      expect(await boundInstall(), a.installId);
      await _event(harness, {
        'type': 'tokens_revoked',
        'tokens': {
          'bot': [_botUser],
        },
      }, eventId: 'EvOurBot');
      expect(await boundInstall(), isNull);
    });

    test(
      'an uninstall delivered for another team\'s installation frees nothing',
      () async {
        await _signInSlack(harness, slack, a);
        await _event(
          harness,
          {'type': 'app_uninstalled'},
          eventId: 'EvPartner',
          envelope: {
            'authorizations': [
              {'team_id': 'T0PARTNER', 'user_id': 'U0X', 'is_bot': true},
            ],
          },
        );
        await _event(
          harness,
          {'type': 'app_uninstalled'},
          eventId: 'EvOrgWide',
          envelope: {
            'authorizations': [
              {'team_id': null, 'enterprise_id': 'E0ORG', 'is_bot': true},
            ],
          },
        );
        expect(
          (await harness.service.context.bindings.slack(
            _team,
            fresh: true,
          ))?.installId,
          a.installId,
        );
        await _event(
          harness,
          {'type': 'app_uninstalled'},
          eventId: 'EvOurs',
          envelope: {
            'authorizations': [
              {'team_id': _team, 'user_id': _botUser, 'is_bot': true},
            ],
          },
        );
        expect(
          await harness.service.context.bindings.slack(_team, fresh: true),
          isNull,
        );
      },
    );

    test('revoke kills the bot token and frees the team', () async {
      final grant = await _signInSlack(harness, slack, a);
      final revoke = await harness.call(
        a,
        'POST',
        '/v1/slack/revoke',
        body: SealRequest(seal: grant.seal, workspaceId: 'ws1').toJson(),
      );
      expect(revoke.json, {'ok': true});
      expect(slack.revoked, [grant.accessToken]);
      expect(
        await harness.service.context.bindings.slack(_team, fresh: true),
        isNull,
      );
    });
  });

  group('events', () {
    test('url_verification echoes a well-formed challenge', () async {
      final response = await _hook(
        harness,
        '/v1/hooks/slack/events',
        utf8.encode(
          jsonEncode({'type': 'url_verification', 'challenge': 'abc123'}),
        ),
      );
      expect(response.json, {'challenge': 'abc123'});
    });

    test('a bad or stale signature is refused', () async {
      final body = utf8.encode(
        jsonEncode({'type': 'url_verification', 'challenge': 'abc'}),
      );
      final wrong = await _hook(
        harness,
        '/v1/hooks/slack/events',
        body,
        secret: 'nope',
      );
      expect(wrong.status, 403);
      final stale = await _hook(
        harness,
        '/v1/hooks/slack/events',
        body,
        at: DateTime.now().subtract(const Duration(minutes: 6)),
      );
      expect(stale.status, 403);
      final previous = await _hook(
        harness,
        '/v1/hooks/slack/events',
        body,
        secret: 'old-signing-secret',
      );
      expect(previous.status, 200, reason: 'the previous secret still works');
    });

    test('a hook is judged on its headers before its body', () async {
      // No signature headers: refused without the body being verified.
      final bare = await harness.raw(
        'POST',
        '/v1/hooks/slack/events',
        body: utf8.encode('{}'),
      );
      expect(bare.status, 403);
      final stale = await harness.raw(
        'POST',
        '/v1/hooks/slack/events',
        headers: {
          'x-slack-request-timestamp':
              '${DateTime.now().millisecondsSinceEpoch ~/ 1000 - 600}',
          'x-slack-signature': 'v0=00',
        },
        body: utf8.encode('{}'),
      );
      expect(stale.status, 403);
      final forged = await harness.raw(
        'POST',
        '/v1/hooks/slack/commands',
        headers: {
          'x-slack-request-timestamp':
              '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
          'x-slack-signature': 'v0=00',
        },
        body: utf8.encode('team_id=T0TEAM'),
      );
      expect(forged.status, 403);
      final reasons = [
        for (final line in harness.logs)
          if (line.contains('slack.signature_refused'))
            (jsonDecode(line) as Map<String, Object?>)['reason'],
      ];
      expect(reasons, ['headers', 'stale', 'signature']);
    });

    test('an oversized event is acknowledged and dropped', () async {
      final response = await harness.raw(
        'POST',
        '/v1/hooks/slack/events',
        headers: {
          'x-slack-request-timestamp':
              '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
          'x-slack-signature': 'v0=00',
        },
        body: List.filled(256 * 1024 + 1, 0x20),
      );
      expect(response.status, 200);
      expect(
        harness.logs.where((l) => l.contains('slack.event_dropped')),
        hasLength(1),
      );
    });

    test('messages are relayed as references without text', () async {
      await _signInSlack(harness, slack, a);
      final hook = await _event(harness, {
        'type': 'message',
        'channel_type': 'im',
        'channel': 'D0CHAN',
        'user': _user,
        'text': 'the secret plan is <@U0BOT>',
        'ts': '1731062400.000100',
        'thread_ts': '1731062300.000100',
        'blocks': [
          {'type': 'rich_text'},
        ],
      });
      expect(hook.status, 200);
      expect(hook.json, isEmpty);
      final events = await _poll(harness, a);
      expect(events, hasLength(1));
      final ref = SlackEventRef.tryParse(events.single)!;
      expect(ref.eventId, 'Ev001');
      expect(ref.teamId, _team);
      expect(ref.eventType, 'message.im');
      expect(ref.channelId, 'D0CHAN');
      expect(ref.messageTs, '1731062400.000100');
      expect(ref.threadTs, '1731062300.000100');
      expect(jsonEncode(events), isNot(contains('secret plan')));
      expect(jsonEncode(events), isNot(contains('blocks')));
      expect(harness.logs.join(), isNot(contains('secret plan')));
      expect(await _poll(harness, a), isEmpty, reason: 'drained');
    });

    test('a shared-channel event goes to the installation Slack delivered it '
        'for, never to the workspace the envelope names', () async {
      slack.team = 'T0PARTNER';
      await _signInSlack(harness, slack, b);
      slack.team = _team;
      await _signInSlack(harness, slack, a);
      // Happened in the partner's workspace, delivered for a's installation.
      await _event(
        harness,
        {'type': 'app_mention', 'channel': 'C0SHARED', 'ts': '1.2'},
        eventId: 'EvShared',
        team: 'T0PARTNER',
        authorizedTeam: _team,
      );
      final forA = await _poll(harness, a);
      expect(forA, hasLength(1));
      expect(SlackEventRef.tryParse(forA.single)!.teamId, _team);
      expect(await _poll(harness, b), isEmpty);
    });

    test(
      'an event without an authorization for one workspace is dropped',
      () async {
        await _signInSlack(harness, slack, a);
        var n = 0;
        for (final authorizations in [
          null,
          <Object?>[],
          [
            {'team_id': null, 'enterprise_id': 'E0ORG'},
          ],
          [
            {'team_id': _team},
            {'team_id': 'T0OTHER'},
          ],
        ]) {
          final hook = await _event(
            harness,
            {'type': 'app_mention', 'channel': 'C0CHAN', 'ts': '1.2'},
            eventId: 'EvNoAuth${n++}',
            envelope: {'authorizations': authorizations},
          );
          expect(hook.status, 200);
        }
        expect(await _poll(harness, a), isEmpty);
        expect(
          harness.logs.any((l) => l.contains('"no_authorization"')),
          isTrue,
        );
      },
    );

    test('a poll wakes as soon as a reference is queued', () async {
      await _signInSlack(harness, slack, a);
      final watch = Stopwatch()..start();
      final pending = _poll(harness, a);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await _event(harness, {
        'type': 'app_mention',
        'channel': 'C0CHAN',
        'ts': '1.2',
      });
      final events = await pending;
      expect(events, hasLength(1));
      expect(events.single['event_type'], 'app_mention');
      expect(watch.elapsed, lessThan(const Duration(milliseconds: 400)));
    });

    test(
      'drops retries, our own bot, other apps, unbound teams and other types',
      () async {
        await _signInSlack(harness, slack, a);
        final message = {
          'type': 'message',
          'channel_type': 'channel',
          'channel': 'C0CHAN',
          'ts': '1.1',
        };
        await _event(harness, message, eventId: 'EvA');
        await _event(harness, message, eventId: 'EvA');
        await _event(harness, {...message, 'bot_id': _bot}, eventId: 'EvB');
        await _event(harness, message, eventId: 'EvC', appId: 'A0OTHER');
        await _event(harness, message, eventId: 'EvD', team: 'T0NOBODY');
        await _event(harness, {'type': 'reaction_added'}, eventId: 'EvE');
        final events = await _poll(harness, a);
        expect([for (final e in events) e['event_id']], ['EvA']);
        expect(await _poll(harness, b), isEmpty);
      },
    );

    test('a per-team budget caps the queue', () async {
      final limited = await Harness.start(
        allowed: [a],
        env: {'CONNECT_RATE_SLACK_TEAM_PER_MINUTE': '2'},
        pollTimeout: const Duration(milliseconds: 100),
      );
      addTearDown(limited.close);
      final fake = _FakeSlack(limited.upstream);
      await _signInSlack(limited, fake, a);
      for (var i = 0; i < 4; i++) {
        await _event(limited, {
          'type': 'app_mention',
          'channel': 'C0CHAN',
          'ts': '1.$i',
        }, eventId: 'Ev$i');
      }
      expect(await _poll(limited, a), hasLength(2));
    });

    test('a failed push still answers 200 and forgets the event', () async {
      final store = FlakyStateStore();
      final flaky = await Harness.start(
        allowed: [a],
        state: store,
        pollTimeout: const Duration(milliseconds: 100),
      );
      addTearDown(flaky.close);
      final fake = _FakeSlack(flaky.upstream);
      await _signInSlack(flaky, fake, a);
      store.failPushes.add('slackq:');
      final mention = {'type': 'app_mention', 'channel': 'C0CHAN', 'ts': '1.1'};
      final failed = await _event(flaky, mention, eventId: 'EvRetry');
      expect(failed.status, 200, reason: 'Slack must never see a failure');
      expect(
        await store.get('slackev:EvRetry'),
        isNull,
        reason: 'the dedupe key is dropped with the failed push',
      );
      expect(
        flaky.logs.where((l) => l.contains('"reason":"state_unavailable"')),
        hasLength(1),
      );
      // Slack's retry of the same event is queued once the store is back.
      store.failPushes.clear();
      await _event(flaky, mention, eventId: 'EvRetry');
      expect(
        [for (final e in await _poll(flaky, a)) e['event_id']],
        ['EvRetry'],
      );
    });

    test('an unexpected relay failure still answers 200', () async {
      final store = FlakyStateStore()
        ..failPuts.add('slackev:')
        ..putError = StateError('boom');
      final flaky = await Harness.start(allowed: [a], state: store);
      addTearDown(flaky.close);
      final fake = _FakeSlack(flaky.upstream);
      await _signInSlack(flaky, fake, a);
      final response = await _event(flaky, {
        'type': 'app_mention',
        'channel': 'C0CHAN',
        'ts': '1.1',
      });
      expect(response.status, 200);
      final line = flaky.logs.firstWhere(
        (l) => l.contains('slack.event_failed'),
      );
      expect(line, contains('"exception":"StateError"'));
      expect(line, isNot(contains('boom')));
    });

    test('an empty poll returns after the timeout', () async {
      final events = await _poll(harness, a);
      expect(events, isEmpty);
    });

    test('at most two polls per install at once', () async {
      final first = _poll(harness, a);
      final second = _poll(harness, a);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final third = await harness.call(a, 'POST', '/v1/events/poll');
      expect(third.json, {'error': 'rate_limited'});
      await Future.wait([first, second]);
    });
  });

  group('slash commands', () {
    List<int> form(Map<String, String> fields) =>
        utf8.encode(Uri(queryParameters: fields).query);

    test(
      'a bound team gets a fixed ephemeral answer and a reference',
      () async {
        await _signInSlack(harness, slack, a);
        final response = await _hook(
          harness,
          '/v1/hooks/slack/commands',
          form({
            'api_app_id': 'A0TEST',
            'team_id': _team,
            'user_id': _user,
            'channel_id': 'C0CHAN',
            'command': '/cc',
            'text': 'draft a reply',
            'response_url': 'https://hooks.slack.com/commands/T0TEAM/1/abc',
          }),
          contentType: 'application/x-www-form-urlencoded',
        );
        expect(response.json, {
          'response_type': 'ephemeral',
          'text': 'Got it. Confirm the draft in Control Center.',
        });
        final events = await _poll(harness, a);
        final ref = SlackCommandRef.tryParse(events.single)!;
        expect(ref.command, '/cc');
        expect(ref.text, 'draft a reply');
        expect(ref.responseUrl, startsWith('https://hooks.slack.com/'));
      },
    );

    test('an unbound team is told to connect first', () async {
      final response = await _hook(
        harness,
        '/v1/hooks/slack/commands',
        form({'api_app_id': 'A0TEST', 'team_id': 'T0NOBODY', 'command': '/cc'}),
        contentType: 'application/x-www-form-urlencoded',
      );
      expect(response.json['text'], contains('not connected'));
    });

    test('a foreign response_url is dropped', () async {
      await _signInSlack(harness, slack, a);
      await _hook(
        harness,
        '/v1/hooks/slack/commands',
        form({
          'api_app_id': 'A0TEST',
          'team_id': _team,
          'command': '/cc',
          'response_url': 'https://evil.example/collect',
        }),
        contentType: 'application/x-www-form-urlencoded',
      );
      final events = await _poll(harness, a);
      expect(SlackCommandRef.tryParse(events.single)!.responseUrl, isEmpty);
    });
  });

  test('verifySlackSignature', () {
    final now = DateTime.now().toUtc();
    final ts = '${now.millisecondsSinceEpoch ~/ 1000}';
    final body = utf8.encode('payload');
    final mac = crypto.Hmac(
      crypto.sha256,
      utf8.encode('s1'),
    ).convert([...utf8.encode('v0:$ts:'), ...body]);
    bool check(List<String> secrets, String? sig, {String? at}) =>
        verifySlackSignature(
          secrets: secrets,
          timestamp: at ?? ts,
          signature: sig,
          body: body,
          now: now,
        );
    expect(check(['s1'], 'v0=$mac'), isTrue);
    expect(check(['s2', 's1'], 'v0=$mac'), isTrue);
    expect(check(['s2'], 'v0=$mac'), isFalse);
    expect(check(['s1'], null), isFalse);
    expect(check(const [], 'v0=$mac'), isFalse);
    expect(check(['s1'], 'v0=$mac', at: 'soon'), isFalse);
  });
}
