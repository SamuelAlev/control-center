import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_cost_history_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/model_routing/domain/entities/usage.dart';
import 'package:cc_domain/features/observability/domain/run_verification.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/agent_run_log_mapper.dart';
import 'package:cc_persistence/repositories/distinct_rows.dart';
import 'package:drift/drift.dart' as drift;

/// Drift-backed [AgentRunLogRepository] over the per-workspace [AgentDao]s.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).agentDao` per call: run logs live in their workspace's
/// own database file, so the workspace id picks the file before any SQL runs.
/// [watchAll] and [watchRecent] are the two reads that span files.
class DaoAgentRunLogRepository
    implements AgentRunLogRepository, AgentRunCostHistoryPort {
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
      // Deduped: drift re-runs this on ANY run-log write, so a run starting
      // for agent B re-emitted agent A's 200 rows through mapping, encoding
      // and a socket push. See `distinct_rows.dart`.
      distinctRows(
        _dao(workspaceId).watchLogsByAgent(workspaceId, agentId),
      ).map(_mapper.toDomainList);

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

  @override
  Future<List<UsageCostHistoryEntry>> costHistory(
    String workspaceId,
    DateTime since,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).costHistory(workspaceId, since.millisecondsSinceEpoch ~/ 1000);
    return [
      for (final row in rows)
        UsageCostHistoryEntry(
          recordedAt: row.startedAt,
          provider: row.adapter ?? 'agent',
          accountKey: row.adapter ?? 'agent',
          costUsd: row.costCents / 100.0,
        ),
    ];
  }

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
  ) => distinctRows(
    _dao(
      workspaceId,
    ).watchActiveLogsByConversation(workspaceId, conversationId),
  ).map(_mapper.toDomainList);

  @override
  Future<List<AgentRunLog>> activeByConversation(
    String workspaceId,
    String conversationId,
  ) => watchActiveByConversation(workspaceId, conversationId).first;

  @override
  Stream<List<AgentRunLog>> watchActiveBySpace(
    String workspaceId,
    String spaceId,
  ) => distinctRows(
    _dao(workspaceId).watchActiveLogsBySpace(workspaceId, spaceId),
  ).map(_mapper.toDomainList);

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) => distinctRows(
    _dao(workspaceId).watchLogsByConversation(workspaceId, conversationId),
  ).map(_mapper.toDomainList);

  @override
  Stream<List<AgentRunLog>> watchBySpace(String workspaceId, String spaceId) =>
      distinctRows(
        _dao(workspaceId).watchLogsBySpace(workspaceId, spaceId),
      ).map(_mapper.toDomainList);

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

  static AgentRunLogsTableCompanion _costColumns(RunCost cost) =>
      AgentRunLogsTableCompanion(
        inputTokens: drift.Value(cost.inputTokens),
        outputTokens: drift.Value(cost.outputTokens),
        thoughtTokens: drift.Value(cost.thoughtTokens),
        cachedReadTokens: drift.Value(cost.cachedReadTokens),
        cachedWriteTokens: drift.Value(cost.cachedWriteTokens),
        estimatedCostCents: drift.Value(cost.estimatedCostCents),
        costMicros: drift.Value(cost.costMicros),
        costBasis: drift.Value(cost.costBasis.name),
        durationMs: drift.Value(cost.durationMs),
        timeToFirstTokenMs: drift.Value(cost.timeToFirstTokenMs),
      );

  @override
  Future<void> updateCost(
    String workspaceId,
    String runId,
    RunCost cost,
  ) async {
    await _dao(
      workspaceId,
    ).updateLogCost(workspaceId, runId, _costColumns(cost));
  }

  @override
  Future<void> addChildCostMicros(
    String workspaceId,
    String runId,
    int amountMicros,
  ) async {
    if (amountMicros < 0) {
      throw ArgumentError.value(amountMicros, 'amountMicros', 'must be >= 0');
    }
    if (amountMicros == 0) {
      // Still resolve the workspace, so an invalid id cannot silently pass.
      _dao(workspaceId);
      return;
    }
    await _dao(
      workspaceId,
    ).addLogChildCostMicros(workspaceId, runId, amountMicros);
  }

  @override
  Future<bool> updateRuntime(
    String workspaceId,
    String runId, {
    int? pid,
    bool markRunning = false,
    String? logPath,
    String? contextSnapshotJson,
    DateTime? lastOutputAt,
    RunLiveness? liveness,
    RunErrorFamily? errorFamily,
    String? summary,
    String? modelId,
    String? effort,
    String? taskFamily,
  }) async {
    final dao = _dao(workspaceId);
    final hasMetadata =
        pid != null ||
        logPath != null ||
        contextSnapshotJson != null ||
        lastOutputAt != null ||
        liveness != null ||
        errorFamily != null ||
        summary != null ||
        modelId != null ||
        effort != null ||
        taskFamily != null;
    if (!hasMetadata && !markRunning) {
      return false;
    }
    return await dao.updateLogRuntime(
          workspaceId,
          runId,
          AgentRunLogsTableCompanion(
            pid: drift.Value.absentIfNull(pid),
            status: const drift.Value.absent(),
            logPath: drift.Value.absentIfNull(logPath),
            contextSnapshotJson: drift.Value.absentIfNull(contextSnapshotJson),
            lastOutputAt: drift.Value.absentIfNull(lastOutputAt),
            livenessClass: drift.Value.absentIfNull(liveness?.name),
            errorFamily: drift.Value.absentIfNull(errorFamily?.name),
            summary: drift.Value.absentIfNull(summary),
            modelId: drift.Value.absentIfNull(modelId),
            effort: drift.Value.absentIfNull(effort),
            taskFamily: drift.Value.absentIfNull(taskFamily),
          ),
          hasMetadata: hasMetadata,
          markRunning: markRunning,
        ) !=
        0;
  }

  @override
  Future<bool> completeIfActive(
    AgentRunLog completed, {
    bool writeCost = true,
  }) async {
    final workspaceId = completed.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      throw ArgumentError.value(
        completed.id,
        'completed.workspaceId',
        'a run log must carry the workspace it belongs to',
      );
    }
    if (completed.completedAt == null ||
        (completed.status != RunStatus.completed &&
            completed.status != RunStatus.error)) {
      throw ArgumentError.value(
        completed.id,
        'completed',
        'terminal write requires a completed/error status and timestamp',
      );
    }
    final row = AgentRunLogsTableCompanion(
      completedAt: drift.Value(completed.completedAt),
      status: drift.Value(completed.status.name),
      summary: drift.Value(completed.summary),
      livenessClass: drift.Value(completed.liveness?.name),
      latencyJson: drift.Value(
        completed.latency.isEmpty
            ? null
            : jsonEncode(completed.latency.toJson()),
      ),
      verificationStatus: drift.Value(completed.verification.status.wire),
      verificationJson: drift.Value(
        completed.verification.status == VerificationStatus.unverified
            ? null
            : jsonEncode(completed.verification.toJson()),
      ),
      nativeSessionId: drift.Value(completed.nativeSessionId),
      resumedNativeSession: drift.Value(completed.resumedNativeSession),
      // No final cost report: stamp elapsed time, but preserve usage that a
      // concurrent updateCost may already have recorded.
      durationMs: writeCost
          ? const drift.Value.absent()
          : drift.Value(completed.cost.durationMs),
    );
    final terminal = writeCost
        ? row.copyWith(
            inputTokens: drift.Value(completed.cost.inputTokens),
            outputTokens: drift.Value(completed.cost.outputTokens),
            thoughtTokens: drift.Value(completed.cost.thoughtTokens),
            cachedReadTokens: drift.Value(completed.cost.cachedReadTokens),
            cachedWriteTokens: drift.Value(completed.cost.cachedWriteTokens),
            estimatedCostCents: drift.Value(completed.cost.estimatedCostCents),
            costMicros: drift.Value(completed.cost.costMicros),
            costBasis: drift.Value(completed.cost.costBasis.name),
            durationMs: drift.Value(completed.cost.durationMs),
            timeToFirstTokenMs: drift.Value(completed.cost.timeToFirstTokenMs),
          )
        : row;
    return await _dao(
          workspaceId,
        ).completeLogIfActive(workspaceId, completed.id, terminal) !=
        0;
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
        spaceId: drift.Value.absentIfNull(log.spaceId),
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
        costMicros: drift.Value(log.cost.costMicros),
        costBasis: drift.Value(log.cost.costBasis.name),
        childCostCents: drift.Value(log.childCostCents),
        childCostMicros: drift.Value(log.childCostMicros),
        effort: drift.Value.absentIfNull(log.effort),
        taskFamily: drift.Value.absentIfNull(log.taskFamily),
        nativeSessionId: drift.Value.absentIfNull(log.nativeSessionId),
        resumedNativeSession: drift.Value(log.resumedNativeSession),
        latencyJson: drift.Value.absentIfNull(
          // An empty profile is written as NULL, not `[]`: "no stage was ever
          // observed" and "the array is empty" are the same fact, and NULL is
          // what a legacy row has.
          log.latency.isEmpty ? null : jsonEncode(log.latency.toJson()),
        ),
        verificationStatus: drift.Value(log.verification.status.wire),
        verificationJson: drift.Value.absentIfNull(
          log.verification.status == VerificationStatus.unverified
              ? null
              : jsonEncode(log.verification.toJson()),
        ),
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
        pipelineStepId: drift.Value.absentIfNull(log.pipelineStepId),
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
