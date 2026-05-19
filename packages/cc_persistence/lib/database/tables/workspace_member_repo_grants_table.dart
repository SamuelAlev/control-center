import 'package:cc_persistence/database/tables/repos.dart';
import 'package:drift/drift.dart';

/// Drift table for per-repo access grants of workspace members.
///
/// Workspace membership alone must never grant code visibility: the server
/// holds full checkouts, so every code-bearing surface checks the member's
/// grant on that repo. Absence of a row means no access
/// (`RepoGrantLevel.none`). Owners/admins are implicitly `write` on every
/// linked repo and carry no rows here. Workspace-scoped.
@TableIndex(
  name: 'idx_member_repo_grants_ws_user',
  columns: {#workspaceId, #userId},
)
@TableIndex(
  name: 'uq_member_repo_grants_ws_user_repo',
  columns: {#workspaceId, #userId, #repoId},
  unique: true,
)
class WorkspaceMemberRepoGrantsTable extends Table {
  /// Unique grant identifier.
  TextColumn get id => text()();

  /// The workspace (isolation boundary).
  TextColumn get workspaceId => text()();

  /// The granted member.
  TextColumn get userId => text()();

  /// The linked repo the grant applies to.
  TextColumn get repoId =>
      text().references(ReposTable, #id, onDelete: KeyAction.cascade)();

  /// Grant level wire name (`RepoGrantLevel`: `read` / `review` / `write`).
  TextColumn get level => text().withDefault(const Constant('read'))();

  /// When the grant was created or last changed.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'workspace_member_repo_grants';

  @override
  Set<Column> get primaryKey => {id};
}
