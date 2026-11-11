import 'dart:async';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectErrorCode, ConnectException;
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/chat/slack_connect.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:test/test.dart';

/// The Connect side of the shared Slack app: the relay poller and the
/// in-memory bot token.
///
/// The properties pinned here are the ones a mistake would turn into an
/// outage or a confused deputy: a burst of Slack calls renews the token once;
/// only a grant Connect refuses for good is forgotten, never one that merely
/// could not be renewed right now; a renewed seal is saved before anything
/// else can fail; and a renewed token for a different bot is never used.
void main() {
  group('the relay poller', () {
    late List<Object> polls;
    late List<Duration> sleeps;
    late ConnectSlackEventClient client;
    late Completer<void> idle;

    setUp(() {
      polls = [];
      sleeps = [];
      idle = Completer<void>();
      client = ConnectSlackEventClient(
        poll: () async {
          if (polls.isEmpty) {
            // Park the loop until the test closes the client.
            if (!idle.isCompleted) {
              idle.complete();
            }
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return const [];
          }
          final next = polls.removeAt(0);
          if (next is Exception) {
            throw next;
          }
          return (next as List).cast<Map<String, Object?>>();
        },
        sleep: (delay) async => sleeps.add(delay),
      );
    });

    tearDown(() => client.close());

    Map<String, Object?> event(String id, {String team = 'T1'}) => {
      'kind': 'event',
      'event_id': id,
      'team_id': team,
      'event_type': 'message.im',
      'channel_id': 'D1',
      'message_ts': '1.1',
    };

    Map<String, Object?> command(String id, {String team = 'T1'}) => {
      'kind': 'command',
      'command_id': id,
      'team_id': team,
      'user_id': 'U1',
      'channel_id': 'C1',
      'command': '/cc',
      'text': 'help',
      'response_url': 'https://hooks.slack.com/commands/T1/1/x',
    };

    test('routes each item to the team that attached', () async {
      final t1 = <SlackRelayItem>[];
      final t2 = <SlackRelayItem>[];
      polls.add([
        event('Ev1'),
        command('c-1', team: 'T2'),
        event('Ev3', team: 'T9'),
      ]);

      client
        ..attach('T1', onItem: t1.add, onState: (_, _) {})
        ..attach('T2', onItem: t2.add, onState: (_, _) {});
      await idle.future;

      expect(t1.single, isA<SlackRelayedEvent>());
      expect((t1.single as SlackRelayedEvent).eventId, 'Ev1');
      final routed = t2.single as SlackRelayedCommand;
      expect(routed.commandId, 'c-1');
      expect(routed.responseUrl, 'https://hooks.slack.com/commands/T1/1/x');
      // T9 attached nowhere: dropped, not buffered.
    });

    test('a redelivered item is routed once', () async {
      final seen = <SlackRelayItem>[];
      polls
        ..add([event('Ev1'), command('c-1')])
        ..add([event('Ev1'), command('c-1')]);

      client.attach('T1', onItem: seen.add, onState: (_, _) {});
      await idle.future;

      expect(seen, hasLength(2));
    });

    test('a malformed item is skipped, not fatal', () async {
      final seen = <SlackRelayItem>[];
      polls.add([
        {'kind': 'event', 'team_id': 'T1'},
        {'kind': 'command', 'command_id': 'c-1'},
        event('Ev2'),
      ]);

      client.attach('T1', onItem: seen.add, onState: (_, _) {});
      await idle.future;

      expect(seen.map((i) => (i as SlackRelayedEvent).eventId), ['Ev2']);
    });

    test('attaching a team again replaces its sink', () async {
      final first = <SlackRelayItem>[];
      final second = <SlackRelayItem>[];
      polls.add([event('Ev1')]);
      final detachFirst = client.attach(
        'T1',
        onItem: first.add,
        onState: (_, _) {},
      );
      client.attach('T1', onItem: second.add, onState: (_, _) {});
      // The replaced sink's detach must not remove its replacement.
      detachFirst();
      await idle.future;
      await pumpEventQueue();

      expect(client.attachedTeams, ['T1']);
      expect(first, isEmpty);
      expect(second, hasLength(1));
    });

    test('failures back off and are reported, then recover', () async {
      final states = <(ChatConnectionState, String?)>[];
      polls
        ..add(const ConnectException(ConnectErrorCode.providerUnavailable))
        ..add(Exception('socket closed'))
        ..add(<Map<String, Object?>>[]);

      client.attach(
        'T1',
        onItem: (_) {},
        onState: (state, error) => states.add((state, error)),
      );
      await idle.future;

      expect(sleeps, [const Duration(seconds: 1), const Duration(seconds: 2)]);
      expect(states, [
        (ChatConnectionState.connecting, null),
        (ChatConnectionState.connecting, 'provider_unavailable'),
        (ChatConnectionState.connecting, 'relay_unavailable'),
        (ChatConnectionState.connected, null),
      ]);
    });

    test('the backoff is capped at 32 seconds', () async {
      for (var i = 0; i < 8; i++) {
        polls.add(Exception('down'));
      }
      polls.add(<Map<String, Object?>>[]);

      client.attach('T1', onItem: (_) {}, onState: (_, _) {});
      await idle.future;

      expect(sleeps.last, const Duration(seconds: 32));
      expect(sleeps.map((d) => d.inSeconds), [1, 2, 4, 8, 16, 32, 32, 32]);
    });
  });

  group('the bot token', () {
    late _Grants grants;
    late List<String> persisted;
    late List<String> rejected;
    late DateTime now;
    late SlackAuthIdentity identity;
    late int authTests;

    setUp(() {
      grants = _Grants();
      persisted = [];
      rejected = [];
      now = DateTime.utc(2026, 11, 8, 12);
      identity = const SlackAuthIdentity(
        teamId: 'T1',
        teamName: 'Acme',
        userId: 'UBOT',
        botName: 'controlcenter',
        botId: 'B1',
      );
      authTests = 0;
    });

    SlackConnectSession session({
      DateTime? expiresAt,
      String access = 'xoxe.xoxb-1',
    }) => SlackConnectSession(
      connection: _connection,
      token: ProviderToken(
        accessToken: access,
        expiresAt: expiresAt ?? now.add(const Duration(hours: 12)),
        seal: 'seal-1',
      ),
      grants: grants,
      authTest: (token) async {
        authTests++;
        return identity;
      },
      persist: (token) async => persisted.add(token.seal),
      onRejected: rejected.add,
      clock: () => now,
    );

    ProviderToken renewed(String seal, {String access = 'xoxe.xoxb-2'}) =>
        ProviderToken(
          accessToken: access,
          expiresAt: now.add(const Duration(hours: 12)),
          seal: seal,
        );

    test('a fresh token is used without asking Connect', () async {
      final s = session();

      expect(await s.botToken(), 'xoxe.xoxb-1');
      expect(grants.renewals, 0);
    });

    test('is renewed five minutes before it expires', () async {
      grants.outcomes.add(SlackGrantRenewed(renewed('seal-2')));
      final s = session(expiresAt: now.add(const Duration(minutes: 6)));

      expect(await s.botToken(), 'xoxe.xoxb-1');
      now = now.add(const Duration(minutes: 1, seconds: 1));

      expect(await s.botToken(), 'xoxe.xoxb-2');
      expect(grants.renewals, 1);
    });

    test('a burst of calls renews once', () async {
      final gate = Completer<SlackGrantRenewal>();
      grants.pending = gate;
      final s = session(expiresAt: now);

      final tokens = [for (var i = 0; i < 5; i++) s.botToken()];
      gate.complete(SlackGrantRenewed(renewed('seal-2')));

      expect(await Future.wait(tokens), everyElement('xoxe.xoxb-2'));
      expect(grants.renewals, 1);
      expect(persisted, ['seal-2']);
    });

    test('a token Slack called expired is renewed on demand', () async {
      grants.outcomes.add(SlackGrantRenewed(renewed('seal-2')));
      final s = session();

      expect(await s.botToken(renew: true), 'xoxe.xoxb-2');
    });

    test('the new seal is saved before the token is verified', () async {
      final order = <String>[];
      grants.outcomes.add(SlackGrantRenewed(renewed('seal-2')));
      final s = SlackConnectSession(
        connection: _connection,
        token: ProviderToken(
          accessToken: 'xoxe.xoxb-1',
          expiresAt: now,
          seal: 'seal-1',
        ),
        grants: grants,
        authTest: (token) async {
          order.add('verify');
          throw const SlackApiException('auth.test', 'internal_error');
        },
        persist: (token) async => order.add('persist ${token.seal}'),
        onRejected: rejected.add,
        clock: () => now,
      );

      // A verification outage is not a reason to discard a spent seal's
      // replacement, or to refuse the token.
      expect(await s.botToken(), 'xoxe.xoxb-2');
      expect(order, ['persist seal-2', 'verify']);
      expect(rejected, isEmpty);
    });

    test('a renewed token for another bot is refused for good', () async {
      grants.outcomes.add(SlackGrantRenewed(renewed('seal-2')));
      identity = const SlackAuthIdentity(
        teamId: 'T1',
        teamName: 'Acme',
        userId: 'UBOT',
        botName: 'controlcenter',
        botId: 'B-other',
      );
      final s = session(expiresAt: now);

      await expectLater(
        s.botToken(),
        throwsA(
          isA<SlackApiException>().having(
            (e) => e.error,
            'error',
            'bot_identity_mismatch',
          ),
        ),
      );
      expect(rejected, ['bot_identity_mismatch']);
      expect(s.rejection, 'bot_identity_mismatch');
      // Nothing more is asked of Connect once the grant is known bad.
      await expectLater(s.botToken(), throwsA(isA<SlackApiException>()));
      expect(grants.renewals, 1);
    });

    test('a renewal that is not a rotating bot token is refused', () async {
      grants.outcomes.add(
        SlackGrantRenewed(renewed('seal-2', access: 'xoxb-2')),
      );
      final s = session(expiresAt: now);

      await expectLater(s.botToken(), throwsA(isA<SlackApiException>()));
      expect(rejected, ['not_a_rotating_bot_token']);
      expect(persisted, isEmpty);
    });

    test('a rejected grant is reported once and never retried', () async {
      grants.outcomes.add(const SlackGrantRejected('needs_sign_in'));
      final s = session(expiresAt: now);

      await expectLater(
        s.botToken(),
        throwsA(
          isA<SlackApiException>()
              .having((e) => e.error, 'error', 'token_revoked')
              .having((e) => e.isAuthFailure, 'isAuthFailure', isTrue),
        ),
      );
      await expectLater(s.botToken(), throwsA(isA<SlackApiException>()));

      expect(rejected, ['needs_sign_in']);
      expect(grants.renewals, 1);
      expect(authTests, 0);
    });

    test('an unavailable renewal keeps the grant and tries again', () async {
      grants.outcomes
        ..add(const SlackGrantUnavailable('provider_unavailable'))
        ..add(SlackGrantRenewed(renewed('seal-2')));
      final s = session(expiresAt: now);

      await expectLater(
        s.botToken(),
        throwsA(
          isA<SlackApiException>()
              .having((e) => e.error, 'error', 'provider_unavailable')
              .having((e) => e.isAuthFailure, 'isAuthFailure', isFalse),
        ),
      );
      expect(rejected, isEmpty);

      expect(await s.botToken(), 'xoxe.xoxb-2');
      expect(s.token.seal, 'seal-2');
    });
  });

  group('the relay hub', () {
    late _RoutedConnect connect;
    late ConnectSlackRelayHub hub;
    late List<(String, String?)> states;

    setUp(() {
      connect = _RoutedConnect();
      hub = ConnectSlackRelayHub(
        connect: connect,
        sleep: (_) => Completer<void>().future,
      );
      states = [];
    });
    tearDown(() => hub.close());

    void Function() attach(String workspaceId, String teamId) => hub.attach(
      workspaceId,
      teamId,
      onItem: (_) {},
      onState: (state, error) => states.add((teamId, error)),
    );

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test(
      'one loop per origin, polled at the workspace-chosen target',
      () async {
        connect.targets['ws-a'] = _target('https://a.example', 'ws-a');
        connect.targets['ws-b'] = _target('https://a.example', '');
        connect.targets['ws-c'] = _target('https://c.example', 'ws-c');
        attach('ws-a', 'T-A');
        attach('ws-b', 'T-B');
        attach('ws-c', 'T-C');
        await settle();
        expect(hub.origins.toSet(), {'https://a.example', 'https://c.example'});
        // Both teams at a.example share its one queue, through the guarded
        // target a workspace admin chose.
        expect(
          connect.polled.where((t) => t.origin == 'https://a.example'),
          everyElement(predicate<ConnectTarget>((t) => t.guarded)),
        );
      },
    );

    test('a workspace choice change moves only that workspace', () async {
      connect.targets['ws-a'] = _target('https://a.example', 'ws-a');
      connect.targets['ws-b'] = _target('https://a.example', 'ws-b');
      attach('ws-a', 'T-A');
      attach('ws-b', 'T-B');
      await settle();

      connect.targets['ws-a'] = ConnectTarget.none;
      await hub.rehome('ws-a');
      expect(states.last, ('T-A', 'connect_changed'));

      connect.targets['ws-a'] = _target('https://c.example', 'ws-a');
      await hub.rehome('ws-a');
      await settle();
      expect(hub.origins.toSet(), {'https://a.example', 'https://c.example'});
      expect(
        connect.polled.map((t) => t.origin),
        contains('https://c.example'),
      );
    });
  });
}

ConnectTarget _target(String url, String pinScope) => ConnectTarget(
  mode: ConnectMode.custom,
  baseUrl: url,
  pinScope: pinScope,
  guarded: pinScope.isNotEmpty,
);

/// A Connect whose per-workspace target the test sets, and whose relay
/// polls never answer.
final class _RoutedConnect extends ConnectClient {
  _RoutedConnect()
    : super(
        settings: ConnectSettings(
          secrets: FileSecretsStore(dataDir: Directory.systemTemp.path),
        ),
      );

  final Map<String, ConnectTarget> targets = {};
  final List<ConnectTarget> polled = [];

  @override
  Future<ConnectTarget> targetFor(String? workspaceId) async =>
      targets[workspaceId] ?? ConnectTarget.none;

  @override
  Future<List<Map<String, Object?>>> pollEvents(ConnectTarget target) {
    polled.add(target);
    return Completer<List<Map<String, Object?>>>().future;
  }
}

final _connection = ChatBridgeConnection(
  provider: ChatProvider.slack,
  workspaceId: 'w-1',
  credentials: const {'grant': '{"seal":"seal-1"}'},
  mode: ChatConnectionMode.connect,
  appId: 'A1',
  teamId: 'T1',
  teamName: 'Acme',
  botUserId: 'UBOT',
  botId: 'B1',
  botName: 'controlcenter',
  connectedAt: DateTime.utc(2026),
);

class _Grants implements SlackConnectGrants {
  final List<SlackGrantRenewal> outcomes = [];
  Completer<SlackGrantRenewal>? pending;
  int renewals = 0;

  @override
  SlackRelayAttach attachFor(String workspaceId) =>
      (teamId, {required onItem, required onState}) => () {};

  @override
  Future<SlackGrantRenewal> renew(
    ProviderToken sealed, {
    required String workspaceId,
  }) async {
    renewals++;
    if (pending case final gate?) {
      return gate.future;
    }
    return outcomes.removeAt(0);
  }

  @override
  Future<void> revoke(ProviderToken sealed, {required String workspaceId}) =>
      throw UnimplementedError();
}
