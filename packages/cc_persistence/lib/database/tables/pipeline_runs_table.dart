import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

/// Drift table for pipeline runs.
///
/// Each row represents one execution of a pipeline template. The engine
/// persists state here so it can resume in-flight runs after a crash. The
/// template graph the run was pinned to is in `pipeline_run_snapshots`: this
/// row is rewritten on every step and read by every list, and neither needs
/// the graph.
///
/// At most one live run per `(template_id, dedup_key)`: the trigger
/// dispatcher's idempotency is a schema fact, not a read-then-insert.
@TableIndex.sql(
  'CREATE UNIQUE INDEX uq_pipeline_runs_active_dedup '
  'ON pipeline_runs (template_id, dedup_key) '
  'WHERE dedup_key IS NOT NULL '
  "AND status IN ('pending','queued','running','suspended')",
)
// Admission reads exactly this shape on every run completion: count the slot
// holders of one template, then find its oldest queued row. Template
// retention reads its leading column.
@TableIndex(
  name: 'idx_pipeline_runs_template_status',
  columns: {#templateId, #status, #startedAt},
)
// The newest-first run list (`started_at DESC, rowid DESC`; the entries carry
// the rowid).
@TableIndex(name: 'idx_pipeline_runs_started', columns: {#startedAt})
// Recovery reads every non-terminal run on start; nearly every row is
// terminal.
@TableIndex(name: 'idx_pipeline_runs_status', columns: {#status})
@TableIndex(name: 'idx_pipeline_runs_parent', columns: {#parentPipelineRunId})
class PipelineRunsTable extends Table {
  /// Unique run identifier (UUID v4).
  TextColumn get id => text()();

  /// Which template this run instantiates.
  ///
  /// No foreign key: a run is history and outlives its template (it carries
  /// its own snapshot in `pipeline_run_snapshots`), so a template delete must neither remove its
  /// runs nor be blocked by them, and `PipelineRun.templateId` is required.
  TextColumn get templateId => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// Run lifecycle status.
  ///
  /// Values: `pending` | `queued` | `running` | `suspended` | `completed` |
  /// `failed` | `cancelled`. A `queued` run was admitted but is waiting for a
  /// slot under its template's `max_parallel_runs` cap: it owns no step rows
  /// and nothing executes for it until the engine promotes it.
  TextColumn get status => text()
      // ignore: recursive_getters
      .check(status.isIn(AgentsStoredValues.pipelineRunStatus))
      .withDefault(const Constant('pending'))();

  /// JSON-serialized mutable state bag shared across steps.
  TextColumn get stateJson => text()
      // ignore: recursive_getters
      .check(isJsonObject(stateJson))
      .withDefault(const Constant('{}'))();

  /// Fully-qualified domain event type that triggered this run (nullable).
  TextColumn get triggerEventType => text().nullable()();

  /// JSON-serialized trigger event payload (nullable); always an object,
  /// which is what the run's mapper decodes.
  TextColumn get triggerPayloadJson =>
      // ignore: recursive_getters
      text().nullable().check(isJsonObject(triggerPayloadJson))();

  /// When this run was FIRST created. Never rewritten — a retry or a
  /// crash-resume stamps [attemptStartedAt] instead, so the run keeps one
  /// stable origin for the timeline and the queue's ordering.
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the CURRENT attempt began, or null while the run is still on its
  /// first one (where [startedAt] is the answer).
  ///
  /// A rerun used to overwrite [startedAt], which lost the original start and
  /// left the header disagreeing with the waterfall (whose origin is the first
  /// preserved step row). Keeping both means "started" can name the attempt the
  /// operator is actually looking at without the run forgetting when it began.
  DateTimeColumn get attemptStartedAt => dateTime().nullable()();

  /// When this run reached a terminal state.
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// Accumulated **active** run time in milliseconds (PRD 25 §6). Excludes idle
  /// time between a stop and a restart — displayed duration is `activeMs` plus
  /// `now - lastResumedAt` while running. Fixes the wall-clock inflation bug
  /// where an overnight stop added idle hours to the "duration".
  IntColumn get activeMs => integer().withDefault(const Constant(0))();

  /// When the run last (re)started running (server clock). Folded into
  /// [activeMs] on the next stop. Null while not running.
  DateTimeColumn get lastResumedAt => dateTime().nullable()();

  /// Error message if status is `failed`.
  TextColumn get errorMessage => text().nullable()();

  /// Stack trace captured at failure time. Nullable.
  TextColumn get errorStackTrace => text().nullable()();

  /// Idempotency key for event-triggered runs.
  ///
  /// When non-null, the engine refuses to start a new run if there is already
  /// a non-terminal run with the same `(templateId, dedupKey)` tuple. Set by
  /// the trigger dispatcher from event-specific extractors (e.g.
  /// `"$owner/$name#$prNumber"` for PR events).
  TextColumn get dedupKey => text().nullable()();

  /// Parent pipeline run id when this run was started by a `flow.callPipeline`
  /// node. Null for top-level runs. `SET NULL`: a child run's history
  /// outlives its parent.
  TextColumn get parentPipelineRunId => text().nullable().references(
    PipelineRunsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The parent run's step id that called this child run (with
  /// [parentPipelineRunId]). Null for top-level runs.
  TextColumn get parentStepId => text().nullable()();

  /// Template version this run was started against.
  IntColumn get templateVersion => integer().withDefault(const Constant(1))();

  /// Which attempt of this run is current, 1-based.
  ///
  /// A re-run and a crash-resume that re-fires steps both open a new attempt on
  /// the SAME run — the run keeps its id, its place in the queue and its
  /// original `started_at`, which is what makes the list stable. Without a
  /// number the only record of that was `attempt_started_at`, a timestamp,
  /// which cannot answer "is this the second try or the fifth".
  IntColumn get attemptCount => integer().withDefault(const Constant(1))();

  /// Aggregated cost of all agent work in this run, in micro-dollars.
  IntColumn get totalCostMicros => integer().withDefault(const Constant(0))();

  /// Aggregated token usage across all agent work in this run.
  IntColumn get totalTokens => integer().withDefault(const Constant(0))();

  /// When true the run is a dry run: dispatch / bash / network side effects
  /// are skipped and steps echo what they would have done.
  BoolColumn get dryRun => boolean().withDefault(const Constant(false))();

  /// When true the row mirrors work owned outside the engine (a projection
  /// reporter wrote it) and holds no `maxParallelRuns` slot. Written once at
  /// insert; see `PipelineRun.isProjection`.
  BoolColumn get isProjection => boolean().withDefault(const Constant(false))();

  @override
  String get tableName => 'pipeline_runs';

  @override
  Set<Column> get primaryKey => {id};
}
