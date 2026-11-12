import 'dart:convert';

import 'package:cc_persistence/database/tables/pipeline_run_snapshots_table.dart';
import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:cc_persistence/database/tables/pipeline_step_runs_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'pipeline_dao.g.dart';

/// Insert order within one `started_at` second — the queue's real tiebreak.
///
/// `started_at` is a drift `DateTime`, stored as a unix timestamp in SECONDS, so a burst of
/// runs created together (adding six repos at once fires six `index_code` runs) all carry
/// the SAME value and `ORDER BY started_at` alone cannot separate them.
/// Ordering was still coming out FIFO, but only by accident: SQLite happened to answer the
/// query from `idx_pipeline_runs_template_status`, whose entries carry an implicit trailing
/// rowid.
const _insertOrder = CustomExpression<int>('rowid');

/// A pipeline-run row read together with the template graph it was pinned
/// to, which is null for a run that has none (a projection row).
typedef PipelineRunWithSnapshot = ({
  PipelineRunsTableData run,
  PipelineRunSnapshotsTableData? snapshot,
});

/// DAO for [PipelineRunsTable], [PipelineRunSnapshotsTable] and
/// [PipelineStepRunsTable].
///
/// Run lists read `pipeline_runs` alone. The single-run reads and the
/// engine's recovery and admission reads, which are what execute or draw a
/// run's graph, join `pipeline_run_snapshots` and return
/// [PipelineRunWithSnapshot].
@DriftAccessor(
  tables: [PipelineRunsTable, PipelineRunSnapshotsTable, PipelineStepRunsTable],
)
class PipelineDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$PipelineDaoMixin {
  /// Creates a [PipelineDao].
  PipelineDao(super.db);

  // ── Pipeline runs ─────────────────────────────────────────────────

  /// Inserts a new pipeline run, and the template graph it is pinned to when
  /// [templateSnapshotJson] is given, in one transaction.
  Future<void> insertRun(
    PipelineRunsTableCompanion run, {
    String? templateSnapshotJson,
  }) => transaction(() async {
    await into(pipelineRunsTable).insert(run);
    if (templateSnapshotJson != null) {
      await into(pipelineRunSnapshotsTable).insert(
        PipelineRunSnapshotsTableCompanion.insert(
          runId: run.id.value,
          templateSnapshotJson: templateSnapshotJson,
        ),
      );
    }
  });

  /// Pipeline-run rows matching [where], each with its snapshot row (a
  /// primary-key lookup per run).
  JoinedSelectStatement<HasResultSet, dynamic> _withSnapshot(
    Expression<bool> where,
  ) => select(pipelineRunsTable).join([
    leftOuterJoin(
      pipelineRunSnapshotsTable,
      pipelineRunSnapshotsTable.runId.equalsExp(pipelineRunsTable.id),
    ),
  ])..where(where);

  PipelineRunWithSnapshot _readWithSnapshot(TypedResult row) => (
    run: row.readTable(pipelineRunsTable),
    snapshot: row.readTableOrNull(pipelineRunSnapshotsTable),
  );

  /// Updates a pipeline run row, writing only the columns [run] carries.
  ///
  /// Deliberately a partial `write` rather than a whole-row `replace`: the
  /// three columns a run does NOT own from a caller's snapshot —
  /// `state_json`, `total_cost_micros` and `total_tokens` — are left absent by
  /// `pipelineRunToUpdateCompanion` and have their own single-purpose writers
  /// ([updateRunState], [incrementRunCost]).
  ///
  /// A whole-row replace made every lifecycle transition a blind rewrite of
  /// those three from whenever the caller last read the run. Completing a run
  /// is exactly when its last agents' cost rollups land, so the completion
  /// wrote a total that predated them and the run's page under-reported what it
  /// had spent; a fan-out branch merging state between another branch's read
  /// and its terminal write lost that key the same way.
  Future<void> updateRun(PipelineRunsTableCompanion run) async {
    await (update(
      pipelineRunsTable,
    )..where((t) => t.id.equals(run.id.value))).write(run);
  }

  /// Gets a pipeline run by ID, with its snapshot.
  Future<PipelineRunWithSnapshot?> getRun(String id) => _withSnapshot(
    pipelineRunsTable.id.equals(id),
  ).map(_readWithSnapshot).getSingleOrNull();

  /// Watches a single pipeline run by ID, with its snapshot.
  Stream<PipelineRunWithSnapshot?> watchRun(String id) => _withSnapshot(
    pipelineRunsTable.id.equals(id),
  ).map(_readWithSnapshot).watchSingleOrNull();

  /// The statuses a run can hold while it is still going to do work — the
  /// complement of the terminal set. `queued` belongs here: a capped run
  /// waiting for a slot has not finished, and treating it as gone would let a
  /// repeated trigger queue a second copy of work already waiting.
  static const List<String> nonTerminalStatuses = [
    'pending',
    'queued',
    'running',
    'suspended',
  ];

  /// The statuses that occupy one of a template's `maxParallelRuns` slots —
  /// [nonTerminalStatuses] minus `queued`, which is by definition what is
  /// *waiting* for a slot.
  static const List<String> slotHoldingStatuses = [
    'pending',
    'running',
    'suspended',
  ];

  /// This workspace's non-terminal runs (pending, queued, running,
  /// suspended), with their snapshots: recovery executes them.
  ///
  /// The startup pipeline-resume reconciler needs every in-flight run on the
  /// install, which it gets by visiting each workspace's database in turn.
  Future<List<PipelineRunWithSnapshot>> nonTerminalRuns() => _withSnapshot(
    pipelineRunsTable.status.isIn(nonTerminalStatuses),
  ).map(_readWithSnapshot).get();

  /// Returns the active (non-terminal) run matching `(templateId, workspaceId,
  /// dedupKey)`, with its snapshot, or null. Used for trigger idempotency.
  Future<PipelineRunWithSnapshot?> findActiveByDedupKey(
    String templateId,
    String workspaceId,
    String dedupKey,
  ) => _withSnapshot(
    pipelineRunsTable.templateId.equals(templateId) &
        pipelineRunsTable.workspaceId.equals(workspaceId) &
        pipelineRunsTable.dedupKey.equals(dedupKey) &
        pipelineRunsTable.status.isIn(nonTerminalStatuses),
  ).map(_readWithSnapshot).getSingleOrNull();

  /// Counts the runs of [templateId] that hold one of the template's
  /// `maxParallelRuns` slots. See [slotHoldingStatuses].
  ///
  /// Projection rows (`is_projection`) are never counted: they mirror work
  /// the engine does not own, so a slot they held would never be released.
  Future<int> countActiveForTemplate(String workspaceId, String templateId) {
    final count = pipelineRunsTable.id.count();
    final predicate =
        pipelineRunsTable.workspaceId.equals(workspaceId) &
        pipelineRunsTable.templateId.equals(templateId) &
        pipelineRunsTable.status.isIn(slotHoldingStatuses) &
        pipelineRunsTable.isProjection.equals(false);
    final query = selectOnly(pipelineRunsTable)
      ..addColumns([count])
      ..where(predicate);
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  /// The oldest `queued` run of [templateId], with its snapshot (admission
  /// starts it), or null when none is waiting. FIFO by `startedAt`, then by
  /// insert order, so a run that has waited longest is admitted first.
  Future<PipelineRunWithSnapshot?> findOldestQueuedForTemplate(
    String workspaceId,
    String templateId,
  ) =>
      (_withSnapshot(
              pipelineRunsTable.workspaceId.equals(workspaceId) &
                  pipelineRunsTable.templateId.equals(templateId) &
                  pipelineRunsTable.status.equals('queued'),
            )
            ..orderBy([
              OrderingTerm.asc(pipelineRunsTable.startedAt),
              // The run table's rowid: a joined statement must name it.
              OrderingTerm.asc(
                const CustomExpression<int>('pipeline_runs.rowid'),
              ),
            ])
            ..limit(1))
          .map(_readWithSnapshot)
          .getSingleOrNull();

  /// Keys of a run's `state` that a list row keeps: the ones naming the
  /// repository or space the run works on, which per-viewer visibility is
  /// decided by. Everything else in the bag (step outputs, accumulated
  /// context) is read per run, by [getRun] / [watchRun].
  static const List<String> listStateKeys = [
    'repo_full_name',
    'repo_owner',
    'repo_name',
    'repo_id',
    'space_id',
  ];

  /// Most runs a list watch returns (the newest). Older runs are read a
  /// page at a time with [runsPage].
  static const int listLimit = 200;

  /// SELECT list for run lists: every column of `pipeline_runs`, except that
  /// `state_json` is cut down to [listStateKeys] (null members dropped by
  /// `json_patch`). The pinned graph is not in this table at all.
  ///
  /// List watches re-run on every write to `pipeline_runs`, and a running
  /// pipeline writes its state on every step. The bag is still read to pull
  /// the keys out, but it is no longer decoded, re-encoded and shipped once
  /// per row per write.
  late final String _listColumns = [
    for (final c in pipelineRunsTable.$columns)
      switch (c.name) {
        'state_json' =>
          "CASE WHEN json_valid(state_json) THEN json_patch('{}', json_object("
              '${[for (final k in listStateKeys) "'$k', json_extract(state_json, '\$.$k')"].join(', ')}'
              ")) ELSE '{}' END AS state_json",
        final name => name,
      },
  ].join(', ');

  /// Run-list statement: the newest [listLimit] rows, optionally of one
  /// workspace, optionally strictly older than a `(started_at, id)` cursor.
  String _listSql({required bool byWorkspace, required bool hasCursor}) =>
      'SELECT $_listColumns FROM pipeline_runs'
      '${byWorkspace || hasCursor ? ' WHERE ' : ''}'
      '${byWorkspace ? 'workspace_id = ?' : ''}'
      '${byWorkspace && hasCursor ? ' AND ' : ''}'
      '${hasCursor ? '(started_at < ? OR (started_at = ? AND rowid < '
                '(SELECT rowid FROM pipeline_runs WHERE id = ?)))' : ''}'
      ' ORDER BY started_at DESC, rowid DESC LIMIT ?';

  Selectable<PipelineRunsTableData> _list({
    String? workspaceId,
    DateTime? beforeStartedAt,
    String? beforeId,
    int limit = listLimit,
  }) {
    final hasCursor = beforeStartedAt != null && beforeId != null;
    return customSelect(
      _listSql(byWorkspace: workspaceId != null, hasCursor: hasCursor),
      variables: [
        if (workspaceId != null) Variable.withString(workspaceId),
        if (hasCursor) ...[
          Variable<DateTime>(beforeStartedAt),
          Variable<DateTime>(beforeStartedAt),
          Variable.withString(beforeId),
        ],
        Variable.withInt(limit),
      ],
      readsFrom: {pipelineRunsTable},
    ).map((row) => pipelineRunsTable.map(row.data));
  }

  /// Watches the newest [listLimit] pipeline runs of this workspace file,
  /// most recent first, as list rows (see [_listColumns]).
  Stream<List<PipelineRunsTableData>> watchAll() => _list().watch();

  /// Watches the newest [listLimit] runs of [workspaceId], most recent
  /// first, as list rows (see [_listColumns]).
  ///
  /// The [_insertOrder] tiebreak is what lets the runs table read a queue's
  /// position straight off the list: among one template's `queued` rows, the
  /// LAST in this ordering is the next one [findOldestQueuedForTemplate] will
  /// admit.
  Stream<List<PipelineRunsTableData>> watchForWorkspace(String workspaceId) =>
      _list(workspaceId: workspaceId).watch();

  /// One keyset page of [workspaceId]'s runs as list rows, most recent
  /// first: at most [limit] runs strictly older than run [beforeId] (which
  /// started at [beforeStartedAt]), in the order the list watch uses.
  Future<List<PipelineRunsTableData>> runsPage(
    String workspaceId, {
    required DateTime beforeStartedAt,
    required String beforeId,
    int limit = listLimit,
  }) => _list(
    workspaceId: workspaceId,
    beforeStartedAt: beforeStartedAt,
    beforeId: beforeId,
    limit: limit,
  ).get();

  /// Updates just the state JSON for a run.
  Future<void> updateRunState(String runId, String stateJson) async {
    await (update(pipelineRunsTable)..where((t) => t.id.equals(runId))).write(
      PipelineRunsTableCompanion(stateJson: Value(stateJson)),
    );
  }

  /// Adds [micros] and [tokens] to the run's aggregated cost columns, in ONE
  /// statement.
  ///
  /// Read-modify-write is wrong here, and a fan-out is exactly where it shows:
  /// every agent of a `forEach` / team dispatch publishes `AgentRunCompleted`
  /// at roughly the same moment, so two rollups can both read the pre-increment
  /// total before either writes and the second silently erases the first. `SET
  /// col = col + ?` is evaluated by SQLite against the row as it stands, so the
  /// increments compose however the callers interleave.
  ///
  /// Only the two cost columns are touched, so a concurrent state merge (or a
  /// lifecycle transition) is not clobbered.
  Future<void> incrementRunCost(String runId, int micros, int tokens) =>
      customUpdate(
        'UPDATE pipeline_runs SET total_cost_micros = total_cost_micros + ?, '
        'total_tokens = total_tokens + ? WHERE id = ?',
        variables: [
          Variable<int>(micros),
          Variable<int>(tokens),
          Variable<String>(runId),
        ],
        updates: {pipelineRunsTable},
        updateKind: UpdateKind.update,
      );

  /// Deletes a pipeline run, scoped to [workspaceId]. Its step runs are removed
  /// via the `ON DELETE CASCADE` on [PipelineStepRunsTable.pipelineRunId].
  /// Scoping by `workspaceId` means a run from another workspace is simply not
  /// matched (no cross-workspace delete). Returns the number of rows deleted.
  Future<int> deleteRun(String workspaceId, String runId) => (delete(
    pipelineRunsTable,
  )..where((t) => t.id.equals(runId) & t.workspaceId.equals(workspaceId))).go();

  /// Deletes FINISHED runs of [templateId] that started before [cutoff], keeping the
  /// [keepAtLeast] most recent regardless of age.
  ///
  /// Retention for a template that runs on its own, often: the code-graph watcher publishes
  /// one run per reindex, so a day of editing is hundreds of rows in a table nothing else
  /// prunes and the runs list streams in full.
  /// A non-terminal run is never touched (it may still be live) and the keep-floor means a
  /// quiet workspace still shows its recent history rather than an empty list.
  ///
  /// Returns the ids it deleted, so the caller can drop their routes.
  Future<List<String>> deleteFinishedRunsForTemplate({
    required String templateId,
    required DateTime cutoff,
    required int keepAtLeast,
  }) async {
    final survivors =
        await (select(pipelineRunsTable)
              ..where((t) => t.templateId.equals(templateId))
              ..orderBy([
                (t) => OrderingTerm.desc(t.startedAt),
                (t) => OrderingTerm.desc(_insertOrder),
              ])
              ..limit(keepAtLeast))
            .get();
    final keep = {for (final row in survivors) row.id};
    final deleted =
        await (delete(pipelineRunsTable)..where(
              (t) =>
                  t.templateId.equals(templateId) &
                  t.startedAt.isSmallerThanValue(cutoff) &
                  t.finishedAt.isNotNull() &
                  t.id.isNotIn(keep),
            ))
            .goAndReturn();
    return [for (final row in deleted) row.id];
  }

  // ── Step runs ──────────────────────────────────────────────────────

  /// Inserts a new step run.
  Future<void> insertStepRun(PipelineStepRunsTableCompanion stepRun) =>
      into(pipelineStepRunsTable).insert(stepRun);

  /// Updates a step run's fields.
  Future<void> updateStepRun({
    required String id,
    String? status,
    String? inputJson,
    String? outputJson,
    String? spaceId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {
    await (update(pipelineStepRunsTable)..where((t) => t.id.equals(id))).write(
      PipelineStepRunsTableCompanion(
        status: status != null ? Value(status) : const Value.absent(),
        inputJson: inputJson != null ? Value(inputJson) : const Value.absent(),
        outputJson: outputJson != null
            ? Value(outputJson)
            : const Value.absent(),
        spaceId: spaceId != null ? Value(spaceId) : const Value.absent(),
        errorMessage: errorMessage != null
            ? Value(errorMessage)
            : const Value.absent(),
        errorStackTrace: errorStackTrace != null
            ? Value(errorStackTrace)
            : const Value.absent(),
        finishedAt: finishedAt != null
            ? Value(finishedAt)
            : const Value.absent(),
      ),
    );
  }

  /// Re-opens a step run for another attempt: status `running`, a fresh
  /// [startedAt] and the previous attempt's outcome columns nulled.
  ///
  /// The attempt being replaced is ARCHIVED first (appended to
  /// `attemptHistory` with its status, timing and error): a retry that erased
  /// the failure it was retrying would leave the operator with nothing to
  /// follow when a step flakes. `spaceId` and `inputJson` survive on
  /// purpose — the room the step already opened is reused, and the input
  /// snapshot is rewritten by the body itself.
  ///
  /// A row that never fired (`pending`) archives nothing: there is no attempt
  /// to remember, only a queue position.
  Future<void> restartStepRun(String id, DateTime startedAt) async {
    final row = await getStepRunById(id);
    if (row == null) {
      return;
    }
    String history = row.attemptHistory;
    if (row.status != 'pending') {
      final attempts = _decodeAttemptHistory(history)
        ..add({
          'status': row.status,
          'started_at': row.startedAt.toIso8601String(),
          if (row.finishedAt != null)
            'finished_at': row.finishedAt!.toIso8601String(),
          if (row.errorMessage != null) 'error_message': row.errorMessage,
          if (row.errorStackTrace != null)
            'error_stack_trace': row.errorStackTrace,
        });
      // Bounded: a flake retried forever must not grow the row without limit.
      // The oldest tries are the least interesting once the recent ones tell
      // the story.
      final capped = attempts.length > maxArchivedStepAttempts
          ? attempts.sublist(attempts.length - maxArchivedStepAttempts)
          : attempts;
      history = jsonEncode(capped);
    }
    await (update(pipelineStepRunsTable)..where((t) => t.id.equals(id))).write(
      PipelineStepRunsTableCompanion(
        status: const Value('running'),
        startedAt: Value(startedAt),
        finishedAt: const Value(null),
        errorMessage: const Value(null),
        errorStackTrace: const Value(null),
        outputJson: const Value(null),
        attemptHistory: Value(history),
      ),
    );
  }

  /// Most attempts kept per step run; older ones fall off the front.
  static const int maxArchivedStepAttempts = 20;

  /// Parses an `attempt_history` column value, tolerating (and dropping) a
  /// malformed payload — the archive is a forensics aid, never worth breaking
  /// a restart over.
  static List<Map<String, dynamic>> _decodeAttemptHistory(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return [for (final e in decoded.whereType<Map>()) e.cast()];
    } on Object {
      return [];
    }
  }

  /// Deletes a single step run row.
  Future<int> deleteStepRun(String stepRunId) => (delete(
    pipelineStepRunsTable,
  )..where((t) => t.id.equals(stepRunId))).go();

  /// Returns all step runs for a pipeline run.
  Future<List<PipelineStepRunsTableData>> stepRunsForPipeline(
    String pipelineRunId,
  ) => (select(
    pipelineStepRunsTable,
  )..where((t) => t.pipelineRunId.equals(pipelineRunId))).get();

  /// Returns a single step run by ID, or null.
  Future<PipelineStepRunsTableData?> getStepRunById(String stepRunId) =>
      (select(
        pipelineStepRunsTable,
      )..where((t) => t.id.equals(stepRunId))).getSingleOrNull();

  /// Watches all step runs for a pipeline run.
  Stream<List<PipelineStepRunsTableData>> watchStepRunsForPipeline(
    String pipelineRunId,
  ) => (select(
    pipelineStepRunsTable,
  )..where((t) => t.pipelineRunId.equals(pipelineRunId))).watch();
}
