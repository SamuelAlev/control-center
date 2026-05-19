import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [AgentGoalRun] domain entities and `agent_goal_runs` rows.
class AgentGoalRunMapper {
  /// Creates an [AgentGoalRunMapper].
  const AgentGoalRunMapper();

  /// To domain.
  AgentGoalRun toDomain(AgentGoalRunsTableData row) => AgentGoalRun(
    id: row.id,
    workspaceId: row.workspaceId,
    spaceId: row.spaceId,
    conversationId: row.conversationId,
    agentId: row.agentId,
    userText: row.userText,
    kind: AgentGoalKindWire.fromWire(row.kind),
    status: AgentGoalStatusWire.fromWire(row.status),
    deadlineAt: row.deadlineAt,
    costCapCents: row.costCapCents,
    costCents: row.costCents,
    maxRuns: row.maxRuns,
    runCount: row.runCount,
    activeRunId: row.activeRunId,
    consecutiveFailures: row.consecutiveFailures,
    requestedByUserId: row.requestedByUserId,
    summary: row.summary,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  /// To domain list.
  List<AgentGoalRun> toDomainList(List<AgentGoalRunsTableData> rows) =>
      rows.map(toDomain).toList(growable: false);

  /// To companion.
  AgentGoalRunsTableCompanion toCompanion(AgentGoalRun goal) =>
      AgentGoalRunsTableCompanion(
        id: Value(goal.id),
        workspaceId: Value(goal.workspaceId),
        spaceId: Value(goal.spaceId),
        conversationId: Value(goal.conversationId),
        agentId: Value(goal.agentId),
        userText: Value(goal.userText),
        kind: Value(goal.kind.wire),
        status: Value(goal.status.wire),
        deadlineAt: Value(goal.deadlineAt),
        costCapCents: Value(goal.costCapCents),
        costCents: Value(goal.costCents),
        maxRuns: Value(goal.maxRuns),
        runCount: Value(goal.runCount),
        activeRunId: Value(goal.activeRunId),
        consecutiveFailures: Value(goal.consecutiveFailures),
        requestedByUserId: Value(goal.requestedByUserId),
        summary: Value(goal.summary),
        createdAt: Value(goal.createdAt),
        updatedAt: Value(goal.updatedAt),
      );
}
