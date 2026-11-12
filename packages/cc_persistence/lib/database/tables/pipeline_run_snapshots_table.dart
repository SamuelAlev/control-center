import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:drift/drift.dart';

/// The template graph a pipeline run was pinned to when it started, one row
/// per run, written once at insert.
///
/// Resume, retry, admission and the run detail read it so a template edit
/// mid-run cannot change what the run does or shows. It lives beside
/// `pipeline_runs` because that row is rewritten on every lifecycle step and
/// read by every run list, and neither needs the graph: lists read
/// `pipeline_runs` alone, the single-run reads join this table.
class PipelineRunSnapshotsTable extends Table {
  /// The run this graph is pinned to. `CASCADE`: the snapshot is part of the
  /// run and goes with it (a run delete, template retention).
  TextColumn get runId =>
      text().references(PipelineRunsTable, #id, onDelete: KeyAction.cascade)();

  /// The graph as `PipelineDefinition.toJson` wrote it: a JSON object.
  TextColumn get templateSnapshotJson =>
      // ignore: recursive_getters
      text().check(isJsonObject(templateSnapshotJson))();

  @override
  String get tableName => 'pipeline_run_snapshots';

  @override
  Set<Column> get primaryKey => {runId};
}
