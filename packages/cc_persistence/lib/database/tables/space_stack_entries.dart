import 'package:drift/drift.dart';

/// Ordered branches inside one space's checkout of one repo.
///
/// A space keeps a single worktree per repo (`isolated_repos`). This table is
/// the stack of branches inside that checkout: position 0 is the bottom, and
/// each later row's pull request targets the branch below it. No rows exist
/// until the first cut.
///
/// [spaceId] is intentionally NOT a foreign key with cascade. Teardown reads
/// these branch names AFTER the space row is gone, so it can delete every
/// recorded branch from a Windows `git worktree` checkout. A cascade would
/// erase the names before that read.
@TableIndex(name: 'idx_space_stack_space', columns: {#workspaceId, #spaceId})
class SpaceStackEntriesTable extends Table {
  @override
  String get tableName => 'space_stack_entries';

  /// Row id (UUID).
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The space this stack belongs to. Not a foreign key: see the class doc.
  TextColumn get spaceId => text()();

  /// The repo whose checkout holds the stack.
  TextColumn get repoId => text().customConstraint(
    'NOT NULL REFERENCES repos (id) ON DELETE CASCADE',
  )();

  /// Order in the stack. 0 is the bottom.
  IntColumn get position => integer()();

  /// Branch name for this layer.
  TextColumn get branch => text()();

  /// The branch this layer's pull request targets.
  TextColumn get baseBranch => text()();

  /// Forge pull-request number, filled at publish.
  IntColumn get prNumber => integer().nullable()();

  /// Forge-neutral pull-request id, filled at publish.
  TextColumn get prExternalId => text().nullable()();

  /// A split rewrote this branch after it was pushed.
  BoolColumn get rewritten => boolean().withDefault(const Constant(false))();

  /// When the layer was recorded.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, spaceId, repoId, position},
    {workspaceId, spaceId, repoId, branch},
  ];
}
