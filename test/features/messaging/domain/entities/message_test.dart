import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 1, 15);

  Message createMessage({
    String id = 'cm-1',
    String spaceId = 'ch-1',
    String senderId = 'agent-1',
    SenderType senderType = SenderType.agent,
    String content = 'Hello',
    MessageType messageType = MessageType.text,
    Map<String, dynamic>? metadata,
    bool compacted = false,
    DateTime? createdAt,
  }) {
    return Message(
      id: id,
      spaceId: spaceId,
      conversationId: spaceId,
      senderId: senderId,
      senderType: senderType,
      content: content,
      messageType: messageType,
      metadata: metadata,
      compacted: compacted,
      createdAt: createdAt ?? now,
    );
  }

  group('Message constructor', () {
    test('creates message with required fields', () {
      final msg = createMessage();
      expect(msg.id, 'cm-1');
      expect(msg.spaceId, 'ch-1');
      expect(msg.senderId, 'agent-1');
      expect(msg.content, 'Hello');
      expect(msg.messageType, MessageType.text);
      expect(msg.compacted, isFalse);
    });

    test('throws ArgumentError for empty spaceId', () {
      expect(
        () => Message(
          id: '1',
          spaceId: '',
          conversationId: '',
          senderId: 'a',
          senderType: SenderType.user,
          content: 'Hi',
          messageType: MessageType.text,
          createdAt: now,
        ),
        throwsA(isA<ArgumentError>()),
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
      final msg = Message(
        id: '1',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 's',
        senderType: SenderType.user,
        content: 'Hi',
        messageType: MessageType.text,
        createdAt: now,
      );
      expect(msg.compacted, isFalse);
    });
  });

  group('MessageType enum', () {
    test('has all expected values', () {
      expect(MessageType.values, [
        MessageType.text,
        MessageType.system,
        MessageType.ticketCard,
        MessageType.agentTurn,
        MessageType.reviewNode,
        MessageType.hireProposal,
        MessageType.reviewSummary,
        MessageType.plan,
        MessageType.userQuestion,
        MessageType.orchestrationProposal,
        MessageType.artifact,
        MessageType.compaction,
        MessageType.steering,
      ]);
    });
  });

  group('SenderType enum', () {
    test('has user and agent values', () {
      expect(SenderType.values, [SenderType.user, SenderType.agent]);
    });
  });

  group('Message computed properties', () {
    test('isUser returns true for user sender', () {
      final msg = createMessage(senderType: SenderType.user);
      expect(msg.isUser, isTrue);
    });

    test('isUser returns false for agent sender', () {
      final msg = createMessage(senderType: SenderType.agent);
      expect(msg.isUser, isFalse);
    });

    test('isSystem returns true for system message', () {
      final msg = createMessage(messageType: MessageType.system);
      expect(msg.isSystem, isTrue);
    });

    test('isSystem returns false for text message', () {
      final msg = createMessage(messageType: MessageType.text);
      expect(msg.isSystem, isFalse);
    });

    test('isTicket returns true for ticket card', () {
      final msg = createMessage(messageType: MessageType.ticketCard);
      expect(msg.isTicket, isTrue);
    });

    test('isTicket returns false for other types', () {
      final msg = createMessage(messageType: MessageType.text);
      expect(msg.isTicket, isFalse);
    });

    test('isAgentTurn returns true for agentTurn type', () {
      final msg = createMessage(messageType: MessageType.agentTurn);
      expect(msg.isAgentTurn, isTrue);
    });

    test(
      'isStreamingComplete returns true when streamComplete metadata set',
      () {
        final msg = createMessage(metadata: {'streamComplete': true});
        expect(msg.isStreamingComplete, isTrue);
      },
    );

    test('isStreamingComplete returns false when not set', () {
      final msg = createMessage();
      expect(msg.isStreamingComplete, isFalse);
    });

    test('isStreamingComplete returns false when metadata is null', () {
      final msg = createMessage(metadata: null);
      expect(msg.isStreamingComplete, isFalse);
    });

    test('isStreamingComplete returns false when streamComplete is false', () {
      final msg = createMessage(metadata: {'streamComplete': false});
      expect(msg.isStreamingComplete, isFalse);
    });
  });

  group('Message == and hashCode', () {
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

  group('Message copyWith', () {
    test('returns new instance with updated content', () {
      final msg = createMessage();
      final updated = msg.copyWith(content: 'New');
      expect(updated.content, 'New');
      expect(updated.id, 'cm-1');
    });

    test('returns new instance with updated senderType', () {
      final msg = createMessage(senderType: SenderType.agent);
      final updated = msg.copyWith(senderType: SenderType.user);
      expect(updated.senderType, SenderType.user);
      expect(updated.isUser, isTrue);
    });

    test('removeMetadata sets metadata to null', () {
      final msg = createMessage(metadata: {'a': 1});
      final updated = msg.copyWith(removeMetadata: true);
      expect(updated.metadata, isNull);
    });

    test('removeMetadata takes precedence over explicit metadata', () {
      final msg = createMessage(metadata: {'a': 1});
      final updated = msg.copyWith(removeMetadata: true, metadata: {'b': 2});
      expect(updated.metadata, isNull);
    });

    test('copyWith without changes returns equal message', () {
      final msg = createMessage();
      final updated = msg.copyWith();
      expect(updated, equals(msg));
    });
  });
}
