import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:drift/drift.dart';

/// Drift table for pipeline templates.
///
/// Each row stores one editable pipeline template: its nodes (with body
/// keys + per-node config + canvas positions) and edges (source → target).
/// Built-in templates are seeded on first launch and re-upserted on app
/// start to keep their definition in sync with the code (`isBuiltIn = true`).
/// Users can also create entirely custom templates from the editor.
///
/// A file holds one workspace, so the template id alone is the key; the
/// lists read the whole (small) table and sort it in memory.
class PipelineTemplatesTable extends Table {
  /// Template identifier (e.g. 'pr_review'). Unique in the workspace's file,
  /// used by triggers and `PipelineEngine.start`.
  TextColumn get id => text()();

  /// Workspace this template belongs to. Templates are per-workspace because
  /// their node configs reference workspace-scoped agent IDs.
  TextColumn get workspaceId => text()();

  /// Human-readable name shown in the editor list.
  TextColumn get name => text()();

  /// Optional description.
  TextColumn get description => text().nullable()();

  /// JSON array of node objects, shape:
  /// `[{stepId, kind, bodyKey, config: {...}, x, y, waitForStepIds?: [...]}]`.
  TextColumn get nodesJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(nodesJson))
      .withDefault(const Constant('[]'))();

  /// JSON array of edges, shape: `[{from, to}]`.
  TextColumn get edgesJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(edgesJson))
      .withDefault(const Constant('[]'))();

  /// JSON array of declared input fields collected on a manual run, shape:
  /// `[{key, label, type, required, defaultValue, helpText, placeholder,
  /// options}]`. Empty for pipelines that take no user-supplied input.
  TextColumn get inputsJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(inputsJson))
      .withDefault(const Constant('[]'))();

  /// Whether this template is enabled.
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  /// Whether this template ships with the app.
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  /// How many runs of this template may execute at once. NULL means unlimited
  /// (the default). A start requested while the cap is full is persisted as a
  /// `queued` run and admitted when a slot frees — never dropped.
  IntColumn get maxParallelRuns => integer().nullable()();

  /// Monotonic version, bumped on each edit. Runs pin to the version they
  /// started against so an in-flight run isn't silently rewired by an edit.
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// When this template was first created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this template was last edited.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'pipeline_templates';

  @override
  Set<Column> get primaryKey => {id};
}
