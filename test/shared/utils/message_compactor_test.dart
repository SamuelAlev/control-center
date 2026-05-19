import 'package:control_center/shared/utils/message_compactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompactableMessage', () {
    test('constructs with required fields', () {
      const msg = CompactableMessage(
        id: '1',
        label: 'Test',
        content: 'Hello world',
        compacted: false,
      );

      expect(msg.id, '1');
      expect(msg.label, 'Test');
      expect(msg.content, 'Hello world');
      expect(msg.contentLength, 11);
      expect(msg.compacted, isFalse);
    });

    test('contentLength returns correct value', () {
      const msg = CompactableMessage(
        id: '1',
        label: 'T',
        content: '12345',
        compacted: false,
      );

      expect(msg.contentLength, 5);
    });

    test('compacted messages have compacted flag', () {
      const msg = CompactableMessage(
        id: '1',
        label: 'T',
        content: 'content',
        compacted: true,
      );

      expect(msg.compacted, isTrue);
    });
  });

  group('MessageCompaction result', () {
    test('constructs with idsToCompact and summary', () {
      final compaction = MessageCompaction(
        idsToCompact: ['1', '2', '3'],
        summary: 'Compacted 3 messages',
      );

      expect(compaction.idsToCompact, ['1', '2', '3']);
      expect(compaction.summary, 'Compacted 3 messages');
    });
  });

  group('MessageCompactor.compact', () {
    late MessageCompactor compactor;

    setUp(() {
      compactor = const MessageCompactor();
    });

    test('returns null when total chars under limit', () {
      final messages = [
        const CompactableMessage(
          id: '1',
          label: 'User',
          content: 'Hello',
          compacted: false,
        ),
        const CompactableMessage(
          id: '2',
          label: 'Assistant',
          content: 'Hi there',
          compacted: false,
        ),
      ];

      final result = compactor.compact(messages: messages, contextSize: 100);

      expect(result, isNull);
    });

    test('returns null for single message under limit', () {
      final messages = [
        const CompactableMessage(
          id: '1',
          label: 'User',
          content: 'Hello',
          compacted: false,
        ),
      ];

      final result = compactor.compact(messages: messages, contextSize: 50);

      expect(result, isNull);
    });

    test('returns null for empty message list', () {
      final result = compactor.compact(messages: [], contextSize: 10);

      expect(result, isNull);
    });

    test('returns compaction when chars exceed limit', () {
      final longContent = 'x' * 500;
      final messages = [
        CompactableMessage(
          id: '1',
          label: 'User',
          content: longContent,
          compacted: false,
        ),
        CompactableMessage(
          id: '2',
          label: 'Assistant',
          content: longContent,
          compacted: false,
        ),
        CompactableMessage(
          id: '3',
          label: 'User',
          content: longContent,
          compacted: false,
        ),
      ];

      final result = compactor.compact(
        messages: messages,
        contextSize: 10,
      );

      expect(result, isNotNull);
      expect(result!.idsToCompact, isNotEmpty);
      expect(result.summary, contains('Previous context summary'));
    });

    test('skips already compacted messages', () {
      final longContent = 'x' * 500;
      final messages = [
        CompactableMessage(
          id: '1',
          label: 'User',
          content: longContent,
          compacted: false,
        ),
        CompactableMessage(
          id: '2',
          label: 'Assistant',
          content: longContent,
          compacted: true,
        ),
        CompactableMessage(
          id: '3',
          label: 'User',
          content: longContent,
          compacted: false,
        ),
      ];

      final result = compactor.compact(
        messages: messages,
        contextSize: 10,
      );

      expect(result, isNotNull);
      expect(result!.idsToCompact, contains('1'));
      expect(result.idsToCompact, contains('3'));
      expect(result.idsToCompact, isNot(contains('2')));
    });

    test('summary includes message labels', () {
      final longContent = 'x' * 500;
      final messages = [
        CompactableMessage(
          id: '1',
          label: 'CEO Agent',
          content: longContent,
          compacted: false,
        ),
        CompactableMessage(
          id: '2',
          label: 'Developer Agent',
          content: longContent,
          compacted: false,
        ),
      ];

      final result = compactor.compact(
        messages: messages,
        contextSize: 10,
      );

      expect(result, isNotNull);
      expect(result!.summary, contains('CEO Agent'));
      expect(result.summary, contains('Developer Agent'));
    });

    test('truncates content excerpt to ~120 chars plus ellipsis', () {
      final longContent = 'a' * 500;
      final messages = [
        CompactableMessage(
          id: '1',
          label: 'Agent',
          content: longContent,
          compacted: false,
        ),
      ];

      final result = compactor.compact(
        messages: messages,
        contextSize: 10,
      );

      expect(result, isNotNull);
      expect(result!.summary, contains('…'));
    });

    test('returns null when only compacted messages exist', () {
      final messages = [
        const CompactableMessage(
          id: '1',
          label: 'User',
          content: 'Hello world this is a long message',
          compacted: true,
        ),
      ];

      final result = compactor.compact(messages: messages, contextSize: 1);

      expect(result, isNull);
    });

    test('compact with message content under 120 chars preserves full content', () {
      final messages = [
        const CompactableMessage(
          id: '1',
          label: 'Agent',
          content: 'Short message',
          compacted: false,
        ),
      ];

      final result = compactor.compact(messages: messages, contextSize: 1);

      expect(result, isNotNull);
      expect(result!.summary, contains('Short message'));
      expect(result.summary, isNot(contains('…')));
    });

    test('compact with exactly 120 chars does not truncate', () {
      final content = 'a' * 120;
      final messages = [
        CompactableMessage(
          id: '1',
          label: 'Agent',
          content: content,
          compacted: false,
        ),
      ];

      final result = compactor.compact(messages: messages, contextSize: 1);

      expect(result, isNotNull);
      expect(result!.summary, isNot(contains('…')));
    });

    test('stops compacting once under char limit', () {
      final longContent = 'x' * 500;
      const shortContent = 'Hi';
      final messages = [
        CompactableMessage(
          id: '1',
          label: 'First',
          content: longContent,
          compacted: false,
        ),
        const CompactableMessage(
          id: '2',
          label: 'Second',
          content: shortContent,
          compacted: false,
        ),
        CompactableMessage(
          id: '3',
          label: 'Third',
          content: longContent,
          compacted: false,
        ),
      ];

      final result = compactor.compact(messages: messages, contextSize: 200);

      expect(result, isNotNull);
      expect(result!.idsToCompact, contains('1'));
      expect(result.idsToCompact.length, lessThan(3));
    });

    test('IDS to compact are ordered by insertion', () {
      final longContent = 'x' * 500;
      final messages = [
        CompactableMessage(
          id: '10',
          label: 'Z',
          content: longContent,
          compacted: false,
        ),
        CompactableMessage(
          id: '20',
          label: 'Y',
          content: longContent,
          compacted: false,
        ),
      ];

      final result = compactor.compact(messages: messages, contextSize: 1);

      expect(result, isNotNull);
      expect(result!.idsToCompact[0], '10');
      expect(result.idsToCompact[1], '20');
    });

    test('summary includes header', () {
      final longContent = 'x' * 500;
      final messages = [
        CompactableMessage(
          id: '1',
          label: 'Agent',
          content: longContent,
          compacted: false,
        ),
      ];

      final result = compactor.compact(messages: messages, contextSize: 1);

      expect(result, isNotNull);
      expect(result!.summary, startsWith('## Previous context summary'));
    });

    test('summary format uses markdown list syntax', () {
      final longContent = 'x' * 500;
      final messages = [
        CompactableMessage(
          id: '1',
          label: 'CEO',
          content: longContent,
          compacted: false,
        ),
      ];

      final result = compactor.compact(messages: messages, contextSize: 1);

      expect(result, isNotNull);
      expect(result!.summary, contains('- [CEO]'));
    });

    test('returns null when nonCompacted is empty after filter', () {
      final messages = [
        const CompactableMessage(
          id: '1',
          label: 'Agent',
          content: 'Some content here that is moderately long enough to consider',
          compacted: true,
        ),
      ];

      final result = compactor.compact(messages: messages, contextSize: 100);

      expect(result, isNull);
    });

    test('compacts single non-compacted message when over limit', () {
      final longContent = 'x' * 500;
      final messages = [
        CompactableMessage(
          id: '1',
          label: 'User',
          content: longContent,
          compacted: false,
        ),
        const CompactableMessage(
          id: '2',
          label: 'Assistant',
          content: 'OK',
          compacted: true,
        ),
      ];

      final result = compactor.compact(messages: messages, contextSize: 1);

      expect(result, isNotNull);
      expect(result!.idsToCompact, ['1']);
      expect(result.idsToCompact.length, 1);
    });

    test('respects contextSize multiplier for char limit', () {
      final longContent = 'x' * 100;
      final messages = [
        CompactableMessage(
          id: '1',
          label: 'Agent',
          content: longContent,
          compacted: false,
        ),
      ];

      final underLimit = compactor.compact(
        messages: messages,
        contextSize: 50,
      );
      expect(underLimit, isNull);

      final overLimit = compactor.compact(
        messages: messages,
        contextSize: 10,
      );
      expect(overLimit, isNotNull);
    });
  });
}
