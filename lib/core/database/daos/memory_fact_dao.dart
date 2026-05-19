import 'dart:typed_data';

import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/memory_facts.dart';
import 'package:control_center/core/database/utils/fts_query_utils.dart';
import 'package:control_center/core/infrastructure/embedding/rrf.dart';
import 'package:drift/drift.dart';

part 'memory_fact_dao.g.dart';

@DriftAccessor(tables: [MemoryFactsTable])
class MemoryFactDao extends DatabaseAccessor<AppDatabase>
    with _$MemoryFactDaoMixin {
  MemoryFactDao(super.attachedDatabase);

  Stream<List<MemoryFactsTableData>> watchByWorkspace(String workspaceId) =>
      (select(memoryFactsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<List<MemoryFactsTableData>> getByWorkspace(String workspaceId) =>
      (select(memoryFactsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<MemoryFactsTableData?> getById(String id) =>
      (select(memoryFactsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsert(MemoryFactsTableCompanion entry) =>
      into(memoryFactsTable).insertOnConflictUpdate(entry);

  Future<List<MemoryFactsTableData>> getActiveByTopic(
    String workspaceId,
    String topic,
  ) =>
      (select(memoryFactsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.topic.equals(topic) &
                  t.supersededBy.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<List<MemoryFactsTableData>> searchFts(
    String workspaceId,
    String query,
  ) {
    final ftsQuery = toFtsOrQuery(query);
    if (ftsQuery.isEmpty) {
      return Future.value(const []);
    }
    return customSelect(
      'SELECT mf.* FROM memory_facts_table mf '
      'JOIN memory_facts_fts fts ON fts.rowid = mf.rowid '
      'WHERE fts.memory_facts_fts MATCH ? '
      'AND mf.workspace_id = ? '
      'AND mf.superseded_by IS NULL '
      'ORDER BY rank '
      'LIMIT 20',
      variables: [
        Variable<String>(ftsQuery),
        Variable<String>(workspaceId),
      ],
      readsFrom: {memoryFactsTable},
    ).map((row) => memoryFactsTable.map(row.data)).get();
  }


  /// Vector KNN search using sqlite_vector.
  Future<List<MemoryFactsTableData>> searchVector(
    String workspaceId,
    Float32List queryEmbedding, {
    int limit = 30,
  }) {
    final vectorJson = '[${queryEmbedding.map((v) => v.toStringAsFixed(6)).join(', ')}]';
    return customSelect(
      'SELECT mf.* FROM memory_facts_table mf '
      "JOIN vector_full_scan('memory_facts_table', 'embedding', vector_as_f32(?), ?) AS v "
      'ON mf.rowid = v.rowid '
      'WHERE mf.workspace_id = ? '
      'AND mf.superseded_by IS NULL '
      'ORDER BY v.distance '
      'LIMIT ?',
      variables: [
        Variable<String>(vectorJson),
        Variable<int>(limit),
        Variable<String>(workspaceId),
        Variable<int>(limit),
      ],
      readsFrom: {memoryFactsTable},
    ).map((row) => memoryFactsTable.map(row.data)).get();
  }

  /// Hybrid BM25 + vector search via RRF fusion.
  Future<List<MemoryFactsTableData>> searchHybrid(
    String workspaceId,
    String query,
    Float32List queryEmbedding, {
    int limit = 10,
  }) async {
    final ftsResults = await searchFts(workspaceId, query);
    final vectorResults = await searchVector(
      workspaceId,
      queryEmbedding,
      limit: 30,
    );

    return reciprocalRankFusion(
      [ftsResults, vectorResults],
      k: 60,
      limit: limit,
    );
  }

  Stream<List<MemoryFactsTableData>> watchActiveByWorkspace(
    String workspaceId,
  ) =>
      (select(memoryFactsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.supersededBy.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<List<MemoryFactsTableData>> getByAuthor(
    String workspaceId,
    String agentId,
  ) =>
      (select(memoryFactsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.authoredByAgentId.equals(agentId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<void> deleteById(String id) =>
      (delete(memoryFactsTable)..where((t) => t.id.equals(id))).go();
}
