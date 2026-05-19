import 'package:drift/drift.dart';

/// Drift table for pipeline templates.
///
/// Each row stores one editable pipeline template: its nodes (with body
/// keys + per-node config + canvas positions) and edges (source → target).
/// Built-in templates are seeded on first launch and re-upserted on app
/// start to keep their definition in sync with the code (`isBuiltIn = true`).
/// Users can also create entirely custom templates from the editor.
@TableIndex(
  name: 'idx_pipeline_templates_isBuiltIn',
  columns: {#isBuiltIn},
)
@TableIndex(
  name: 'idx_pipeline_templates_workspaceId',
  columns: {#workspaceId},
)
class PipelineTemplatesTable extends Table {
  /// Template identifier (e.g. 'pr_review'). Unique per workspace, used by
  /// triggers and `PipelineEngine.start`.
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
  TextColumn get nodesJson =>
      text().withDefault(const Constant('[]'))();

  /// JSON array of edges, shape: `[{from, to}]`.
  TextColumn get edgesJson =>
      text().withDefault(const Constant('[]'))();

  /// JSON array of declared input fields collected on a manual run, shape:
  /// `[{key, label, type, required, defaultValue, helpText, placeholder,
  /// options}]`. Empty for pipelines that take no user-supplied input.
  TextColumn get inputsJson =>
      text().withDefault(const Constant('[]'))();

  /// Whether this template is enabled.
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  /// Whether this template ships with the app.
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  /// Monotonic version, bumped on each edit. Runs pin to the version they
  /// started against so an in-flight run isn't silently rewired by an edit.
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// When this template was first created.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// When this template was last edited.
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {workspaceId, id};
}
