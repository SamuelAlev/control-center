import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:test/test.dart';

/// Covers construction, derived predicates, copyWith preservation, the
/// MessageMention codec and the equality contract for [ChannelMessage].
void main() {
  group('ChannelMessage construction', () {
    test('a populated message round-trips every direct field', () {
      final createdAt = DateTime(2025, 6, 1, 12);
      final message = ChannelMessage(
        id: 'm1',
        channelId: 'ch1',
        conversationId: 'ch1',
        senderId: 'u1',
        senderType: ChannelSenderType.user,
        content: 'hello',
        messageType: ChannelMessageType.text,
        metadata: const {'k': 'v'},
        compacted: true,
        reverted: true,
        revertedAt: 99,
        createdAt: createdAt,
      );

      expect(message.id, 'm1');
      expect(message.channelId, 'ch1');
      expect(message.conversationId, 'ch1');
      expect(message.senderId, 'u1');
      expect(message.senderType, ChannelSenderType.user);
      expect(message.content, 'hello');
      expect(message.messageType, ChannelMessageType.text);
      expect(message.metadata, {'k': 'v'});
      expect(message.compacted, isTrue);
      expect(message.reverted, isTrue);
      expect(message.revertedAt, 99);
      expect(message.createdAt, createdAt);
    });

    test('nullable fields default to null and flags default to false', () {
      final message = ChannelMessage(
        id: 'm1',
        channelId: 'ch1',
        conversationId: 'ch1',
        senderId: 'u1',
        senderType: ChannelSenderType.agent,
        content: 'hi',
        messageType: ChannelMessageType.text,
        createdAt: DateTime(2025, 6, 1),
      );

      expect(message.metadata, isNull);
      expect(message.compacted, isFalse);
      expect(message.reverted, isFalse);
      expect(message.revertedAt, isNull);
    });
  });

  group('ChannelMessage type predicates', () {
    ChannelMessage make(
      ChannelMessageType type, {
      Map<String, dynamic>? meta,
    }) => ChannelMessage(
      id: 'm1',
      channelId: 'ch1',
      conversationId: 'ch1',
      senderId: 'u1',
      senderType: ChannelSenderType.agent,
      content: '',
      messageType: type,
      metadata: meta,
      createdAt: DateTime(2025, 6, 1),
    );

    test('isUser tracks senderType', () {
      expect(
        ChannelMessage(
          id: 'm1',
          channelId: 'ch1',
          conversationId: 'ch1',
          senderId: 'u1',
          senderType: ChannelSenderType.user,
          content: '',
          messageType: ChannelMessageType.text,
          createdAt: DateTime(2025, 6, 1),
        ).isUser,
        isTrue,
      );
      expect(make(ChannelMessageType.text).isUser, isFalse);
    });

    test('each messageType flag maps to its enum value', () {
      expect(make(ChannelMessageType.system).isSystem, isTrue);
      expect(make(ChannelMessageType.ticketCard).isTicket, isTrue);
      expect(make(ChannelMessageType.agentTurn).isAgentTurn, isTrue);
      expect(make(ChannelMessageType.reviewNode).isReviewNode, isTrue);
      expect(make(ChannelMessageType.hireProposal).isHireProposal, isTrue);
      expect(make(ChannelMessageType.reviewSummary).isReviewSummary, isTrue);
      expect(make(ChannelMessageType.plan).isPlan, isTrue);
      expect(make(ChannelMessageType.userQuestion).isUserQuestion, isTrue);
      expect(
        make(ChannelMessageType.orchestrationProposal).isOrchestrationProposal,
        isTrue,
      );
      expect(make(ChannelMessageType.artifact).isArtifact, isTrue);
      expect(make(ChannelMessageType.compaction).isCompaction, isTrue);
    });

    test('a text message is none of the type flags', () {
      final message = make(ChannelMessageType.text);
      expect(message.isSystem, isFalse);
      expect(message.isTicket, isFalse);
      expect(message.isAgentTurn, isFalse);
      expect(message.isReviewNode, isFalse);
      expect(message.isHireProposal, isFalse);
      expect(message.isReviewSummary, isFalse);
      expect(message.isPlan, isFalse);
      expect(message.isUserQuestion, isFalse);
      expect(message.isOrchestrationProposal, isFalse);
      expect(message.isArtifact, isFalse);
      expect(message.isCompaction, isFalse);
    });
  });

  group('ChannelMessage metadata-derived accessors', () {
    test('isContextSummary covers both first-class and legacy compaction', () {
      expect(
        make(ChannelMessageType.compaction).isContextSummary,
        isTrue,
        reason: 'first-class compaction message',
      );
      expect(
        make(
          ChannelMessageType.system,
          meta: const {'compacted': true},
        ).isContextSummary,
        isTrue,
        reason: 'legacy compacted system summary',
      );
      // A non-compaction system summary without the legacy flag is NOT a context
      // summary.
      expect(make(ChannelMessageType.system).isContextSummary, isFalse);
    });

    test('compaction accessors read metadata keys with fallbacks', () {
      final message = make(
        ChannelMessageType.compaction,
        meta: const {
          'tailStartId': 'tail-9',
          'compactionReason': 'manual',
          'compactedIds': ['a', 'b', 7, 'c'],
        },
      );
      expect(message.compactionTailStartId, 'tail-9');
      expect(message.compactionReason, 'manual');
      expect(message.compactedIds, [
        'a',
        'b',
        'c',
      ], reason: 'non-string entries are filtered');

      // Defaults when keys absent.
      final bare = make(ChannelMessageType.compaction);
      expect(bare.compactionTailStartId, isNull);
      expect(bare.compactionReason, 'auto');
      expect(bare.compactedIds, isEmpty);

      // Non-list compactedIds yields empty.
      expect(
        make(
          ChannelMessageType.compaction,
          meta: const {'compactedIds': 'nope'},
        ).compactedIds,
        isEmpty,
      );
    });

    test('question / plan / thread / edit / delete flags read metadata', () {
      expect(
        make(
          ChannelMessageType.userQuestion,
          meta: const {'answered': true},
        ).isQuestionAnswered,
        isTrue,
      );
      expect(make(ChannelMessageType.userQuestion).isQuestionAnswered, isFalse);

      expect(
        make(
          ChannelMessageType.plan,
          meta: const {'planStatus': 'approved'},
        ).planStatus,
        'approved',
      );
      expect(make(ChannelMessageType.plan).planStatus, 'pending');

      expect(
        make(
          ChannelMessageType.text,
          meta: const {'streamComplete': true},
        ).isStreamingComplete,
        isTrue,
      );
      expect(make(ChannelMessageType.text).isStreamingComplete, isFalse);

      expect(
        make(ChannelMessageType.text, meta: const {'editedAt': 1}).isEdited,
        isTrue,
      );
      expect(make(ChannelMessageType.text).isEdited, isFalse);

      expect(
        make(ChannelMessageType.text, meta: const {'deletedAt': 1}).isDeleted,
        isTrue,
      );
      expect(make(ChannelMessageType.text).isDeleted, isFalse);
    });

    test('isReverted mirrors the reverted flag', () {
      expect(
        ChannelMessage(
          id: 'm',
          channelId: 'c',
          conversationId: 'c',
          senderId: 'u',
          senderType: ChannelSenderType.user,
          content: '',
          messageType: ChannelMessageType.text,
          reverted: true,
          createdAt: DateTime(2025, 6, 1),
        ).isReverted,
        isTrue,
      );
      expect(make(ChannelMessageType.text).isReverted, isFalse);
    });
  });

  group('ChannelMessage metadata mutators', () {
    final base = ChannelMessage(
      id: 'm1',
      channelId: 'ch1',
      conversationId: 'ch1',
      senderId: 'u1',
      senderType: ChannelSenderType.agent,
      content: 'hi',
      messageType: ChannelMessageType.text,
      metadata: const {'keep': 'me'},
      createdAt: DateTime(2025, 6, 1),
    );

    test('metadataWithEdited preserves the rest of the map', () {
      final next = base.metadataWithEdited(atEpochMs: 555);
      expect(next, {'keep': 'me', 'editedAt': 555});
    });

    test('metadataWithDeleted marks a soft delete and preserves the rest', () {
      final next = base.metadataWithDeleted(atEpochMs: 777);
      expect(next, {'keep': 'me', 'deletedAt': 777});
    });

    test('metadataWithFeedback sets and removes the feedback entry', () {
      final withFb = base.metadataWithFeedback(
        MessageFeedback.notHelpful,
        atEpochMs: 10,
      );
      expect(withFb['keep'], 'me', reason: 'other entries survive');
      expect(withFb['feedback'], {'value': 'notHelpful', 'at': 10});

      final removed = base.metadataWithFeedback(null, atEpochMs: 10);
      expect(removed.containsKey('feedback'), isFalse);
      expect(removed['keep'], 'me');
    });

    test('metadata mutators work on a null-metadata message', () {
      final noMeta = ChannelMessage(
        id: 'm',
        channelId: 'c',
        conversationId: 'c',
        senderId: 'u',
        senderType: ChannelSenderType.user,
        content: '',
        messageType: ChannelMessageType.text,
        createdAt: DateTime(2025, 6, 1),
      );
      expect(noMeta.metadataWithEdited(atEpochMs: 1), {'editedAt': 1});
      expect(noMeta.metadataWithDeleted(atEpochMs: 1), {'deletedAt': 1});
      expect(
        noMeta.metadataWithFeedback(MessageFeedback.helpful, atEpochMs: 1),
        {
          'feedback': {'value': 'helpful', 'at': 1},
        },
      );
    });

    test(
      'feedback getter returns null when metadata is missing or malformed',
      () {
        expect(base.feedback, isNull, reason: 'no feedback key');
        expect(
          make(
            ChannelMessageType.text,
            meta: const {'feedback': 'string'},
          ).feedback,
          isNull,
          reason: 'feedback is not a map',
        );
      },
    );

    test('feedback getter parses the stored wire value', () {
      expect(
        make(
          ChannelMessageType.text,
          meta: const {
            'feedback': {'value': 'helpful', 'at': 5},
          },
        ).feedback,
        MessageFeedback.helpful,
      );
      expect(
        make(
          ChannelMessageType.text,
          meta: const {
            'feedback': {'value': 'notHelpful', 'at': 5},
          },
        ).feedback,
        MessageFeedback.notHelpful,
      );
    });
  });

  group('ChannelMessage transcript + turn metrics', () {
    test('transcript decodes segments lazily and tolerates bad input', () {
      final withSegs = ChannelMessage(
        id: 'm',
        channelId: 'c',
        conversationId: 'c',
        senderId: 'u',
        senderType: ChannelSenderType.user,
        content: '',
        messageType: ChannelMessageType.agentTurn,
        metadata: const {
          'segments': [
            {'type': 'text', 'ts': 0, 'text': 'answer'},
            {'type': 'reasoning', 'ts': 1, 'text': 'thinking'},
          ],
        },
        createdAt: DateTime(2025, 6, 1),
      );
      expect(withSegs.transcript.length, 2);
      // `late final` caches the decode — a second access returns the same list.
      expect(identical(withSegs.transcript, withSegs.transcript), isTrue);

      // Non-list segments yields empty.
      final bad = ChannelMessage(
        id: 'm',
        channelId: 'c',
        conversationId: 'c',
        senderId: 'u',
        senderType: ChannelSenderType.user,
        content: '',
        messageType: ChannelMessageType.agentTurn,
        metadata: const {'segments': 'nope'},
        createdAt: DateTime(2025, 6, 1),
      );
      expect(bad.transcript, isEmpty);
    });

    test('turn outcome + metrics read metadata.turn/outcome', () {
      final message = ChannelMessage(
        id: 'm',
        channelId: 'c',
        conversationId: 'c',
        senderId: 'u',
        senderType: ChannelSenderType.agent,
        content: '',
        messageType: ChannelMessageType.agentTurn,
        metadata: const {
          'outcome': 'completed',
          'turn': {'durationMs': 1200, 'totalTokens': 800, 'costCents': 4},
        },
        createdAt: DateTime(2025, 6, 1),
      );
      expect(message.turnOutcome, TurnOutcome.completed);
      expect(message.turnDurationMs, 1200);
      expect(message.turnTotalTokens, 800);
      expect(message.turnCostCents, 4);

      // Absent keys.
      final bare = ChannelMessage(
        id: 'm',
        channelId: 'c',
        conversationId: 'c',
        senderId: 'u',
        senderType: ChannelSenderType.agent,
        content: '',
        messageType: ChannelMessageType.agentTurn,
        createdAt: DateTime(2025, 6, 1),
      );
      expect(bare.turnOutcome, isNull);
      expect(bare.turnDurationMs, isNull);
      expect(bare.turnTotalTokens, isNull);
      expect(bare.turnCostCents, isNull);

      // Non-map turn.
      expect(
        ChannelMessage(
          id: 'm',
          channelId: 'c',
          conversationId: 'c',
          senderId: 'u',
          senderType: ChannelSenderType.agent,
          content: '',
          messageType: ChannelMessageType.agentTurn,
          metadata: const {'turn': 'nope'},
          createdAt: DateTime(2025, 6, 1),
        ).turnDurationMs,
        isNull,
      );
    });
  });

  group('ChannelMessage list accessors', () {
    final base = ChannelMessage(
      id: 'm',
      channelId: 'c',
      conversationId: 'c',
      senderId: 'u',
      senderType: ChannelSenderType.user,
      content: '',
      messageType: ChannelMessageType.text,
      createdAt: DateTime(2025, 6, 1),
    );

    test('mentions decode from metadata.mentions, filtering non-maps', () {
      final message = ChannelMessage(
        id: 'm',
        channelId: 'c',
        conversationId: 'c',
        senderId: 'u',
        senderType: ChannelSenderType.user,
        content: '',
        messageType: ChannelMessageType.text,
        metadata: const {
          'mentions': [
            {'agentId': 'a1', 'raw': '@a1'},
            {'agentId': 'u2', 'raw': '@u2', 'principalType': 'user'},
            'not-a-map',
          ],
        },
        createdAt: DateTime(2025, 6, 1),
      );
      expect(message.mentions.length, 2);
      expect(message.mentions[0].agentId, 'a1');
      expect(message.mentions[1].principalType, PrincipalType.user);
      expect(base.mentions, isEmpty);
      expect(
        ChannelMessage(
          id: 'm',
          channelId: 'c',
          conversationId: 'c',
          senderId: 'u',
          senderType: ChannelSenderType.user,
          content: '',
          messageType: ChannelMessageType.text,
          metadata: const {'mentions': 'x'},
          createdAt: DateTime(2025, 6, 1),
        ).mentions,
        isEmpty,
      );
    });

    test('attachments decode from metadata.attachments', () {
      final message = ChannelMessage(
        id: 'm',
        channelId: 'c',
        conversationId: 'c',
        senderId: 'u',
        senderType: ChannelSenderType.user,
        content: '',
        messageType: ChannelMessageType.text,
        metadata: const {
          'attachments': [
            {
              'id': 'att1',
              'path': '/p',
              'name': 'n.png',
              'kind': 'image',
              'size': 10,
            },
            'bad',
          ],
        },
        createdAt: DateTime(2025, 6, 1),
      );
      expect(message.attachments.length, 1);
      expect(message.attachments.single.id, 'att1');
      expect(base.attachments, isEmpty);
    });

    test('entityRefs decode and skip malformed refs', () {
      final message = ChannelMessage(
        id: 'm',
        channelId: 'c',
        conversationId: 'c',
        senderId: 'u',
        senderType: ChannelSenderType.user,
        content: '',
        messageType: ChannelMessageType.text,
        metadata: const {
          'entityRefs': [
            {'type': 'ticket', 'id': 'T-1'},
            {'type': 'unknown', 'id': 'x'},
            {'type': 'pr', 'id': ''},
          ],
        },
        createdAt: DateTime(2025, 6, 1),
      );
      expect(message.entityRefs.length, 1);
      expect(message.entityRefs.single.id, 'T-1');
      expect(base.entityRefs, isEmpty);
    });
  });

  group('ChannelMessage equality', () {
    final createdAt = DateTime(2025, 6, 1);
    ChannelMessage make({
      String id = 'm1',
      String channelId = 'ch',
      Map<String, dynamic>? metadata = const {'k': 'v'},
    }) => ChannelMessage(
      id: id,
      channelId: channelId,
      conversationId: channelId,
      senderId: 'u',
      senderType: ChannelSenderType.agent,
      content: 'x',
      messageType: ChannelMessageType.text,
      metadata: metadata,
      createdAt: createdAt,
    );

    test('identical instances are equal', () {
      final a = make();
      expect(a, a);
    });

    test('deep-equal by value, including a deep metadata comparison', () {
      expect(make(), make());
    });

    test('a differing field breaks equality', () {
      expect(make(id: 'm1') == make(id: 'm2'), isFalse);
      expect(make(channelId: 'a') == make(channelId: 'b'), isFalse);
      expect(
        make(metadata: const {'k': 'v'}) == make(metadata: const {'k': 'w'}),
        isFalse,
      );
    });

    test('hashCode matches for equal instances', () {
      expect(make().hashCode, make().hashCode);
    });

    test('a non-ChannelMessage is never equal', () {
      expect(make() == Object(), isFalse);
    });
  });

  group('ChannelMessage.copyWith', () {
    final base = ChannelMessage(
      id: 'm1',
      channelId: 'ch1',
      conversationId: 'ch1',
      senderId: 'u1',
      senderType: ChannelSenderType.user,
      content: 'orig',
      messageType: ChannelMessageType.text,
      metadata: const {'k': 'v'},
      compacted: true,
      reverted: false,
      revertedAt: 42,
      createdAt: DateTime(2025, 6, 1),
    );

    test('a single-field copyWith preserves every other field', () {
      final next = base.copyWith(content: 'new');
      expect(next.content, 'new');
      expect(next.id, 'm1');
      expect(next.channelId, 'ch1');
      expect(next.conversationId, 'ch1');
      expect(next.senderId, 'u1');
      expect(next.senderType, ChannelSenderType.user);
      expect(next.messageType, ChannelMessageType.text);
      expect(next.metadata, {'k': 'v'});
      expect(next.compacted, isTrue);
      expect(next.reverted, isFalse);
      expect(next.revertedAt, 42);
      expect(next.createdAt, DateTime(2025, 6, 1));
    });

    test('a no-op copyWith is equal to the original', () {
      expect(base.copyWith(), base);
    });

    test('removeMetadata clears metadata to null', () {
      expect(base.copyWith(removeMetadata: true).metadata, isNull);
      // default keeps existing metadata
      expect(base.copyWith().metadata, {'k': 'v'});
    });

    test('removeRevertedAt clears revertedAt to null', () {
      expect(base.copyWith(removeRevertedAt: true).revertedAt, isNull);
      expect(base.copyWith().revertedAt, 42);
    });
  });

  group('MessageMention', () {
    test('a const mention carries every field and aliases principalId', () {
      const mention = MessageMention(
        agentId: 'a1',
        raw: '@a1',
        resolvedVia: 'roster',
        principalType: PrincipalType.user,
      );
      expect(mention.agentId, 'a1');
      expect(mention.raw, '@a1');
      expect(mention.resolvedVia, 'roster');
      expect(mention.principalType, PrincipalType.user);
      expect(mention.principalId, 'a1', reason: 'principalId aliases agentId');
    });

    test('defaults to principalType agent', () {
      const mention = MessageMention(agentId: 'a', raw: '@a');
      expect(mention.principalType, PrincipalType.agent);
      expect(mention.resolvedVia, isNull);
    });

    test(
      'toJson omits principalType for the agent default (pre-§15 compat)',
      () {
        const mention = MessageMention(agentId: 'a1', raw: '@a1');
        expect(mention.toJson(), {'agentId': 'a1', 'raw': '@a1'});

        const human = MessageMention(
          agentId: 'u1',
          raw: '@u1',
          resolvedVia: 'roster',
          principalType: PrincipalType.user,
        );
        expect(human.toJson(), {
          'agentId': 'u1',
          'raw': '@u1',
          'resolvedVia': 'roster',
          'principalType': 'user',
        });
      },
    );

    test('fromJson tolerates a missing principalType (defaults to agent)', () {
      final mention = MessageMention.fromJson(const {
        'agentId': 'a1',
        'raw': '@a1',
        'resolvedVia': 'roster',
      });
      expect(mention.agentId, 'a1');
      expect(mention.resolvedVia, 'roster');
      expect(mention.principalType, PrincipalType.agent);
    });

    test('fromJson honors an explicit principalType', () {
      final mention = MessageMention.fromJson(const {
        'agentId': 'u1',
        'raw': '@u1',
        'principalType': 'user',
      });
      expect(mention.principalType, PrincipalType.user);
    });

    test('a mention round-trips through toJson then fromJson', () {
      const original = MessageMention(
        agentId: 'u9',
        raw: '@u9',
        resolvedVia: 'roster',
        principalType: PrincipalType.user,
      );
      final decoded = MessageMention.fromJson(original.toJson());
      expect(decoded, original);
    });

    test('equality is by value and hashCode is stable', () {
      const a = MessageMention(agentId: 'a', raw: '@a');
      const b = MessageMention(agentId: 'a', raw: '@a');
      const c = MessageMention(
        agentId: 'a',
        raw: '@a',
        principalType: PrincipalType.user,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse, reason: 'different principalType');
      expect(a == Object(), isFalse);
    });
  });

  group('MessageFeedback', () {
    test('wireName is the enum name', () {
      expect(MessageFeedback.helpful.wireName, 'helpful');
      expect(MessageFeedback.notHelpful.wireName, 'notHelpful');
    });

    test('fromWire parses known values and nulls unknown ones', () {
      expect(MessageFeedback.fromWire('helpful'), MessageFeedback.helpful);
      expect(
        MessageFeedback.fromWire('notHelpful'),
        MessageFeedback.notHelpful,
      );
      expect(MessageFeedback.fromWire('thumbs'), isNull);
      expect(MessageFeedback.fromWire(null), isNull);
    });
  });
}

/// Local `make` helper for terser predicate construction in this file.
ChannelMessage make(ChannelMessageType type, {Map<String, dynamic>? meta}) =>
    ChannelMessage(
      id: 'm1',
      channelId: 'ch1',
      conversationId: 'ch1',
      senderId: 'u1',
      senderType: ChannelSenderType.agent,
      content: '',
      messageType: type,
      metadata: meta,
      createdAt: DateTime(2025, 6, 1),
    );
