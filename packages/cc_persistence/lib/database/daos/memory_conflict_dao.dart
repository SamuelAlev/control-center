import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/memory_conflicts.dart';
import 'package:drift/drift.dart';

part 'memory_conflict_dao.g.dart';

@DriftAccessor(tables: [MemoryConflictsTable])
/// Data access for memory conflicts (workspace-scoped).
class MemoryConflictDao extends DatabaseAccessor<AppDatabase>
    with _$MemoryConflictDaoMixin {
  /// Creates a [MemoryConflictDao].
  MemoryConflictDao(super.attachedDatabase);

  /// Watches conflicts in a workspace, newest first.
  Stream<List<MemoryConflictsTableData>> watchByWorkspace(String workspaceId) =>
      (select(memoryConflictsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Reads conflicts in a workspace, newest first.
  Future<List<MemoryConflictsTableData>> getByWorkspace(String workspaceId) =>
      (select(memoryConflictsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Reads unresolved conflicts in a workspace.
  Future<List<MemoryConflictsTableData>> getUnresolved(String workspaceId) =>
      (select(memoryConflictsTable)
            ..where(
              (t) => t.workspaceId.equals(workspaceId) & t.resolution.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Inserts or updates a conflict.
  Future<void> upsert(MemoryConflictsTableCompanion entry) =>
      into(memoryConflictsTable).insertOnConflictUpdate(entry);
}