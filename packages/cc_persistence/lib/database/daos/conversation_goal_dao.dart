import 'package:cc_persistence/database/tables/conversation_goals_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'conversation_goal_dao.g.dart';

/// Data access for per-space working goals. Every read and mutation filters by
/// BOTH `workspaceId` and `spaceId` — an id-only query would leak across spaces
/// or workspaces.
@DriftAccessor(tables: [ConversationGoalsTable])
class ConversationGoalDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ConversationGoalDaoMixin {
  /// Creates a [ConversationGoalDao].
  ConversationGoalDao(super.db);

  /// Watches the space's goal (or null when none is set).
  Stream<ConversationGoalsTableData?> watchForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(conversationGoalsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId),
          ))
          .watchSingleOrNull();

  /// Returns the space's goal (or null when none is set).
  Future<ConversationGoalsTableData?> getForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(conversationGoalsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId),
          ))
          .getSingleOrNull();

  /// Inserts or replaces the space's goal.
  Future<void> upsert(ConversationGoalsTableCompanion entry) =>
      into(conversationGoalsTable).insertOnConflictUpdate(entry);

  /// Deletes the space's goal, scoped by workspace + space. Returns rows
  /// deleted (0 when it belongs to another space/workspace).
  Future<int> deleteForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (delete(conversationGoalsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId),
          ))
          .go();
}
