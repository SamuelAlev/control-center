import 'package:control_center/core/database/tables/pipeline_runs_table.dart';
import 'package:drift/drift.dart';

/// Drift table for individual step executions within a pipeline run.
///
/// Each row is one step firing. The engine walks this table during resume
/// to find the deepest suspended/pending step.
@TableIndex(
  name: 'idx_pipeline_step_runs_pipelineRunId',
  columns: {#pipelineRunId},
)
@TableIndex(
  name: 'idx_pipeline_step_runs_status',
  columns: {#status},
)
class PipelineStepRunsTable extends Table {
  /// Unique step run identifier (UUID v4).
  TextColumn get id => text()();

  /// Parent pipeline run.
  TextColumn get pipelineRunId => text().references(
        PipelineRunsTable,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Step definition ID from the template (e.g. 'setup', 'fetch_context').
  TextColumn get stepId => text()();

  /// Step lifecycle status.
  ///
  /// Values: `pending` | `running` | `suspended` | `completed` | `failed` | `skipped`
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// JSON-serialized input payload. Nullable — most steps read from
  /// pipeline state instead.
  TextColumn get inputJson => text().nullable()();

  /// JSON-serialized output payload. Null until step completes.
  TextColumn get outputJson => text().nullable()();

  /// Error message if status is `failed`.
  TextColumn get errorMessage => text().nullable()();

  /// Stack trace captured at failure time. Nullable.
  TextColumn get errorStackTrace => text().nullable()();

  /// Identifies which parallel branch this step belongs to when multiple
  /// `.listen()` calls fan out from the same source step. Null for
  /// non-parallel steps.
  IntColumn get branchIndex => integer().nullable()();

  /// Number of body attempts so far (retry policy). Persisted so a crash
  /// mid-retry doesn't reset the budget on resume.
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// When this step was started.
  DateTimeColumn get startedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// When this step reached a terminal state.
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
