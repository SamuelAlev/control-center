import 'package:cc_domain/features/governance/domain/entities/agent_runtime_state.dart';
import 'package:cc_domain/features/governance/domain/value_objects/heartbeat_status.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [AgentRuntimeState] domain entities and `agent_runtime_state`
/// rows.
class AgentRuntimeStateMapper {
  /// Creates an [AgentRuntimeStateMapper].
  const AgentRuntimeStateMapper();

  /// To domain.
  AgentRuntimeState toDomain(AgentRuntimeStateTableData row) =>
      AgentRuntimeState(
        agentId: row.agentId,
        workspaceId: row.workspaceId,
        reportedStatus: HeartbeatStatus.fromStorage(row.reportedStatus),
        lastHeartbeatAt: row.lastHeartbeatAt,
        currentRunId: row.currentRunId,
        note: row.note,
        updatedAt: row.updatedAt,
      );

  /// To domain list.
  List<AgentRuntimeState> toDomainList(List<AgentRuntimeStateTableData> rows) =>
      rows.map(toDomain).toList(growable: false);

  /// To companion.
  AgentRuntimeStateTableCompanion toCompanion(AgentRuntimeState s) =>
      AgentRuntimeStateTableCompanion(
        agentId: Value(s.agentId),
        workspaceId: Value(s.workspaceId),
        reportedStatus: Value(s.reportedStatus.name),
        lastHeartbeatAt: Value(s.lastHeartbeatAt),
        currentRunId: Value(s.currentRunId),
        note: Value(s.note),
        updatedAt: Value(s.updatedAt),
      );
}
