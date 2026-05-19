import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 1, 15);

  ChannelMessage createMessage({
    String id = 'cm-1',
    String channelId = 'ch-1',
    String senderId = 'agent-1',
    ChannelSenderType senderType = ChannelSenderType.agent,
    String content = 'Hello',
    ChannelMessageType messageType = ChannelMessageType.text,
    Map<String, dynamic>? metadata,
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
      compacted: compacted,
      createdAt: createdAt ?? now,
    );
  }

  group('ChannelMessage constructor', () {
    test('creates message with required fields', () {
      final msg = createMessage();
      expect(msg.id, 'cm-1');
      expect(msg.channelId, 'ch-1');
      expect(msg.senderId, 'agent-1');
      expect(msg.content, 'Hello');
      expect(msg.messageType, ChannelMessageType.text);
      expect(msg.compacted, isFalse);
    });

    test('throws assertion error for empty channelId', () {
      expect(
        () => ChannelMessage(
          id: '1',
          channelId: '',
          senderId: 'a',
          senderType: ChannelSenderType.user,
          content: 'Hi',
          messageType: ChannelMessageType.text,
          createdAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('stores optional metadata map', () {
      final msg = createMessage(metadata: {'key': 'val', 'num': 42});
      expect(msg.metadata, {'key': 'val', 'num': 42});
    });

    test('metadata defaults to null', () {
      final msg = createMessage();
      expect(msg.metadata, isNull);
    });

    test('compacted defaults to false', () {
      final msg = ChannelMessage(
        id: '1',
        channelId: 'ch-1',
        senderId: 's',
        senderType: ChannelSenderType.user,
        content: 'Hi',
        messageType: ChannelMessageType.text,
        createdAt: now,
      );
      expect(msg.compacted, isFalse);
    });
  });

  group('ChannelMessageType enum', () {
    test('has all expected values', () {
      expect(ChannelMessageType.values, [
        ChannelMessageType.text,
        ChannelMessageType.system,
        ChannelMessageType.ticketCard,
        ChannelMessageType.agentTurn,
        ChannelMessageType.reviewNode,
        ChannelMessageType.hireProposal,
        ChannelMessageType.reviewSummary,
        ChannelMessageType.plan,
        ChannelMessageType.userQuestion,
        ChannelMessageType.orchestrationProposal,
      ]);
    });
  });

  group('ChannelSenderType enum', () {
    test('has user and agent values', () {
      expect(ChannelSenderType.values, [
        ChannelSenderType.user,
        ChannelSenderType.agent,
      ]);
    });
  });

  group('ChannelMessage computed properties', () {
    test('isUser returns true for user sender', () {
      final msg = createMessage(senderType: ChannelSenderType.user);
      expect(msg.isUser, isTrue);
    });

    test('isUser returns false for agent sender', () {
      final msg = createMessage(senderType: ChannelSenderType.agent);
      expect(msg.isUser, isFalse);
    });

    test('isSystem returns true for system message', () {
      final msg = createMessage(messageType: ChannelMessageType.system);
      expect(msg.isSystem, isTrue);
    });

    test('isSystem returns false for text message', () {
      final msg = createMessage(messageType: ChannelMessageType.text);
      expect(msg.isSystem, isFalse);
    });

    test('isTicket returns true for ticket card', () {
      final msg = createMessage(messageType: ChannelMessageType.ticketCard);
      expect(msg.isTicket, isTrue);
    });

    test('isTicket returns false for other types', () {
      final msg = createMessage(messageType: ChannelMessageType.text);
      expect(msg.isTicket, isFalse);
    });

    test('isAgentTurn returns true for agentTurn type', () {
      final msg = createMessage(messageType: ChannelMessageType.agentTurn);
      expect(msg.isAgentTurn, isTrue);
    });

    test('isStreamingComplete returns true when streamComplete metadata set', () {
      final msg = createMessage(
        metadata: {'streamComplete': true},
      );
      expect(msg.isStreamingComplete, isTrue);
    });

    test('isStreamingComplete returns false when not set', () {
      final msg = createMessage();
      expect(msg.isStreamingComplete, isFalse);
    });

    test('isStreamingComplete returns false when metadata is null', () {
      final msg = createMessage(metadata: null);
      expect(msg.isStreamingComplete, isFalse);
    });

    test('isStreamingComplete returns false when streamComplete is false', () {
      final msg = createMessage(
        metadata: {'streamComplete': false},
      );
      expect(msg.isStreamingComplete, isFalse);
    });
  });

  group('ChannelMessage == and hashCode', () {
    test('identical messages are equal', () {
      final a = createMessage();
      final b = createMessage();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id makes unequal', () {
      final a = createMessage(id: 'a');
      final b = createMessage(id: 'b');
      expect(a, isNot(equals(b)));
    });

    test('different content makes unequal', () {
      final a = createMessage(content: 'Hello');
      final b = createMessage(content: 'World');
      expect(a, isNot(equals(b)));
    });

    test('different compacted flag makes unequal', () {
      final a = createMessage(compacted: false);
      final b = createMessage(compacted: true);
      expect(a, isNot(equals(b)));
    });

    test('messages with different metadata are unequal', () {
      final a = createMessage(metadata: {'a': 1});
      final b = createMessage(metadata: {'b': 2});
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = createMessage();
      expect(a, equals(a));
    });
  });

  group('ChannelMessage copyWith', () {
    test('returns new instance with updated content', () {
      final msg = createMessage();
      final updated = msg.copyWith(content: 'New');
      expect(updated.content, 'New');
      expect(updated.id, 'cm-1');
    });

    test('returns new instance with updated senderType', () {
      final msg = createMessage(senderType: ChannelSenderType.agent);
      final updated = msg.copyWith(senderType: ChannelSenderType.user);
      expect(updated.senderType, ChannelSenderType.user);
      expect(updated.isUser, isTrue);
    });

    test('removeMetadata sets metadata to null', () {
      final msg = createMessage(metadata: {'a': 1});
      final updated = msg.copyWith(removeMetadata: true);
      expect(updated.metadata, isNull);
    });

    test('removeMetadata takes precedence over explicit metadata', () {
      final msg = createMessage(metadata: {'a': 1});
      final updated = msg.copyWith(
        removeMetadata: true,
        metadata: {'b': 2},
      );
      expect(updated.metadata, isNull);
    });

    test('copyWith without changes returns equal message', () {
      final msg = createMessage();
      final updated = msg.copyWith();
      expect(updated, equals(msg));
    });
  });
}
