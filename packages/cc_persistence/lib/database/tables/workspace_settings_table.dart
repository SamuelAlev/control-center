import 'package:drift/drift.dart';

/// Drift table for workspace-scoped settings (branch naming, agent/model
/// defaults, default sandbox capabilities, data-sharing policy).
///
/// Lives in the WORKSPACE database, not `global.db`, for three reasons:
///
///  1. `workspace.export` is a `VACUUM INTO` of the single workspace file, so
///     settings held anywhere else would silently not travel with an exported
///     workspace and `workspace.import` would produce one with amnesia.
///  2. Deleting a workspace is unlinking its file — no orphan rows, no cascade.
///  3. The isolation ratchet pins the global-table set precisely so it cannot
///     grow by habit; a table named `workspace_settings` does not belong there.
///
/// Values are opaque strings (JSON where structured); the client owns each
/// key's schema, exactly as `user_preferences` does one scope up. This is for
/// settings with no pre-authorization server consumer and no validation-critical
/// shape — `workspaces.secret_exclude_globs` and `workspaces.review_concurrency`
/// stay TYPED COLUMNS on the registry, because the former is read on the
/// per-repo-path authorization path and demoting a security control to an
/// opaque string would be a downgrade.
///
/// [workspaceId] is redundant on disk (the file *is* the workspace) but is
/// carried anyway: it keeps the DAO signature `…(workspaceId, key)`, which is
/// what the required-`workspaceId` rule and the no-cached-DAO ratchet actually
/// protect, and it makes the file self-describing. `CachesTable` is the
/// precedent.
///
/// Deliberately NOT pruned by `DatabaseRetentionService`. That is the whole
/// reason this table exists rather than reusing `caches`: cache rows are
/// deleted once `updatedAt` passes the retention window, and only a WRITE bumps
/// `updatedAt` — so a policy set once and never edited disappears on a timer.
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
