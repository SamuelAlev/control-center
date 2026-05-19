import 'package:drift/drift.dart';

@TableIndex(name: 'idx_space_repos_spaceId', columns: {#spaceId})
/// Many-to-many join between spaces and the repos a space provisions
/// worktrees for.
///
/// A row `(workspaceId, spaceId, repoId)` declares that the space's
/// conversation workspace should check out that repo. When a space has NO
/// rows, the provisioner falls back to every repo linked to the workspace
/// (back-compat with spaces created before per-space selection existed);
/// PR-workbench spaces ignore this table entirely and always provision
/// exactly the PR's repo.
///
/// `workspaceId` is carried (not just derivable via the space) so reads scope
/// to the workspace directly — workspace isolation is a hard invariant.
class SpaceReposTable extends Table {
  /// Workspace the space and repo belong to.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// Space side of the link.
  TextColumn get spaceId => text().customConstraint(
    'NOT NULL REFERENCES spaces (id) ON DELETE CASCADE',
  )();

  /// Repo side of the link.
  TextColumn get repoId => text().customConstraint(
    'NOT NULL REFERENCES repos (id) ON DELETE CASCADE',
  )();

  /// The branch this repo's copy-on-write worktree is cut from.
  ///
  /// Null (the default) means the repo's own default branch, resolved
  /// read-only from `origin/HEAD`. A value pins the checkout to that base —
  /// which is how a pipeline node says "review this against `release/1.2`"
  /// without opening a second space, and how a template names a branch it
  /// only learns at run time (the entry is rendered before it is stored).
  ///
  /// It is the BASE, not the working branch: the worktree still gets its own
  /// `conv/<space>` branch cut from here, so an agent's commits never land on
  /// the branch it was told to start from.
  TextColumn get branch => text().nullable()();

  /// When the link was created (drives ordering).
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'space_repos';

  @override
  Set<Column> get primaryKey => {spaceId, repoId};
}
