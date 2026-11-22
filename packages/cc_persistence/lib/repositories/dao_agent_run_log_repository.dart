import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_cost_history_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_output_port.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/ports/wake_run_ledger.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/model_routing/domain/entities/usage.dart';
import 'package:cc_domain/features/observability/domain/run_verification.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/agent_run_log_mapper.dart';
import 'package:cc_persistence/repositories/distinct_rows.dart';
import 'package:cc_persistence/src/log/cc_persistence_log.dart';
import 'package:drift/drift.dart' as drift;

/// Drift-backed [AgentRunLogRepository] over the per-workspace [AgentDao]s.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).agentDao` per call: run logs live in their workspace's
/// own database file, so the workspace id picks the file before any SQL runs.
/// [nonTerminal] and [watchRecent] are the two reads that span files.
///
/// A run is stored as its run-log row plus, once it has one, a payload row
/// (`agent_run_payloads`: prompt-context snapshot, output contract, output,
/// verification detail). Lists and watches read the
/// run-log row alone, so their runs carry no payload fields. [getById],
/// [activeRunForAgent], [latestForTicket] and [forPipelineStep] read both and
/// return the whole run. Every write sends each row only the columns it
/// changes: a status or counter write never touches the payload row, and
/// [recordOutput] never touches the run-log row.
class DaoAgentRunLogRepository
    implements
        AgentRunLogRepository,
        AgentRunCostHistoryPort,
        AgentRunOutputPort,
        WakeRunLedger {
  /// Creates a [DaoAgentRunLogRepository] over the per-workspace databases.
  DaoAgentRunLogRepository(this._dbs) : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final AgentRunLogMapper _mapper = const AgentRunLogMapper();

  AgentDao _dao(String workspaceId) => _dbs.of(workspaceId).agentDao;

  /// Newest-first, the order every run-log query uses (`started_at`, then
  /// `id`). Applied to the merged list of the cross-workspace reads, which
  /// concatenation would otherwise leave interleaved by workspace.
  static int _newestFirst(AgentRunLogsTableData a, AgentRunLogsTableData b) {
    final byStart = b.startedAt.compareTo(a.startedAt);
    return byStart != 0 ? byStart : b.id.compareTo(a.id);
  }

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

  /// Whole runs, payloads included: the engine harvests their output.
  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => [
    for (final row in await _dao(
      workspaceId,
    ).logsForPipelineStep(workspaceId, pipelineRunId, pipelineStepId))
      _mapper.toDomainWithPayload(row),
  ];

  /// CROSS-WORKSPACE BY DESIGN: the liveness jobs (the orphan-run reaper,
  /// process detection) are defined over every workspace, so this reads each
  /// workspace file's unfinished runs and merges them.
  @override
  Future<List<AgentRunLog>> nonTerminal() async {
    final perWorkspace = await _cross.fanOut(
      (db) => db.agentDao.nonTerminalLogs(),
      onError: (workspaceId, error) => CcPersistenceLog.warning(
        'DaoAgentRunLogRepository: unfinished-run read failed for workspace '
        '$workspaceId: $error',
      ),
      backgroundWriter: 'unfinished-run reconciler',
    );
    final rows = [for (final list in perWorkspace) ...list]..sort(_newestFirst);
    return _mapper.toDomainList(rows);
  }

  @override
  Stream<List<AgentRunLog>> watchNonTerminalForWorkspace(String workspaceId) =>
      distinctRows(
        _dao(workspaceId).watchNonTerminalLogs(workspaceId),
      ).map(_mapper.toDomainList);

  @override
  Future<AgentRunLog?> latestForTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final row = await _dao(
      workspaceId,
    ).latestLogForTicket(workspaceId, ticketId);
    return row == null ? null : _mapper.toDomainWithPayload(row);
  }

  /// One keyset page of [workspaceId]'s run history, newest first: at most
  /// [limit] runs started strictly before [before] (by `started_at`, then
  /// `id`), or the newest when [before] is null. Narrowed by any of
  /// [agentId], [spaceId] and [conversationId].
  ///
  /// The watches show a bounded newest window; this is how a history view
  /// reads past it without an `OFFSET` scan. Server-side, like
  /// [costHistory]: not part of the client-reachable interface.
  Future<List<AgentRunLog>> page(
    String workspaceId, {
    required int limit,
    String? agentId,
    String? spaceId,
    String? conversationId,
    AgentRunLog? before,
  }) async => _mapper.toDomainList(
    await _dao(workspaceId).logsPage(
      workspaceId,
      limit: limit,
      agentId: agentId,
      spaceId: spaceId,
      conversationId: conversationId,
      beforeStartedAt: before?.startedAt,
      beforeId: before?.id,
    ),
  );

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
          costMicros: row.costMicros,
        ),
    ];
  }

  /// CROSS-WORKSPACE BY DESIGN: the bounded global view for live
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
    return row == null ? null : _mapper.toDomainWithPayload(row);
  }

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async {
    final row = await _dao(workspaceId).getActiveLogByAgent(agentId);
    return row == null ? null : _mapper.toDomainWithPayload(row);
  }

  @override
  Future<void> recordOutput(
    String workspaceId,
    String runId,
    Map<String, dynamic> output,
  ) async {
    await _dao(workspaceId).writePayload(
      workspaceId,
      runId,
      AgentRunPayloadsTableCompanion(
        outputJson: drift.Value(jsonEncode(output)),
      ),
    );
  }

  @override
  Future<int?> addOutputRejection(String workspaceId, String runId) =>
      _dao(workspaceId).addOutputRejection(workspaceId, runId);

  /// The payload columns [log] carries. A null field is absent, never a
  /// clear: a run read from a list has no payload fields, and writing it back
  /// must leave its payload row as it is.
  static AgentRunPayloadsTableCompanion _payloadOf(AgentRunLog log) =>
      AgentRunPayloadsTableCompanion(
        contextSnapshotJson: drift.Value.absentIfNull(log.contextSnapshotJson),
        expectedOutputSchema: drift.Value.absentIfNull(
          log.expectedOutputSchema == null
              ? null
              : jsonEncode(log.expectedOutputSchema),
        ),
        outputJson: drift.Value.absentIfNull(
          log.outputJson == null ? null : jsonEncode(log.outputJson),
        ),
        verificationJson: _verificationDetail(log.verification),
      );

  /// The verification detail to store for [verification], or absent when it
  /// has none: the verdict alone is `agent_run_logs.verification_status`, and
  /// a run read from a list carries the verdict without its detail.
  static drift.Value<String?> _verificationDetail(
    RunVerification verification,
  ) {
    final hasDetail =
        verification.verifier != null ||
        verification.verifiedAt != null ||
        verification.notes != null;
    return verification.isChecked && hasDetail
        ? drift.Value(jsonEncode(verification.toJson()))
        : const drift.Value.absent();
  }

  static AgentRunLogsTableCompanion _costColumns(RunCost cost) =>
      AgentRunLogsTableCompanion(
        inputTokens: drift.Value(cost.inputTokens),
        outputTokens: drift.Value(cost.outputTokens),
        thoughtTokens: drift.Value(cost.thoughtTokens),
        cachedReadTokens: drift.Value(cost.cachedReadTokens),
        cachedWriteTokens: drift.Value(cost.cachedWriteTokens),
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
            logPath: drift.Value.absentIfNull(logPath),
            lastOutputAt: drift.Value.absentIfNull(lastOutputAt),
            livenessClass: drift.Value.absentIfNull(liveness?.name),
            errorFamily: drift.Value.absentIfNull(errorFamily?.name),
            summary: drift.Value.absentIfNull(summary),
            modelId: drift.Value.absentIfNull(modelId),
            effort: drift.Value.absentIfNull(effort),
            taskFamily: drift.Value.absentIfNull(taskFamily),
          ),
          AgentRunPayloadsTableCompanion(
            contextSnapshotJson: drift.Value.absentIfNull(contextSnapshotJson),
          ),
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
      errorCode: drift.Value(completed.errorCode),
      livenessClass: drift.Value(completed.liveness?.name),
      latencyJson: drift.Value(
        completed.latency.isEmpty
            ? null
            : jsonEncode(completed.latency.toJson()),
      ),
      verificationStatus: drift.Value(completed.verification.status.wire),
      nativeSessionId: drift.Value(completed.nativeSessionId),
      resumedNativeSession: drift.Value(completed.resumedNativeSession),
      // Absent rather than cleared when the caller has no reason: a reason an
      // earlier write recorded (the stop path) is never erased.
      endReason: drift.Value.absentIfNull(completed.endReason?.wire),
      // No `wake_ids`: the list is written when the run starts and grows as
      // the run drains pushed wakes ([addWakeIds]); a terminal write built
      // from the run's start would drop what it drained.
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
            costMicros: drift.Value(completed.cost.costMicros),
            costBasis: drift.Value(completed.cost.costBasis.name),
            durationMs: drift.Value(completed.cost.durationMs),
            timeToFirstTokenMs: drift.Value(completed.cost.timeToFirstTokenMs),
          )
        : row;
    return await _dao(workspaceId).completeLogIfActive(
          workspaceId,
          completed.id,
          terminal,
          AgentRunPayloadsTableCompanion(
            verificationJson: _verificationDetail(completed.verification),
          ),
        ) !=
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
        costMicros: drift.Value(log.cost.costMicros),
        costBasis: drift.Value(log.cost.costBasis.name),
        childCostMicros: drift.Value(log.childCostMicros),
        effort: drift.Value.absentIfNull(log.effort),
        taskFamily: drift.Value.absentIfNull(log.taskFamily),
        nativeSessionId: drift.Value.absentIfNull(log.nativeSessionId),
        resumedNativeSession: drift.Value(log.resumedNativeSession),
        latencyJson: drift.Value.absentIfNull(
          // An empty profile is written as NULL, not `[]`: "no stage was ever
          // observed" and "the array is empty" are the same fact.
          log.latency.isEmpty ? null : jsonEncode(log.latency.toJson()),
        ),
        verificationStatus: drift.Value(log.verification.status.wire),
        agentRole: drift.Value(log.role.name),
        durationMs: drift.Value.absentIfNull(log.cost.durationMs),
        timeToFirstTokenMs: drift.Value.absentIfNull(
          log.cost.timeToFirstTokenMs,
        ),
        livenessClass: drift.Value.absentIfNull(log.liveness?.name),
        errorFamily: drift.Value.absentIfNull(log.errorFamily?.name),
        lastOutputAt: drift.Value.absentIfNull(log.lastOutputAt),
        pipelineRunId: drift.Value.absentIfNull(log.pipelineRunId),
        pipelineStepId: drift.Value.absentIfNull(log.pipelineStepId),
        errorCode: drift.Value.absentIfNull(log.errorCode),
        outputContractMode: drift.Value(
          log.outputContractMode.toStorageString(),
        ),
        outputRejections: drift.Value(log.outputRejections),
        retryOfRunId: drift.Value.absentIfNull(log.retry.parentRunId),
        retryAttempt: drift.Value(log.retry.attempt),
        parentRunId: drift.Value.absentIfNull(log.parentRunId),
        spawnToolCallId: drift.Value.absentIfNull(log.spawnToolCallId),
        endReason: drift.Value.absentIfNull(log.endReason?.wire),
        wakeIds: _wakeIdsOf(log),
        // Absent when null, so a later write of a run built without it never
        // turns a person's run into a bot run.
        requestedByUserId: drift.Value.absentIfNull(log.requestedByUserId),
        // Absent when null for the same reason: a later write never clears
        // why the run started.
        wakeReason: drift.Value.absentIfNull(log.wakeReason?.wire),
        // Absent when null: a later write never clears which run started it.
        startedByRunId: drift.Value.absentIfNull(log.startedByRunId),
      ),
      _payloadOf(log),
    );
  }

  /// `agent_run_logs.wake_ids` for [log]: written when the run carries wake
  /// ids, absent otherwise, so a write of a run built without them (a status
  /// update from a caller that never read them) never clears the record of
  /// which wakes the run delivered.
  static drift.Value<String> _wakeIdsOf(AgentRunLog log) => log.wakeIds.isEmpty
      ? const drift.Value.absent()
      : drift.Value(jsonEncode(log.wakeIds));

  @override
  Future<WakeLedgerRun?> runForWake(String workspaceId, String wakeId) async {
    // The newest run: a wake reopened after a server stop and delivered
    // again is on two runs, and only the later one says what became of it.
    final rows = await _dbs
        .of(workspaceId)
        .customSelect(
          'SELECT id, completed_at, end_reason FROM agent_run_logs '
          'WHERE wake_ids IS NOT NULL AND '
          'EXISTS (SELECT 1 FROM json_each(agent_run_logs.wake_ids) '
          'WHERE json_each.value = ?) ORDER BY started_at DESC, id DESC '
          'LIMIT 1',
          variables: [drift.Variable.withString(wakeId)],
        )
        .get();
    final row = rows.firstOrNull;
    if (row == null) {
      return null;
    }
    return WakeLedgerRun(
      runId: row.read<String>('id'),
      live: row.readNullable<DateTime>('completed_at') == null,
      endReason: RunEndReasonWire.tryParse(
        row.readNullable<String>('end_reason'),
      ),
    );
  }

  @override
  Future<void> addWakeIds(
    String workspaceId,
    String runId,
    List<String> wakeIds,
  ) async {
    if (wakeIds.isEmpty) {
      return;
    }
    final db = _dbs.of(workspaceId);
    await db.transaction(() async {
      final rows = await db
          .customSelect(
            'SELECT wake_ids FROM agent_run_logs WHERE id = ?',
            variables: [drift.Variable.withString(runId)],
          )
          .get();
      final row = rows.firstOrNull;
      if (row == null) {
        return;
      }
      final stored = row.read<String?>('wake_ids');
      final ids = <String>[
        if (stored != null)
          for (final id in jsonDecode(stored) as List) '$id',
      ];
      final merged = [...ids, ...wakeIds.where((id) => !ids.contains(id))];
      if (merged.length == ids.length) {
        return;
      }
      await db.customUpdate(
        'UPDATE agent_run_logs SET wake_ids = ? WHERE id = ?',
        variables: [
          drift.Variable.withString(jsonEncode(merged.toSet().toList())),
          drift.Variable.withString(runId),
        ],
        updates: {db.agentRunLogsTable},
      );
    });
  }
}
