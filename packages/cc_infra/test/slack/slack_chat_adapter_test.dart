import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_infra/cc_infra.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// [SlackChatAdapter] is where every Slack-shaped detail is supposed to stop.
///
/// So these tests are about *normalization*: what the core is allowed to see out
/// of a Socket Mode envelope and what shape a markdown reply takes on its way
/// back. If a Slack quirk (the double-delivered mention, subtype chrome, mrkdwn)
/// escapes this file, it has escaped into provider-agnostic code.
void main() {
  late _Harness h;

  setUp(() => h = _Harness());
  tearDown(() => h.dispose());

  group('inbound normalization', () {
    test('a mention becomes a request with the bot stripped', () async {
      await h.envelope(
        _event('app_mention', user: 'U1', text: '<@BOT> summarize the PRs'),
        id: 'Ev1',
      );

      final event = h.events.single as ChatMessageEvent;
      expect(event.dedupeKey, 'Ev1');
      expect(event.externalTeamId, 'T1');
      expect(event.externalChannelId, 'C1');
      expect(event.externalMessageId, '1.1');
      expect(event.externalUserId, 'U1');
      expect(event.text, 'summarize the PRs');
      expect(event.viaMention, isTrue);
      expect(event.isDm, isFalse);
      expect(event.externalThreadId, isNull);
    });

    test('the duplicate `message` copy of a mention is dropped', () async {
      // Slack delivers a space mention twice, in two envelopes with the same
      // event id. Dropping it here keeps the core from having to know that.
      await h.envelope(
        _event('app_mention', user: 'U1', text: '<@BOT> go'),
        id: 'Ev1',
      );
      await h.envelope(
        _event('message', user: 'U1', text: '<@BOT> go'),
        id: 'Ev1',
      );

      expect(h.events, hasLength(1));
      expect((h.events.single as ChatMessageEvent).viaMention, isTrue);
    });

    test('a plain message is passed on for the core to judge', () async {
      // Whether an unaddressed message is a request depends on whether the
      // thread is bridged, which is a Control Center question.
      await h.envelope(
        _event(
          'message',
          user: 'U1',
          text: 'and also the flaky test',
          ts: '111.2',
          threadTs: '111.1',
        ),
        id: 'Ev2',
      );

      final event = h.events.single as ChatMessageEvent;
      expect(event.viaMention, isFalse);
      expect(event.externalThreadId, '111.1');
      expect(event.externalMessageId, '111.2');
    });

    test('a DM is recognized by channel type and by id shape', () async {
      await h.envelope(
        _event('message', user: 'U1', text: 'hi', spaceType: 'im'),
        id: 'Ev1',
      );
      await h.envelope(
        _event('message', user: 'U1', text: 'hi again', space: 'D100'),
        id: 'Ev2',
      );

      expect(h.events.map((e) => (e as ChatMessageEvent).isDm), [true, true]);
    });

    test('subtype chrome is not a request, but a file share is', () async {
      for (final subtype in [
        'message_changed',
        'message_deleted',
        'channel_join',
        'thread_broadcast',
      ]) {
        await h.envelope(
          _event('message', user: 'U1', text: 'x', subtype: subtype),
          id: 'Ev-$subtype',
        );
      }
      expect(h.events, isEmpty);

      await h.envelope(
        _event(
          'message',
          user: 'U1',
          text: 'here it is',
          subtype: 'file_share',
        ),
        id: 'Ev-file',
      );
      expect(h.events, hasLength(1));
    });

    test('the bot never hears itself', () async {
      await h.envelope({
        'type': 'app_mention',
        'user': 'UOTHER',
        'bot_id': 'B1',
        'channel': 'C1',
        'ts': '1.1',
        'text': 'hi',
      }, id: 'Ev1');
      await h.envelope(
        _event('app_mention', user: 'BOT', text: 'hi'),
        id: 'Ev2',
      );

      expect(h.events, isEmpty);
    });

    test('an event from another Slack team is not served', () async {
      await h.adapter.handleEnvelope(
        SlackEnvelope.fromJson({
          'type': 'events_api',
          'envelope_id': 'e1',
          'payload': {
            'team_id': 'T-other',
            'event_id': 'Ev1',
            'event': _event('app_mention', user: 'U1', text: '<@BOT> go'),
          },
        }),
      );

      expect(h.events, isEmpty);
    });

    test(
      'a slash command is split into verb, rest and a reply handle',
      () async {
        await h.command('/ops', 'Ticket Fix the login test | It fails on CI.');

        final event = h.events.single as ChatCommandEvent;
        // The trigger id is what a redelivery repeats, so it is the dedupe key.
        expect(event.dedupeKey, 'Tr1');
        expect(event.command, '/ops');
        expect(event.verb, 'ticket');
        expect(event.rest, 'Fix the login test | It fails on CI.');
        expect(event.externalUserId, 'U1');
        expect(event.externalChannelId, 'C1');
        expect(event.replyHandle, 'https://hooks.slack.test/commands/Tr1');
      },
    );

    test(
      'a bare command has an empty verb rather than a missing one',
      () async {
        await h.command('/cc', '');

        final event = h.events.single as ChatCommandEvent;
        expect(event.verb, '');
        expect(event.rest, '');
      },
    );
  });

  group('outbound translation', () {
    test('markdown is posted as mrkdwn', () async {
      await h.adapter.postMessage(
        conversationId: 'C1',
        markdown: '**bold** and [a link](https://example.com)',
        threadId: '1.1',
      );

      final posted = h.api.posted.single;
      expect(posted['channel'], 'C1');
      expect(posted['thread_ts'], '1.1');
      expect(posted['text'], '*bold* and <https://example.com|a link>');
    });

    test('a stream append is standard markdown, untouched', () async {
      final handle = await h.adapter.startStream(
        conversationId: 'C1',
        threadId: '1.1',
      );
      await h.adapter.appendStream(handle: handle, markdown: '**bold**');

      expect(h.api.appended.single, '**bold**');
    });

    test('a stream names the member it is answering', () async {
      // Slack refuses to open a stream in a space without both ids
      // (`missing_recipient_team_id`), which costs the live reply entirely.
      await h.adapter.startStream(
        conversationId: 'C1',
        threadId: '1.1',
        recipient: const ChatRecipient(
          externalUserId: 'U7',
          externalTeamId: 'T9',
        ),
      );

      expect(h.api.started.single['recipient_user_id'], 'U7');
      expect(h.api.started.single['recipient_team_id'], 'T9');
    });

    test('a stream for nobody in particular names nobody', () async {
      await h.adapter.startStream(conversationId: 'C1', threadId: '1.1');

      // Absent rather than null: an assistant DM does not need a recipient and
      // an empty argument is not the same as no argument.
      final started = h.api.started.single;
      expect(started.containsKey('recipient_user_id'), isFalse);
      expect(started.containsKey('recipient_team_id'), isFalse);
    });

    test('a plan without streaming refuses permanently', () async {
      h.api.fail('chat.startStream', 'feature_not_enabled');

      await expectLater(
        h.adapter.startStream(conversationId: 'C1', threadId: '1.1'),
        throwsA(
          isA<ChatStreamingUnavailable>()
              .having((e) => e.reason, 'reason', 'feature_not_enabled')
              .having((e) => e.permanent, 'permanent', isTrue),
        ),
      );
    });

    test('an ordinary stream failure is worth retrying', () async {
      h.api.fail('chat.startStream', 'ratelimited');

      await expectLater(
        h.adapter.startStream(conversationId: 'C1', threadId: '1.1'),
        throwsA(
          isA<ChatStreamingUnavailable>().having(
            (e) => e.permanent,
            'permanent',
            isFalse,
          ),
        ),
      );
    });

    test(
      'a command reply without a response url is refused, not thrown',
      () async {
        expect(await h.adapter.respondToCommand(null, markdown: 'hi'), isFalse);
        expect(await h.adapter.respondToCommand('', markdown: 'hi'), isFalse);
        expect(h.api.commandReplies, isEmpty);
      },
    );

    test('a profile is normalized to the port’s shape', () async {
      h.api.users['U3'] = {
        'id': 'U3',
        'name': 'dana',
        'team_id': 'T1',
        'is_bot': false,
        'profile': {'email': 'dana@example.com', 'real_name': 'Dana'},
      };

      final profile = await h.adapter.userProfile('U3');

      expect(profile?.id, 'U3');
      expect(profile?.label, 'Dana');
      expect(profile?.email, 'dana@example.com');
      expect(profile?.isBot, isFalse);
      expect(profile?.teamId, 'T1');
    });

    test('the capability set states Slack’s real limits', () {
      expect(h.adapter.capabilities.streaming, isTrue);
      // Slack only streams into a thread, which is why the core has to know.
      expect(h.adapter.capabilities.streamingRequiresThread, isTrue);
      expect(h.adapter.capabilities.taskCards, isTrue);
      expect(h.adapter.capabilities.maxMessageLength, 39000);
      expect(h.adapter.capabilities.maxStreamChunkLength, lessThan(39000));
    });
  });

  group('task cards', () {
    test('the answer follows the card as its own append', () async {
      final handle = await h.adapter.startStream(
        conversationId: 'C1',
        threadId: '1.1',
        withTaskCard: true,
      );
      expect(h.api.started.single['task_display_mode'], 'plan');

      await h.adapter.appendStream(
        handle: handle,
        markdown: 'Here is what I found.',
        card: _card,
      );

      expect(h.api.appends, hasLength(2));
      final tasks = _maps(h.api.appends.first['chunks']);
      expect(h.api.appends.first.containsKey('markdown_text'), isFalse);
      expect(tasks.first, {
        'type': 'plan_update',
        'title': 'Summarize the open PRs',
      });
      expect(tasks[1]['type'], 'task_update');
      // Slack's plan view ignores markdown mixed into task updates and it
      // refuses markdown_text and chunks on the same call. The answer is a
      // later chunks-only markdown_text append.
      _expectAnswer(h.api.appends.last, 'Here is what I found.');
    });

    test('the card says what the agent is doing and nothing more', () async {
      final handle = await h.adapter.startStream(
        conversationId: 'C1',
        threadId: '1.1',
        withTaskCard: true,
      );

      await h.adapter.appendStream(handle: handle, card: _card);

      // A plan title plus the live work row. The live line is the task's
      // `title` (replaces). Setup has no body; `output` is never sent. The
      // call to action waits until the turn finishes so it is last.
      final chunks = _maps(h.api.appends.single['chunks']);
      expect(chunks.first['type'], 'plan_update');
      expect(chunks.first['title'], 'Summarize the open PRs');
      final task = _tasks(chunks).single;
      expect(task['id'], 'msg-1');
      expect(task.containsKey('task'), isFalse);
      expect(task['title'], 'Checking the diff for the release branch');
      expect(task['status'], 'in_progress');
      expect(task.containsKey('details'), isFalse);
      expect(task.containsKey('output'), isFalse);
      expect(task.containsKey('sources'), isFalse);
    });

    test('a later update does not repeat the call to action', () async {
      final handle = await h.adapter.startStream(
        conversationId: 'C1',
        threadId: '1.1',
        withTaskCard: true,
      );

      await h.adapter.appendStream(
        handle: handle,
        card: _card.copyWith(status: ChatTaskStatus.complete),
      );
      await h.adapter.appendStream(
        handle: handle,
        markdown: 'The answer.',
        card: _card.copyWith(status: ChatTaskStatus.complete),
      );

      expect(h.api.appends, hasLength(3));
      final first = _tasks(_maps(h.api.appends.first['chunks']));
      expect(first.map((t) => t['id']), ['msg-1', 'msg-1-open']);
      expect(first.last['sources'], [
        {
          'type': 'url',
          'url': 'https://cc.example/open/x',
          'text': 'View in Control Center',
        },
      ]);
      final cardUpdate = _maps(h.api.appends[1]['chunks']);
      expect(cardUpdate.any((c) => c.containsKey('sources')), isFalse);
      expect(cardUpdate.any((c) => c.containsKey('output')), isFalse);
      expect(
        cardUpdate.where((c) => c['id'] == 'msg-1').single['status'],
        'complete',
      );
      _expectAnswer(h.api.appends.last, 'The answer.');
    });

    test('a later thought replaces the bullet on the same task', () async {
      final handle = await h.adapter.startStream(
        conversationId: 'C1',
        threadId: '1.1',
        withTaskCard: true,
      );

      const firstCard = ChatTaskCard(
        id: 'msg-1',
        title: 'Summarize the open PRs',
        status: ChatTaskStatus.inProgress,
        narration: 'Working on it…',
        link: ChatTaskLink(
          label: 'View in Control Center',
          url: 'https://cc.example/open/x',
        ),
      );
      await h.adapter.appendStream(handle: handle, card: firstCard);
      await h.adapter.appendStream(
        handle: handle,
        card: ChatTaskCard(
          id: firstCard.id,
          title: firstCard.title,
          status: ChatTaskStatus.inProgress,
          narration: 'Cloning web-app…',
          link: firstCard.link,
        ),
      );

      final first = _tasks(_maps(h.api.appends.first['chunks']));
      final second = _tasks(_maps(h.api.appends.last['chunks']));
      expect(first.single['id'], 'msg-1');
      expect(first.single['title'], 'Working on it…');
      expect(first.single.containsKey('output'), isFalse);
      expect(first.single.containsKey('sources'), isFalse);
      expect(second.single['id'], 'msg-1');
      expect(second.single['title'], 'Cloning web-app…');
      expect(second.single.containsKey('details'), isFalse);
      expect(second.single.containsKey('output'), isFalse);
      expect(second.single.containsKey('sources'), isFalse);
    });

    test('a card over Slack’s chunk ceiling loses its narration', () async {
      final handle = await h.adapter.startStream(
        conversationId: 'C1',
        threadId: '1.1',
        withTaskCard: true,
      );

      await h.adapter.appendStream(
        handle: handle,
        card: _card.copyWith(narration: 'thinking out loud ' * 20),
      );

      // Slack caps a task chunk at 256 characters and answers a longer one with
      // `invalid_arguments`, which costs the card entirely — so the live title
      // is trimmed to fit.
      final task = _tasks(_maps(h.api.appends.single['chunks'])).single;
      expect(task.containsKey('details'), isFalse);
      expect(task.containsKey('output'), isFalse);
      expect((task['title'] as String).length, lessThanOrEqualTo(256));
      expect(task['title'], endsWith('…'));
    });

    test(
      'a finished card keeps the request as title, not the last tool',
      () async {
        final handle = await h.adapter.startStream(
          conversationId: 'C1',
          threadId: '1.1',
          withTaskCard: true,
        );

        await h.adapter.appendStream(
          handle: handle,
          markdown: 'Done.',
          card: const ChatTaskCard(
            id: 'msg-1',
            title: 'Summarize the open PRs',
            status: ChatTaskStatus.complete,
            latestAction: ChatTaskAction(name: 'Bash', detail: 'which swift'),
          ),
        );

        expect(h.api.appends, hasLength(2));
        final chunks = _maps(h.api.appends.first['chunks']);
        expect(chunks.first, {
          'type': 'plan_update',
          'title': 'Summarize the open PRs',
        });
        expect(_tasks(chunks).single['title'], 'Summarize the open PRs');
        _expectAnswer(h.api.appends.last, 'Done.');
      },
    );

    test('a finished card is complete, not in progress', () async {
      final handle = await h.adapter.startStream(
        conversationId: 'C1',
        threadId: '1.1',
        withTaskCard: true,
      );

      await h.adapter.appendStream(
        handle: handle,
        card: _card.copyWith(status: ChatTaskStatus.complete),
      );

      expect(
        _tasks(_maps(h.api.appends.single['chunks'])).map((c) => c['status']),
        everyElement('complete'),
      );
    });

    test('steps become one plan with a row per task', () async {
      final handle = await h.adapter.startStream(
        conversationId: 'C1',
        threadId: '1.1',
        withTaskCard: true,
      );

      await h.adapter.appendStream(
        handle: handle,
        card: const ChatTaskCard(
          id: 'msg-1',
          title: 'Summarize the open PRs',
          status: ChatTaskStatus.inProgress,
          steps: [
            ChatTaskStep(
              id: 'setup-1',
              title: 'Starting the agent…',
              status: ChatTaskStatus.complete,
            ),
            ChatTaskStep(
              id: 'think-1',
              title: 'Thinking…',
              status: ChatTaskStatus.complete,
            ),
            ChatTaskStep(
              id: 'c-1',
              title: 'Bash which swift',
              status: ChatTaskStatus.inProgress,
            ),
          ],
          link: ChatTaskLink(
            label: 'View in Control Center',
            url: 'https://cc.example/open/x',
          ),
        ),
      );

      final chunks = _maps(h.api.appends.single['chunks']);
      expect(chunks.first, {
        'type': 'plan_update',
        'title': 'Summarize the open PRs',
      });
      expect(_tasks(chunks).map((c) => c['id']), ['setup-1', 'think-1', 'c-1']);
      expect(_tasks(chunks).map((c) => c['title']), [
        'Starting the agent…',
        'Thinking…',
        'Bash which swift',
      ]);
      expect(_tasks(chunks).map((c) => c['status']), [
        'complete',
        'complete',
        'in_progress',
      ]);
      expect(_tasks(chunks).any((c) => c.containsKey('sources')), isFalse);
    });

    test(
      'View in Control Center is a trailing row when the turn finishes',
      () async {
        final handle = await h.adapter.startStream(
          conversationId: 'C1',
          threadId: '1.1',
          withTaskCard: true,
        );

        const steps = [
          ChatTaskStep(
            id: 'setup-1',
            title: 'Starting the agent…',
            status: ChatTaskStatus.complete,
          ),
          ChatTaskStep(
            id: 'think-1',
            title: 'Thinking…',
            status: ChatTaskStatus.complete,
          ),
          ChatTaskStep(
            id: 'c-1',
            title: 'Bash which swift',
            status: ChatTaskStatus.inProgress,
          ),
        ];
        const link = ChatTaskLink(
          label: 'View in Control Center',
          url: 'https://cc.example/open/x',
        );
        await h.adapter.appendStream(
          handle: handle,
          card: const ChatTaskCard(
            id: 'msg-1',
            title: 'Summarize the open PRs',
            status: ChatTaskStatus.inProgress,
            steps: steps,
            link: link,
          ),
        );
        await h.adapter.appendStream(
          handle: handle,
          card: ChatTaskCard(
            id: 'msg-1',
            title: 'Summarize the open PRs',
            status: ChatTaskStatus.complete,
            steps: [
              for (final step in steps)
                ChatTaskStep(
                  id: step.id,
                  title: step.title,
                  status: ChatTaskStatus.complete,
                ),
            ],
            link: link,
          ),
        );

        final live = _tasks(_maps(h.api.appends.first['chunks']));
        expect(live.map((c) => c['id']), ['setup-1', 'think-1', 'c-1']);
        expect(live.any((c) => c.containsKey('sources')), isFalse);

        final done = _tasks(_maps(h.api.appends.last['chunks']));
        expect(done.map((c) => c['id']), [
          'setup-1',
          'think-1',
          'c-1',
          'msg-1-open',
        ]);
        expect(done.last['title'], 'View in Control Center');
        expect(done.last['status'], 'complete');
        expect(done.last['sources'], [
          {
            'type': 'url',
            'url': 'https://cc.example/open/x',
            'text': 'View in Control Center',
          },
        ]);
        expect(done.first.containsKey('sources'), isFalse);
      },
    );

    test(
      'thinking details leave once and the answer is the stream body',
      () async {
        final handle = await h.adapter.startStream(
          conversationId: 'C1',
          threadId: '1.1',
          withTaskCard: true,
        );

        const think = ChatTaskStep(
          id: 'think-1',
          title: 'Thinking…',
          status: ChatTaskStatus.complete,
          details: 'Let me start.',
        );
        await h.adapter.appendStream(
          handle: handle,
          card: const ChatTaskCard(
            id: 'msg-1',
            title: 'Yo wassup?',
            status: ChatTaskStatus.inProgress,
            steps: [think],
          ),
        );
        await h.adapter.appendStream(
          handle: handle,
          markdown: 'Hey.',
          card: const ChatTaskCard(
            id: 'msg-1',
            title: 'Yo wassup?',
            status: ChatTaskStatus.complete,
            steps: [think],
          ),
        );

        final first = _tasks(_maps(h.api.appends.first['chunks'])).single;
        expect(first['details'], 'Let me start.');
        expect(h.api.appends, hasLength(3));
        final cardUpdate = _tasks(_maps(h.api.appends[1]['chunks'])).single;
        expect(cardUpdate.containsKey('details'), isFalse);
        _expectAnswer(h.api.appends.last, 'Hey.');
      },
    );

    test('a refused display mode costs the card, never the stream', () async {
      // Thinking Steps is new; if Slack will not take the mode, the reply still
      // has to arrive.
      h.api.failOnce('chat.startStream', 'invalid_arguments');

      final handle = await h.adapter.startStream(
        conversationId: 'C1',
        threadId: '1.1',
        withTaskCard: true,
      );
      await h.adapter.appendStream(handle: handle, markdown: 'The answer.');

      expect(h.api.started.single.containsKey('task_display_mode'), isFalse);
      expect(h.api.appended.single, 'The answer.');

      // And it stops asking for the rest of the connection's life.
      await h.adapter.startStream(
        conversationId: 'C1',
        threadId: '2.1',
        withTaskCard: true,
      );
      expect(h.api.started.last.containsKey('task_display_mode'), isFalse);
    });

    test('a whole post carries the card above the answer', () async {
      await h.adapter.postMessage(
        conversationId: 'C1',
        markdown: '**The** whole answer.',
        threadId: '1.1',
        card: _card.copyWith(
          status: ChatTaskStatus.complete,
          result: 'The whole answer.',
        ),
      );

      final posted = h.api.posted.single;
      // mrkdwn for the notification text, standard markdown in the block.
      expect(posted['text'], '*The* whole answer.');
      final blocks = _maps(posted['blocks']);
      // The block form keeps `task_id` and rich text — the shape the chunk form
      // deliberately does not share.
      expect(blocks.first['type'], 'task_card');
      expect(blocks.first['task_id'], 'msg-1');
      expect(_flatten(blocks.first['details']), contains('Checking the diff'));
      expect(blocks.first.containsKey('output'), isFalse);
      expect(_flatten(blocks.first['sources']), contains('cc.example/open/x'));
      expect(blocks.last, {
        'type': 'markdown',
        'text': '**The** whole answer.',
      });
    });

    test('a whole post of a turn is a plan wrapping the rows', () async {
      await h.adapter.postMessage(
        conversationId: 'C1',
        markdown: 'Done.',
        threadId: '1.1',
        card: const ChatTaskCard(
          id: 'msg-1',
          title: 'Summarize the open PRs',
          status: ChatTaskStatus.complete,
          steps: [
            ChatTaskStep(
              id: 'setup-1',
              title: 'Starting the agent…',
              status: ChatTaskStatus.complete,
            ),
            ChatTaskStep(
              id: 'think-1',
              title: 'Thinking…',
              status: ChatTaskStatus.complete,
              details: 'Let me start.',
            ),
            ChatTaskStep(
              id: 'c-1',
              title: 'Bash which swift',
              status: ChatTaskStatus.complete,
            ),
          ],
          link: ChatTaskLink(
            label: 'View in Control Center',
            url: 'https://cc.example/open/x',
          ),
        ),
      );

      final plan = _maps(h.api.posted.single['blocks']).first;
      expect(plan['type'], 'plan');
      expect(plan['title'], 'Summarize the open PRs');
      final tasks = _maps(plan['tasks']);
      expect(tasks.map((t) => t['task_id']), [
        'setup-1',
        'think-1',
        'c-1',
        'msg-1-open',
      ]);
      expect(tasks.first['type'], 'task_card');
      expect(tasks.first.containsKey('sources'), isFalse);
      expect(_flatten(tasks[1]['details']), contains('Let me start.'));
      expect(_flatten(tasks.last['sources']), contains('cc.example/open/x'));
      expect(tasks.any((t) => t.containsKey('output')), isFalse);
    });

    test('an answer too long for one block is split, not truncated', () async {
      // Long enough to need three blocks, still inside Slack's message ceiling.
      final long = List.filled(1500, 'a paragraph of prose').join('\n\n');

      await h.adapter.postMessage(
        conversationId: 'C1',
        markdown: long,
        threadId: '1.1',
        card: _card,
      );

      final blocks = _maps(h.api.posted.single['blocks']).skip(1).toList();
      expect(blocks.length, greaterThan(1));
      for (final block in blocks) {
        expect((block['text']! as String).length, lessThanOrEqualTo(11900));
      }
      // Nothing was dropped on the way into the blocks.
      expect(
        blocks.map((b) => b['text']! as String).join().replaceAll('\n', ''),
        long.replaceAll('\n', ''),
      );
    });

    test('a post without a card is a plain message', () async {
      await h.adapter.postMessage(conversationId: 'C1', markdown: 'hello');

      expect(h.api.posted.single.containsKey('blocks'), isFalse);
    });

    test('a command reply carries the card as a block', () async {
      final answered = await h.adapter.respondToCommand(
        'https://hooks.slack.test/commands/Tr1',
        markdown: 'Filed **CC-1** — Rotate the certificate.',
        card: _card.copyWith(status: ChatTaskStatus.complete),
      );

      expect(answered, isTrue);
      final reply = h.api.commandPayloads.single;
      // Still mrkdwn, still the notification text.
      expect(reply['text'], 'Filed *CC-1* — Rotate the certificate.');
      expect(_maps(reply['blocks']).single['type'], 'task_card');
    });
  });
}

/// A card mid-turn, with everything a reader is allowed to see on it.
const _card = ChatTaskCard(
  id: 'msg-1',
  title: 'Summarize the open PRs',
  status: ChatTaskStatus.inProgress,
  narration: 'Checking the diff for the release branch',
  actionCount: 3,
  latestAction: ChatTaskAction(name: 'Bash', detail: 'which swift'),
  link: ChatTaskLink(
    label: 'View in Control Center',
    url: 'https://cc.example/open/x',
  ),
);

/// The list of Block Kit maps behind a payload field.
List<Map<String, dynamic>> _maps(Object? value) =>
    (value! as List).cast<Map<String, dynamic>>();

/// Streaming `task_update` chunks, skipping the `plan_update` that leads them.
List<Map<String, dynamic>> _tasks(List<Map<String, dynamic>> chunks) =>
    chunks.where((c) => c['type'] == 'task_update').toList();

/// The answer on a plan stream: a markdown_text chunk, never mixed with
/// task updates or with top-level `markdown_text`.
void _expectAnswer(Map<String, dynamic> sent, String text) {
  expect(sent.containsKey('markdown_text'), isFalse);
  expect(sent['chunks'], [
    {'type': 'markdown_text', 'text': text},
  ]);
}

/// Every string in a rich_text tree, so an assertion can be about the words on
/// the card rather than about Block Kit's nesting.
String _flatten(Object? node) {
  if (node is String) {
    return node;
  }
  if (node is List) {
    return node.map(_flatten).join(' ');
  }
  if (node is Map) {
    return [
      node['text'],
      node['url'],
      node['elements'],
    ].map(_flatten).join(' ');
  }
  return '';
}

Map<String, dynamic> _event(
  String type, {
  required String user,
  required String text,
  String space = 'C1',
  String ts = '1.1',
  String? threadTs,
  String? spaceType,
  String? subtype,
}) => {
  'type': type,
  'user': user,
  'text': text,
  'channel': space,
  'ts': ts,
  'thread_ts': ?threadTs,
  'channel_type': ?spaceType,
  'subtype': ?subtype,
};

/// The adapter over a real [SlackApiClient] speaking to a recording HTTP
/// adapter, so outbound payloads are exercised as Slack would see them.
class _Harness {
  _Harness() {
    api = _SlackApiStub();
    adapter = SlackChatAdapter(
      workspaceId: 'ws-1',
      api: api.client,
      appToken: 'xapp-1',
      botUserId: 'BOT',
      botName: 'controlcenter',
      teamId: 'T1',
    );
    _sub = adapter.events.listen(events.add);
  }

  late final _SlackApiStub api;
  late final SlackChatAdapter adapter;
  final events = <ChatInboundEvent>[];
  late final StreamSubscription<ChatInboundEvent> _sub;
  int _triggers = 0;

  Future<void> envelope(
    Map<String, dynamic> event, {
    required String id,
  }) async {
    await adapter.handleEnvelope(
      SlackEnvelope.fromJson({
        'type': 'events_api',
        'envelope_id': 'env-$id',
        'payload': {'team_id': 'T1', 'event_id': id, 'event': event},
      }),
    );
    // The events stream is a broadcast controller, so a listener sees the event
    // one microtask later.
    await pumpEventQueue();
  }

  Future<void> command(String command, String text) async {
    final trigger = 'Tr${++_triggers}';
    await adapter.handleEnvelope(
      SlackEnvelope.fromJson({
        'type': 'slash_commands',
        'envelope_id': 'env-$trigger',
        'payload': {
          'team_id': 'T1',
          'trigger_id': trigger,
          'command': command,
          'text': text,
          'user_id': 'U1',
          'space_id': 'C1',
          'response_url': 'https://hooks.slack.test/commands/$trigger',
        },
      }),
    );
    await pumpEventQueue();
  }

  void dispose() {
    unawaited(_sub.cancel());
    unawaited(adapter.stop());
  }
}

/// A real [SlackApiClient] over a recording adapter: calls are observed as Slack
/// would see them (method + JSON payload) and any method can be made to fail.
class _SlackApiStub {
  _SlackApiStub() {
    client = SlackApiClient(
      dio: Dio()..httpClientAdapter = _Adapter(this),
      botToken: 'xoxb-1',
    );
  }

  late final SlackApiClient client;

  final List<String> calls = [];
  final List<Map<String, dynamic>> posted = [];
  final List<Map<String, dynamic>> started = [];
  final List<Map<String, dynamic>> appends = [];
  final List<Map<String, dynamic>> commandPayloads = [];
  final Map<String, Map<String, dynamic>> users = {};
  final Map<String, String> _failures = {};
  final Map<String, String> _onceFailures = {};

  /// Text-only appends, which is what most assertions are about.
  List<String> get appended =>
      appends.map((a) => a['markdown_text']).whereType<String>().toList();

  List<String> get commandReplies =>
      commandPayloads.map((r) => r['text'] as String).toList();

  void fail(String method, String error) => _failures[method] = error;

  /// Fails [method] on its next call only — how a refusal the client is expected
  /// to recover from is scripted.
  void failOnce(String method, String error) => _onceFailures[method] = error;

  Map<String, dynamic> handle(String method, Map<String, dynamic> payload) {
    calls.add(method);
    if (_failures[method] case final error?) {
      return {'ok': false, 'error': error};
    }
    if (_onceFailures.remove(method) case final error?) {
      return {'ok': false, 'error': error};
    }
    switch (method) {
      case 'chat.postMessage':
        posted.add(payload);
        return {'ok': true, 'ts': '900.${posted.length}'};
      case 'chat.startStream':
        started.add(payload);
        return {'ok': true, 'ts': '950.1', 'channel': payload['channel']};
      case 'chat.appendStream':
        appends.add(payload);
        return {'ok': true};
      case 'users.info':
        final user = users[payload['user']];
        return user == null
            ? {'ok': false, 'error': 'user_not_found'}
            : {'ok': true, 'user': user};
      case 'response_url':
        commandPayloads.add(payload);
        return {'ok': true};
      default:
        return {'ok': true};
    }
  }
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.stub);

  final _SlackApiStub stub;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final raw = requestStream == null
        ? const <int>[]
        : await requestStream.expand((chunk) => chunk).toList();
    final decoded = raw.isEmpty ? null : jsonDecode(utf8.decode(raw));
    // A slash-command reply goes to Slack's per-invocation response_url, not to
    // a named API method.
    final method = options.path.startsWith('https://slack.com/api/')
        ? options.path.split('/').last
        : 'response_url';
    return ResponseBody.fromString(
      jsonEncode(
        stub.handle(
          method,
          decoded is Map ? Map<String, dynamic>.from(decoded) : const {},
        ),
      ),
      200,
      headers: const {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
