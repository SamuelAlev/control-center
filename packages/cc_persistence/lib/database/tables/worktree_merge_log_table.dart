import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_worktree_merges_workspace', columns: {#workspaceId})
/// Drift table for worktree merge logs.
class WorktreeMergeLogTable extends Table {
  /// Unique merge log identifier.
  TextColumn get id => text()();
  /// Owning workspace.
  TextColumn get workspaceId => text().references(
        WorkspacesTable,
        #id,
        onDelete: KeyAction.cascade,
      )();
  /// Branch being merged from.
  TextColumn get sourceBranch => text()();
  /// Branch being merged into.
  TextColumn get targetBranch => text()();
  /// Who performed the merge.
  TextColumn get mergedBy => text().nullable()();
  /// Merge commit SHA.
  TextColumn get mergeCommit => text().nullable()();
  /// Optional PR URL.
  TextColumn get prUrl => text().nullable()();
  /// Merge status.
  TextColumn get status => text().withDefault(const Constant('merged'))();
  /// When this merge was recorded.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
