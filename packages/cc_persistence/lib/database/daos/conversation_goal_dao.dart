import 'package:cc_persistence/database/tables/conversation_goals_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'conversation_goal_dao.g.dart';

/// Data access for per-conversation working goals. Every read and mutation
/// filters by BOTH `workspaceId` and `conversationId` — an id-only query would
/// leak across conversations or workspaces.
@DriftAccessor(tables: [ConversationGoalsTable])
class ConversationGoalDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ConversationGoalDaoMixin {
  /// Creates a [ConversationGoalDao].
  ConversationGoalDao(super.db);

  /// Watches the conversation's goal (or null when none is set).
  Stream<ConversationGoalsTableData?> watchForConversation(
    String workspaceId,
    String conversationId,
  ) =>
      (select(conversationGoalsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.conversationId.equals(conversationId),
          ))
          .watchSingleOrNull();

  /// Returns the conversation's goal (or null when none is set).
  Future<ConversationGoalsTableData?> getForConversation(
    String workspaceId,
    String conversationId,
  ) =>
      (select(conversationGoalsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.conversationId.equals(conversationId),
          ))
          .getSingleOrNull();

  /// Inserts or replaces the conversation's goal.
  Future<void> upsert(ConversationGoalsTableCompanion entry) =>
      into(conversationGoalsTable).insertOnConflictUpdate(entry);

  /// Deletes the conversation's goal, scoped by workspace + conversation.
  /// Returns rows deleted (0 when it belongs to another conversation/workspace).
  Future<int> deleteForConversation(
    String workspaceId,
    String conversationId,
  ) =>
      (delete(conversationGoalsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.conversationId.equals(conversationId),
          ))
          .go();
}
