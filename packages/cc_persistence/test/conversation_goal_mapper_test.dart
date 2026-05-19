import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/conversation_goal_mapper.dart';
import 'package:test/test.dart';

/// Unit tests for [ConversationGoalMapper] — the bidirectional row↔entity
/// mapping plus the nullable helper. The round-trip (toCompanion → toDomain)
/// is the load-bearing assertion: a field the mapper forgets would silently
/// reset on persist.
void main() {
  const mapper = ConversationGoalMapper();

  final row = ConversationGoalsTableData(
    spaceId: 'c-1',
    workspaceId: 'ws-1',
    title: 'Ship the goal feature',
    createdAt: DateTime(2026, 7, 1, 9),
    updatedAt: DateTime(2026, 7, 1, 10),
  );

  group('ConversationGoalMapper.toDomain', () {
    test('maps every field verbatim', () {
      final g = mapper.toDomain(row);
      expect(g.spaceId, 'c-1');
      expect(g.workspaceId, 'ws-1');
      expect(g.title, 'Ship the goal feature');
      expect(g.createdAt, DateTime(2026, 7, 1, 9));
      expect(g.updatedAt, DateTime(2026, 7, 1, 10));
    });
  });

  group('ConversationGoalMapper.toDomainOrNull', () {
    test('returns null for a null row', () {
      expect(mapper.toDomainOrNull(null), isNull);
    });

    test('maps a present row', () {
      expect(mapper.toDomainOrNull(row)?.title, 'Ship the goal feature');
    });
  });

  group('ConversationGoalMapper.toCompanion', () {
    test('carries every field as a Value', () {
      final g = mapper.toDomain(row);
      final c = mapper.toCompanion(g);
      expect(c.spaceId.value, 'c-1');
      expect(c.workspaceId.value, 'ws-1');
      expect(c.title.value, 'Ship the goal feature');
      expect(c.createdAt.value, DateTime(2026, 7, 1, 9));
      expect(c.updatedAt.value, DateTime(2026, 7, 1, 10));
    });
  });

  group('ConversationGoalMapper round-trip', () {
    test('toCompanion → toDomain preserves every field', () {
      final original = mapper.toDomain(row);
      final roundTripped = mapper.toCompanion(original).toCompanionGoal();
      expect(roundTripped, original);
    });
  });
}

/// Extension that rebuilds a [ConversationGoal] from a companion, for the
/// round-trip assertion.
extension on ConversationGoalsTableCompanion {
  ConversationGoal toCompanionGoal() => ConversationGoal(
    spaceId: spaceId.value,
    workspaceId: workspaceId.value,
    title: title.value,
    createdAt: createdAt.value,
    updatedAt: updatedAt.value,
  );
}
