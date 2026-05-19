import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_level.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_status.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [OrgGoal] domain entities and `goals` table rows.
class GoalMapper {
  /// Creates a [GoalMapper].
  const GoalMapper();

  /// To domain.
  OrgGoal toDomain(GoalsTableData row) => OrgGoal(
    id: row.id,
    workspaceId: row.workspaceId,
    title: row.title,
    level: OrgGoalLevel.fromStorage(row.level),
    parentGoalId: row.parentGoalId,
    description: row.description,
    status: OrgGoalStatus.fromStorage(row.status),
    ownerAgentId: row.ownerAgentId,
    teamId: row.teamId,
    targetTicketId: row.targetTicketId,
    progress: row.progress,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  /// To domain list.
  List<OrgGoal> toDomainList(List<GoalsTableData> rows) =>
      rows.map(toDomain).toList(growable: false);

  /// To companion.
  GoalsTableCompanion toCompanion(OrgGoal goal) => GoalsTableCompanion(
    id: Value(goal.id),
    workspaceId: Value(goal.workspaceId),
    parentGoalId: Value(goal.parentGoalId),
    level: Value(goal.level.name),
    title: Value(goal.title),
    description: Value(goal.description),
    status: Value(goal.status.name),
    ownerAgentId: Value(goal.ownerAgentId),
    teamId: Value(goal.teamId),
    targetTicketId: Value(goal.targetTicketId),
    progress: Value(goal.progress),
    createdAt: Value(goal.createdAt),
    updatedAt: Value(goal.updatedAt),
  );
}
