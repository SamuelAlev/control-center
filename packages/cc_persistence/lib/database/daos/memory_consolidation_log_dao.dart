import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/memory_consolidation_log.dart';
import 'package:drift/drift.dart';

part 'memory_consolidation_log_dao.g.dart';

@DriftAccessor(tables: [MemoryConsolidationLogTable])
/// Data access for consolidation-pass audit rows (workspace-scoped).
class MemoryConsolidationLogDao extends DatabaseAccessor<AppDatabase>
    with _$MemoryConsolidationLogDaoMixin {
  /// Creates a [MemoryConsolidationLogDao].
  MemoryConsolidationLogDao(super.attachedDatabase);

  /// Records a consolidation pass.
  Future<void> insertPass(MemoryConsolidationLogTableCompanion entry) =>
      into(memoryConsolidationLogTable).insert(entry);

  /// Reads consolidation passes for a workspace, newest first.
  Future<List<MemoryConsolidationLogTableData>> getByWorkspace(
    String workspaceId,
  ) =>
      (select(memoryConsolidationLogTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();
}