import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:test/test.dart';

Message _turn({Map<String, dynamic>? metadata}) => Message(
  id: 'm1',
  spaceId: 'c1',
  conversationId: 'c1',
  senderId: 'a1',
  senderType: SenderType.agent,
  content: 'hello',
  messageType: MessageType.agentTurn,
  metadata: metadata,
  createdAt: DateTime(2026, 6, 29),
);

void main() {
  group('MessageFeedback', () {
    test('feedback getter decodes metadata', () {
      expect(_turn().feedback, isNull);
      expect(
        _turn(
          metadata: {
            'feedback': {'value': 'helpful'},
          },
        ).feedback,
        MessageFeedback.helpful,
      );
      expect(
        _turn(
          metadata: {
            'feedback': {'value': 'notHelpful'},
          },
        ).feedback,
        MessageFeedback.notHelpful,
      );
      expect(
        _turn(
          metadata: {
            'feedback': {'value': 'garbage'},
          },
        ).feedback,
        isNull,
      );
    });

    test(
      'metadataWithFeedback sets feedback without clobbering other keys',
      () {
        final msg = _turn(
          metadata: {
            'segments': ['a', 'b'],
            'snapshot': {'start': 'sha1'},
          },
        );
        final next = msg.metadataWithFeedback(
          MessageFeedback.helpful,
          atEpochMs: 123,
        );
        expect(next['segments'], ['a', 'b']);
        expect(next['snapshot'], {'start': 'sha1'});
        expect(next['feedback'], {'value': 'helpful', 'at': 123});
      },
    );

    test('metadataWithFeedback(null) clears the feedback key only', () {
      final msg = _turn(
        metadata: {
          'segments': ['a'],
          'feedback': {'value': 'helpful', 'at': 1},
        },
      );
      final next = msg.metadataWithFeedback(null, atEpochMs: 999);
      expect(next.containsKey('feedback'), isFalse);
      expect(next['segments'], ['a']);
    });
  });

  group('edit / soft-delete metadata (§8.3)', () {
    test('isEdited / isDeleted reflect their metadata stamps', () {
      expect(_turn().isEdited, isFalse);
      expect(_turn().isDeleted, isFalse);
      expect(_turn(metadata: {'editedAt': 123}).isEdited, isTrue);
      expect(_turn(metadata: {'deletedAt': 123}).isDeleted, isTrue);
    });

    test(
      'metadataWithEdited stamps editedAt without clobbering other keys',
      () {
        final msg = _turn(
          metadata: {
            'segments': ['a'],
            'feedback': {'value': 'helpful'},
          },
        );
        final next = msg.metadataWithEdited(atEpochMs: 555);
        expect(next['editedAt'], 555);
        expect(next['segments'], ['a']);
        expect(next['feedback'], {'value': 'helpful'});
      },
    );

    test(
      'metadataWithDeleted stamps deletedAt without clobbering other keys',
      () {
        final msg = _turn(
          metadata: {
            'segments': ['a'],
          },
        );
        final next = msg.metadataWithDeleted(atEpochMs: 777);
        expect(next['deletedAt'], 777);
        expect(next['segments'], ['a']);
      },
    );
  });
}
