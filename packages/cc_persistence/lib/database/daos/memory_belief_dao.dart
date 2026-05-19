import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/memory_beliefs.dart';
import 'package:drift/drift.dart';

part 'memory_belief_dao.g.dart';

@DriftAccessor(tables: [MemoryBeliefsTable])
/// Data access for harmonized cross-agent beliefs (workspace-scoped).
class MemoryBeliefDao extends DatabaseAccessor<AppDatabase>
    with _$MemoryBeliefDaoMixin {
  /// Creates a [MemoryBeliefDao].
  MemoryBeliefDao(super.attachedDatabase);

  /// Inserts or updates a belief.
  Future<void> upsert(MemoryBeliefsTableCompanion entry) =>
      into(memoryBeliefsTable).insertOnConflictUpdate(entry);

  /// Watches beliefs in a workspace, strongest first.
  Stream<List<MemoryBeliefsTableData>> watchByWorkspace(String workspaceId) =>
      (select(memoryBeliefsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.confidence)]))
          .watch();

  /// Reads beliefs in a workspace, strongest first.
  Future<List<MemoryBeliefsTableData>> getByWorkspace(String workspaceId) =>
      (select(memoryBeliefsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.confidence)]))
          .get();

  /// Replaces all beliefs for a workspace with [entries] (a harmonization pass
  /// recomputes the full set). Scoped delete keeps it workspace-isolated.
  Future<void> replaceWorkspace(
    String workspaceId,
    List<MemoryBeliefsTableCompanion> entries,
  ) async {
    await transaction(() async {
      await (delete(memoryBeliefsTable)
            ..where((t) => t.workspaceId.equals(workspaceId)))
          .go();
      for (final entry in entries) {
        await into(memoryBeliefsTable).insert(entry);
      }
    });
  }
}