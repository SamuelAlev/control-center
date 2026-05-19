import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/mappers/agent_run_log_mapper.dart';
import 'package:drift/drift.dart' as drift;

/// Drift-backed [AgentRunLogRepository] that reads from [AgentDao].
class DaoAgentRunLogRepository implements AgentRunLogRepository {
  /// Creates a new [DaoAgentRunLogRepository].
  DaoAgentRunLogRepository(this._dao);

  final AgentDao _dao;
  final AgentRunLogMapper _mapper = const AgentRunLogMapper();

  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) =>
      _dao.watchLogsByAgent(workspaceId, agentId).map(_mapper.toDomainList);

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async =>
      _mapper.toDomainList(
        await _dao.logsForPipelineRun(workspaceId, pipelineRunId),
      );

  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async =>
      _mapper.toDomainList(
        await _dao.logsForPipelineStep(workspaceId, pipelineRunId, pipelineStepId),
      );

  @override
  Stream<List<AgentRunLog>> watchAll() =>
      _dao.watchAllLogs().map(_mapper.toDomainList);

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) =>
      _dao
          .watchActiveLogsByConversation(workspaceId, conversationId)
          .map(_mapper.toDomainList);

  @override
  Future<AgentRunLog?> getById(String id) async {
    final row = await _dao.getLogById(id);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<AgentRunLog?> activeRunForAgent(String agentId) async {
    final row = await _dao.getActiveLogByAgent(agentId);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<void> upsert(AgentRunLog log) => _dao.upsertLog(
    AgentRunLogsTableCompanion(
      id: drift.Value(log.id),
      agentId: drift.Value(log.agentId),
      workspaceId: drift.Value.absentIfNull(log.workspaceId),
      conversationId: drift.Value.absentIfNull(log.conversationId),
      ticketId: drift.Value.absentIfNull(log.ticketId),
      channelId: drift.Value.absentIfNull(log.channelId),
      startedAt: drift.Value(log.startedAt),
      completedAt: drift.Value.absentIfNull(log.completedAt),
      status: drift.Value(log.status.name),
      summary: drift.Value.absentIfNull(log.summary),
      adapter: drift.Value.absentIfNull(log.adapter),
      pid: drift.Value.absentIfNull(log.pid),
      logPath: drift.Value.absentIfNull(log.logPath),
      inputTokens: drift.Value(log.cost.inputTokens),
      outputTokens: drift.Value(log.cost.outputTokens),
      estimatedCostCents: drift.Value(log.cost.estimatedCostCents),
      livenessClass: drift.Value.absentIfNull(log.liveness?.name),
      errorFamily: drift.Value.absentIfNull(log.errorFamily?.name),
      lastOutputAt: drift.Value.absentIfNull(log.lastOutputAt),
      continuationSummary: drift.Value.absentIfNull(log.continuationSummary),
      contextSnapshotJson: drift.Value.absentIfNull(log.contextSnapshotJson),
      pipelineRunId: drift.Value.absentIfNull(log.pipelineRunId),
      pipelineStepRunId: drift.Value.absentIfNull(log.pipelineStepRunId),
      errorCode: drift.Value.absentIfNull(log.errorCode),
      expectedOutputSchema: drift.Value.absentIfNull(
        log.expectedOutputSchema == null
            ? null
            : jsonEncode(log.expectedOutputSchema),
      ),
      outputContractMode: drift.Value(log.outputContractMode.toStorageString()),
      outputJson: drift.Value.absentIfNull(
        log.outputJson == null ? null : jsonEncode(log.outputJson),
      ),
      outputRejections: drift.Value(log.outputRejections),
      retryOfRunId: drift.Value.absentIfNull(log.retry.parentRunId),
      retryAttempt: drift.Value(log.retry.attempt),
    ),
  );
}

