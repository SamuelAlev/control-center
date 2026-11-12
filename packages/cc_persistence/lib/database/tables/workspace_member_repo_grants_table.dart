import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:cc_persistence/database/tables/repos.dart';
import 'package:drift/drift.dart';

/// Drift table for per-repo access grants of workspace members.
///
/// Workspace membership alone must never grant code visibility: the server
/// holds full checkouts, so every code-bearing surface checks the member's
/// grant on that repo. Absence of a row means no access
/// (`RepoGrantLevel.none`). Owners/admins are implicitly `write` on every
/// linked repo and carry no rows here. Workspace-scoped.
///
/// One grant per member and repo: `(userId, repoId)` is unique, and setting a
/// grant is one upsert on it.
@TableIndex(
  name: 'uq_member_repo_grants_user_repo',
  columns: {#userId, #repoId},
  unique: true,
)
@TableIndex(name: 'idx_member_repo_grants_repo', columns: {#repoId})
class WorkspaceMemberRepoGrantsTable extends Table {
  /// Unique grant identifier.
  TextColumn get id => text()();

  /// The workspace (isolation boundary).
  TextColumn get workspaceId => text()();

  /// The granted member. No foreign key: users live in the global database.
  TextColumn get userId => text()();

  /// The linked repo the grant applies to; the grant goes with it.
  TextColumn get repoId =>
      text().references(ReposTable, #id, onDelete: KeyAction.cascade)();

  /// Grant level wire name (`RepoGrantLevel`: `read` / `review` / `write`).
  /// `none` is never stored: it is the absence of a row.
  TextColumn get level => text()
      // ignore: recursive_getters
      .check(level.isIn(PlatformStoredValues.repoGrantLevel))
      .withDefault(const Constant('read'))();

  /// When the grant was created or last changed.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'workspace_member_repo_grants';

  @override
  Set<Column> get primaryKey => {id};
}
