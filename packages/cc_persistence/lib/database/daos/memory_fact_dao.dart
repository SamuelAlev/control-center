import 'dart:typed_data';

import 'package:cc_persistence/database/tables/memory_fact_embeddings.dart';
import 'package:cc_persistence/database/tables/memory_facts.dart';
import 'package:cc_persistence/database/utils/fts_query_utils.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/search/rrf.dart';
import 'package:drift/drift.dart';

part 'memory_fact_dao.g.dart';

@DriftAccessor(tables: [MemoryFactsTable, MemoryFactEmbeddingsTable])
/// Data access for memory facts and their vectors.
///
/// A fact row carries no vector (`memory_fact_embeddings` does), so every fact
/// read here is a plain select and only the vector search touches the side
/// table.
class MemoryFactDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$MemoryFactDaoMixin {
  /// Creates a [MemoryFactDao].
  MemoryFactDao(super.attachedDatabase);

  SimpleSelectStatement<$MemoryFactsTableTable, MemoryFactsTableData>
  _newestFirst(String workspaceId) => select(memoryFactsTable)
    ..where((t) => t.workspaceId.equals(workspaceId))
    ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

  /// Watches facts in a workspace, newest first.
  Stream<List<MemoryFactsTableData>> watchByWorkspace(String workspaceId) =>
      _newestFirst(workspaceId).watch();

  /// Reads facts in a workspace, newest first.
  Future<List<MemoryFactsTableData>> getByWorkspace(String workspaceId) =>
      _newestFirst(workspaceId).get();

  /// Looks up a fact by id, scoped to [workspaceId]. A fact owned by another
  /// workspace is simply not found (fact ids are global UUIDs, so the
  /// workspace clause — not id uniqueness — is the isolation boundary).
  Future<MemoryFactsTableData?> getById(String workspaceId, String id) =>
      (select(memoryFactsTable)
            ..where((t) => t.id.equals(id) & t.workspaceId.equals(workspaceId)))
          .getSingleOrNull();

  /// Inserts or updates a fact. An update never touches the fact's vector
  /// row: that is [putEmbedding]'s, and [dropEmbeddingUnlessText]'s when the
  /// text changes.
  Future<void> upsert(MemoryFactsTableCompanion entry) =>
      into(memoryFactsTable).insertOnConflictUpdate(entry);

  /// Stores [embedding] as the vector of fact [factId], replacing any it had.
  ///
  /// Writes only the side row: the fact row, its `updated_at` and its
  /// full-text index entry stay as they are.
  Future<void> putEmbedding(String factId, Uint8List embedding) =>
      into(memoryFactEmbeddingsTable).insertOnConflictUpdate(
        MemoryFactEmbeddingsTableCompanion.insert(
          factId: factId,
          embedding: embedding,
        ),
      );

  /// Removes the vector of fact [factId] unless the fact's stored text is
  /// still [topic] and [content], the text the vector was computed from.
  ///
  /// For a write that changes a fact without a vector to go with it (the
  /// model is not installed): a vector of the old text would rank the fact
  /// for what it no longer says. The backfill embeds it again later.
  Future<void> dropEmbeddingUnlessText(
    String factId, {
    required String topic,
    required String content,
  }) => customUpdate(
    'DELETE FROM memory_fact_embeddings WHERE fact_id = ? AND NOT EXISTS '
    '(SELECT 1 FROM memory_facts WHERE id = ? AND topic = ? AND content = ?)',
    variables: [
      Variable<String>(factId),
      Variable<String>(factId),
      Variable<String>(topic),
      Variable<String>(content),
    ],
    updates: {memoryFactEmbeddingsTable},
    updateKind: UpdateKind.delete,
  );

  /// Active facts of [workspaceId] that have no vector yet, oldest first: the
  /// backfill's work list.
  ///
  /// "No vector" is "no side row": an anti-join probing the side table's
  /// primary key once per fact. Superseded facts are left out because the
  /// vector search never returns them.
  Future<List<MemoryFactsTableData>> getActiveWithoutEmbedding(
    String workspaceId, {
    int limit = 64,
  }) => customSelect(
    withoutEmbeddingSql,
    variables: [Variable<String>(workspaceId), Variable<int>(limit)],
    readsFrom: {memoryFactsTable, memoryFactEmbeddingsTable},
  ).map((row) => memoryFactsTable.map(row.data)).get();

  /// The statement [getActiveWithoutEmbedding] runs (public so a test can
  /// assert its plan).
  static const withoutEmbeddingSql =
      'SELECT mf.* FROM memory_facts mf '
      'WHERE mf.workspace_id = ? AND mf.superseded_by IS NULL '
      'AND NOT EXISTS (SELECT 1 FROM memory_fact_embeddings e '
      'WHERE e.fact_id = mf.id) '
      'ORDER BY mf.created_at '
      'LIMIT ?';

  /// Stores each vector of [embeddings] (fact id to vector) for a fact that
  /// has none yet and whose stored text is still the text the vector was
  /// computed from (`topic` and `content` of the entry). Returns how many
  /// were stored.
  ///
  /// The backfill's write. It embeds outside any transaction, so by the time
  /// it writes, a fact may be gone, changed, or embedded by its own write;
  /// each of those is skipped instead of failing the batch on a foreign key
  /// or overwriting a fresher vector.
  Future<int> putBackfilledEmbeddings(
    List<({String factId, String topic, String content, Uint8List embedding})>
    embeddings,
  ) => transaction(() async {
    var stored = 0;
    for (final e in embeddings) {
      stored += await customUpdate(
        'INSERT INTO memory_fact_embeddings (fact_id, embedding) '
        'SELECT id, ? FROM memory_facts '
        'WHERE id = ? AND topic = ? AND content = ? '
        'ON CONFLICT (fact_id) DO NOTHING',
        variables: [
          Variable<Uint8List>(e.embedding),
          Variable<String>(e.factId),
          Variable<String>(e.topic),
          Variable<String>(e.content),
        ],
        updates: {memoryFactEmbeddingsTable},
        updateKind: UpdateKind.insert,
      );
    }
    return stored;
  });

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
      'SELECT mf.* FROM memory_facts mf '
      'JOIN memory_facts_fts fts ON fts.rowid = mf.rowid '
      'WHERE fts.memory_facts_fts MATCH ? '
      'AND mf.workspace_id = ? '
      'AND mf.superseded_by IS NULL '
      'ORDER BY rank '
      'LIMIT 20',
      variables: [Variable<String>(match), Variable<String>(workspaceId)],
      readsFrom: {memoryFactsTable},
    ).map((row) => memoryFactsTable.map(row.data)).get();
  }

  /// Vector KNN search using sqlite_vector.
  ///
  /// The scan runs over `memory_fact_embeddings` and yields ITS rowids: each
  /// is matched to its side row in this statement and the fact is reached
  /// through the `fact_id` that row stores, never through a rowid of
  /// `memory_facts`.
  ///
  /// The scan has no per-workspace partition, so it spans every embedding in
  /// the file and the `mf.workspace_id = ?` filter below is the isolation
  /// boundary (unlike FTS, which is also scoped at the index level).
  /// `vector_full_scan_stream` has no top-k cut, so the filters run BEFORE the
  /// ranking — with `vector_full_scan`'s up-front k, superseded facts nearer
  /// the query crowded live ones out of the result. CROSS JOIN pins the scan
  /// as the outer loop; as the inner one it would re-run per candidate row.
  Future<List<MemoryFactsTableData>> searchVector(
    String workspaceId,
    Float32List queryEmbedding, {
    int limit = 30,
  }) {
    final vectorJson =
        '[${queryEmbedding.map((v) => v.toStringAsFixed(6)).join(', ')}]';
    return customSelect(
      'SELECT mf.* FROM '
      "vector_full_scan_stream('memory_fact_embeddings', 'embedding', "
      'vector_as_f32(?)) AS v '
      'CROSS JOIN memory_fact_embeddings e ON e.rowid = v.rowid '
      'CROSS JOIN memory_facts mf ON mf.id = e.fact_id '
      'WHERE mf.workspace_id = ? '
      'AND mf.superseded_by IS NULL '
      'ORDER BY v.distance '
      'LIMIT ?',
      variables: [
        Variable<String>(vectorJson),
        Variable<String>(workspaceId),
        Variable<int>(limit),
      ],
      readsFrom: {memoryFactsTable, memoryFactEmbeddingsTable},
    ).map((row) => memoryFactsTable.map(row.data)).get();
  }

  /// Hybrid BM25 + vector search via RRF fusion.
  Future<List<MemoryFactsTableData>> searchHybrid(
    String workspaceId,
    String query,
    Float32List queryEmbedding, {
    int limit = 10,
  }) async {
    // Concurrent: the two voices are independent queries and the fusion needs
    // both, so running them in sequence just adds the slower one's latency to
    // the faster one's.
    final results = await Future.wait([
      searchFts(workspaceId, query),
      searchVector(workspaceId, queryEmbedding, limit: 30),
    ]);
    final ftsResults = results[0];
    final vectorResults = results[1];

    return reciprocalRankFusion(
      [ftsResults, vectorResults],
      k: 60,
      limit: limit,
    );
  }

  /// Watches active (non-superseded) facts in a workspace.
  Stream<List<MemoryFactsTableData>> watchActiveByWorkspace(
    String workspaceId,
  ) => (_newestFirst(
    workspaceId,
  )..where((t) => t.supersededBy.isNull())).watch();

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
  /// delete another's fact. Its vector goes with it (`ON DELETE CASCADE`).
  Future<void> deleteById(String workspaceId, String id) => (delete(
    memoryFactsTable,
  )..where((t) => t.id.equals(id) & t.workspaceId.equals(workspaceId))).go();

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
      'UPDATE memory_facts SET recall_count = recall_count + 1, '
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
