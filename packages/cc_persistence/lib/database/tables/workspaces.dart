import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:cc_persistence/database/tables/users_table.dart';
import 'package:drift/drift.dart';

/// Drift table definition for workspaces.
///
/// **CROSS-WORKSPACE BY DESIGN** — this is the registry and it lives in
/// `global.db`. It is the one workspace-related table that is *not* inside a
/// workspace database file: the switcher, the picker and "manage workspaces"
/// must list every workspace without opening a single per-workspace file.
///
/// A workspace is a user-named container with an optional custom logo. Its
/// content — repos, agents, spaces, tickets, everything — lives in
/// `workspaces/<id>.db`, keyed by [id]. Deleting a workspace soft-deletes this
/// row and unlinks that file.
@TableIndex(name: 'idx_workspaces_owner', columns: {#ownerUserId})
class WorkspacesTable extends Table {
  /// Unique workspace identifier.
  TextColumn get id => text()();

  /// Workspace display name (user-supplied at creation).
  TextColumn get name => text()();

  /// Optional path to a local image file used as the workspace logo.
  TextColumn get logoPath => text().nullable()();

  /// The user who owns this workspace (holds the `owner` membership role).
  /// Nullable in SQL only until the identity bootstrap backfills it on first
  /// boot; treated as required everywhere else. A user is never deleted
  /// (attribution is permanent), and must not be while they own a workspace.
  TextColumn get ownerUserId => text().nullable().references(UsersTable, #id)();

  /// JSON array of glob patterns whose matching paths are hard-blocked from
  /// guest/viewer visibility on code-bearing surfaces (secret exclusion).
  TextColumn get secretExcludeGlobs => text()
      // ignore: recursive_getters
      .check(isJsonArray(secretExcludeGlobs))
      .withDefault(const Constant('[]'))();

  /// Default fan-out for parallel reviewer dispatch on this workspace.
  /// `dispatch_reviewers` MCP tool uses this when no explicit `concurrency`
  /// argument is provided.
  IntColumn get reviewConcurrency => integer().withDefault(const Constant(3))();

  /// Whether a completed review publishes to GitHub automatically (opt-in;
  /// off by default — publishing is otherwise user-gated behind the
  /// "Publish to GitHub" action, which itself stays ActionClass-guarded).
  BoolColumn get autoPublishReview =>
      boolean().withDefault(const Constant(false))();

  /// Whose provider apps this workspace uses (`inherit` / `hosted` /
  /// `custom` / `own`): the server's choice, a Connect of its own, or its own
  /// apps. Typed because the server reads it on every credential path — not
  /// an opaque `workspace_settings` string. A `WorkspaceConnectMode` wire
  /// name.
  TextColumn get connectMode => text()
      // ignore: recursive_getters
      .check(connectMode.isIn(PlatformStoredValues.workspaceConnectMode))
      .withDefault(const Constant('inherit'))();

  /// The canonical Connect base URL when [connectMode] is `custom`. Empty
  /// otherwise.
  TextColumn get connectUrl => text().withDefault(const Constant(''))();

  /// Numeric id of this workspace's own GitHub App, used while [connectMode]
  /// is `own`. Empty when none is saved. The private key is never a column;
  /// it lives in `secrets.json`.
  TextColumn get githubAppId => text().withDefault(const Constant(''))();

  /// The operator's manual order for the workspace switcher / manager
  /// (drag-to-reorder in "manage workspaces"). Lower sorts first;
  /// [createdAt] is the stable tiebreak. Mirrors `repos.position` — one manual
  /// order per list, server-owned, so every client (desktop/web/phone) renders
  /// workspaces in the same sequence.
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft-delete timestamp. When non-null, the workspace is considered deleted.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  String get tableName => 'workspaces';

  @override
  Set<Column> get primaryKey => {id};
}
