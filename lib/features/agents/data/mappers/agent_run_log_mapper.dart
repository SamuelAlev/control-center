import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/value_objects/retry_meta.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';

/// Maps database agent run log rows to domain [AgentRunLog] entities.
class AgentRunLogMapper {
  /// Creates a const [AgentRunLogMapper].
  const AgentRunLogMapper();

  /// Converts a single database row into an [AgentRunLog] domain entity.
  AgentRunLog toDomain(AgentRunLogsTableData row) {
    return AgentRunLog(
      id: row.id,
      agentId: row.agentId,
      workspaceId: row.workspaceId,
      conversationId: row.conversationId,
      ticketId: row.ticketId,
      channelId: row.channelId,
      startedAt: row.startedAt,
      completedAt: row.completedAt,
      status: _parseRunStatus(row.status),
      summary: row.summary,
      adapter: row.adapter,
      pid: row.pid,
      logPath: row.logPath,
      cost: RunCost(
        inputTokens: row.inputTokens,
        outputTokens: row.outputTokens,
        estimatedCostCents: row.estimatedCostCents,
      ),
      liveness: RunLiveness.tryParse(row.livenessClass),
      errorFamily: RunErrorFamily.tryParse(row.errorFamily),
      lastOutputAt: row.lastOutputAt,
      continuationSummary: row.continuationSummary,
      contextSnapshotJson: row.contextSnapshotJson,
      pipelineRunId: row.pipelineRunId,
      pipelineStepRunId: row.pipelineStepRunId,
      errorCode: row.errorCode,
      retry: RetryMeta(
        parentRunId: row.retryOfRunId,
        attempt: row.retryAttempt,
      ),
    );
  }

  /// Converts a list of database rows into a list of [AgentRunLog] domain entities.
  List<AgentRunLog> toDomainList(List<AgentRunLogsTableData> rows) =>
      rows.map(toDomain).toList(growable: false);

  static RunStatus _parseRunStatus(String value) {
    return switch (value) {
      'pending' => RunStatus.pending,
      'running' => RunStatus.running,
      'completed' => RunStatus.completed,
      'error' => RunStatus.error,
      _ => RunStatus.error,
    };
  }
}

