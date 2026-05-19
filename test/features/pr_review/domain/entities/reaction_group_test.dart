import 'package:control_center/features/pr_review/domain/entities/reaction_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReactionGroup constructor', () {
    test('creates with all fields', timeout: const Timeout.factor(2), () {
      const group = ReactionGroup(
        content: '+1',
        emoji: '👍',
        count: 3,
        userReacted: true,
        usernames: ['alice', 'bob', 'charlie'],
      );
      expect(group.content, '+1');
      expect(group.emoji, '👍');
      expect(group.count, 3);
      expect(group.userReacted, true);
      expect(group.usernames, ['alice', 'bob', 'charlie']);
    });

    test('usernames defaults to empty list', timeout: const Timeout.factor(2), () {
      const group = ReactionGroup(
        content: 'heart',
        emoji: '❤️',
        count: 0,
        userReacted: false,
      );
      expect(group.usernames, isEmpty);
    });
  });

  group('ReactionGroup.copyWith', () {
    const original = ReactionGroup(
      content: '+1',
      emoji: '👍',
      count: 2,
      userReacted: false,
      usernames: ['alice', 'bob'],
    );

    test('updates count', timeout: const Timeout.factor(2), () {
      final updated = original.copyWith(count: 5);
      expect(updated.count, 5);
      expect(updated.content, '+1');
      expect(updated.emoji, '👍');
      expect(updated.userReacted, false);
      expect(updated.usernames, ['alice', 'bob']);
    });

    test('updates userReacted', timeout: const Timeout.factor(2), () {
      final updated = original.copyWith(userReacted: true);
      expect(updated.userReacted, true);
      expect(updated.count, 2);
    });

    test('updates usernames', timeout: const Timeout.factor(2), () {
      final updated = original.copyWith(usernames: ['alice', 'bob', 'charlie']);
      expect(updated.usernames, ['alice', 'bob', 'charlie']);
    });

    test('preserves unchanged fields', timeout: const Timeout.factor(2), () {
      final updated = original.copyWith();
      expect(updated, equals(original));
    });
  });

  group('ReactionGroup.emojiForContent', () {
    test('returns emoji for known content', timeout: const Timeout.factor(2), () {
      expect(ReactionGroup.emojiForContent('+1'), '👍');
      expect(ReactionGroup.emojiForContent('-1'), '👎');
      expect(ReactionGroup.emojiForContent('laugh'), '😄');
      expect(ReactionGroup.emojiForContent('hooray'), '🎉');
      expect(ReactionGroup.emojiForContent('confused'), '😕');
      expect(ReactionGroup.emojiForContent('heart'), '❤️');
      expect(ReactionGroup.emojiForContent('rocket'), '🚀');
      expect(ReactionGroup.emojiForContent('eyes'), '👀');
    });

    test('returns empty string for unknown content', timeout: const Timeout.factor(2), () {
      expect(ReactionGroup.emojiForContent('unknown'), '');
      expect(ReactionGroup.emojiForContent(''), '');
    });
  });

  group('ReactionGroup.supportedReactions', () {
    test('has 8 supported reactions', timeout: const Timeout.factor(2), () {
      expect(ReactionGroup.supportedReactions.length, 8);
    });

    test('each reaction has content and emoji', timeout: const Timeout.factor(2), () {
      for (final r in ReactionGroup.supportedReactions) {
        expect(r.content, isNotEmpty);
        expect(r.emoji, isNotEmpty);
      }
    });
  });

  group('ReactionGroup == and hashCode', () {
    const a = ReactionGroup(
      content: '+1',
      emoji: '👍',
      count: 3,
      userReacted: true,
      usernames: ['alice', 'bob'],
    );

    test('equal when all fields match', timeout: const Timeout.factor(2), () {
      const b = ReactionGroup(
        content: '+1',
        emoji: '👍',
        count: 3,
        userReacted: true,
        usernames: ['alice', 'bob'],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when content differs', timeout: const Timeout.factor(2), () {
      const b = ReactionGroup(
        content: '-1',
        emoji: '👎',
        count: 3,
        userReacted: true,
        usernames: ['alice', 'bob'],
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when count differs', timeout: const Timeout.factor(2), () {
      const b = ReactionGroup(
        content: '+1',
        emoji: '👍',
        count: 99,
        userReacted: true,
        usernames: ['alice', 'bob'],
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when userReacted differs', timeout: const Timeout.factor(2), () {
      const b = ReactionGroup(
        content: '+1',
        emoji: '👍',
        count: 3,
        userReacted: false,
        usernames: ['alice', 'bob'],
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when usernames differ', timeout: const Timeout.factor(2), () {
      const b = ReactionGroup(
        content: '+1',
        emoji: '👍',
        count: 3,
        userReacted: true,
        usernames: ['alice'],
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when usernames order differs', timeout: const Timeout.factor(2), () {
      const b = ReactionGroup(
        content: '+1',
        emoji: '👍',
        count: 3,
        userReacted: true,
        usernames: ['bob', 'alice'],
      );
      expect(a, isNot(equals(b)));
    });

    test('self equality', timeout: const Timeout.factor(2), () {
      expect(a, equals(a));
    });

    test('not equal to other types', timeout: const Timeout.factor(2), () {
      expect(a, isNot(equals('not a reaction')));
    });
  });
}
