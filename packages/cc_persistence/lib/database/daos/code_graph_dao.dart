import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/code_edges.dart';
import 'package:cc_persistence/database/tables/code_files.dart';
import 'package:cc_persistence/database/tables/code_symbols.dart';
import 'package:cc_persistence/database/utils/fts_query_utils.dart';
import 'package:cc_persistence/search/rrf.dart';
import 'package:drift/drift.dart';

part 'code_graph_dao.g.dart';

/// Data access for the code graph: symbols, edges, and per-file index state.
///
/// Search mirrors MemoryFactDao exactly — FTS5 (BM25), sqlite_vector KNN,
/// and RRF fusion of the two — scoped by `workspaceId` (and `repoId`). Graph
/// traversal (callers / callees / impact radius) walks `code_edges`, also
/// scoped by `workspaceId` so it never crosses workspace boundaries.
@DriftAccessor(tables: [CodeSymbolsTable, CodeEdgesTable, CodeFilesTable])
class CodeGraphDao extends DatabaseAccessor<AppDatabase>
    with _$CodeGraphDaoMixin {
  /// Creates a [CodeGraphDao].
  CodeGraphDao(super.attachedDatabase);

  // ---------------------------------------------------------------------------
  // Ingest
  // ---------------------------------------------------------------------------

  /// Batch-upserts symbols (deterministic ids → in-place update on re-index).
  Future<void> upsertSymbols(List<CodeSymbolsTableCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(codeSymbolsTable, rows));

  /// Batch-upserts edges.
  Future<void> upsertEdges(List<CodeEdgesTableCompanion> rows) => batch(
    (b) => b.insertAll(codeEdgesTable, rows, mode: InsertMode.insertOrReplace),
  );

  /// Records (or updates) a file's content hash + symbol count.
  Future<void> upsertFile(CodeFilesTableCompanion row) =>
      into(codeFilesTable).insertOnConflictUpdate(row);

  // ---------------------------------------------------------------------------
  // Incremental re-index
  // ---------------------------------------------------------------------------

  /// Reads the code-file index entry for a single file.
  Future<CodeFilesTableData?> getFile(
    String workspaceId,
    String repoId,
    String path,
  ) =>
      (select(codeFilesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.repoId.equals(repoId) &
                t.path.equals(path),
          ))
          .getSingleOrNull();

  /// Reads all code-file index entries for a repo.
  Future<List<CodeFilesTableData>> getFiles(String workspaceId, String repoId) =>
      (select(codeFilesTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.repoId.equals(repoId),
          ))
          .get();

  /// Deletes a single file's symbols and edges in one transaction so the FTS
  /// and vector indexes never observe a half-removed file.
  Future<void> deleteByFile(
    String workspaceId,
    String repoId,
    String filePath,
  ) =>
      transaction(() async {
        await (delete(codeSymbolsTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.repoId.equals(repoId) &
                  t.filePath.equals(filePath),
            ))
            .go();
        await (delete(codeEdgesTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.repoId.equals(repoId) &
                  t.sourceFilePath.equals(filePath),
            ))
            .go();
        await (delete(codeFilesTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.repoId.equals(repoId) &
                  t.path.equals(filePath),
            ))
            .go();
      });

  /// Removes the entire index for a repo within a workspace.
  Future<void> deleteByRepo(String workspaceId, String repoId) =>
      transaction(() async {
        await (delete(codeSymbolsTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.repoId.equals(repoId),
            ))
            .go();
        await (delete(codeEdgesTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.repoId.equals(repoId),
            ))
            .go();
        await (delete(codeFilesTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.repoId.equals(repoId),
            ))
            .go();
      });

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Reads a symbol by id, scoped to [workspaceId].
  Future<CodeSymbolsTableData?> getSymbolById(String workspaceId, String id) =>
      (select(codeSymbolsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.id.equals(id),
          ))
          .getSingleOrNull();

  /// Reads symbols matching a name within a repo.
  Future<List<CodeSymbolsTableData>> getSymbolsByName(
    String workspaceId,
    String repoId,
    String name, {
    int limit = 20,
  }) =>
      (select(codeSymbolsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.repoId.equals(repoId) &
                  t.name.equals(name),
            )
            ..limit(limit))
          .get();

  /// Watches symbols in a repo, sorted by file path.
  Stream<List<CodeSymbolsTableData>> watchSymbolsByRepo(
    String workspaceId,
    String repoId,
  ) =>
      (select(codeSymbolsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.repoId.equals(repoId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.filePath)]))
          .watch();

  /// Symbols still missing an embedding — fed to a background backfill so the
  /// embedding model never blocks ingest.
  Future<List<CodeSymbolsTableData>> getSymbolsWithoutEmbedding(
    String workspaceId,
    String repoId, {
    int limit = 200,
  }) =>
      (select(codeSymbolsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.repoId.equals(repoId) &
                  t.embedding.isNull(),
            )
            ..limit(limit))
          .get();

  /// Reads all symbols in a repo.
  Future<List<CodeSymbolsTableData>> getSymbolsByRepo(
    String workspaceId,
    String repoId,
  ) =>
      (select(codeSymbolsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.repoId.equals(repoId),
          ))
          .get();

  /// Edges whose target hasn't been resolved to a symbol id yet (cross-file
  /// references awaiting the name-resolution pass).
  Future<List<CodeEdgesTableData>> getUnresolvedEdges(
    String workspaceId,
    String repoId,
  ) =>
      (select(codeEdgesTable)..where(
            (e) =>
                e.workspaceId.equals(workspaceId) &
                e.repoId.equals(repoId) &
                e.targetSymbolId.isNull() &
                e.targetName.isNotNull(),
          ))
          .get();

  /// Binds a previously-unresolved edge to a resolved target symbol id. Keeps
  /// the edge's id stable (id is derived at creation time, not from the
  /// resolved target) so re-index doesn't churn rows. Scoped to [workspaceId]
  /// so the update can never touch another workspace's edge.
  Future<void> setEdgeTarget(
    String workspaceId,
    String edgeId,
    String targetSymbolId,
  ) =>
      (update(codeEdgesTable)..where(
            (e) => e.id.equals(edgeId) & e.workspaceId.equals(workspaceId),
          ))
          .write(
            CodeEdgesTableCompanion(targetSymbolId: Value(targetSymbolId)),
          );

  // ---------------------------------------------------------------------------
  // Search — mirrors MemoryFactDao (FTS5 / vector / RRF hybrid)
  // ---------------------------------------------------------------------------

  /// Full-text search over code symbols via FTS5.
  Future<List<CodeSymbolsTableData>> searchFts(
    String workspaceId,
    String repoId,
    String query, {
    int limit = 20,
  }) {
    // The MATCH is scoped to [workspaceId] at the index level; the explicit
    // `cs.workspace_id = ?` below remains the authoritative isolation filter,
    // and `cs.repo_id = ?` narrows to the repo within that workspace.
    final match = toWorkspaceScopedFtsMatch(
      query,
      workspaceId,
      textColumns: const ['name', 'qualified_name', 'signature', 'docstring'],
    );
    if (match.isEmpty) {
      return Future.value(const []);
    }
    return customSelect(
      'SELECT cs.* FROM code_symbols cs '
      'JOIN code_symbols_fts fts ON fts.rowid = cs.rowid '
      'WHERE fts.code_symbols_fts MATCH ? '
      'AND cs.workspace_id = ? '
      'AND cs.repo_id = ? '
      'ORDER BY rank '
      'LIMIT ?',
      variables: [
        Variable<String>(match),
        Variable<String>(workspaceId),
        Variable<String>(repoId),
        Variable<int>(limit),
      ],
      readsFrom: {codeSymbolsTable},
    ).map((row) => codeSymbolsTable.map(row.data)).get();
  }


  /// Vector KNN search using sqlite_vector.
  ///
  /// `vector_full_scan` has no per-workspace partition, so the scan spans all
  /// embeddings and the `cs.workspace_id = ?` / `cs.repo_id = ?` filters below
  /// are the isolation boundary (unlike FTS, which is also scoped at the index
  /// level).
  Future<List<CodeSymbolsTableData>> searchVector(
    String workspaceId,
    String repoId,
    Float32List queryEmbedding, {
    int limit = 30,
  }) {
    final vectorJson =
        '[${queryEmbedding.map((v) => v.toStringAsFixed(6)).join(', ')}]';
    return customSelect(
      'SELECT cs.* FROM code_symbols cs '
      "JOIN vector_full_scan('code_symbols', 'embedding', vector_as_f32(?), ?) AS v "
      'ON cs.rowid = v.rowid '
      'WHERE cs.workspace_id = ? '
      'AND cs.repo_id = ? '
      'ORDER BY v.distance '
      'LIMIT ?',
      variables: [
        Variable<String>(vectorJson),
        Variable<int>(limit),
        Variable<String>(workspaceId),
        Variable<String>(repoId),
        Variable<int>(limit),
      ],
      readsFrom: {codeSymbolsTable},
    ).map((row) => codeSymbolsTable.map(row.data)).get();
  }

  /// Hybrid BM25 + vector search via RRF fusion (k = 60), identical to the
  /// memory fact path.
  Future<List<CodeSymbolsTableData>> searchHybrid(
    String workspaceId,
    String repoId,
    String query,
    Float32List queryEmbedding, {
    int limit = 10,
  }) async {
    final ftsResults = await searchFts(workspaceId, repoId, query);
    final vectorResults = await searchVector(
      workspaceId,
      repoId,
      queryEmbedding,
      limit: 30,
    );
    return reciprocalRankFusion(
      [ftsResults, vectorResults],
      k: 60,
      limit: limit,
    );
  }

  // ---------------------------------------------------------------------------
  // Graph traversal
  // ---------------------------------------------------------------------------

  String _kindPlaceholders(Set<CodeEdgeKind> kinds) =>
      List.filled(kinds.length, '?').join(', ');

  /// Symbols that [symbolId] points to via [kinds] edges (outgoing), scoped to
  /// [workspaceId].
  Future<List<CodeSymbolsTableData>> getCallees(
    String workspaceId,
    String symbolId, {
    Set<CodeEdgeKind> kinds = const {CodeEdgeKind.calls},
    int? limit,
  }) {
    final names = kinds.map((k) => k.name).toList();
    return customSelect(
      'SELECT cs.* FROM code_edges e '
      'JOIN code_symbols cs ON cs.id = e.target_symbol_id '
      'WHERE e.source_symbol_id = ? AND e.workspace_id = ? '
      'AND e.kind IN (${_kindPlaceholders(kinds)})'
      '${limit != null ? ' LIMIT ?' : ''}',
      variables: [
        Variable<String>(symbolId),
        Variable<String>(workspaceId),
        ...names.map(Variable<String>.new),
        if (limit != null) Variable<int>(limit),
      ],
      readsFrom: {codeEdgesTable, codeSymbolsTable},
    ).map((row) => codeSymbolsTable.map(row.data)).get();
  }

  /// Symbols that point to [symbolId] via [kinds] edges (incoming), scoped to
  /// [workspaceId].
  Future<List<CodeSymbolsTableData>> getCallers(
    String workspaceId,
    String symbolId, {
    Set<CodeEdgeKind> kinds = const {CodeEdgeKind.calls},
    int? limit,
  }) {
    final names = kinds.map((k) => k.name).toList();
    return customSelect(
      'SELECT cs.* FROM code_edges e '
      'JOIN code_symbols cs ON cs.id = e.source_symbol_id '
      'WHERE e.target_symbol_id = ? AND e.workspace_id = ? '
      'AND e.kind IN (${_kindPlaceholders(kinds)})'
      '${limit != null ? ' LIMIT ?' : ''}',
      variables: [
        Variable<String>(symbolId),
        Variable<String>(workspaceId),
        ...names.map(Variable<String>.new),
        if (limit != null) Variable<int>(limit),
      ],
      readsFrom: {codeEdgesTable, codeSymbolsTable},
    ).map((row) => codeSymbolsTable.map(row.data)).get();
  }

  /// Transitive reverse-call closure: everything that (in)directly depends on
  /// [symbolId], up to [depth] hops. Returns the reachable symbols (incl. the
  /// root at depth 0), the edges among them, and a depth map.
  ///
  /// Uses a recursive CTE (`UNION` for cycle safety); [depth] is clamped to
  /// 1..6 to bound runaway recursion on dense graphs.
  Future<CodeImpactResult> getImpactRadius(
    String workspaceId,
    String symbolId, {
    int depth = 2,
    Set<CodeEdgeKind> edgeKinds = const {
      CodeEdgeKind.calls,
      CodeEdgeKind.extendsType,
      CodeEdgeKind.implementsType,
    },
  }) async {
    final clamped = depth.clamp(1, 6);
    final names = edgeKinds.map((k) => k.name).toList();
    final nodeRows = await customSelect(
      'WITH RECURSIVE impact(id, d) AS ('
      '  SELECT ?, 0'
      '  UNION'
      '  SELECT e.source_symbol_id, impact.d + 1'
      '  FROM code_edges e'
      '  JOIN impact ON e.target_symbol_id = impact.id'
      '  WHERE impact.d < ? AND e.target_symbol_id IS NOT NULL'
      '    AND e.workspace_id = ?'
      '    AND e.kind IN (${_kindPlaceholders(edgeKinds)})'
      ') '
      'SELECT cs.*, MIN(impact.d) AS impact_depth '
      'FROM impact JOIN code_symbols cs ON cs.id = impact.id '
      'WHERE cs.workspace_id = ? '
      'GROUP BY cs.id',
      variables: [
        Variable<String>(symbolId),
        Variable<int>(clamped),
        Variable<String>(workspaceId),
        ...names.map(Variable<String>.new),
        Variable<String>(workspaceId),
      ],
      readsFrom: {codeEdgesTable, codeSymbolsTable},
    ).get();

    final nodes = <CodeSymbolsTableData>[];
    final depthById = <String, int>{};
    for (final row in nodeRows) {
      final symbol = codeSymbolsTable.map(row.data);
      nodes.add(symbol);
      depthById[symbol.id] = row.read<int>('impact_depth');
    }

    if (nodes.isEmpty) {
      return const CodeImpactResult(nodes: [], edges: [], depthById: {});
    }

    final ids = nodes.map((n) => n.id).toList();
    final edges =
        await (select(codeEdgesTable)..where(
              (e) =>
                  e.workspaceId.equals(workspaceId) &
                  e.sourceSymbolId.isIn(ids) &
                  e.targetSymbolId.isIn(ids) &
                  e.kind.isIn(names),
            ))
            .get();

    return CodeImpactResult(nodes: nodes, edges: edges, depthById: depthById);
  }
}

/// Raw result of [CodeGraphDao.getImpactRadius] (table rows; the repository
/// maps these into domain `CodeSubgraph`).
class CodeImpactResult {
  /// Creates a [CodeImpactResult].
  const CodeImpactResult({
    required this.nodes,
    required this.edges,
    required this.depthById,
  });

  /// The symbols in the impact subgraph.
  final List<CodeSymbolsTableData> nodes;
  /// The edges among the impact subgraph symbols.
  final List<CodeEdgesTableData> edges;
  /// Depth map from symbol id to hop distance.
  final Map<String, int> depthById;
}
