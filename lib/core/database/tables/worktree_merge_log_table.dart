import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_worktree_merges_workspace', columns: {#workspaceId})
class WorktreeMergeLogTable extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().references(
        WorkspacesTable,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get sourceBranch => text()();
  TextColumn get targetBranch => text()();
  TextColumn get mergedBy => text().nullable()();
  TextColumn get mergeCommit => text().nullable()();
  TextColumn get prUrl => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('merged'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
