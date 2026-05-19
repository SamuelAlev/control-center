import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/agent_run_log_mapper.dart';
import 'package:drift/drift.dart' as drift;

/// Drift-backed [AgentRunLogRepository] over the per-workspace [AgentDao]s.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).agentDao` per call: run logs live in their workspace's
/// own database file, so the workspace id picks the file before any SQL runs.
/// [watchAll] and [watchRecent] are the two reads that span files.
class DaoAgentRunLogRepository implements AgentRunLogRepository {
  /// Creates a [DaoAgentRunLogRepository] over the per-workspace databases.
  DaoAgentRunLogRepository(this._dbs) : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final AgentRunLogMapper _mapper = const AgentRunLogMapper();

  AgentDao _dao(String workspaceId) => _dbs.of(workspaceId).agentDao;

  /// Newest-first, the order every run-log query uses. Applied to the merged
  /// list of the cross-workspace reads, which concatenation would otherwise
  /// leave interleaved by workspace.
  static int _newestFirst(AgentRunLogsTableData a, AgentRunLogsTableData b) =>
      b.startedAt.compareTo(a.startedAt);

  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) =>
      _dao(
        workspaceId,
      ).watchLogsByAgent(workspaceId, agentId).map(_mapper.toDomainList);

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => _mapper.toDomainList(
    await _dao(workspaceId).logsForPipelineRun(workspaceId, pipelineRunId),
  );

  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => _mapper.toDomainList(
    await _dao(
      workspaceId,
    ).logsForPipelineStep(workspaceId, pipelineRunId, pipelineStepId),
  );

  /// CROSS-WORKSPACE BY DESIGN: the completeness-critical system jobs (the
  /// orphan-run reaper, cost rollups, process detection) are defined over every
  /// workspace, so this watch merges one stream per workspace file. Live UI
  /// should prefer [watchRecent]; a workspace-scoped surface uses
  /// [watchByAgent].
  @override
  Stream<List<AgentRunLog>> watchAll() => _cross
      .mergeStreams((db) => db.agentDao.watchAllLogs(), sort: _newestFirst)
      .map(_mapper.toDomainList);

  /// CROSS-WORKSPACE BY DESIGN: the bounded companion to [watchAll] for live
  /// dashboards. [limit] rows are taken from every workspace file before the
  /// merge, because taking fewer could drop a row that outranks another
  /// workspace's; the merged list is then trimmed back to [limit].
  @override
  Stream<List<AgentRunLog>> watchRecent(int limit) => _cross
      .mergeStreams(
        (db) => db.agentDao.watchRecentLogs(limit),
        sort: _newestFirst,
        limit: limit,
      )
      .map(_mapper.toDomainList);

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) => _dao(workspaceId)
      .watchActiveLogsByConversation(workspaceId, conversationId)
      .map(_mapper.toDomainList);

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) => _dao(workspaceId)
      .watchLogsByConversation(workspaceId, conversationId)
      .map(_mapper.toDomainList);

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getLogById(id);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async {
    final row = await _dao(workspaceId).getActiveLogByAgent(agentId);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<void> upsert(AgentRunLog log) async {
    // A run log is stored in its own workspace's file, so [AgentRunLog
    // .workspaceId] is what picks that file. The field is nullable for historic
    // reasons but a workspace-less run has nowhere to be written: reject it
    // loudly here rather than guessing a workspace or dropping the row.
    //
    // `async` matters: without it the throw escapes SYNCHRONOUSLY instead of
    // completing the returned future with an error, so `upsert(x).catchError(…)`
    // and `unawaited(upsert(x))` both blow past their handler.
    final workspaceId = log.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      throw ArgumentError.value(
        log.id,
        'log.workspaceId',
        'a run log must carry the workspace it belongs to',
      );
    }
    return _dao(workspaceId).upsertLog(
      AgentRunLogsTableCompanion(
        id: drift.Value(log.id),
        agentId: drift.Value(log.agentId),
        workspaceId: drift.Value(workspaceId),
        conversationId: drift.Value.absentIfNull(log.conversationId),
        ticketId: drift.Value.absentIfNull(log.ticketId),
        channelId: drift.Value.absentIfNull(log.channelId),
        startedAt: drift.Value(log.startedAt),
        completedAt: drift.Value.absentIfNull(log.completedAt),
        status: drift.Value(log.status.name),
        summary: drift.Value.absentIfNull(log.summary),
        adapter: drift.Value.absentIfNull(log.adapter),
        modelId: drift.Value.absentIfNull(log.modelId),
        pid: drift.Value.absentIfNull(log.pid),
        logPath: drift.Value.absentIfNull(log.logPath),
        inputTokens: drift.Value(log.cost.inputTokens),
        outputTokens: drift.Value(log.cost.outputTokens),
        thoughtTokens: drift.Value(log.cost.thoughtTokens),
        cachedReadTokens: drift.Value(log.cost.cachedReadTokens),
        cachedWriteTokens: drift.Value(log.cost.cachedWriteTokens),
        estimatedCostCents: drift.Value(log.cost.estimatedCostCents),
        childCostCents: drift.Value(log.childCostCents),
        agentRole: drift.Value(log.role.name),
        durationMs: drift.Value.absentIfNull(log.cost.durationMs),
        timeToFirstTokenMs: drift.Value.absentIfNull(
          log.cost.timeToFirstTokenMs,
        ),
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
        outputContractMode: drift.Value(
          log.outputContractMode.toStorageString(),
        ),
        outputJson: drift.Value.absentIfNull(
          log.outputJson == null ? null : jsonEncode(log.outputJson),
        ),
        outputRejections: drift.Value(log.outputRejections),
        retryOfRunId: drift.Value.absentIfNull(log.retry.parentRunId),
        retryAttempt: drift.Value(log.retry.attempt),
        parentRunId: drift.Value.absentIfNull(log.parentRunId),
        spawnToolCallId: drift.Value.absentIfNull(log.spawnToolCallId),
      ),
    );
  }
}
