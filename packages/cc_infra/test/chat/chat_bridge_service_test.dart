import 'dart:async';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_space_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/repositories/chat_link_repositories.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_link_method.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_capabilities.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

/// [ChatBridgeService]: who may drive an agent from a chat app, what crosses the
/// boundary once and how a reply gets back — all of it against a fake provider,
/// because none of it is allowed to depend on which product is on the other side.
///
/// The access tests are the ones that matter most. A chat message carries no
/// Control Center identity, so the bridge is the chokepoint where "some chat
/// account said this" becomes "this workspace member said this" — and the failure
/// mode of getting it wrong is silently acting as somebody else.
void main() {
  late _Harness h;

  setUp(() => h = _Harness());
  tearDown(() => h.dispose());

  group('access', () {
    test('a linked writing member drives an agent', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();

      await h.mention('U1', text: 'summarize the open PRs');

      expect(h.messaging.dispatched, hasLength(1));
      final sent = h.messaging.dispatched.single;
      expect(sent.senderUserId, 'user-1');
      expect(sent.content, 'summarize the open PRs');
      expect(h.spaceLinks.rows, hasLength(1));
      // Provenance is stamped, which is what stops the outbound mirror echoing —
      // and it names the provider, so a workspace bridged to two apps stays
      // legible.
      final stamp = sent.metadata?['chat'] as Map?;
      expect(stamp?['provider'], 'slack');
      expect(stamp?['userId'], 'U1');
    });

    test('an unlinked chat account is refused with instructions', () async {
      await h.bridge.start();

      await h.mention('U-stranger', text: 'do the thing');

      expect(h.messaging.dispatched, isEmpty);
      expect(h.spaceLinks.rows, isEmpty);
      // Visible in the thread, not ephemeral: an ephemeral anchored to a thread
      // nobody opened raises no unread, so the bridge read as dead.
      expect(h.adapter.ephemerals, isEmpty);
      final refusal = h.adapter.posted.single;
      expect(refusal.threadId, '1.1');
      expect(refusal.markdown, contains('link'));
    });

    test('a linked non-member is refused, never attributed', () async {
      // A link can outlive a membership: the user was removed from the workspace
      // but their chat link row is still there.
      h.link('U1', 'user-outside');
      await h.bridge.start();

      await h.mention('U1', text: 'deploy');

      expect(h.messaging.dispatched, isEmpty);
      expect(h.adapter.posted.single.markdown, contains('not a member'));
    });

    test('a viewer is told their role is read-only', () async {
      h.member('user-2', WorkspaceRole.viewer);
      h.link('U2', 'user-2');
      await h.bridge.start();

      await h.mention('U2', text: 'ship it');

      expect(h.messaging.dispatched, isEmpty);
      expect(h.adapter.posted.single.markdown, contains('read-only'));
    });

    test('a verified provider email links a member on first contact', () async {
      h.adapter.profiles['U3'] = const ChatUserProfile(
        id: 'U3',
        label: 'Dana',
        email: 'dana@example.com',
        teamId: 'T1',
      );
      h.users.add(
        User(
          id: 'user-3',
          handle: 'dana',
          displayName: 'Dana',
          email: 'dana@example.com',
          createdAt: DateTime(2026),
        ),
      );
      h.member('user-3', WorkspaceRole.member);
      await h.bridge.start();

      await h.mention('U3', text: 'hello');

      expect(h.messaging.dispatched.single.senderUserId, 'user-3');
      final link = h.userLinks.rows.single;
      expect(link.userId, 'user-3');
      expect(link.method, ChatLinkMethod.email);
      expect(link.provider, ChatProvider.slack);
    });

    test('an email that matches a non-member links nothing', () async {
      h.adapter.profiles['U4'] = const ChatUserProfile(
        id: 'U4',
        label: 'Outsider',
        email: 'outsider@example.com',
      );
      h.users.add(
        User(
          id: 'user-4',
          handle: 'outsider',
          displayName: 'Outsider',
          email: 'outsider@example.com',
          createdAt: DateTime(2026),
        ),
      );
      await h.bridge.start();

      await h.mention('U4', text: 'hello');

      expect(h.userLinks.rows, isEmpty);
      expect(h.messaging.dispatched, isEmpty);
    });

    test('a bot account is never auto-linked by email', () async {
      h.adapter.profiles['U5'] = const ChatUserProfile(
        id: 'U5',
        label: 'Deploy bot',
        email: 'alex@example.com',
        isBot: true,
      );
      await h.bridge.start();

      await h.mention('U5', text: 'release');

      expect(h.userLinks.rows, isEmpty);
      expect(h.messaging.dispatched, isEmpty);
    });
  });

  group('inbound routing', () {
    test('the same event delivered twice crosses once', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();

      // Providers redeliver whatever they have not seen acknowledged.
      await h.mention('U1', text: 'go', dedupeKey: 'Ev1');
      await h.mention('U1', text: 'go', dedupeKey: 'Ev1');
      await h.mention('U1', text: 'go', dedupeKey: 'Ev2');

      expect(h.messaging.dispatched, hasLength(2));
    });

    test('a thread reply continues the bridged space', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'start', messageId: '111.1');

      // A plain reply in the thread, no mention needed.
      await h.message(
        'U1',
        text: 'and also the flaky test',
        messageId: '111.2',
        threadId: '111.1',
      );

      expect(h.messaging.dispatched, hasLength(2));
      // Same Control Center space: one thread is one conversation.
      expect(
        h.messaging.dispatched.map((d) => d.spaceId).toSet(),
        hasLength(1),
      );
      expect(h.spaceLinks.rows, hasLength(1));
    });

    test('an unbridged plain space message is ignored', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();

      await h.message('U1', text: 'just chatting', messageId: '9.1');
      // A reply in a thread nobody bridged is also somebody else's conversation.
      await h.message(
        'U1',
        text: 'still chatting',
        messageId: '9.2',
        threadId: '9.1',
      );

      expect(h.messaging.dispatched, isEmpty);
    });

    test('a DM needs no mention and is one continuous conversation', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();

      await h.message(
        'U1',
        text: 'what is failing on main?',
        conversationId: 'D100',
        messageId: '200.1',
        isDm: true,
      );
      await h.message(
        'U1',
        text: 'and the release?',
        conversationId: 'D100',
        messageId: '300.1',
        threadId: '300.1',
        isDm: true,
      );

      expect(h.messaging.dispatched, hasLength(2));
      expect(h.spaceLinks.rows, hasLength(1));
      // The DM anchors on the conversation, not a thread.
      expect(h.spaceLinks.rows.single.externalThreadId, isNull);
      // The agent surface gets a status line and a title. Both are deliberately
      // fire-and-forget — a provider that refuses them must not delay the reply.
      await pumpEventQueue();
      expect(h.adapter.calls, contains('setThreadStatus'));
      expect(h.adapter.calls, contains('setThreadTitle'));
      expect(h.spaceLinks.rows.single.ccSpaceId, isNotEmpty);
    });

    test('a provider without threads gets no status line or title', () async {
      h = _Harness(capabilities: _bare);
      h.link('U1', 'user-1');
      await h.bridge.start();

      await h.message(
        'U1',
        text: 'hello',
        conversationId: 'D100',
        messageId: '1.1',
        isDm: true,
      );
      await pumpEventQueue();

      expect(h.adapter.calls, isNot(contains('setThreadStatus')));
      expect(h.adapter.calls, isNot(contains('setThreadTitle')));
      // The message still crossed: chrome degrades, the feature does not.
      expect(h.messaging.dispatched, hasLength(1));
    });

    test('the bot never answers itself', () async {
      await h.bridge.start();

      await h.mention('BOT', text: 'hi');

      expect(h.messaging.dispatched, isEmpty);
    });

    test(
      'an empty mention asks for a request instead of dispatching',
      () async {
        h.link('U1', 'user-1');
        await h.bridge.start();

        await h.mention('U1', text: '');

        expect(h.messaging.dispatched, isEmpty);
        expect(
          h.adapter.posted.single.markdown,
          contains('Tell me what you need'),
        );
      },
    );

    test('a refusal reaches a provider without ephemerals', () async {
      h = _Harness(capabilities: _bare);
      await h.bridge.start();

      await h.mention('U-stranger', text: 'do the thing');

      // Posting a message is the one capability every provider has, so the
      // person who asked always hears why nothing happened.
      final refusal = h.adapter.posted.single;
      expect(refusal.threadId, '1.1');
      expect(refusal.markdown, contains('link'));
      expect(h.messaging.dispatched, isEmpty);
    });

    test(
      'a stale link whose space was deleted is rebuilt in place',
      () async {
        h.link('U1', 'user-1');
        h.spaceLinks.rows.add(
          ChatSpaceLink(
            id: 'link-1',
            workspaceId: 'ws-1',
            provider: ChatProvider.slack,
            externalTeamId: 'T1',
            externalChannelId: 'C1',
            externalThreadId: '1.1',
            ccSpaceId: 'gone',
            createdByUserId: 'user-1',
            createdAt: DateTime(2026),
            lastActivityAt: DateTime(2026),
          ),
        );
        await h.bridge.start();

        await h.mention('U1', text: 'again', messageId: '1.1');

        // The row is unique on the external tuple, so the id has to be reused.
        expect(h.spaceLinks.rows, hasLength(1));
        expect(h.spaceLinks.rows.single.id, 'link-1');
        expect(h.spaceLinks.rows.single.ccSpaceId, isNot('gone'));
        expect(h.messaging.dispatched, hasLength(1));
      },
    );

    test(
      'the space is named after the request and the conversation',
      () async {
        h.link('U1', 'user-1');
        h.adapter.conversationNames['C1'] = 'engineering';
        await h.bridge.start();

        await h.mention('U1', text: 'Fix the flaky login test');

        expect(
          h.createdSpaces.single,
          '#engineering · Fix the flaky login test',
        );
      },
    );
  });

  group('outbound streaming', () {
    test('streams the agent reply and closes the stream', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      // The mention already opened the stream so Slack is not silent while the
      // agent has said nothing yet.
      expect(h.adapter.startedStreams, 1);

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', SegmentOpened(0, _text('Looking')));
      h.registry.apply('msg-1', const SegmentDelta(0, ' at the diff'));
      await pumpEventQueue();
      // Text appends are still throttled, so a burst of deltas is one call.
      expect(h.adapter.appended, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(h.adapter.startedStreams, 1);
      expect(h.adapter.appended, ['Looking at the diff']);

      h.registry.apply('msg-1', const SegmentDelta(0, '. Done.'));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      // The tail is flushed before the stream closes, exactly once.
      expect(h.adapter.appended, ['Looking at the diff', '. Done.']);
      expect(h.adapter.calls.where((c) => c == 'stopStream'), hasLength(1));
      expect(h.adapter.posted, isEmpty);
      expect(h.bridge.streamingAvailable, isTrue);
    });

    test('reasoning rides the Thinking row; tool output stays out', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply(
        'msg-1',
        SegmentOpened(
          0,
          ReasoningSegment(text: 'private', startedAt: DateTime(2026)),
        ),
      );
      h.registry.apply('msg-1', const SegmentDelta(0, ' thinking'));
      await pumpEventQueue();
      expect(h.adapter.cards.last.narration, 'Thinking…');
      expect(
        h.adapter.cards.any((c) => (c.narration ?? '').contains('private')),
        isFalse,
      );
      expect(_thinkDetails(h.adapter.cards.last), isNull);

      h.registry.apply('msg-1', SegmentOpened(1, _text('The answer.')));
      h.registry.apply('msg-1', const TurnFinished(1, TurnOutcome.completed));
      await pumpEventQueue();

      expect(h.adapter.appended, ['The answer.']);
      expect(_thinkDetails(h.adapter.cards.last), 'private thinking');
      expect(
        h.adapter.cards.any((c) => (c.narration ?? '').contains('private')),
        isFalse,
      );
    });

    test('a provider that refuses streaming falls back to one message', () async {
      h.adapter.streamingRefusal = const ChatStreamingUnavailable(
        'feature_not_enabled',
      );
      h.link('U1', 'user-1');
      var availability = true;
      h.onStreamingAvailability = (value) => availability = value;
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', SegmentOpened(0, _text('Full reply.')));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      expect(availability, isFalse);
      expect(h.bridge.streamingAvailable, isFalse);
      // The whole reply arrives once and nothing was lost to the failed start.
      expect(
        h.adapter.posted.where((p) => p.markdown == 'Full reply.'),
        hasLength(1),
      );

      // A second turn does not retry streaming.
      h.adapter.calls.clear();
      h.registry.register('msg-2', spaceId: spaceId);
      h.registry.apply('msg-2', SegmentOpened(0, _text('Second.')));
      h.registry.apply('msg-2', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();
      expect(h.adapter.calls, isNot(contains('startStream')));
      expect(h.adapter.posted.last.markdown, 'Second.');
    });

    test('the stream is opened for the member who asked', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', SegmentOpened(0, _text('Here.')));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      // Slack will not stream into a space without knowing who the reply is
      // for, so the asker travels with the request rather than being looked up.
      expect(
        h.adapter.lastStreamRecipient,
        const ChatRecipient(externalUserId: 'U1', externalTeamId: 'T1'),
      );
    });

    test('a turn started in Control Center streams to the linker', () async {
      // Nobody asked in chat — the work was started in the app — but the reply
      // still has to arrive live in the thread, so the card is addressed to the
      // member whose link created it.
      h.link('U1', 'user-1');
      h.spaceLinks.rows.add(_storedLink);
      await h.bridge.start();

      h.registry.register('msg-1', spaceId: 'chan-9');
      h.registry.apply('msg-1', SegmentOpened(0, _text('Unprompted.')));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      expect(
        h.adapter.lastStreamRecipient,
        const ChatRecipient(externalUserId: 'U1', externalTeamId: 'T1'),
      );
    });

    test('a link whose creator unlinked names no recipient', () async {
      // Nobody left to address, which costs the live reply on a provider that
      // requires one — never the reply itself.
      h.spaceLinks.rows.add(_storedLink);
      await h.bridge.start();

      h.registry.register('msg-1', spaceId: 'chan-9');
      h.registry.apply('msg-1', SegmentOpened(0, _text('Unprompted.')));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      expect(h.adapter.startedStreams, 1);
      expect(h.adapter.lastStreamRecipient, isNull);
    });

    test('a stream that takes nothing posts the reply whole', () async {
      // A stream can open and then refuse every append (a payload shape the
      // provider will not take). Finishing it would leave the reader an empty
      // message where the answer should be.
      h.adapter.appendFailure = StateError('invalid_arguments');
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', SegmentOpened(0, _text('The whole answer.')));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      expect(h.adapter.startedStreams, 1);
      // Closed rather than left spinning and the reply arrives once, complete.
      expect(h.adapter.calls, contains('stopStream'));
      expect(h.adapter.posted.single.markdown, 'The whole answer.');
    });

    test('a refused card costs the card, not the live reply', () async {
      // The words are the product. A provider that takes them but not the card
      // beside them keeps streaming, without one.
      h.adapter.cardAppendFailure = StateError('invalid_chunks');
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', SegmentOpened(0, _text('First half.')));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      h.registry.apply('msg-1', const SegmentDelta(0, ' Second half.'));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      // The whole reply arrived live and nothing was posted a second time.
      expect(h.adapter.appended, ['First half.', ' Second half.']);
      expect(h.adapter.cards, isEmpty);
      expect(h.adapter.posted, isEmpty);
      // And it stops asking: only the first append carried a card.
      expect(h.adapter.calls.where((c) => c == 'appendStream'), hasLength(3));
    });

    test('a stream that broke mid-reply is not re-posted', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', SegmentOpened(0, _text('First half.')));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(h.adapter.appended, ['First half.']);

      // The reader already has the opening, so re-posting the whole reply would
      // duplicate it — Control Center keeps the complete record instead.
      h.adapter.appendFailure = StateError('service_unavailable');
      h.registry.apply('msg-1', const SegmentDelta(0, ' Second half.'));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      expect(h.adapter.posted, isEmpty);
    });

    test('a provider without streaming posts whole replies', () async {
      h = _Harness(capabilities: _bare);
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', SegmentOpened(0, _text('The whole answer.')));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      // It is never even attempted, so no capability probe is wasted.
      expect(h.adapter.calls, isNot(contains('startStream')));
      expect(h.adapter.posted.single.markdown, 'The whole answer.');
    });

    test('a reply longer than the provider allows is truncated', () async {
      h = _Harness(capabilities: _bare);
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', SegmentOpened(0, _text('x' * 200)));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      final posted = h.adapter.posted.single.markdown;
      expect(posted, startsWith('x' * 100));
      expect(posted, contains('truncated'));
    });

    test('a silent failed turn says so rather than nothing', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.failed));
      await pumpEventQueue();

      expect(h.adapter.appended.single, contains('failed'));
      expect(h.adapter.posted, isEmpty);
    });

    test('a turn in an unbridged space is not relayed', () async {
      await h.bridge.start();
      h.registry.register('msg-1', spaceId: 'other-channel');
      h.registry.apply('msg-1', SegmentOpened(0, _text('Nobody asked.')));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      expect(h.adapter.posted, isEmpty);
      expect(h.adapter.calls, isNot(contains('startStream')));
    });
  });

  group('task cards', () {
    test('the card reports the turn without quoting it', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'summarize the open PRs please');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply(
        'msg-1',
        SegmentOpened(
          0,
          ReasoningSegment(
            text: 'Let me start.\nReading the release diff',
            startedAt: DateTime(2026),
          ),
        ),
      );
      await pumpEventQueue();
      expect(h.adapter.cards.last.narration, 'Thinking…');

      h.registry.apply(
        'msg-1',
        SegmentOpened(1, _tool('Bash', 'c-1', {'command': 'which swift'})),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // A card is worth a stream on its own: it is what says the agent is
      // working, before there is an answer to show. The mention opened it; the
      // turn edits that same card.
      expect(h.adapter.lastStreamWantedCard, isTrue);
      expect(h.adapter.cards.first.narration, 'Working on it…');
      expect(
        h.adapter.cards.map((c) => c.narration),
        containsAll(['Working on it…', 'Thinking…', 'Bash which swift']),
      );
      final card = h.adapter.cards.last;
      expect(card.id, 'setup-$spaceId');
      expect(card.title, 'summarize the open PRs please');
      expect(card.status, ChatTaskStatus.inProgress);
      // The live line is whatever happened last — here the tool replaced
      // "Thinking…". The thought is that row's details, not the message body.
      expect(card.narration, 'Bash which swift');
      expect(card.actionCount, 1);
      expect(card.latestAction?.name, 'Bash');
      expect(card.latestAction?.detail, 'which swift');
      expect(card.steps.map((s) => s.title), [
        'Working on it…',
        'Thinking…',
        'Bash which swift',
      ]);
      expect(card.steps.map((s) => s.status), [
        ChatTaskStatus.complete,
        ChatTaskStatus.complete,
        ChatTaskStatus.inProgress,
      ]);
      expect(card.steps.map((s) => s.id), [
        'setup-$spaceId',
        'setup-$spaceId-think',
        'c-1',
      ]);
      expect(
        card.steps.firstWhere((s) => s.title == 'Thinking…').details,
        'Let me start.\nReading the release diff',
      );
      expect(card.steps.last.details, isNull);
      expect(
        card.link?.url,
        'https://cc.example/open/workspaces/ws-1/spaces/$spaceId',
      );
      // The thought is on the row, not streamed as the reply.
      expect(h.adapter.appended, isEmpty);
    });

    test('a card and the text it explains travel together', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply(
        'msg-1',
        SegmentOpened(0, _tool('Read', 'c-1', {'file_path': 'lib/main.dart'})),
      );
      h.registry.apply('msg-1', SegmentOpened(1, _text('Here it is.')));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // The mention already sent the ack card; the answer rides the next append
      // with the card that explains it, so the two can never disagree.
      expect(h.adapter.appends, hasLength(2));
      expect(h.adapter.appends.first.markdown, isNull);
      expect(h.adapter.appends.last.markdown, 'Here it is.');
      expect(
        h.adapter.appends.last.card?.latestAction?.detail,
        'lib/main.dart',
      );
    });

    test('an unchanged card is not resent', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', SegmentOpened(0, _text('One.')));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      h.registry.apply('msg-1', const SegmentDelta(0, ' Two.'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(h.adapter.appended, ['One.', ' Two.']);
      // Text moved on, the card did not: the last append carries no card.
      expect(h.adapter.appends.last.card, isNull);
      expect(h.adapter.cards, hasLength(1));
    });

    test('the last card of a finished turn says how it ended', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', SegmentOpened(0, _text('Done.')));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      expect(h.adapter.cards.last.status, ChatTaskStatus.complete);
      expect(h.adapter.cards.last.result, 'Done.');

      h.registry.register('msg-2', spaceId: spaceId);
      h.registry.apply('msg-2', SegmentOpened(0, _text('Half an answer.')));
      h.registry.apply('msg-2', const TurnFinished(0, TurnOutcome.interrupted));
      await pumpEventQueue();

      // Interrupted and maxTurns are errors on the card: the reader's question is
      // "did I get an answer" and the honest answer is no.
      expect(h.adapter.cards.last.status, ChatTaskStatus.error);
      expect(h.adapter.cards.last.result, 'Half an answer.');
    });

    test('a wordless failed turn posts its card with the excuse', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.failed));
      await pumpEventQueue();

      // The mention already opened the stream; a wordless failure finishes that
      // same card rather than posting a second message beside it.
      expect(h.adapter.startedStreams, 1);
      expect(h.adapter.posted, isEmpty);
      expect(h.adapter.appended.single, contains('failed'));
      expect(h.adapter.cards.last.status, ChatTaskStatus.error);
      expect(h.adapter.cards.last.result, contains('failed'));
      expect(h.adapter.calls, contains('stopStream'));
    });

    test('the whole-post fallback carries the finished card', () async {
      h.adapter.streamingRefusal = const ChatStreamingUnavailable(
        'feature_not_enabled',
      );
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply(
        'msg-1',
        SegmentOpened(0, _tool('Grep', 'c-1', {'pattern': 'TODO'})),
      );
      h.registry.apply('msg-1', SegmentOpened(1, _text('Full reply.')));
      h.registry.apply('msg-1', const TurnFinished(1, TurnOutcome.completed));
      await pumpEventQueue();

      final posted = h.adapter.posted.single;
      expect(posted.markdown, 'Full reply.');
      expect(posted.card?.status, ChatTaskStatus.complete);
      expect(posted.card?.latestAction?.detail, 'TODO');
    });

    test('a provider without cards behaves exactly as before', () async {
      h = _Harness(capabilities: _slackWithoutCards);
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply(
        'msg-1',
        SegmentOpened(
          0,
          ReasoningSegment(text: 'thinking', startedAt: DateTime(2026)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      // Nothing to say yet, so nothing was opened for the card's sake.
      expect(h.adapter.calls, isNot(contains('startStream')));

      h.registry.apply('msg-1', SegmentOpened(1, _text('The answer.')));
      h.registry.apply('msg-1', const TurnFinished(1, TurnOutcome.completed));
      await pumpEventQueue();

      expect(h.adapter.appended, ['The answer.']);
      expect(h.adapter.cards, isEmpty);
      expect(h.adapter.lastStreamWantedCard, isFalse);
    });

    test('a server nobody can link to still gets a card', () async {
      h = _Harness(linkable: false);
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'explain');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.registry.register('msg-1', spaceId: spaceId);
      h.registry.apply('msg-1', SegmentOpened(0, _text('The answer.')));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      expect(h.adapter.cards.last.link, isNull);
    });

    test('a turn nobody asked for is titled generically', () async {
      // Armed from a stored link at boot rather than by a mention, so there is no
      // request this turn can be named after.
      h.spaceLinks.rows.add(_storedLink);
      await h.bridge.start();

      h.registry.register('msg-1', spaceId: 'chan-9');
      h.registry.apply('msg-1', SegmentOpened(0, _text('Unprompted.')));
      h.registry.apply('msg-1', const TurnFinished(0, TurnOutcome.completed));
      await pumpEventQueue();

      expect(h.adapter.cards.last.title, 'Agent activity');
    });
  });

  group('workspace setup', () {
    test('a mention opens a card before anything else happens', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'fix the flaky test');

      expect(h.adapter.startedStreams, 1);
      expect(h.adapter.lastStreamWantedCard, isTrue);
      final card = h.adapter.cards.single;
      expect(card.title, 'fix the flaky test');
      expect(card.status, ChatTaskStatus.inProgress);
      expect(card.narration, 'Working on it…');
      expect(h.adapter.appended, isEmpty);
    });

    test('the card reports the setup before the agent can answer', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      // A first mention creates the space and creating it clones the repos —
      // minutes in which the agent has said nothing at all.
      h.messaging.whileDispatching = (spaceId) async {
        h.provisioning(
          spaceId,
          step: const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.repo,
            subject: 'acme/widgets',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // The real call returns once the run is registered.
        h.registry.register('msg-1', spaceId: spaceId);
      };
      await h.mention('U1', text: 'fix the flaky test');

      expect(h.adapter.lastStreamWantedCard, isTrue);
      expect(h.adapter.cards.first.narration, 'Working on it…');
      expect(h.adapter.cards.last.narration, 'Cloning acme/widgets…');
      expect(h.adapter.cards.last.status, ChatTaskStatus.inProgress);
      // Setup is a card, never words: the thread carries the answer only.
      expect(h.adapter.appended, isEmpty);
    });

    test('each step replaces the last and readiness is a step too', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      h.messaging.whileDispatching = (spaceId) async {
        h.provisioning(
          spaceId,
          step: const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.prCheckout,
            subject: 'acme/widgets',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        h.provisioning(
          spaceId,
          step: const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.agent,
            subject: 'Reviewer',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        h.provisioning(spaceId, status: SpaceProvisioningStatus.ready);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        h.registry.register('msg-1', spaceId: spaceId);
      };
      await h.mention('U1', text: 'review it');

      expect(h.adapter.cards.map((c) => c.narration), [
        'Working on it…',
        'Checking out the pull request in acme/widgets…',
        'Setting up Reviewer…',
        // Provisioned, but the first token has not landed yet — the same wait a
        // warm space has and worth saying rather than blanking the card.
        'Starting the agent…',
      ]);
      // One card, edited in place, on one stream.
      expect(h.adapter.startedStreams, 1);
      expect(h.adapter.cards.map((c) => c.id).toSet(), hasLength(1));
    });

    test('the turn takes over the card setup opened', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      h.messaging.whileDispatching = (spaceId) async {
        h.provisioning(
          spaceId,
          step: const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.repo,
            subject: 'acme/widgets',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // The real call returns once the run is registered.
        h.registry.register('msg-1', spaceId: spaceId);
      };
      await h.mention('U1', text: 'fix the flaky test');
      final setupCardId = h.adapter.cards.first.id;

      h.registry.apply(
        'msg-1',
        SegmentOpened(
          0,
          ReasoningSegment(
            text: 'Reading the failing test',
            startedAt: DateTime(2026),
          ),
        ),
      );
      await pumpEventQueue();
      expect(h.adapter.cards.last.narration, 'Thinking…');

      h.registry.apply('msg-1', SegmentOpened(1, _text('Fixed.')));
      h.registry.apply('msg-1', const TurnFinished(1, TurnOutcome.completed));
      await pumpEventQueue();

      // The reader is already watching that card in that thread, so the turn
      // continues it instead of opening a second message beside it.
      expect(h.adapter.startedStreams, 1);
      expect(h.adapter.cards.map((c) => c.id).toSet(), {setupCardId});
      expect(h.adapter.appended, ['Fixed.']);
      // Reasoning is a live "Thinking…" line; the thought is that row's details.
      // The finished card drops the live line; the answer is streamed text.
      expect(h.adapter.cards.map((c) => c.narration), contains('Thinking…'));
      expect(h.adapter.cards.last.narration, isNull);
      expect(_thinkDetails(h.adapter.cards.last), 'Reading the failing test');
      expect(h.adapter.cards.last.result, 'Fixed.');
      expect(h.adapter.cards.last.status, ChatTaskStatus.complete);
      expect(h.adapter.calls, contains('stopStream'));
    });

    test('a failed setup says so on the card', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      h.messaging.whileDispatching = (spaceId) async {
        h.provisioning(spaceId, status: SpaceProvisioningStatus.failed);
        await Future<void>.delayed(const Duration(milliseconds: 30));
      };
      await h.mention('U1', text: 'fix the flaky test');

      expect(h.adapter.cards.first.narration, 'Working on it…');
      expect(h.adapter.cards.last.narration, contains('setup failed'));
      expect(h.adapter.cards.last.status, ChatTaskStatus.error);
      expect(h.adapter.calls, contains('stopStream'));
    });

    test('setup after dispatch returns still reaches the card', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'fix the flaky test');
      final spaceId = h.messaging.dispatched.single.spaceId;

      // Production: sendAndDispatch posts the message and fires the run
      // unawaited. The clone that run is gated on is still going.
      h.provisioning(
        spaceId,
        step: const SpaceProvisioningStep(
          kind: SpaceProvisioningStepKind.repo,
          subject: 'acme/widgets',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(h.adapter.cards.first.narration, 'Working on it…');
      expect(h.adapter.cards.last.narration, 'Cloning acme/widgets…');
    });

    test('setup nobody is waiting for is not announced', () async {
      h.link('U1', 'user-1');
      h.spaceLinks.rows.add(_storedLink);
      await h.bridge.start();

      // A boot-time reconciler re-provisioning a stored link, or a space
      // being set up in the app: real progress, but no chat request to report it to.
      h.provisioning(
        'chan-9',
        step: const SpaceProvisioningStep(
          kind: SpaceProvisioningStepKind.repo,
          subject: 'acme/widgets',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(h.adapter.calls, isNot(contains('startStream')));
      expect(h.adapter.cards, isEmpty);
    });

    test('another workspace’s setup is ignored', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      h.messaging.whileDispatching = (spaceId) async {
        h.provisioning(
          spaceId,
          workspaceId: 'ws-2',
          step: const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.repo,
            subject: 'acme/widgets',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
      };
      await h.mention('U1', text: 'fix the flaky test');

      // The mention still opened a card; only the other workspace's progress
      // was ignored, so the narration never became a clone line.
      expect(h.adapter.cards.last.narration, 'Working on it…');
    });

    test('a provider without cards reports no setup at all', () async {
      h = _Harness(capabilities: _slackWithoutCards);
      h.link('U1', 'user-1');
      await h.bridge.start();
      h.messaging.whileDispatching = (spaceId) async {
        h.provisioning(
          spaceId,
          step: const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.repo,
            subject: 'acme/widgets',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
      };
      await h.mention('U1', text: 'fix the flaky test');

      // Nothing to render it with, so the thread stays as it was: quiet until
      // the answer.
      expect(h.adapter.calls, isNot(contains('startStream')));
      expect(h.adapter.posted, isEmpty);
    });

    test('a run waiting for its workspace still gets a card', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      h.messaging.whileDispatching = (spaceId) async {
        // Dispatch registers the run and *then* waits for the clone it needs, so
        // a registered run that has said nothing must not silence the card.
        h.registry.register('msg-1', spaceId: spaceId);
        h.provisioning(
          spaceId,
          step: const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.repo,
            subject: 'acme/widgets',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
      };
      await h.mention('U1', text: 'fix the flaky test');

      expect(h.adapter.cards.first.narration, 'Working on it…');
      expect(h.adapter.cards.last.narration, 'Cloning acme/widgets…');
    });

    test('a ready-only setup does not invent a second message', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      h.messaging.whileDispatching = (spaceId) async =>
          h.provisioning(spaceId, status: SpaceProvisioningStatus.ready);
      await h.mention('U1', text: 'fix the flaky test');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // The ack card is already open, so ready updates it rather than posting
      // a whole reply beside it.
      expect(h.adapter.startedStreams, 1);
      expect(h.adapter.posted, isEmpty);
      expect(h.adapter.cards.last.narration, 'Starting the agent…');
    });
  });

  group('outbound mirror', () {
    test('a message typed in Control Center reaches the chat thread', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'start');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.messages.rows['m-2'] = Message(
        id: 'm-2',
        spaceId: spaceId,
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderType: SenderType.user,
        content: 'one more thing',
        messageType: MessageType.text,
        createdAt: DateTime(2026),
      );
      h.publish(spaceId, 'm-2');
      await pumpEventQueue();

      expect(h.adapter.posted.single.markdown, contains('one more thing'));
      expect(h.adapter.posted.single.markdown, contains('Alex Doe'));
    });

    test('a message that came from the chat app does not echo back', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'start');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.messages.rows['m-1'] = Message(
        id: 'm-1',
        spaceId: spaceId,
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderType: SenderType.user,
        content: 'from the chat app',
        messageType: MessageType.text,
        metadata: const {
          'chat': {'provider': 'slack', 'channelId': 'C1'},
        },
        createdAt: DateTime(2026),
      );
      h.publish(spaceId, 'm-1');
      await pumpEventQueue();

      expect(h.adapter.posted, isEmpty);
    });

    test('another workspace’s message is not mirrored', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();
      await h.mention('U1', text: 'start');
      final spaceId = h.messaging.dispatched.single.spaceId;

      h.publish(spaceId, 'm-3', workspaceId: 'ws-2');
      await pumpEventQueue();

      expect(h.adapter.posted, isEmpty);
    });
  });

  group('commands', () {
    test('ticket files a ticket for the linked reporter', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();

      await h.command('ticket', 'Fix the flaky login test | It fails on CI.');

      final ticket = h.tickets.single;
      expect(ticket.title, 'Fix the flaky login test');
      expect(ticket.description, 'It fails on CI.');
      expect(ticket.reporterUserId, 'user-1');
      expect(h.adapter.commandReplies.single, contains('CC-1'));
      // The confirmation is a finished card whose reason to exist is the link:
      // the reporter's next move is opening the ticket they just filed.
      final card = h.adapter.commandCards.single;
      expect(card?.status, ChatTaskStatus.complete);
      expect(card?.title, 'CC-1 — Fix the flaky login test');
      expect(
        card?.link?.url,
        'https://cc.example/open/workspaces/ws-1/tickets/${ticket.id}',
      );
    });

    test('a refused ticket gets no card, only the reason', () async {
      await h.bridge.start();

      await h.command('ticket', 'Something', user: 'U-stranger');

      expect(h.adapter.commandCards.single, isNull);
    });

    test('a ticket without a description is still filed', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();

      await h.command('ticket', 'Rotate the staging certificate');

      expect(h.tickets.single.description, isNull);
    });

    test('an unlinked account cannot file a ticket', () async {
      await h.bridge.start();

      await h.command('ticket', 'Something', user: 'U-stranger');

      expect(h.tickets, isEmpty);
      expect(h.adapter.commandReplies.single, contains('link'));
    });

    test('a titleless ticket is explained, not filed', () async {
      h.link('U1', 'user-1');
      await h.bridge.start();

      await h.command('ticket', '');

      expect(h.tickets, isEmpty);
      expect(h.adapter.commandReplies.single, contains('title'));
    });

    test('link CODE links this chat account, once', () async {
      final code = h.linkCodes.mint(
        workspaceId: 'ws-1',
        provider: ChatProvider.slack,
        userId: 'user-1',
      );
      await h.bridge.start();

      await h.command('link', code.code);

      expect(h.userLinks.rows.single.userId, 'user-1');
      expect(h.userLinks.rows.single.method, ChatLinkMethod.code);
      expect(h.adapter.commandReplies.single, contains('Linked'));

      // Replaying the same code links nothing further.
      await h.command('link', code.code, user: 'U-other', key: 'cmd-2');
      expect(h.userLinks.rows, hasLength(1));
      expect(h.adapter.commandReplies.last, contains('not valid'));
    });

    test('a code whose member left the workspace is refused', () async {
      final code = h.linkCodes.mint(
        workspaceId: 'ws-1',
        provider: ChatProvider.slack,
        userId: 'user-gone',
      );
      await h.bridge.start();

      await h.command('link', code.code);

      expect(h.userLinks.rows, isEmpty);
      expect(h.adapter.commandReplies.single, contains('no longer a member'));
    });

    test(
      'help and unknown verbs name the command the user actually typed',
      () async {
        await h.bridge.start();

        await h.command('help', '', command: '/ops');
        expect(h.adapter.commandReplies.single, contains('`/ops ticket'));
        expect(h.adapter.commandReplies.single, isNot(contains('/cc')));

        await h.command('frobnicate', '', command: '/ops', key: 'cmd-3');
        expect(
          h.adapter.commandReplies.last,
          contains('I do not know `frobnicate`'),
        );
      },
    );

    test('a renamed command also reaches the linking instructions', () async {
      await h.bridge.start();
      await h.command('help', '', command: '/ops');

      await h.mention('U-stranger', text: 'hello');

      expect(h.adapter.posted.single.markdown, contains('`/ops link CODE`'));
    });

    test(
      'a reply falls back to an ephemeral when the handle is gone',
      () async {
        await h.bridge.start();

        await h.command('help', '', replyHandle: null);

        expect(h.adapter.commandReplies, isEmpty);
        expect(h.adapter.ephemerals.single.markdown, contains('What I can do'));
      },
    );
  });
}

/// A provider whose only capability is posting a message, for the degrade paths.
const _bare = ChatProviderCapabilities(maxMessageLength: 100);

/// Slack's capabilities minus cards, for the "nothing changes" guarantee.
const _slackWithoutCards = ChatProviderCapabilities(
  streaming: true,
  streamingRequiresThread: true,
  ephemeralMessages: true,
  slashCommands: true,
  maxMessageLength: 39000,
  maxStreamChunkLength: 3800,
);

/// A link already in the database when the bridge arms: a space bridged in an
/// earlier run, which nobody has asked anything through yet this one.
final _storedLink = ChatSpaceLink(
  id: 'cl-1',
  workspaceId: 'ws-1',
  provider: ChatProvider.slack,
  externalTeamId: 'T1',
  externalChannelId: 'C9',
  externalThreadId: '9.1',
  ccSpaceId: 'chan-9',
  createdByUserId: 'user-1',
  createdAt: DateTime(2026),
  lastActivityAt: DateTime(2026),
);

TextSegment _text(String text) =>
    TextSegment(text: text, startedAt: DateTime(2026));

ToolSegment _tool(String name, String callId, Map<String, dynamic> inputs) =>
    ToolSegment(
      toolName: name,
      toolCallId: callId,
      inputs: inputs,
      startedAt: DateTime(2026),
    );

/// Wires the bridge over in-memory link stores, a real [ActiveStreamRegistry]
/// and a recording [_FakeChatProviderAdapter] — so the assertions are about the
/// bridge's decisions, not about any provider's payload shapes.
class _Harness {
  _Harness({
    ChatProviderCapabilities capabilities = _slackLike,
    // A server nobody can reach by link is the one case a card carries no call
    // to action, so it is a harness switch rather than a separate fixture.
    bool linkable = true,
  }) {
    adapter = _FakeChatProviderAdapter(capabilities: capabilities);
    registry = ActiveStreamRegistry();
    bridge = ChatBridgeService(
      connection: ChatBridgeConnection(
        provider: ChatProvider.slack,
        workspaceId: 'ws-1',
        credentials: const {'botToken': 'xoxb-1', 'appToken': 'xapp-1'},
        appId: 'A1',
        teamId: 'T1',
        teamName: 'Acme',
        botUserId: 'BOT',
        botName: 'controlcenter',
        connectedAt: DateTime(2026),
      ),
      adapter: adapter,
      descriptor: const ChatProviderDescriptor(
        provider: ChatProvider.slack,
        credentialFields: [],
        capabilities: _slackLike,
      ),
      streamRegistry: registry,
      messaging: messaging,
      messages: messages,
      createSpace: _createSpace,
      spaceLinks: spaceLinks,
      userLinks: userLinks,
      users: users,
      members: members,
      linkCodes: linkCodes,
      eventBus: eventBus,
      createTicket: _createTicket,
      deepLinks: linkable
          ? const ChatDeepLinks(origin: 'https://cc.example')
          : null,
      newId: () => 'id-${++_ids}',
      clock: () => DateTime(2026),
      // Short enough to keep the tests quick, long enough that a burst of deltas
      // still coalesces into one append.
      flushInterval: const Duration(milliseconds: 10),
      onStreamingAvailability: (value) => onStreamingAvailability?.call(value),
    );
    member('user-1', WorkspaceRole.member);
    users.add(
      User(
        id: 'user-1',
        handle: 'alex',
        displayName: 'Alex Doe',
        email: 'alex@example.com',
        createdAt: DateTime(2026),
      ),
    );
  }

  late final _FakeChatProviderAdapter adapter;
  late final ActiveStreamRegistry registry;
  late final ChatBridgeService bridge;
  final messaging = _FakeMessagingPort();
  final messages = _FakeMessages();
  final spaceLinks = _FakeSpaceLinks();
  final userLinks = _FakeUserLinks();
  final users = _FakeUsers();
  final members = _FakeMembers();
  final linkCodes = ChatLinkCodeStore();
  final eventBus = DomainEventBus();
  final createdSpaces = <String>[];
  final tickets =
      <
        ({
          String id,
          String key,
          String title,
          String? description,
          String reporterUserId,
        })
      >[];
  void Function(bool available)? onStreamingAvailability;
  int _ids = 0;
  int _events = 0;

  void member(String userId, WorkspaceRole role) =>
      members.rows[userId] = WorkspaceMember(
        id: 'm-$userId',
        workspaceId: 'ws-1',
        userId: userId,
        role: role,
        joinedAt: DateTime(2026),
      );

  void link(String externalUserId, String userId) => userLinks.rows.add(
    ChatUserLink(
      id: 'ul-$externalUserId',
      workspaceId: 'ws-1',
      provider: ChatProvider.slack,
      externalTeamId: 'T1',
      externalUserId: externalUserId,
      userId: userId,
      method: ChatLinkMethod.code,
      linkedAt: DateTime(2026),
    ),
  );

  Future<void> mention(
    String externalUserId, {
    required String text,
    String conversationId = 'C1',
    String messageId = '1.1',
    String? dedupeKey,
  }) => message(
    externalUserId,
    text: text,
    conversationId: conversationId,
    messageId: messageId,
    dedupeKey: dedupeKey,
    viaMention: true,
  );

  Future<void> message(
    String externalUserId, {
    required String text,
    String conversationId = 'C1',
    String messageId = '1.1',
    String? threadId,
    String? dedupeKey,
    bool viaMention = false,
    bool isDm = false,
  }) => bridge.handleInbound(
    ChatMessageEvent(
      dedupeKey: dedupeKey ?? 'ev-${++_events}',
      externalTeamId: 'T1',
      externalChannelId: conversationId,
      externalThreadId: threadId,
      externalMessageId: messageId,
      externalUserId: externalUserId,
      text: text,
      viaMention: viaMention,
      isDm: isDm,
    ),
  );

  Future<void> command(
    String verb,
    String rest, {
    String user = 'U1',
    String command = '/cc',
    String conversationId = 'C1',
    String key = 'cmd-1',
    Object? replyHandle = 'handle',
  }) => bridge.handleInbound(
    ChatCommandEvent(
      dedupeKey: key,
      externalTeamId: 'T1',
      externalChannelId: conversationId,
      externalUserId: user,
      command: command,
      verb: verb,
      rest: rest,
      replyHandle: replyHandle,
    ),
  );

  void publish(
    String spaceId,
    String messageId, {
    String workspaceId = 'ws-1',
  }) => eventBus.publish(
    MessageReceived(
      spaceId: spaceId,
      messageId: messageId,
      senderName: 'Alex',
      contentPreview: 'preview',
      isAgentMessage: false,
      workspaceId: workspaceId,
      occurredAt: DateTime(2026),
    ),
  );

  /// Announces where a space's workspace provisioning stands, the way
  /// `SpaceProvisioningService` does while it clones and sets up.
  void provisioning(
    String spaceId, {
    SpaceProvisioningStatus status = SpaceProvisioningStatus.provisioning,
    SpaceProvisioningStep? step,
    String workspaceId = 'ws-1',
  }) => eventBus.publish(
    SpaceProvisioningChanged(
      workspaceId: workspaceId,
      spaceId: spaceId,
      status: status,
      step: step,
      occurredAt: DateTime(2026),
    ),
  );

  Future<Space> _createSpace({
    required String workspaceId,
    required String name,
    required String createdByUserId,
  }) async {
    createdSpaces.add(name);
    final space = Space(
      id: 'chan-${++_ids}',
      name: name,
      workspaceId: workspaceId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      kind: SpaceKind.slack,
    );
    messaging.spaces.add(space.id);
    messages.spaces[space.id] = space;
    return space;
  }

  Future<({String id, String key, String title})> _createTicket({
    required String workspaceId,
    required String title,
    required String reporterUserId,
    String? description,
  }) async {
    final key = 'CC-${tickets.length + 1}';
    tickets.add((
      id: 'ticket-$key',
      key: key,
      title: title,
      description: description,
      reporterUserId: reporterUserId,
    ));
    return (id: 'ticket-$key', key: key, title: title);
  }

  void dispose() {
    unawaited(bridge.stop());
    eventBus.dispose();
  }
}

/// Slack's capability set, so the default harness exercises the full-featured
/// path without importing the Slack adapter.
const _slackLike = ChatProviderCapabilities(
  streaming: true,
  streamingRequiresThread: true,
  ephemeralMessages: true,
  threadStatus: true,
  threadTitle: true,
  slashCommands: true,
  taskCards: true,
  maxMessageLength: 39000,
  maxStreamChunkLength: 3800,
);

String? _thinkDetails(ChatTaskCard card) {
  for (final step in card.steps) {
    if (step.title == 'Thinking…') {
      return step.details;
    }
  }
  return null;
}

class _Posted {
  _Posted(this.conversationId, this.threadId, this.markdown, this.card);

  final String conversationId;
  final String? threadId;
  final String markdown;
  final ChatTaskCard? card;
}

/// One `appendStream` call, so a test can assert what travelled together.
class _Appended {
  _Appended(this.markdown, this.card);

  final String? markdown;
  final ChatTaskCard? card;
}

class _Ephemeral {
  _Ephemeral(this.conversationId, this.userId, this.markdown);

  final String conversationId;
  final String userId;
  final String markdown;
}

/// Records what the bridge asked of a provider and can be scripted to refuse.
class _FakeChatProviderAdapter implements ChatProviderAdapter {
  _FakeChatProviderAdapter({required this.capabilities});

  @override
  final ChatProviderCapabilities capabilities;

  final List<String> calls = [];
  final List<_Posted> posted = [];
  final List<_Ephemeral> ephemerals = [];
  final List<_Appended> appends = [];
  final List<String> commandReplies = [];
  final List<ChatTaskCard?> commandCards = [];
  final Map<String, ChatUserProfile> profiles = {};
  final Map<String, String> conversationNames = {};
  int startedStreams = 0;
  bool lastStreamWantedCard = false;
  ChatRecipient? lastStreamRecipient;

  /// Every non-empty markdown chunk, in order — what the reader actually reads.
  List<String> get appended => appends
      .map((a) => a.markdown ?? '')
      .where((markdown) => markdown.isNotEmpty)
      .toList();

  /// Every card the bridge sent, in order.
  List<ChatTaskCard> get cards =>
      appends.map((a) => a.card).whereType<ChatTaskCard>().toList();

  /// When set, [startStream] throws it instead of opening a stream.
  ChatStreamingUnavailable? streamingRefusal;

  /// When set, [appendStream] throws it instead of delivering — how a provider
  /// that opens a stream and then refuses what is sent on it is scripted.
  Object? appendFailure;

  /// When set, [appendStream] throws it only for an append carrying a card, so a
  /// provider that takes the words but not the card can be scripted.
  Object? cardAppendFailure;

  final _events = StreamController<ChatInboundEvent>.broadcast();

  @override
  ChatProvider get provider => ChatProvider.slack;

  @override
  String get botUserId => 'BOT';

  @override
  String get botName => 'controlcenter';

  @override
  String get teamId => 'T1';

  @override
  ChatConnectionState get state => ChatConnectionState.connected;

  @override
  String? get lastError => null;

  @override
  Stream<ChatInboundEvent> get events => _events.stream;

  @override
  Stream<ChatTransportStatus> get status => const Stream.empty();

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<void> stop() async {
    calls.add('stop');
    await _events.close();
  }

  @override
  Future<void> postMessage({
    required String conversationId,
    required String markdown,
    String? threadId,
    ChatTaskCard? card,
  }) async {
    calls.add('postMessage');
    posted.add(_Posted(conversationId, threadId, markdown, card));
  }

  @override
  Future<void> postEphemeral({
    required String conversationId,
    required String userId,
    required String markdown,
    String? threadId,
  }) async {
    calls.add('postEphemeral');
    ephemerals.add(_Ephemeral(conversationId, userId, markdown));
  }

  @override
  Future<ChatStreamHandle> startStream({
    required String conversationId,
    String? threadId,
    bool withTaskCard = false,
    ChatRecipient? recipient,
  }) async {
    calls.add('startStream');
    if (streamingRefusal case final refusal?) {
      throw refusal;
    }
    startedStreams++;
    lastStreamWantedCard = withTaskCard;
    lastStreamRecipient = recipient;
    return _FakeStream();
  }

  @override
  @override
  Future<void> appendStream({
    required ChatStreamHandle handle,
    String? markdown,
    ChatTaskCard? card,
  }) async {
    calls.add('appendStream');
    if (appendFailure case final failure?) {
      throw failure;
    }
    if (card != null) {
      if (cardAppendFailure case final failure?) {
        throw failure;
      }
    }
    appends.add(_Appended(markdown, card));
  }

  @override
  Future<void> stopStream({required ChatStreamHandle handle}) async =>
      calls.add('stopStream');

  @override
  Future<void> setThreadStatus({
    required String conversationId,
    required String threadId,
    required String status,
  }) async => calls.add('setThreadStatus');

  @override
  Future<void> setThreadTitle({
    required String conversationId,
    required String threadId,
    required String title,
  }) async => calls.add('setThreadTitle');

  @override
  Future<bool> respondToCommand(
    Object? replyHandle, {
    required String markdown,
    ChatTaskCard? card,
  }) async {
    calls.add('respondToCommand');
    if (replyHandle == null) {
      return false;
    }
    commandReplies.add(markdown);
    commandCards.add(card);
    return true;
  }

  @override
  Future<String?> conversationName(String conversationId) async {
    calls.add('conversationName');
    return conversationNames[conversationId];
  }

  @override
  Future<ChatUserProfile?> userProfile(String externalUserId) async {
    calls.add('userProfile');
    return profiles[externalUserId];
  }
}

class _FakeStream implements ChatStreamHandle {}

class _Dispatched {
  _Dispatched(this.spaceId, this.content, this.senderUserId, this.metadata);

  final String spaceId;
  final String content;
  final String? senderUserId;
  final Map<String, dynamic>? metadata;
}

class _FakeMessagingPort implements MessagingPort {
  final List<_Dispatched> dispatched = [];
  final Set<String> spaces = {};

  /// What the server does between accepting a request and returning: on a fresh
  /// space that is provisioning the workspace and the real call only returns
  /// once the run is registered. Tests that care about setup put that here.
  Future<void> Function(String spaceId)? whileDispatching;

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async =>
      spaces.contains(spaceId);

  @override
  Future<void> sendAndDispatch(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    Map<String, dynamic>? metadata,
  }) async {
    dispatched.add(_Dispatched(spaceId, content, senderUserId, metadata));
    await whileDispatching?.call(spaceId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// Context and branch surfaces this fake does not exercise.
  @override
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target = 'tool_output',
  }) async => const ConversationShakeResult();

  @override
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input = '',
  }) async => const ConversationSideChannelResult();

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
  }) async => const GuidedGoalStepResult();
}

class _FakeMessages implements MessagingRepository {
  final Map<String, Message> rows = {};
  final Map<String, Space> spaces = {};

  @override
  Future<Message?> getMessageById(
    String workspaceId,
    String messageId,
  ) async => rows[messageId];

  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async =>
      spaces[spaceId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

class _FakeSpaceLinks implements ChatSpaceLinkRepository {
  final List<ChatSpaceLink> rows = [];

  @override
  Future<void> upsert(ChatSpaceLink link) async {
    rows
      ..removeWhere(
        (r) =>
            r.provider == link.provider &&
            r.externalChannelId == link.externalChannelId &&
            r.externalThreadId == link.externalThreadId,
      )
      ..add(link);
  }

  @override
  Future<ChatSpaceLink?> forExternalThread(
    String workspaceId, {
    required ChatProvider provider,
    required String externalChannelId,
    String? externalThreadId,
  }) async => rows
      .where(
        (r) =>
            r.workspaceId == workspaceId &&
            r.provider == provider &&
            r.externalChannelId == externalChannelId &&
            r.externalThreadId == externalThreadId,
      )
      .firstOrNull;

  @override
  Future<ChatSpaceLink?> forCcSpace(
    String workspaceId,
    String ccSpaceId,
  ) async => rows
      .where(
        (r) => r.workspaceId == workspaceId && r.ccSpaceId == ccSpaceId,
      )
      .firstOrNull;

  @override
  Future<List<ChatSpaceLink>> forWorkspace(
    String workspaceId, {
    ChatProvider? provider,
  }) async => rows
      .where(
        (r) =>
            r.workspaceId == workspaceId &&
            (provider == null || r.provider == provider),
      )
      .toList();

  @override
  Future<int> delete(String id, {required String workspaceId}) async {
    final before = rows.length;
    rows.removeWhere((r) => r.id == id && r.workspaceId == workspaceId);
    return before - rows.length;
  }
}

class _FakeUserLinks implements ChatUserLinkRepository {
  final List<ChatUserLink> rows = [];

  @override
  Future<void> upsert(ChatUserLink link) async {
    rows
      ..removeWhere(
        (r) =>
            r.provider == link.provider &&
            r.externalTeamId == link.externalTeamId &&
            r.externalUserId == link.externalUserId,
      )
      ..add(link);
  }

  @override
  Future<ChatUserLink?> forExternalUser(
    String workspaceId, {
    required ChatProvider provider,
    required String externalTeamId,
    required String externalUserId,
  }) async => rows
      .where(
        (r) =>
            r.workspaceId == workspaceId &&
            r.provider == provider &&
            r.externalTeamId == externalTeamId &&
            r.externalUserId == externalUserId,
      )
      .firstOrNull;

  @override
  Future<ChatUserLink?> forUser(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  }) async => rows
      .where(
        (r) =>
            r.workspaceId == workspaceId &&
            r.provider == provider &&
            r.userId == userId,
      )
      .firstOrNull;

  @override
  Future<List<ChatUserLink>> forWorkspace(
    String workspaceId, {
    ChatProvider? provider,
  }) async => rows
      .where(
        (r) =>
            r.workspaceId == workspaceId &&
            (provider == null || r.provider == provider),
      )
      .toList();

  @override
  Stream<List<ChatUserLink>> watchForWorkspace(
    String workspaceId, {
    ChatProvider? provider,
  }) => Stream.value(rows);

  @override
  Future<int> deleteForUser(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  }) async {
    final before = rows.length;
    rows.removeWhere(
      (r) =>
          r.workspaceId == workspaceId &&
          r.userId == userId &&
          r.provider == provider,
    );
    return before - rows.length;
  }
}

class _FakeUsers implements UserRepository {
  final List<User> rows = [];

  void add(User user) => rows.add(user);

  @override
  Future<User?> getById(String id) async =>
      rows.where((u) => u.id == id).firstOrNull;

  @override
  Future<User?> getByEmail(String email) async =>
      rows.where((u) => u.email == email).firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMembers implements WorkspaceMembershipRepository {
  final Map<String, WorkspaceMember> rows = {};

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      rows[userId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
