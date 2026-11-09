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
      ..on('POST', 'https://slack.com/api/oauth.v2.access', (call) {
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
  final done = await harness.browser(
    '/oauth/slack/done',
    cookie: cookieFrom(callback),
  );
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
  String secret = 'signing-secret',
  DateTime? eventTime,
}) => _hook(
  harness,
  '/v1/hooks/slack/events',
  utf8.encode(
    jsonEncode({
      'type': 'event_callback',
      'api_app_id': appId,
      'team_id': team,
      'event_id': eventId,
      'event_time': (eventTime ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000,
      'event': event,
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
        final done = await harness.browser(
          '/oauth/slack/done',
          cookie: cookieFrom(callback),
        );
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

    test(
      'a second sign-in for a team being connected stops before any '
      'exchange',
      () async {
        final first = await _slackOidc(harness, slack, a);
        expect(first.oidc.status, 303);
        final second = await _slackOidc(harness, slack, b);
        expect(second.oidc.status, 409);
        expect(second.oidc.body, contains('already being connected'));
        expect(second.botState, isNull);
        expect(slack.botExchanges, 0);
        // The first one still completes.
        final callback = await harness.browser(
          '/oauth/slack/callback?code=bot-code&state=${first.botState}',
        );
        final done = await harness.browser(
          '/oauth/slack/done',
          cookie: cookieFrom(callback),
        );
        final claim = await harness.call(
          a,
          'POST',
          '/v1/oauth/slack/claim',
          body: OAuthClaimRequest(
            loginId: first.loginId,
            confirmCode: confirmCodeFrom(done.body)!,
            codeVerifier: first.pkce.verifier,
            workspaceId: 'ws1',
          ).toJson(),
        );
        expect(claim.status, 200, reason: claim.body);
        // Once it finished, the team is free for the next sign-in.
        final third = await _slackOidc(harness, slack, a);
        expect(third.oidc.status, 303);
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
      final done = await harness.browser(
        '/oauth/slack/done',
        cookie: cookieFrom(callback),
      );
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
      expect(claim.json, {'error': 'access_denied'});
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
        final done = await harness.browser(
          '/oauth/slack/done',
          cookie: cookieFrom(callback),
        );
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
        expect(claim.json, {'error': 'access_denied'});
        expect(slack.revoked, isEmpty);
        expect(
          (await harness.service.context.bindings.slack('T0VICTIM'))?.installId,
          b.installId,
        );
      },
    );
  });

  group('refresh and revoke', () {
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
