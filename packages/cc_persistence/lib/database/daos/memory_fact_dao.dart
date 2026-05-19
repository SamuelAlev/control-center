import 'dart:typed_data';

import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/memory_facts.dart';
import 'package:cc_persistence/database/utils/fts_query_utils.dart';
import 'package:cc_persistence/search/rrf.dart';
import 'package:drift/drift.dart';

part 'memory_fact_dao.g.dart';

@DriftAccessor(tables: [MemoryFactsTable])
/// Data access for memory facts.
class MemoryFactDao extends DatabaseAccessor<AppDatabase>
    with _$MemoryFactDaoMixin {
  /// Creates a [MemoryFactDao].
  MemoryFactDao(super.attachedDatabase);

  /// Watches facts in a workspace, newest first.
  Stream<List<MemoryFactsTableData>> watchByWorkspace(String workspaceId) =>
      (select(memoryFactsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Reads facts in a workspace, newest first.
  Future<List<MemoryFactsTableData>> getByWorkspace(String workspaceId) =>
      (select(memoryFactsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  /// Looks up a fact by id, scoped to [workspaceId]. A fact owned by another
  /// workspace is simply not found (fact ids are global UUIDs, so the
  /// workspace clause — not id uniqueness — is the isolation boundary).
  Future<MemoryFactsTableData?> getById(String workspaceId, String id) =>
      (select(memoryFactsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .getSingleOrNull();

  /// Inserts or updates a fact.
  Future<void> upsert(MemoryFactsTableCompanion entry) =>
      into(memoryFactsTable).insertOnConflictUpdate(entry);

  /// Reads active (non-superseded) facts for a topic.
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

  /// Full-text search over facts via FTS5.
  Future<List<MemoryFactsTableData>> searchFts(
    String workspaceId,
    String query,
  ) {
    // The MATCH is scoped to [workspaceId] at the index level; the explicit
    // `mf.workspace_id = ?` below remains the authoritative isolation filter.
    final match = toWorkspaceScopedFtsMatch(
      query,
      workspaceId,
      textColumns: const ['topic', 'content'],
    );
    if (match.isEmpty) {
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
        Variable<String>(match),
        Variable<String>(workspaceId),
      ],
      readsFrom: {memoryFactsTable},
    ).map((row) => memoryFactsTable.map(row.data)).get();
  }


  /// Vector KNN search using sqlite_vector.
  ///
  /// `vector_full_scan` has no per-workspace partition, so the scan spans all
  /// embeddings and the `mf.workspace_id = ?` filter below is the isolation
  /// boundary (unlike FTS, which is also scoped at the index level).
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

  /// Watches active (non-superseded) facts in a workspace.
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

  /// Reads facts authored by a specific agent.
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

  /// Deletes a fact by id, scoped to [workspaceId] so one workspace can never
  /// delete another's fact.
  Future<void> deleteById(String workspaceId, String id) =>
      (delete(memoryFactsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .go();

  /// Reads active (non-superseded) facts in a workspace, newest first.
  Future<List<MemoryFactsTableData>> getActiveByWorkspace(String workspaceId) =>
      (select(memoryFactsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.supersededBy.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  /// Reads active facts by id (scoped), for the graph voice / recall hydration.
  Future<List<MemoryFactsTableData>> getActiveByIds(
    String workspaceId,
    List<String> ids,
  ) {
    if (ids.isEmpty) {
      return Future.value(const []);
    }
    return (select(memoryFactsTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.id.isIn(ids) &
              t.supersededBy.isNull(),
        ))
        .get();
  }

  /// Most-recently-created active facts (the temporal recall voice's candidate
  /// pool).
  Future<List<MemoryFactsTableData>> recentActive(
    String workspaceId, {
    int limit = 30,
  }) =>
      (select(memoryFactsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.supersededBy.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  /// Bumps [MemoryFactsTable.recallCount] + [MemoryFactsTable.lastRecalledAt]
  /// for the given ids (scoped). Best-effort recall telemetry.
  Future<void> markRecalled(
    String workspaceId,
    List<String> ids,
    DateTime at,
  ) async {
    if (ids.isEmpty) {
      return;
    }
    await customUpdate(
      'UPDATE memory_facts_table SET recall_count = recall_count + 1, '
      'last_recalled_at = ? WHERE workspace_id = ? AND id IN (${List.filled(ids.length, '?').join(',')})',
      variables: [
        Variable<DateTime>(at),
        Variable<String>(workspaceId),
        ...ids.map(Variable<String>.new),
      ],
      updates: {memoryFactsTable},
    );
  }
}
