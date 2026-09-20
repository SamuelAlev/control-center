import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [ConversationGoal] domain entities and `conversation_goals`
/// table rows.
class ConversationGoalMapper {
  /// Creates a [ConversationGoalMapper].
  const ConversationGoalMapper();

  /// To domain.
  ConversationGoal toDomain(ConversationGoalsTableData row) => ConversationGoal(
    conversationId: row.conversationId,
    workspaceId: row.workspaceId,
    title: row.title,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  /// To domain (nullable row → nullable entity).
  ConversationGoal? toDomainOrNull(ConversationGoalsTableData? row) =>
      row == null ? null : toDomain(row);

  /// To companion.
  ConversationGoalsTableCompanion toCompanion(ConversationGoal goal) =>
      ConversationGoalsTableCompanion(
        conversationId: Value(goal.conversationId),
        workspaceId: Value(goal.workspaceId),
        title: Value(goal.title),
        createdAt: Value(goal.createdAt),
        updatedAt: Value(goal.updatedAt),
      );
}
