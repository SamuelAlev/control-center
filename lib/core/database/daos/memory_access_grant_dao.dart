import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/memory_access_grants.dart';
import 'package:drift/drift.dart';

part 'memory_access_grant_dao.g.dart';

@DriftAccessor(tables: [MemoryAccessGrantsTable])
class MemoryAccessGrantDao extends DatabaseAccessor<AppDatabase>
    with _$MemoryAccessGrantDaoMixin {
  MemoryAccessGrantDao(super.attachedDatabase);

  Future<List<MemoryAccessGrantsTableData>> getByWorkspace(
    String workspaceId,
  ) =>
      (select(memoryAccessGrantsTable)
            ..where((t) => t.workspaceId.equals(workspaceId)))
          .get();

  Stream<List<MemoryAccessGrantsTableData>> watchByWorkspace(
    String workspaceId,
  ) =>
      (select(memoryAccessGrantsTable)
            ..where((t) => t.workspaceId.equals(workspaceId)))
          .watch();

  Future<void> upsert(MemoryAccessGrantsTableCompanion entry) =>
      into(memoryAccessGrantsTable).insertOnConflictUpdate(entry);

  Future<void> upsertAll(List<MemoryAccessGrantsTableCompanion> entries) =>
      batch((b) {
        for (final entry in entries) {
          b.insert(memoryAccessGrantsTable, entry, mode: InsertMode.insertOrReplace);
        }
      });
}
