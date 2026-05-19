import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/working_memory_items.dart';
import 'package:drift/drift.dart';

part 'working_memory_item_dao.g.dart';

@DriftAccessor(tables: [WorkingMemoryItemsTable])
/// Data access for the hot working-memory tier (workspace-scoped).
class WorkingMemoryItemDao extends DatabaseAccessor<AppDatabase>
    with _$WorkingMemoryItemDaoMixin {
  /// Creates a [WorkingMemoryItemDao].
  WorkingMemoryItemDao(super.attachedDatabase);

  /// Inserts a hot item.
  Future<void> upsert(WorkingMemoryItemsTableCompanion entry) =>
      into(workingMemoryItemsTable).insertOnConflictUpdate(entry);

  /// All hot items for an agent, newest first.
  Future<List<WorkingMemoryItemsTableData>> getForAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(workingMemoryItemsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.agentId.equals(agentId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// All hot items in a workspace, newest first.
  Future<List<WorkingMemoryItemsTableData>> getForWorkspace(
    String workspaceId,
  ) =>
      (select(workingMemoryItemsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Watches the hot item count for an agent (drives the working-memory panel).
  Stream<List<WorkingMemoryItemsTableData>> watchForAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(workingMemoryItemsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.agentId.equals(agentId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Deletes hot items by id (after they consolidate into durable facts).
  Future<void> deleteByIds(String workspaceId, List<String> ids) {
    if (ids.isEmpty) {
      return Future.value();
    }
    return (delete(workingMemoryItemsTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.id.isIn(ids),
        ))
        .go();
  }

  /// Deletes hot items whose [WorkingMemoryItemsTable.expiresAt] is past [now].
  /// Returns the number of rows removed.
  Future<int> deleteExpired(String workspaceId, DateTime now) =>
      (delete(workingMemoryItemsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.expiresAt.isNotNull() &
                t.expiresAt.isSmallerThanValue(now),
          ))
          .go();
}