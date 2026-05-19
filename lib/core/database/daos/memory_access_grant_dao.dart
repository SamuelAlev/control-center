import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/memory_access_grants.dart';
import 'package:drift/drift.dart';

part 'memory_access_grant_dao.g.dart';

@DriftAccessor(tables: [MemoryAccessGrantsTable])
/// Data access for memory access grants.
class MemoryAccessGrantDao extends DatabaseAccessor<AppDatabase>
    with _$MemoryAccessGrantDaoMixin {
  /// Creates a [MemoryAccessGrantDao].
  MemoryAccessGrantDao(super.attachedDatabase);

  /// Reads all access grants for a workspace.
  Future<List<MemoryAccessGrantsTableData>> getByWorkspace(
    String workspaceId,
  ) =>
      (select(memoryAccessGrantsTable)
            ..where((t) => t.workspaceId.equals(workspaceId)))
          .get();

  /// Watches access grants for a workspace.
  Stream<List<MemoryAccessGrantsTableData>> watchByWorkspace(
    String workspaceId,
  ) =>
      (select(memoryAccessGrantsTable)
            ..where((t) => t.workspaceId.equals(workspaceId)))
          .watch();

  /// Inserts or updates an access grant.
  Future<void> upsert(MemoryAccessGrantsTableCompanion entry) =>
      into(memoryAccessGrantsTable).insertOnConflictUpdate(entry);

  /// Batch inserts or replaces access grants.
  Future<void> upsertAll(List<MemoryAccessGrantsTableCompanion> entries) =>
      batch((b) {
        for (final entry in entries) {
          b.insert(memoryAccessGrantsTable, entry, mode: InsertMode.insertOrReplace);
        }
      });
}
