import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/value_objects/message_attachment.dart';
import 'package:control_center/core/domain/value_objects/transcript_segment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testTime = DateTime(2024, 6, 15, 12, 0);

  ChannelMessage createMessage({
    String id = 'msg-1',
    String channelId = 'ch-1',
    String senderId = 'user-1',
    ChannelSenderType senderType = ChannelSenderType.user,
    String content = 'Hello',
    ChannelMessageType messageType = ChannelMessageType.text,
    Map<String, dynamic>? metadata,
    String? parentMessageId,
    bool compacted = false,
    DateTime? createdAt,
  }) {
    return ChannelMessage(
      id: id,
      channelId: channelId,
      senderId: senderId,
      senderType: senderType,
      content: content,
      messageType: messageType,
      metadata: metadata,
      parentMessageId: parentMessageId,
      compacted: compacted,
      createdAt: createdAt ?? testTime,
    );
  }

  group('MessageMention', () {

    group('constructor', () {
      test('creates with required fields', () {
        const m = MessageMention(agentId: 'a1', raw: '@agent-1');
        expect(m.agentId, 'a1');
        expect(m.raw, '@agent-1');
        expect(m.resolvedVia, isNull);
      });

      test('creates with optional resolvedVia', () {
        const m = MessageMention(
          agentId: 'a1',
          raw: '@agent-1',
          resolvedVia: 'roster',
        );
        expect(m.resolvedVia, 'roster');
      });
    });

    group('fromJson/toJson', () {
      test('round-trips with required fields', () {
        final json = {'agentId': 'a1', 'raw': '@agent-1'};
        final m = MessageMention.fromJson(json);
        expect(m.agentId, 'a1');
        expect(m.raw, '@agent-1');
        expect(m.resolvedVia, isNull);
        expect(m.toJson(), json);
      });

      test('round-trips with resolvedVia', () {
        final json = {'agentId': 'a1', 'raw': '@agent-1', 'resolvedVia': 'roster'};
        final m = MessageMention.fromJson(json);
        expect(m.resolvedVia, 'roster');
        expect(m.toJson(), json);
      });

      test('toJson omits resolvedVia when null', () {
        const m = MessageMention(agentId: 'a1', raw: '@agent-1');
        final json = m.toJson();
        expect(json.containsKey('resolvedVia'), isFalse);
      });
    });

    group('== and hashCode', () {
      test('equal for same values', () {
        const a = MessageMention(agentId: 'a1', raw: '@agent-1');
        const b = MessageMention(agentId: 'a1', raw: '@agent-1');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal for different agentId', () {
        const a = MessageMention(agentId: 'a1', raw: '@agent-1');
        const b = MessageMention(agentId: 'a2', raw: '@agent-1');
        expect(a, isNot(equals(b)));
      });

      test('not equal for different resolvedVia', () {
        const a = MessageMention(agentId: 'a1', raw: '@agent-1', resolvedVia: 'x');
        const b = MessageMention(agentId: 'a1', raw: '@agent-1', resolvedVia: 'y');
        expect(a, isNot(equals(b)));
      });
    });
  });

  group('ChannelMessageType', () {
    test('has all expected values', () {
      expect(ChannelMessageType.values, containsAll([
        ChannelMessageType.text,
        ChannelMessageType.system,
        ChannelMessageType.ticketCard,
        ChannelMessageType.agentTurn,
        ChannelMessageType.reviewNode,
        ChannelMessageType.hireProposal,
        ChannelMessageType.reviewSummary,
        ChannelMessageType.plan,
        ChannelMessageType.userQuestion,
      ]));
    });
  });

  group('ChannelSenderType', () {
    test('has user and agent', () {
      expect(ChannelSenderType.values,
          containsAll([ChannelSenderType.user, ChannelSenderType.agent]));
    });
  });

  group('ChannelMessage', () {

    group('constructor', () {
      test('creates with required fields', () {
        final msg = createMessage();
        expect(msg.id, 'msg-1');
        expect(msg.channelId, 'ch-1');
        expect(msg.senderId, 'user-1');
        expect(msg.senderType, ChannelSenderType.user);
        expect(msg.content, 'Hello');
        expect(msg.messageType, ChannelMessageType.text);
        expect(msg.metadata, isNull);
        expect(msg.parentMessageId, isNull);
        expect(msg.compacted, isFalse);
        expect(msg.createdAt, testTime);
      });

      test('creates with all optional fields', () {
        final msg = createMessage(
          metadata: {'key': 'value'},
          parentMessageId: 'parent-1',
          compacted: true,
        );
        expect(msg.metadata, {'key': 'value'});
        expect(msg.parentMessageId, 'parent-1');
        expect(msg.compacted, isTrue);
      });

      test('asserts channelId is not empty', () {
        expect(
          () => ChannelMessage(
            id: 'x',
            channelId: '',
            senderId: 's',
            senderType: ChannelSenderType.user,
            content: '',
            messageType: ChannelMessageType.text,
            createdAt: testTime,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('default compacted is false', () {
        final msg = createMessage();
        expect(msg.compacted, isFalse);
      });
    });

    group('convenience getters', () {
      test('isUser returns true for user sender', () {
        final msg = createMessage(senderType: ChannelSenderType.user);
        expect(msg.isUser, isTrue);
      });

      test('isUser returns false for agent sender', () {
        final msg = createMessage(senderType: ChannelSenderType.agent);
        expect(msg.isUser, isFalse);
      });

      test('isSystem', () {
        final msg = createMessage(messageType: ChannelMessageType.system);
        expect(msg.isSystem, isTrue);
        expect(createMessage().isSystem, isFalse);
      });

      test('isTicket', () {
        final msg = createMessage(messageType: ChannelMessageType.ticketCard);
        expect(msg.isTicket, isTrue);
      });

      test('isAgentTurn', () {
        final msg = createMessage(messageType: ChannelMessageType.agentTurn);
        expect(msg.isAgentTurn, isTrue);
      });

      test('isReviewNode', () {
        final msg = createMessage(messageType: ChannelMessageType.reviewNode);
        expect(msg.isReviewNode, isTrue);
      });

      test('isHireProposal', () {
        final msg = createMessage(messageType: ChannelMessageType.hireProposal);
        expect(msg.isHireProposal, isTrue);
      });

      test('isReviewSummary', () {
        final msg = createMessage(messageType: ChannelMessageType.reviewSummary);
        expect(msg.isReviewSummary, isTrue);
      });

      test('isPlan', () {
        final msg = createMessage(messageType: ChannelMessageType.plan);
        expect(msg.isPlan, isTrue);
      });

      test('isUserQuestion', () {
        final msg = createMessage(messageType: ChannelMessageType.userQuestion);
        expect(msg.isUserQuestion, isTrue);
      });

      test('isQuestionAnswered returns true when metadata answered is true', () {
        final msg = createMessage(metadata: {'answered': true});
        expect(msg.isQuestionAnswered, isTrue);
      });

      test('isQuestionAnswered returns false when missing', () {
        final msg = createMessage();
        expect(msg.isQuestionAnswered, isFalse);
      });

      test('planStatus returns value from metadata', () {
        final msg = createMessage(metadata: {'planStatus': 'approved'});
        expect(msg.planStatus, 'approved');
      });

      test('planStatus defaults to pending', () {
        final msg = createMessage();
        expect(msg.planStatus, 'pending');
      });

      test('isThreadReply returns true when parentMessageId is set', () {
        final msg = createMessage(parentMessageId: 'parent-1');
        expect(msg.isThreadReply, isTrue);
      });

      test('isThreadReply returns false when parentMessageId is null', () {
        final msg = createMessage();
        expect(msg.isThreadReply, isFalse);
      });

      test('isStreamingComplete returns true when metadata says so', () {
        final msg = createMessage(metadata: {'streamComplete': true});
        expect(msg.isStreamingComplete, isTrue);
      });

      test('isStreamingComplete returns false when missing', () {
        final msg = createMessage();
        expect(msg.isStreamingComplete, isFalse);
      });
    });

    group('transcript', () {
      test('returns empty list when metadata is null', () {
        final msg = createMessage();
        expect(msg.transcript, isEmpty);
      });

      test('returns empty list when segments is not a list', () {
        final msg = createMessage(metadata: {'segments': 'not a list'});
        expect(msg.transcript, isEmpty);
      });

      test('decodes segments from metadata', () {
        final msg = createMessage(metadata: {
          'segments': [
            {'type': 'reasoning', 'text': 'thinking...', 'ts': 1700000000000},
            {'type': 'tool', 'toolName': 'Read', 'toolCallId': 'c1', 'status': 'ok', 'ts': 1700000000000},
          ],
        });
        expect(msg.transcript, hasLength(2));
        expect(msg.transcript.first, isA<ReasoningSegment>());
        expect(msg.transcript[1], isA<ToolSegment>());
      });

      test('skips non-map entries in segments list', () {
        final msg = createMessage(metadata: {
          'segments': ['not a map', 42],
        });
        expect(msg.transcript, isEmpty);
      });
    });

    group('turn metadata', () {
      test('turnOutcome decodes from metadata', () {
        expect(createMessage().turnOutcome, isNull);
        expect(
          createMessage(metadata: {'outcome': 'completed'}).turnOutcome,
          TurnOutcome.completed,
        );
        expect(
          createMessage(metadata: {'outcome': 'interrupted'}).turnOutcome,
          TurnOutcome.interrupted,
        );
      });

      test('turn stats decode from metadata', () {
        final msg = createMessage(metadata: {
          'turn': {'durationMs': 130000, 'totalTokens': 41000, 'costCents': 12},
        });
        expect(msg.turnDurationMs, 130000);
        expect(msg.turnTotalTokens, 41000);
        expect(msg.turnCostCents, 12);
      });

      test('turn stats are null when absent', () {
        final msg = createMessage();
        expect(msg.turnDurationMs, isNull);
        expect(msg.turnTotalTokens, isNull);
        expect(msg.turnCostCents, isNull);
      });
    });

    group('mentions', () {
      test('returns empty list when metadata is null', () {
        final msg = createMessage();
        expect(msg.mentions, isEmpty);
      });

      test('returns empty list when mentions is not a list', () {
        final msg = createMessage(metadata: {'mentions': 'not a list'});
        expect(msg.mentions, isEmpty);
      });

      test('decodes mentions from metadata', () {
        final msg = createMessage(metadata: {
          'mentions': [
            {'agentId': 'a1', 'raw': '@agent-1'},
          ],
        });
        expect(msg.mentions, hasLength(1));
        expect(msg.mentions.first.agentId, 'a1');
      });

      test('skips entries that are not Map<String, dynamic>', () {
        final msg = createMessage(metadata: {
          'mentions': [42, true],
        });
        expect(msg.mentions, isEmpty);
      });
    });

    group('attachments', () {
      test('returns empty list when metadata is null', () {
        final msg = createMessage();
        expect(msg.attachments, isEmpty);
      });

      test('returns empty list when attachments is not a list', () {
        final msg = createMessage(metadata: {'attachments': 'not a list'});
        expect(msg.attachments, isEmpty);
      });

      test('decodes attachments from metadata', () {
        final msg = createMessage(metadata: {
          'attachments': [
            {
              'id': 'att-1',
              'path': '/tmp/file.png',
              'name': 'file.png',
              'kind': 'image',
              'size': 1024,
              'order': 0,
            },
          ],
        });
        expect(msg.attachments, hasLength(1));
        expect(msg.attachments.first.id, 'att-1');
        expect(msg.attachments.first.kind, AttachmentKind.image);
      });

      test('skips entries that are not Map<String, dynamic>', () {
        final msg = createMessage(metadata: {
          'attachments': ['bad'],
        });
        expect(msg.attachments, isEmpty);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', () {
        final a = createMessage();
        final b = createMessage();
        expect(a, equals(b));
      });

      test('== returns true for same instance', () {
        final msg = createMessage();
        expect(msg, equals(msg));
      });

      test('== returns false for different id', () {
        final a = createMessage(id: 'msg-1');
        final b = createMessage(id: 'msg-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different channelId', () {
        final a = createMessage(channelId: 'ch-1');
        final b = createMessage(channelId: 'ch-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different senderId', () {
        final a = createMessage(senderId: 's1');
        final b = createMessage(senderId: 's2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different senderType', () {
        final a = createMessage(senderType: ChannelSenderType.user);
        final b = createMessage(senderType: ChannelSenderType.agent);
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different content', () {
        final a = createMessage(content: 'Hello');
        final b = createMessage(content: 'World');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different messageType', () {
        final a = createMessage(messageType: ChannelMessageType.text);
        final b = createMessage(messageType: ChannelMessageType.system);
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different metadata', () {
        final a = createMessage(metadata: {'k': 'v1'});
        final b = createMessage(metadata: {'k': 'v2'});
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different parentMessageId', () {
        final a = createMessage(parentMessageId: 'p1');
        final b = createMessage(parentMessageId: 'p2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different compacted', () {
        final a = createMessage(compacted: false);
        final b = createMessage(compacted: true);
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different createdAt', () {
        final a = createMessage(createdAt: DateTime(2024, 1, 1));
        final b = createMessage(createdAt: DateTime(2024, 2, 1));
        expect(a, isNot(equals(b)));
      });

      test('== returns false for non-ChannelMessage', () {
        final msg = createMessage();
        expect(msg, isNot(equals('not a message')));
      });

      test('hashCode matches for equal instances', () {
        final a = createMessage();
        final b = createMessage();
        expect(a.hashCode, equals(b.hashCode));
      });

      test('hashCode differs for different instances', () {
        final a = createMessage(id: 'msg-1');
        final b = createMessage(id: 'msg-2');
        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });

    group('copyWith', () {
      test('returns identical copy with no arguments', () {
        final msg = createMessage();
        final copy = msg.copyWith();
        expect(copy, equals(msg));
        expect(copy.hashCode, equals(msg.hashCode));
      });

      test('updates id', () {
        final msg = createMessage();
        final copy = msg.copyWith(id: 'new-id');
        expect(copy.id, 'new-id');
        expect(copy.channelId, msg.channelId);
      });

      test('updates channelId', () {
        final msg = createMessage();
        final copy = msg.copyWith(channelId: 'new-ch');
        expect(copy.channelId, 'new-ch');
      });

      test('updates senderId', () {
        final msg = createMessage();
        final copy = msg.copyWith(senderId: 'new-sender');
        expect(copy.senderId, 'new-sender');
      });

      test('updates senderType', () {
        final msg = createMessage();
        final copy = msg.copyWith(senderType: ChannelSenderType.agent);
        expect(copy.senderType, ChannelSenderType.agent);
      });

      test('updates content', () {
        final msg = createMessage();
        final copy = msg.copyWith(content: 'Updated');
        expect(copy.content, 'Updated');
      });

      test('updates messageType', () {
        final msg = createMessage();
        final copy = msg.copyWith(messageType: ChannelMessageType.system);
        expect(copy.messageType, ChannelMessageType.system);
      });

      test('updates metadata', () {
        final msg = createMessage();
        final copy = msg.copyWith(metadata: {'key': 'val'});
        expect(copy.metadata, {'key': 'val'});
      });

      test('removes metadata via removeMetadata flag', () {
        final msg = createMessage(metadata: {'key': 'val'});
        final copy = msg.copyWith(removeMetadata: true);
        expect(copy.metadata, isNull);
      });

      test('updates parentMessageId', () {
        final msg = createMessage();
        final copy = msg.copyWith(parentMessageId: 'parent-2');
        expect(copy.parentMessageId, 'parent-2');
      });

      test('removes parentMessageId via removeParentMessageId flag', () {
        final msg = createMessage(parentMessageId: 'parent-1');
        final copy = msg.copyWith(removeParentMessageId: true);
        expect(copy.parentMessageId, isNull);
      });

      test('updates compacted', () {
        final msg = createMessage();
        final copy = msg.copyWith(compacted: true);
        expect(copy.compacted, isTrue);
      });

      test('updates createdAt', () {
        final msg = createMessage();
        final newDate = DateTime(2025, 1, 1);
        final copy = msg.copyWith(createdAt: newDate);
        expect(copy.createdAt, newDate);
      });

      test('does not mutate original', () {
        final msg = createMessage();
        msg.copyWith(content: 'Changed');
        expect(msg.content, 'Hello');
      });

      test('chaining copyWith calls', () {
        final msg = createMessage();
        final copy = msg
            .copyWith(content: 'Updated')
            .copyWith(compacted: true);
        expect(copy.content, 'Updated');
        expect(copy.compacted, isTrue);
      });
    });
  });
}
