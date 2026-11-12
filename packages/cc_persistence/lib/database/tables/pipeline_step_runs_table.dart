import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// Drift table for individual step executions within a pipeline run.
///
/// Each row is one step firing. The engine walks this table during resume
/// to find the deepest suspended/pending step.
@TableIndex(
  name: 'idx_pipeline_step_runs_pipelineRunId',
  columns: {#pipelineRunId},
)
@TableIndex(name: 'idx_pipeline_step_runs_space', columns: {#spaceId})
class PipelineStepRunsTable extends Table {
  /// Unique step run identifier (UUID v4).
  TextColumn get id => text()();

  /// Parent pipeline run. `CASCADE`: a step is part of its run.
  TextColumn get pipelineRunId =>
      text().references(PipelineRunsTable, #id, onDelete: KeyAction.cascade)();

  /// Step definition ID from the template (e.g. 'setup', 'fetch_context').
  TextColumn get stepId => text()();

  /// Step lifecycle status.
  ///
  /// A `PipelineStepStatus` storage string.
  TextColumn get status => text()
      // ignore: recursive_getters
      .check(status.isIn(AgentsStoredValues.pipelineStepStatus))
      .withDefault(const Constant('pending'))();

  /// JSON-serialized input payload. Nullable — most steps read from
  /// pipeline state instead.
  TextColumn get inputJson =>
      // ignore: recursive_getters
      text().nullable().check(isJson(inputJson))();

  /// JSON-serialized output payload. Null until step completes.
  TextColumn get outputJson =>
      // ignore: recursive_getters
      text().nullable().check(isJson(outputJson))();

  /// Conversation/space this step spawned (when it dispatched agents into a
  /// hidden conversation). The step-detail UI links to this space; null for
  /// steps that don't create a conversation. `SET NULL`: the step record
  /// outlives the room.
  TextColumn get spaceId => text().nullable().references(
    SpacesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Error message if status is `failed`.
  TextColumn get errorMessage => text().nullable()();

  /// Stack trace captured at failure time. Nullable.
  TextColumn get errorStackTrace => text().nullable()();

  /// Number of body attempts so far (retry policy). Persisted so a crash
  /// mid-retry doesn't reset the budget on resume.
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// JSON list of archived previous attempts (`PipelineStepAttempt` maps,
  /// oldest first), written by `PipelineDao.restartStepRun` just before it
  /// clears the previous outcome. This is what keeps a retry from erasing the
  /// failure it is retrying: the row moves on, the tries survive.
  TextColumn get attemptHistory => text()
      // ignore: recursive_getters
      .check(isJsonArray(attemptHistory))
      .withDefault(const Constant('[]'))();

  /// When this step was started.
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();

  /// When this step reached a terminal state.
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  String get tableName => 'pipeline_step_runs';

  @override
  Set<Column> get primaryKey => {id};
}
