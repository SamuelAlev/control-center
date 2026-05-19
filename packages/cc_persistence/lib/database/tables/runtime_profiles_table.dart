import 'package:drift/drift.dart';

/// Drift table for custom runtime profiles — reusable runtime definitions that
/// wrap a protocol family, a CLI command, and fixed launch arguments.
///
/// A profile is a workspace-level definition; agents register against one via
/// `agents.runtime_profile_id`, making the runtimes that back agents
/// configurable instead of hardcoded. Workspace-scoped: every read filters by
/// [workspaceId].
@TableIndex(name: 'idx_runtime_profiles_workspaceId', columns: {#workspaceId})
class RuntimeProfilesTable extends Table {
  /// Unique profile identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Display name of the profile.
  TextColumn get name => text()();

  /// Protocol family the runtime speaks: `claude`, `acp`, `pi`, `codex`,
  /// or `cli`.
  TextColumn get protocolFamily => text().withDefault(const Constant('cli'))();

  /// The CLI command (executable) the runtime launches.
  TextColumn get command => text()();

  /// JSON array of fixed launch arguments always passed to the command.
  TextColumn get fixedArgsJson => text().withDefault(const Constant('[]'))();

  /// Optional description of the profile.
  TextColumn get description => text().nullable()();

  /// When the profile was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the profile was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'runtime_profiles';

  @override
  Set<Column> get primaryKey => {id};
}
