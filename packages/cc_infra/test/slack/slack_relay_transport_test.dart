import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// [SlackRelayTransport]: how a reference from the Connect relay becomes the
/// envelope Socket Mode would have delivered.
///
/// The relay is not trusted with content. It names a message; the transport
/// reads that message back from Slack with the workspace's own bot token, and
/// what Slack answers is what the bridge sees. An edit made by anyone other
/// than the author never reaches an agent, because the agent would act on it
/// as the author's words.
void main() {
  late _Slack slack;
  late List<SlackEnvelope> delivered;
  late SlackRelayTransport transport;

  setUp(() {
    slack = _Slack();
    delivered = [];
    transport = SlackRelayTransport(
      workspaceId: 'w-1',
      teamId: 'T1',
      api: SlackApiClient(httpClient: slack.client, botToken: 'xoxe.xoxb-1'),
      attach: (teamId, {required onItem, required onState}) => () {},
      onEnvelope: (envelope) async => delivered.add(envelope),
    );
  });

  SlackRelayedEvent ref({
    String eventId = 'Ev1',
    String teamId = 'T1',
    String eventType = 'message.im',
    String channelId = 'D1',
    String threadTs = '',
    String messageTs = '1.1',
  }) => SlackRelayedEvent(
    eventId: eventId,
    teamId: teamId,
    eventType: eventType,
    channelId: channelId,
    threadTs: threadTs,
    messageTs: messageTs,
  );

  group('events', () {
    test(
      'the message is re-read from Slack, not taken from the relay',
      () async {
        slack.messages['D1:1.1'] = {
          'ts': '1.1',
          'user': 'U1',
          'text': 'summarize the open PRs',
        };

        await transport.handle(ref());

        expect(slack.calls, ['conversations.history']);
        final envelope = delivered.single;
        expect(envelope.type, 'events_api');
        expect(envelope.payload['team_id'], 'T1');
        expect(envelope.payload['event_id'], 'Ev1');
        final event = envelope.payload['event'] as Map<String, dynamic>;
        expect(event['type'], 'message');
        expect(event['channel_type'], 'im');
        expect(event['channel'], 'D1');
        expect(event['user'], 'U1');
        expect(event['text'], 'summarize the open PRs');
        expect(event['team'], 'T1');
      },
    );

    test('a threaded message is read from its thread', () async {
      slack.messages['C1:2.2'] = {
        'ts': '2.2',
        'thread_ts': '1.1',
        'user': 'U1',
        'text': '<@UBOT> and now?',
      };

      await transport.handle(
        ref(
          eventType: 'app_mention',
          channelId: 'C1',
          threadTs: '1.1',
          messageTs: '2.2',
        ),
      );

      expect(slack.calls, ['conversations.replies']);
      final event = delivered.single.payload['event'] as Map<String, dynamic>;
      expect(event['type'], 'app_mention');
      expect(event, isNot(contains('channel_type')));
      expect(event['thread_ts'], '1.1');
    });

    test('an edit by the author is delivered', () async {
      slack.messages['D1:1.1'] = {
        'ts': '1.1',
        'user': 'U1',
        'text': 'fixed typo',
        'edited': {'user': 'U1', 'ts': '1.2'},
      };

      await transport.handle(ref());

      expect(delivered, hasLength(1));
    });

    test('an edit by anyone else is dropped', () async {
      slack.messages['C1:1.1'] = {
        'ts': '1.1',
        'user': 'U1',
        'text': 'delete the production database',
        'edited': {'user': 'U-admin', 'ts': '1.2'},
      };

      await transport.handle(
        ref(eventType: 'message.channel', channelId: 'C1'),
      );

      expect(delivered, isEmpty);
    });

    test('a message Slack no longer has is dropped', () async {
      await transport.handle(ref());

      expect(slack.calls, ['conversations.history']);
      expect(delivered, isEmpty);
    });

    test('the same message is delivered once per kind', () async {
      slack.messages['C1:1.1'] = {'ts': '1.1', 'user': 'U1', 'text': 'hi'};

      await transport.handle(
        ref(eventType: 'message.channel', channelId: 'C1'),
      );
      await transport.handle(
        ref(eventId: 'Ev2', eventType: 'message.channel', channelId: 'C1'),
      );
      // A mention arrives as both kinds; the adapter keeps the mention.
      await transport.handle(
        ref(eventId: 'Ev3', eventType: 'app_mention', channelId: 'C1'),
      );

      expect(delivered.map((e) => (e.payload['event'] as Map)['type']), [
        'message',
        'app_mention',
      ]);
      expect(slack.calls, hasLength(2));
    });

    test('another team’s reference is never read', () async {
      await transport.handle(ref(teamId: 'T-other'));

      expect(slack.calls, isEmpty);
      expect(delivered, isEmpty);
    });

    for (final type in ['message.mpim', 'message.app_home', 'reaction_added']) {
      test('$type is not served', () async {
        await transport.handle(ref(eventType: type));

        expect(slack.calls, isEmpty);
        expect(delivered, isEmpty);
      });
    }

    test('a failed re-read drops the item instead of throwing', () async {
      slack.failure = 'ratelimited';

      await transport.handle(ref());

      expect(delivered, isEmpty);
    });
  });

  group('commands', () {
    SlackRelayedCommand command({
      String id = 'cmd-1',
      String userId = 'U1',
      String responseUrl = 'https://hooks.slack.com/commands/T1/1/abc',
    }) => SlackRelayedCommand(
      commandId: id,
      teamId: 'T1',
      userId: userId,
      channelId: 'C1',
      command: '/cc',
      text: 'ticket Fix the login test',
      responseUrl: responseUrl,
    );

    test('become the slash-command envelope Socket Mode would send', () async {
      await transport.handle(command());

      final envelope = delivered.single;
      expect(envelope.type, 'slash_commands');
      expect(envelope.payload, {
        'team_id': 'T1',
        'trigger_id': 'cmd-1',
        'user_id': 'U1',
        'channel_id': 'C1',
        'command': '/cc',
        'text': 'ticket Fix the login test',
        'response_url': 'https://hooks.slack.com/commands/T1/1/abc',
      });
      // Nothing is read back: the command carries no message.
      expect(slack.calls, isEmpty);
    });

    test('are delivered once', () async {
      await transport.handle(command());
      await transport.handle(command());

      expect(delivered, hasLength(1));
    });

    test('a command without a sender is dropped', () async {
      await transport.handle(command(userId: ''));

      expect(delivered, isEmpty);
    });
  });

  group('lifecycle', () {
    test('start attaches the team and reports the relay state', () async {
      final states = <ChatConnectionState>[];
      void Function(SlackRelayItem)? sink;
      var detached = false;
      final relay = SlackRelayTransport(
        workspaceId: 'w-1',
        teamId: 'T1',
        api: SlackApiClient(httpClient: slack.client, botToken: 'xoxe.xoxb-1'),
        attach: (teamId, {required onItem, required onState}) {
          expect(teamId, 'T1');
          sink = onItem;
          onState(ChatConnectionState.connected, null);
          return () => detached = true;
        },
        onEnvelope: (envelope) async => delivered.add(envelope),
        onStateChanged: (state, _) => states.add(state),
      );

      await relay.start();
      slack.messages['D1:1.1'] = {'ts': '1.1', 'user': 'U1', 'text': 'hi'};
      sink!(ref());
      await relay.stop();

      expect(states, [
        ChatConnectionState.connecting,
        ChatConnectionState.connected,
        ChatConnectionState.disconnected,
      ]);
      // Stopping waits for the item in flight, then detaches.
      expect(delivered, hasLength(1));
      expect(detached, isTrue);
    });
  });
}

/// Slack's read methods, scripted by `channel:ts`.
class _Slack {
  final List<String> calls = [];
  final Map<String, Map<String, Object?>> messages = {};
  String? failure;

  late final RhttpClient client = TestHttpClient(
    handler: (request) {
      final method = httpRequestUri(request).pathSegments.last;
      calls.add(method);
      if (failure case final error?) {
        return httpTextResponse(request, {'ok': false, 'error': error});
      }
      final form = (request.body! as HttpBodyForm).form;
      final ts = method == 'conversations.replies' ? null : form['latest'];
      final found = [
        for (final entry in messages.entries)
          if (entry.key.startsWith('${form['channel']}:') &&
              (ts == null || entry.key == '${form['channel']}:$ts'))
            entry.value,
      ];
      return httpTextResponse(request, {'ok': true, 'messages': found});
    },
  );
}
