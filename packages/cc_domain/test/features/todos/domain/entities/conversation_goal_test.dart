import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:test/test.dart';

void main() {
  // A canonical goal used by most tests.
  ConversationGoal goal({
    String conversationId = 'c-1',
    String workspaceId = 'ws-1',
    String title = 'Ship the goal feature',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ConversationGoal(
    conversationId: conversationId,
    workspaceId: workspaceId,
    title: title,
    createdAt: createdAt ?? DateTime(2026, 7, 1, 9),
    updatedAt: updatedAt ?? DateTime(2026, 7, 1, 10),
  );

  group('ConversationGoal construction', () {
    test('stores every field verbatim', () {
      final g = goal();
      expect(g.conversationId, 'c-1');
      expect(g.workspaceId, 'ws-1');
      expect(g.title, 'Ship the goal feature');
      expect(g.createdAt, DateTime(2026, 7, 1, 9));
      expect(g.updatedAt, DateTime(2026, 7, 1, 10));
    });

    test('rejects a blank title', () {
      expect(() => goal(title: '   '), throwsA(isA<AssertionError>()));
    });

    test('rejects an empty workspaceId', () {
      expect(() => goal(workspaceId: ''), throwsA(isA<AssertionError>()));
    });

    test('rejects an empty conversationId', () {
      expect(() => goal(conversationId: ''), throwsA(isA<AssertionError>()));
    });

    test('accepts a title that is non-empty after trimming', () {
      // The assertion only guards against blank — leading/trailing whitespace is
      // preserved by the entity (the repository trims before persisting).
      final g = goal(title: '  spaced goal  ');
      expect(g.title, '  spaced goal  ');
    });
  });

  group('ConversationGoal.copyWith', () {
    test('returns a copy with the given field replaced', () {
      final g = goal();
      final updated = g.copyWith(
        title: 'Revised goal',
        updatedAt: DateTime(2026, 7, 2, 11),
      );
      expect(updated.title, 'Revised goal');
      expect(updated.updatedAt, DateTime(2026, 7, 2, 11));
      // Untouched fields are preserved.
      expect(updated.conversationId, g.conversationId);
      expect(updated.workspaceId, g.workspaceId);
      expect(updated.createdAt, g.createdAt);
    });

    test('omitting every field yields an equal copy', () {
      final g = goal();
      expect(g.copyWith(), g);
    });
  });

  group('ConversationGoal equality', () {
    test('is equal when every field matches', () {
      expect(goal(), goal());
    });

    test('is unequal when the title differs', () {
      expect(goal(title: 'a'), isNot(goal(title: 'b')));
    });

    test('is unequal when the conversation differs', () {
      expect(goal(conversationId: 'c-1'), isNot(goal(conversationId: 'c-2')));
    });

    test('is unequal when the workspace differs', () {
      expect(goal(workspaceId: 'ws-1'), isNot(goal(workspaceId: 'ws-2')));
    });

    test('is unequal when createdAt differs', () {
      expect(
        goal(createdAt: DateTime(2026, 1, 1)),
        isNot(goal(createdAt: DateTime(2026, 1, 2))),
      );
    });

    test('is unequal when updatedAt differs', () {
      expect(
        goal(updatedAt: DateTime(2026, 1, 1)),
        isNot(goal(updatedAt: DateTime(2026, 1, 2))),
      );
    });

    test('hashCode matches for equal goals', () {
      expect(goal().hashCode, goal().hashCode);
    });

    test('hashCode differs for unequal goals', () {
      expect(goal(title: 'a').hashCode, isNot(goal(title: 'b').hashCode));
    });

    test('is not equal to an unrelated type', () {
      expect(goal(), isNot('not a goal'));
    });

    test('identical references are equal', () {
      final g = goal();
      expect(g, same(g));
    });
  });
}
