import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/code_mode_tables.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'code_mode_dao.g.dart';

/// The position of one execution in the newest-first order: the exclusive
/// start of the next, older page.
typedef CodeExecutionPosition = ({int startedAtMs, String id});

/// What [CodeModeDao.beginExecution] did.
enum CodeExecutionBeginResult {
  /// The running execution and its payload were written.
  begun,

  /// Nothing was written: the execution's run has no run log in this file.
  noRun,

  /// Nothing was written: an execution with this id is already recorded.
  idTaken,

  /// Nothing was written: the execution names a space this file no longer
  /// has.
  spaceGone,
}

/// What [CodeModeDao.appendCall] did.
enum CodeExecutionAppendResult {
  /// The call row was written.
  appended,

  /// Nothing was written: the execution is not running (finished, or gone).
  notRunning,

  /// Nothing was written: the execution already has a call with this
  /// sequence.
  sequenceTaken,
}

/// What [CodeModeDao.finishExecution] did.
enum CodeExecutionFinishOutcome {
  /// The running execution was finished.
  finished,

  /// Nothing was written: no execution with this id exists any more (it was
  /// deleted with its run or its space).
  gone,

  /// Nothing was written: the execution is already finished, and a finished
  /// record never changes.
  alreadyFinished,
}

/// Data access for code mode in ONE workspace: the execution audit rows
/// (`code_executions`, `code_execution_payloads`, `code_execution_calls`) and
/// the values scripts stored (`code_mode_store`).
///
/// Every method is scoped by hanging off a [WorkspaceDatabase]: the isolation
/// boundary is the database file.
@DriftAccessor(
  tables: [
    AgentRunLogsTable,
    AgentsTable,
    ConversationsTable,
    SpacesTable,
    CodeExecutionsTable,
    CodeExecutionPayloadsTable,
    CodeExecutionCallsTable,
    CodeModeStoreTable,
  ],
)
class CodeModeDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$CodeModeDaoMixin {
  /// Creates a [CodeModeDao] bound to one workspace's database.
  CodeModeDao(super.attachedDatabase);

  /// The `status` of an execution that has not ended.
  static const String runningStatus = 'running';

  // ── Executions ──

  /// Records an admitted script: its [execution] row (status `running`) and
  /// its [payload] (the source), in one transaction, or writes nothing and
  /// says why not.
  ///
  /// The run, the id and the space are checked inside the transaction
  /// rather than left to the constraints, so a caller learns which rule
  /// refused the write instead of reading a constraint error. A conversation
  /// or agent the row names that is gone from this file is recorded as none:
  /// those rows can be deleted at any moment, who may read a record does not
  /// depend on them, and the audit record must not be lost to one deleted a
  /// moment before the script was admitted. A space that is gone is refused:
  /// the space decides who may read the record, and a record with none is
  /// readable by every member.
  Future<CodeExecutionBeginResult> beginExecution(
    CodeExecutionsTableCompanion execution,
    CodeExecutionPayloadsTableCompanion payload,
  ) => transaction(() async {
    if (!await _exists(
      agentRunLogsTable,
      agentRunLogsTable.id,
      execution.runId.value,
    )) {
      return CodeExecutionBeginResult.noRun;
    }
    final id = execution.id.value;
    if (await _exists(codeExecutionsTable, codeExecutionsTable.id, id)) {
      return CodeExecutionBeginResult.idTaken;
    }
    final spaceId = execution.spaceId.present ? execution.spaceId.value : null;
    if (spaceId != null &&
        !await _exists(spacesTable, spacesTable.id, spaceId)) {
      return CodeExecutionBeginResult.spaceGone;
    }
    Future<Value<String?>> live<T extends HasResultSet, D>(
      ResultSetImplementation<T, D> table,
      GeneratedColumn<String> column,
      Value<String?> value,
    ) async {
      final ref = value.present ? value.value : null;
      return ref != null && await _exists(table, column, ref)
          ? Value(ref)
          : const Value(null);
    }

    await into(codeExecutionsTable).insert(
      execution.copyWith(
        conversationId: await live(
          conversationsTable,
          conversationsTable.id,
          execution.conversationId,
        ),
        agentId: await live(agentsTable, agentsTable.id, execution.agentId),
      ),
    );
    await into(codeExecutionPayloadsTable).insert(payload);
    return CodeExecutionBeginResult.begun;
  });

  /// Records one settled nested call of execution `call.executionId`, only
  /// while that execution is running, or writes nothing and says why not.
  /// A call row is insert-only: one with a sequence already recorded is
  /// refused, never replaced.
  Future<CodeExecutionAppendResult> appendCall(
    CodeExecutionCallsTableCompanion call,
  ) => transaction(() async {
    final id = call.executionId.value;
    if (await _statusOf(id) != runningStatus) {
      return CodeExecutionAppendResult.notRunning;
    }
    final existing =
        await (selectOnly(codeExecutionCallsTable)
              ..addColumns([codeExecutionCallsTable.sequence])
              ..where(
                codeExecutionCallsTable.executionId.equals(id) &
                    codeExecutionCallsTable.sequence.equals(
                      call.sequence.value,
                    ),
              )
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) {
      return CodeExecutionAppendResult.sequenceTaken;
    }
    await into(codeExecutionCallsTable).insert(call);
    return CodeExecutionAppendResult.appended;
  });

  /// Finishes the running execution [id]: [terminal]'s columns on the row,
  /// the output, console and error name on its payload, and those of [calls]
  /// whose sequence has no row yet inserted, in one transaction that only a
  /// row still `running` passes (the update is conditional on the status, so
  /// two finishes cannot both win). A call row already recorded is kept as
  /// it is: a call appended while the finish was on its way must not roll
  /// the finish back and leave the record running.
  ///
  /// [terminal] must hold only the columns that describe how the script
  /// ended; what [beginExecution] wrote (the run, the conversation, agent and
  /// space, the description, the start, the source) is never rewritten, so a
  /// row those point at that was deleted meanwhile cannot fail this write.
  Future<CodeExecutionFinishOutcome> finishExecution({
    required String id,
    required CodeExecutionsTableCompanion terminal,
    required String output,
    required String console,
    required String? errorName,
    required List<CodeExecutionCallsTableCompanion> calls,
  }) => transaction(() async {
    final updated =
        await (update(codeExecutionsTable)
              ..where((t) => t.id.equals(id) & t.status.equals(runningStatus)))
            .write(terminal);
    if (updated == 0) {
      return await _statusOf(id) == null
          ? CodeExecutionFinishOutcome.gone
          : CodeExecutionFinishOutcome.alreadyFinished;
    }
    await (update(
      codeExecutionPayloadsTable,
    )..where((t) => t.executionId.equals(id))).write(
      CodeExecutionPayloadsTableCompanion(
        output: Value(output),
        console: Value(console),
        errorName: Value(errorName),
      ),
    );
    if (calls.isNotEmpty) {
      final recorded = {
        for (final row
            in await (selectOnly(codeExecutionCallsTable)
                  ..addColumns([codeExecutionCallsTable.sequence])
                  ..where(codeExecutionCallsTable.executionId.equals(id)))
                .get())
          row.read(codeExecutionCallsTable.sequence),
      };
      for (final call in calls) {
        if (!recorded.contains(call.sequence.value)) {
          await into(codeExecutionCallsTable).insert(call);
        }
      }
    }
    return CodeExecutionFinishOutcome.finished;
  });

  /// Ends the running execution [id] with [status], [errorKind] and
  /// [durationMs] and nothing else. Returns whether a running row was
  /// changed. The smallest write that ends a record: it touches no payload
  /// and no call row, so nothing another write left behind can fail it.
  Future<bool> closeRunning({
    required String id,
    required String status,
    required String errorKind,
    required int durationMs,
  }) async {
    final updated =
        await (update(codeExecutionsTable)
              ..where((t) => t.id.equals(id) & t.status.equals(runningStatus)))
            .write(
              CodeExecutionsTableCompanion(
                status: Value(status),
                errorKind: Value(errorKind),
                durationMs: Value(durationMs),
              ),
            );
    return updated > 0;
  }

  /// Finishes every execution still `running` as [status] / [errorKind],
  /// with the time from its start to [nowMs] (at least 0) as its duration.
  /// Returns how many.
  ///
  /// For the boot sweep, which runs before the server admits a script: a
  /// script runs only inside the server process that admitted it, so every
  /// row still running then belonged to a process that is gone. No row is
  /// judged by its start time, so a clock that stepped cannot hide one.
  Future<int> finishAllRunning({
    required int nowMs,
    required String status,
    required String errorKind,
  }) => customUpdate(
    'UPDATE code_executions SET status = ?, error_kind = ?, '
    'duration_ms = MAX(0, ? - started_at_ms) '
    'WHERE status = ?',
    variables: [
      Variable.withString(status),
      Variable.withString(errorKind),
      Variable.withInt(nowMs),
      Variable.withString(runningStatus),
    ],
    updates: {codeExecutionsTable},
    updateKind: UpdateKind.update,
  );

  /// The highest [CodeExecutionsTable.idSuffix] recorded for `repl` call
  /// [toolCallId] of run [runId], or 0 when there is none: one read on
  /// `idx_code_executions_run_tool_call_suffix`.
  Future<int> highestIdSuffix(String runId, String toolCallId) async {
    final highest = codeExecutionsTable.idSuffix.max();
    final row =
        await (selectOnly(codeExecutionsTable)
              ..addColumns([highest])
              ..where(
                codeExecutionsTable.runId.equals(runId) &
                    codeExecutionsTable.toolCallId.equals(toolCallId),
              ))
            .getSingle();
    return row.read(highest) ?? 0;
  }

  Future<String?> _statusOf(String id) async {
    final row =
        await (selectOnly(codeExecutionsTable)
              ..addColumns([codeExecutionsTable.status])
              ..where(codeExecutionsTable.id.equals(id))
              ..limit(1))
            .getSingleOrNull();
    return row?.read(codeExecutionsTable.status);
  }

  Future<bool> _exists<T extends HasResultSet, D>(
    ResultSetImplementation<T, D> table,
    GeneratedColumn<String> column,
    String value,
  ) async =>
      await (selectOnly(table)
            ..addColumns([column])
            ..where(column.equals(value))
            ..limit(1))
          .getSingleOrNull() !=
      null;

  /// One page of executions, newest first by `(started_at_ms, id)`, strictly
  /// older than [after] when it is given. Each filter that is null (or empty,
  /// for [statuses]) reads everything. Rows in [hiddenSpaceIds] are left out
  /// by the query itself, so the page and its last row come from visible
  /// rows only.
  ///
  /// [sinceMs] is inclusive and [untilMs] exclusive, both epoch milliseconds.
  Future<List<CodeExecutionsTableData>> page({
    required int limit,
    CodeExecutionPosition? after,
    String? runId,
    String? conversationId,
    String? agentId,
    String? spaceId,
    String? toolCallId,
    Set<String> hiddenSpaceIds = const {},
    Set<String> statuses = const {},
    String? surface,
    int? sinceMs,
    int? untilMs,
  }) {
    final query = select(codeExecutionsTable)
      ..where((t) {
        final filters = <Expression<bool>>[
          if (runId != null) t.runId.equals(runId),
          if (conversationId != null) t.conversationId.equals(conversationId),
          if (agentId != null) t.agentId.equals(agentId),
          if (spaceId != null) t.spaceId.equals(spaceId),
          if (toolCallId != null) t.toolCallId.equals(toolCallId),
          if (hiddenSpaceIds.isNotEmpty)
            t.spaceId.isNull() | t.spaceId.isNotIn(hiddenSpaceIds),
          if (statuses.isNotEmpty) t.status.isIn(statuses),
          if (surface != null) t.surface.equals(surface),
          if (sinceMs != null) t.startedAtMs.isBiggerOrEqualValue(sinceMs),
          if (untilMs != null) t.startedAtMs.isSmallerThanValue(untilMs),
          if (after != null)
            t.startedAtMs.isSmallerThanValue(after.startedAtMs) |
                (t.startedAtMs.equals(after.startedAtMs) &
                    t.id.isSmallerThanValue(after.id)),
        ];
        return filters.isEmpty ? const Constant(true) : Expression.and(filters);
      })
      ..orderBy([
        (t) => OrderingTerm.desc(t.startedAtMs),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(limit);
    return query.get();
  }

  /// One execution row, or null.
  Future<CodeExecutionsTableData?> executionById(String id) => (select(
    codeExecutionsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// The payload of execution [executionId], or null when it has none.
  Future<CodeExecutionPayloadsTableData?> payloadOf(String executionId) =>
      (select(
        codeExecutionPayloadsTable,
      )..where((t) => t.executionId.equals(executionId))).getSingleOrNull();

  /// The nested calls of execution [executionId], by sequence.
  Future<List<CodeExecutionCallsTableData>> callsOf(String executionId) =>
      (select(codeExecutionCallsTable)
            ..where((t) => t.executionId.equals(executionId))
            ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
          .get();

  // ── Stored values ──

  /// Every value [agentId] stored in [conversationId], key to JSON text.
  Future<Map<String, String>> storedValues(
    String conversationId,
    String agentId,
  ) async {
    final rows = await (select(
      codeModeStoreTable,
    )..where(_storeOwner(conversationId, agentId))).get();
    return {for (final row in rows) row.key: row.valueJson};
  }

  /// Replaces the values of [agentId] in [conversationId] with what [next]
  /// makes of the values stored now, in one transaction.
  ///
  /// [next] runs inside the transaction on the writer, so it sees every
  /// commit that finished before this one and none can land between its read
  /// and the writes. When it throws, nothing is written. Only the keys that
  /// change are touched: a removed key is deleted, a new or changed one is
  /// upserted on its key.
  Future<void> replaceStoredValues(
    String conversationId,
    String agentId,
    Map<String, String> Function(Map<String, String> current) next,
  ) => transaction(() async {
    final current = await storedValues(conversationId, agentId);
    final updated = next(Map.unmodifiable(current));
    final removed = [
      for (final key in current.keys)
        if (!updated.containsKey(key)) key,
    ];
    if (removed.isNotEmpty) {
      await (delete(codeModeStoreTable)..where(
            (t) =>
                _storeOwner(conversationId, agentId)(t) & t.key.isIn(removed),
          ))
          .go();
    }
    final now = DateTime.now();
    for (final MapEntry(:key, :value) in updated.entries) {
      if (current[key] == value) {
        continue;
      }
      await into(codeModeStoreTable).insertOnConflictUpdate(
        CodeModeStoreTableCompanion.insert(
          conversationId: conversationId,
          agentId: agentId,
          key: key,
          valueJson: value,
          updatedAt: Value(now),
        ),
      );
    }
  });

  static Expression<bool> Function($CodeModeStoreTableTable) _storeOwner(
    String conversationId,
    String agentId,
  ) =>
      (t) =>
          t.conversationId.equals(conversationId) & t.agentId.equals(agentId);
}
