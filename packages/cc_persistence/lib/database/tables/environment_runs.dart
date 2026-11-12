import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:cc_persistence/database/tables/environment_definitions.dart';
import 'package:cc_persistence/database/tables/repos.dart';
import 'package:cc_persistence/database/tables/space_environments.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// Drift table recording every environment operation and task.
///
/// **Workspace-scoped**: the redundant `workspace_id` column keeps a row
/// self-describing. [outputText] is a bounded tail; `EnvironmentDao` caps every
/// write of it.
///
/// A run is history: it outlives the space, environment, definition and repo
/// it names, which are cleared to null when they go.
@TableIndex(name: 'idx_environment_runs_space', columns: {#spaceId, #startedAt})
@TableIndex(
  name: 'idx_environment_runs_definition',
  columns: {#definitionId, #startedAt},
)
@TableIndex(
  name: 'idx_environment_runs_environment',
  columns: {#environmentId},
)
@TableIndex(name: 'idx_environment_runs_repo', columns: {#repoId})
class EnvironmentRunsTable extends Table {
  /// Run id.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The space, or null for a test on a throwaway clone.
  TextColumn get spaceId => text().nullable().references(
    SpacesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The environment, or null for a worktree task.
  TextColumn get environmentId => text().nullable().references(
    SpaceEnvironmentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The definition.
  TextColumn get definitionId => text().nullable().references(
    EnvironmentDefinitionsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The repo of a worktree task.
  TextColumn get repoId => text().nullable().references(
    ReposTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// What ran, as `EnvironmentRunKind.name`.
  TextColumn get kind =>
      // ignore: recursive_getters
      text().check(kind.isIn(PlatformStoredValues.environmentRunKind))();

  /// A component id or verb.
  TextColumn get label => text().nullable()();

  /// How it went, as `EnvironmentRunStatus.name`.
  TextColumn get status =>
      // ignore: recursive_getters
      text().check(status.isIn(PlatformStoredValues.environmentRunStatus))();

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
