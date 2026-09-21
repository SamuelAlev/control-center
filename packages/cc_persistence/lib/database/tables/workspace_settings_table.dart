import 'package:drift/drift.dart';

/// Workspace-scoped settings (opaque string/JSON values; client owns schemas).
///
/// Lives in the WORKSPACE DB (not `global.db`): export/import is one file,
/// delete is unlink, and the isolation ratchet pins the global-table set.
/// Security-critical fields stay typed columns on the registry
/// (`secret_exclude_globs`, `review_concurrency`). [workspaceId] is redundant
/// on disk but kept for DAO signatures and self-description. Not pruned by
/// `DatabaseRetentionService` (unlike `caches`).
class WorkspaceSettingsTable extends Table {
  /// The owning workspace.
  TextColumn get workspaceId => text()();

  /// Setting key (client-defined namespace, e.g. `branch_template`).
  TextColumn get key => text()();

  /// Opaque setting value.
  TextColumn get value => text()();

  /// When the value was last written.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'workspace_settings';

  @override
  Set<Column> get primaryKey => {workspaceId, key};
}
