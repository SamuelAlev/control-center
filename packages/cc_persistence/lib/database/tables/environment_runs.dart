import 'package:drift/drift.dart';

/// Drift table recording every environment operation and task.
///
/// **Workspace-scoped**: the redundant `workspace_id` column keeps a row
/// self-describing. [outputText] is a bounded tail; `EnvironmentDao` caps every
/// write of it.
@TableIndex(name: 'idx_environment_runs_space', columns: {#spaceId, #startedAt})
@TableIndex(
  name: 'idx_environment_runs_definition',
  columns: {#definitionId, #startedAt},
)
class EnvironmentRunsTable extends Table {
  /// Run id.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The space, or null for a test on a throwaway clone.
  TextColumn get spaceId => text().nullable()();

  /// The environment, or null for a worktree task.
  TextColumn get environmentId => text().nullable()();

  /// The definition.
  TextColumn get definitionId => text().nullable()();

  /// The repo of a worktree task.
  TextColumn get repoId => text().nullable()();

  /// What ran, as `EnvironmentRunKind.name`.
  TextColumn get kind => text()();

  /// A component id or verb.
  TextColumn get label => text().nullable()();

  /// How it went, as `EnvironmentRunStatus.name`.
  TextColumn get status => text()();

  /// When it started.
  DateTimeColumn get startedAt => dateTime()();

  /// When it finished, or null while running.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// The exit code.
  IntColumn get exitCode => integer().nullable()();

  /// A short failure message; not the output tail.
  TextColumn get error => text().nullable()();

  /// The redacted, bounded output tail.
  TextColumn get outputText => text().withDefault(const Constant(''))();

  @override
  String get tableName => 'environment_runs';

  @override
  Set<Column> get primaryKey => {id};
}
