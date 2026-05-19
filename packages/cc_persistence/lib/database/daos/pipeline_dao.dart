import 'dart:convert';

import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:cc_persistence/database/tables/pipeline_step_runs_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'pipeline_dao.g.dart';

/// Insert order within one `started_at` second — the queue's real tiebreak.
///
/// `started_at` is a drift `DateTime`, stored as a unix timestamp in SECONDS,
/// so a burst of runs created together (adding six repos at once fires six
/// `index_code` runs) all carry the SAME value and `ORDER BY started_at` alone
/// cannot separate them. Ordering was still coming out FIFO, but only by
/// accident: SQLite happened to answer the query from
/// `idx_pipeline_runs_template_status`, whose entries carry an implicit trailing
/// rowid. Naming the tiebreak makes the guarantee the queue's own rather than
/// the query planner's.
///
/// `rowid` is sound as an ordering key here even though SQLite reuses freed
/// values: an insert takes `max(rowid) + 1` over the rows that EXIST, so a new
/// row always outranks every live row, whatever was deleted before it. It is
/// stable too — nothing rewrites a run's rowid, and `started_at` is documented
/// as never rewritten either, so a retry cannot reshuffle the queue.
const _insertOrder = CustomExpression<int>('rowid');

/// DAO for [PipelineRunsTable] and [PipelineStepRunsTable].
@DriftAccessor(tables: [PipelineRunsTable, PipelineStepRunsTable])
class PipelineDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$PipelineDaoMixin {
  /// Creates a [PipelineDao].
  PipelineDao(super.db);

  // ── Pipeline runs ─────────────────────────────────────────────────

  /// Inserts a new pipeline run.
  Future<void> insertRun(PipelineRunsTableCompanion run) =>
      into(pipelineRunsTable).insert(run);

  /// Updates a pipeline run row, writing only the columns [run] carries.
  ///
  /// Deliberately a partial `write` rather than a whole-row `replace`: the
  /// three columns a run does NOT own from a caller's snapshot —
  /// `state_json`, `total_cost_cents` and `total_tokens` — are left absent by
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

  /// Gets a pipeline run by ID.
  Future<PipelineRunsTableData?> getRun(String id) => (select(
    pipelineRunsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Watches a single pipeline run by ID.
  Stream<PipelineRunsTableData?> watchRun(String id) => (select(
    pipelineRunsTable,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

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

  /// This workspace's non-terminal runs (pending, queued, running, suspended).
  ///
  /// The startup pipeline-resume reconciler needs every in-flight run on the
  /// install, which it gets by visiting each workspace's database in turn.
  Future<List<PipelineRunsTableData>> nonTerminalRuns() =>
      (select(pipelineRunsTable)
            ..where((t) => t.status.isIn(nonTerminalStatuses)))
          .get();

  /// Returns the active (non-terminal) run matching `(templateId, workspaceId,
  /// dedupKey)`, or null. Used for trigger idempotency.
  Future<PipelineRunsTableData?> findActiveByDedupKey(
    String templateId,
    String workspaceId,
    String dedupKey,
  ) =>
      (select(pipelineRunsTable)..where(
            (t) =>
                t.templateId.equals(templateId) &
                t.workspaceId.equals(workspaceId) &
                t.dedupKey.equals(dedupKey) &
                t.status.isIn(nonTerminalStatuses),
          ))
          .getSingleOrNull();

  /// Counts the runs of [templateId] that hold one of the template's
  /// `maxParallelRuns` slots. See [slotHoldingStatuses].
  ///
  /// Rows whose `triggerEventType` is in [excludeTriggerEventTypes] are skipped
  /// — the caller uses that for projection rows the engine does not own.
  Future<int> countActiveForTemplate(
    String workspaceId,
    String templateId, {
    Set<String> excludeTriggerEventTypes = const {},
  }) {
    final count = pipelineRunsTable.id.count();
    var predicate =
        pipelineRunsTable.workspaceId.equals(workspaceId) &
        pipelineRunsTable.templateId.equals(templateId) &
        pipelineRunsTable.status.isIn(slotHoldingStatuses);
    if (excludeTriggerEventTypes.isNotEmpty) {
      // A null triggerEventType must still count, so the exclusion is written
      // as "not one of these" OR "has none" rather than a bare NOT IN, which
      // SQL evaluates to NULL (and therefore false) for a null column.
      predicate =
          predicate &
          (pipelineRunsTable.triggerEventType
                  .isNotIn(excludeTriggerEventTypes.toList()) |
              pipelineRunsTable.triggerEventType.isNull());
    }
    final query = selectOnly(pipelineRunsTable)
      ..addColumns([count])
      ..where(predicate);
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  /// The oldest `queued` run of [templateId], or null when none is waiting.
  /// FIFO by `startedAt`, then by [_insertOrder], so a run that has waited
  /// longest is admitted first.
  Future<PipelineRunsTableData?> findOldestQueuedForTemplate(
    String workspaceId,
    String templateId,
  ) =>
      (select(pipelineRunsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.templateId.equals(templateId) &
                  t.status.equals('queued'),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.startedAt),
              (t) => OrderingTerm.asc(_insertOrder),
            ])
            ..limit(1))
          .getSingleOrNull();

  /// Watches this workspace's pipeline runs, most recent first.
  Stream<List<PipelineRunsTableData>> watchAll() =>
      (select(pipelineRunsTable)..orderBy([
            (t) => OrderingTerm.desc(t.startedAt),
            (t) => OrderingTerm.desc(_insertOrder),
          ]))
          .watch();

  /// Watches runs for a specific workspace, most recent first.
  ///
  /// The [_insertOrder] tiebreak is what lets the runs table read a queue's
  /// position straight off the list: among one template's `queued` rows, the
  /// LAST in this ordering is the next one [findOldestQueuedForTemplate] will
  /// admit.
  Stream<List<PipelineRunsTableData>> watchForWorkspace(String workspaceId) =>
      (select(pipelineRunsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.startedAt),
              (t) => OrderingTerm.desc(_insertOrder),
            ]))
          .watch();

  /// Updates just the state JSON for a run.
  Future<void> updateRunState(String runId, String stateJson) async {
    await (update(pipelineRunsTable)..where((t) => t.id.equals(runId))).write(
      PipelineRunsTableCompanion(stateJson: Value(stateJson)),
    );
  }

  /// Adds [cents] and [tokens] to the run's aggregated cost columns, in ONE
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
  Future<void> incrementRunCost(String runId, int cents, int tokens) =>
      customUpdate(
        'UPDATE pipeline_runs SET total_cost_cents = total_cost_cents + ?, '
        'total_tokens = total_tokens + ? WHERE id = ?',
        variables: [
          Variable<int>(cents),
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

  /// Deletes FINISHED runs of [templateId] that started before [cutoff],
  /// keeping the [keepAtLeast] most recent regardless of age. Step runs go with
  /// them via the `ON DELETE CASCADE`. Returns the number of runs deleted.
  ///
  /// Retention for a template that runs on its own, often: the code-graph
  /// watcher publishes one run per reindex, so a day of editing is hundreds of
  /// rows in a table nothing else prunes and the runs list streams in full. A
  /// non-terminal run is never touched (it may still be live) and the
  /// keep-floor means a quiet workspace still shows its recent history rather
  /// than an empty list.
  Future<int> deleteFinishedRunsForTemplate({
    required String templateId,
    required DateTime cutoff,
    required int keepAtLeast,
  }) async {
    final survivors =
        await (select(pipelineRunsTable)
              ..where((t) => t.templateId.equals(templateId))
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
              ..limit(keepAtLeast))
            .get();
    final keep = {for (final row in survivors) row.id};
    return (delete(pipelineRunsTable)..where(
          (t) =>
              t.templateId.equals(templateId) &
              t.startedAt.isSmallerThanValue(cutoff) &
              t.finishedAt.isNotNull() &
              t.id.isNotIn(keep),
        ))
        .go();
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
