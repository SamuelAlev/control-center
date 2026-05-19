import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_persistence/database/tables/code_edges.dart';
import 'package:cc_persistence/database/tables/code_files.dart';
import 'package:cc_persistence/database/tables/code_index_checkpoints.dart';
import 'package:cc_persistence/database/tables/code_symbols.dart';
import 'package:cc_persistence/database/utils/fts_query_utils.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/search/rrf.dart';
import 'package:drift/drift.dart';

part 'code_graph_dao.g.dart';

/// Data access for the code graph: symbols, edges and per-file index state.
///
/// Search mirrors MemoryFactDao exactly — FTS5 (BM25), sqlite_vector KNN,
/// and RRF fusion of the two — scoped by `workspaceId` (and `repoId`). Graph
/// traversal (callers / callees / impact radius) walks `code_edges`, also
/// scoped by `workspaceId` so it never crosses workspace boundaries.
@DriftAccessor(
  tables: [
    CodeSymbolsTable,
    CodeEdgesTable,
    CodeFilesTable,
    CodeIndexCheckpointsTable,
  ],
)
class CodeGraphDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$CodeGraphDaoMixin {
  /// Creates a [CodeGraphDao].
  CodeGraphDao(super.attachedDatabase);

  /// STRICT partition filter — the rows a partition literally owns.
  ///
  /// Null selects the linked checkout (`checkout_id IS NULL`), anything else the
  /// worktree partition with that `isolated_repos` id. Used by the WRITE and
  /// bookkeeping paths (file hashes, deletes, prune), where "what is in this
  /// partition" must mean exactly that — the indexer compares against it to
  /// decide what to add and remove.
  static Expression<bool> _checkoutFilter(
    GeneratedColumn<String> column,
    String? checkoutId,
  ) => checkoutId == null ? column.isNull() : column.equals(checkoutId);

  /// MERGED partition filter — what a reader of [checkoutId] should SEE.
  ///
  /// A worktree partition stores only its delta against the linked checkout
  /// (88% of a worktree's files are byte-identical to base, so storing them
  /// twice bought nothing), which means a symbol read has to span both: the
  /// worktree's own rows plus the base rows for every file the worktree did not
  /// change. Callers de-duplicate by `filePath` with [preferCheckout], so a file
  /// the worktree DID change is served entirely from the worktree's rows.
  ///
  /// Files DELETED in the worktree still match here through their base rows;
  /// `CodeGraphTreeService.audit` is what drops them, by checking the caller's
  /// tree on disk. Keeping it there means one deletion guard for both the stale
  /// -index case and this one.
  static Expression<bool> _mergedCheckoutFilter(
    GeneratedColumn<String> column,
    String? checkoutId,
  ) => checkoutId == null
      ? column.isNull()
      : column.isNull() | column.equals(checkoutId);

  /// Raw-SQL edge-partition predicate for graph traversal (`e` is the
  /// `code_edges` alias). Binds one variable when [checkoutId] is non-null.
  ///
  /// Traversal MUST be partition-scoped now that a worktree stores only a delta:
  /// its edges resolve to BASE symbol ids (the resolver sees merged symbols), so
  /// an unscoped `target_symbol_id = ?` would return callers living in every
  /// other conversation's worktree — one conversation reading another's code.
  /// Scoped, a reader sees base edges plus its own worktree's and nothing else.
  static String _edgePartitionSql(String? checkoutId) => checkoutId == null
      ? 'e.checkout_id IS NULL'
      : '(e.checkout_id IS NULL OR e.checkout_id = ?)';

  /// Collapses merged base+worktree rows to one per file: when a path appears in
  /// both partitions the worktree's rows win outright (it re-extracted the whole
  /// file, so its set is complete) and the base's copies of that path drop.
  /// Input order is preserved, so a ranked query stays ranked.
  static List<CodeSymbolsTableData> preferCheckout(
    List<CodeSymbolsTableData> rows,
    String? checkoutId,
  ) {
    if (checkoutId == null) {
      return rows;
    }
    final overridden = {
      for (final row in rows)
        if (row.checkoutId == checkoutId) row.filePath,
    };
    return [
      for (final row in rows)
        if (row.checkoutId != null || !overridden.contains(row.filePath)) row,
    ];
  }

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

  /// Reads the code-file index entry for a single file in the [checkoutId]
  /// partition (null = linked checkout).
  Future<CodeFilesTableData?> getFile(
    String workspaceId,
    String repoId,
    String path, {
    String? checkoutId,
  }) =>
      (select(codeFilesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.repoId.equals(repoId) &
                _checkoutFilter(t.checkoutId, checkoutId) &
                t.path.equals(path),
          ))
          .getSingleOrNull();

  /// Whether the [checkoutId] partition holds any indexed file (null = linked
  /// checkout). `LIMIT 1` — the existence probe on the read path, so it never
  /// pays for the full partition the way [getFiles] does.
  Future<bool> hasFiles(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async =>
      await (select(codeFilesTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.repoId.equals(repoId) &
                  _checkoutFilter(t.checkoutId, checkoutId),
            )
            ..limit(1))
          .getSingleOrNull() !=
      null;

  /// Reads all code-file index entries for a repo in the [checkoutId]
  /// partition (null = linked checkout).
  Future<List<CodeFilesTableData>> getFiles(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) =>
      (select(codeFilesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.repoId.equals(repoId) &
                _checkoutFilter(t.checkoutId, checkoutId),
          ))
          .get();

  /// Deletes a single file's symbols and edges in one transaction so the FTS
  /// and vector indexes never observe a half-removed file. Scoped to the
  /// [checkoutId] partition (null = linked checkout).
  Future<void> deleteByFile(
    String workspaceId,
    String repoId,
    String filePath, {
    String? checkoutId,
  }) => transaction(
    () => deleteFileRows(workspaceId, repoId, filePath, checkoutId: checkoutId),
  );

  /// The three per-file delete statements of [deleteByFile] WITHOUT the
  /// enclosing transaction, for callers that already hold one (the batched
  /// ingest path) — a nested `transaction()` per file would open a savepoint
  /// per file inside the outer transaction.
  Future<void> deleteFileRows(
    String workspaceId,
    String repoId,
    String filePath, {
    String? checkoutId,
  }) async {
    await (delete(codeSymbolsTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.repoId.equals(repoId) &
              _checkoutFilter(t.checkoutId, checkoutId) &
              t.filePath.equals(filePath),
        ))
        .go();
    await (delete(codeEdgesTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.repoId.equals(repoId) &
              _checkoutFilter(t.checkoutId, checkoutId) &
              t.sourceFilePath.equals(filePath),
        ))
        .go();
    await (delete(codeFilesTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.repoId.equals(repoId) &
              _checkoutFilter(t.checkoutId, checkoutId) &
              t.path.equals(filePath),
        ))
        .go();
  }

  /// The EDGE half of [deleteFileRows] on its own, for the ingest path, which
  /// replaces a file's edges wholesale but must NOT drop its symbol rows — a
  /// surviving symbol row carries an embedding worth keeping (see
  /// [getSymbolEmbedInputs]). Edges hold no vector, so churning them is free.
  Future<void> deleteFileEdgeRows(
    String workspaceId,
    String repoId,
    String filePath, {
    String? checkoutId,
  }) => (delete(codeEdgesTable)..where(
        (t) =>
            t.workspaceId.equals(workspaceId) &
            t.repoId.equals(repoId) &
            _checkoutFilter(t.checkoutId, checkoutId) &
            t.sourceFilePath.equals(filePath),
      ))
      .go();

  /// Deletes symbols by id, chunked at [_maxInListVariables] per statement.
  ///
  /// The ingest path's replacement for "delete every symbol of this file": it
  /// removes only the symbols a fresh extraction no longer defines, leaving the
  /// rest to be upserted in place. Scoped to [workspaceId] so it can never
  /// touch another workspace's row (ids are already partition-unique — the
  /// hash includes the checkout).
  Future<void> deleteSymbolsByIds(String workspaceId, List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    for (var i = 0; i < ids.length; i += _maxInListVariables) {
      final chunk = ids.sublist(
        i,
        (i + _maxInListVariables).clamp(0, ids.length),
      );
      await (delete(codeSymbolsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.id.isIn(chunk),
          ))
          .go();
    }
  }

  /// PROJECTION-ONLY read of what each already-indexed symbol in [filePaths]
  /// was embedded FROM, without dragging its embedding blob along: the id, the
  /// three text fields the embed text is built out of and whether the row
  /// already carries a vector.
  ///
  /// This is what lets a re-index skip inference for a symbol whose text did
  /// not change. Reading the blobs to compare them would defeat the point (a
  /// 384-float vector is ~1.5KB and a generated file can hold thousands of
  /// symbols), so the comparison is on the INPUTS.
  ///
  /// Scoped to the EXACT [checkoutId] partition, never merged with base: the
  /// caller is about to rewrite that partition's rows and a base row's
  /// embedding is not a worktree row's to reuse.
  Future<List<CodeSymbolEmbedRow>> getSymbolEmbedInputs(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) async {
    if (filePaths.isEmpty) {
      return const [];
    }
    final hasEmbedding = codeSymbolsTable.embedding.isNotNull();
    final out = <CodeSymbolEmbedRow>[];
    for (var i = 0; i < filePaths.length; i += _maxInListVariables) {
      final chunk = filePaths.sublist(
        i,
        (i + _maxInListVariables).clamp(0, filePaths.length),
      );
      final query = selectOnly(codeSymbolsTable)
        ..where(
          codeSymbolsTable.workspaceId.equals(workspaceId) &
              codeSymbolsTable.repoId.equals(repoId) &
              _checkoutFilter(codeSymbolsTable.checkoutId, checkoutId) &
              codeSymbolsTable.filePath.isIn(chunk),
        )
        ..addColumns([
          codeSymbolsTable.id,
          codeSymbolsTable.filePath,
          codeSymbolsTable.qualifiedName,
          codeSymbolsTable.signature,
          codeSymbolsTable.docstring,
          hasEmbedding,
        ]);
      for (final row in await query.get()) {
        out.add(
          CodeSymbolEmbedRow(
            id: row.read(codeSymbolsTable.id)!,
            filePath: row.read(codeSymbolsTable.filePath)!,
            qualifiedName: row.read(codeSymbolsTable.qualifiedName)!,
            signature: row.read(codeSymbolsTable.signature)!,
            docstring: row.read(codeSymbolsTable.docstring),
            hasEmbedding: row.read(hasEmbedding) ?? false,
          ),
        );
      }
    }
    return out;
  }

  /// Deletes many files' symbols/edges/file rows in ONE transaction with
  /// `IN (...)` predicates, chunked at [_maxInListVariables] paths per
  /// statement (portable under SQLite's historical 999-variable ceiling).
  /// Replaces the prune path's one-transaction-per-path loop.
  Future<void> deleteFilesBatch(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) {
    if (filePaths.isEmpty) {
      return Future.value();
    }
    return transaction(() async {
      for (var i = 0; i < filePaths.length; i += _maxInListVariables) {
        final chunk = filePaths.sublist(
          i,
          (i + _maxInListVariables).clamp(0, filePaths.length),
        );
        await (delete(codeSymbolsTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.repoId.equals(repoId) &
                  _checkoutFilter(t.checkoutId, checkoutId) &
                  t.filePath.isIn(chunk),
            ))
            .go();
        await (delete(codeEdgesTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.repoId.equals(repoId) &
                  _checkoutFilter(t.checkoutId, checkoutId) &
                  t.sourceFilePath.isIn(chunk),
            ))
            .go();
        await (delete(codeFilesTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.repoId.equals(repoId) &
                  _checkoutFilter(t.checkoutId, checkoutId) &
                  t.path.isIn(chunk),
            ))
            .go();
      }
    });
  }

  /// Chunk size for `IN (...)` lists: stays under SQLite's historical
  /// `SQLITE_MAX_VARIABLE_NUMBER` of 999 even with a few scope variables and
  /// a name used in two lists ([getSymbolNameIndex]).
  static const _maxInListVariables = 400;

  /// Removes the entire index for a repo within a workspace — ALL checkout
  /// partitions (repo unlink must not strand a worktree partition whose
  /// `isolated_repos` row is already gone).
  ///
  /// The index CHECKPOINTS go with it and that is load-bearing: a checkpoint
  /// says "this partition is current as of fingerprint X", so leaving one
  /// behind after wiping the rows makes the next run short-circuit on a match
  /// and serve an empty graph forever. Index state and its checkpoint are
  /// deleted together, always.
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
        await (delete(codeIndexCheckpointsTable)..where(
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
      (select(codeSymbolsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Reads symbols matching a name as seen from the [checkoutId] partition
  /// (null = linked checkout): the worktree's delta merged over the base.
  Future<List<CodeSymbolsTableData>> getSymbolsByName(
    String workspaceId,
    String repoId,
    String name, {
    int limit = 20,
    String? checkoutId,
  }) async => preferCheckout(
    await (select(codeSymbolsTable)
          ..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.repoId.equals(repoId) &
                _mergedCheckoutFilter(t.checkoutId, checkoutId) &
                t.name.equals(name),
          )
          // Over-fetch: the merge can drop base rows a worktree overrides and
          // the limit must apply to what the caller actually sees.
          ..limit(checkoutId == null ? limit : limit * 2))
        .get(),
    checkoutId,
  ).take(limit).toList();

  /// Watches symbols in a repo as seen from the [checkoutId] partition, sorted
  /// by file path (null = linked checkout).
  Stream<List<CodeSymbolsTableData>> watchSymbolsByRepo(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) =>
      (select(codeSymbolsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.repoId.equals(repoId) &
                  _mergedCheckoutFilter(t.checkoutId, checkoutId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.filePath)]))
          .watch()
          .map((rows) => preferCheckout(rows, checkoutId));

  /// Symbols still missing an embedding — fed to a background backfill so the
  /// embedding model never blocks ingest.
  ///
  /// CROSS-PARTITION BY DESIGN: workspace- and repo-scoped but deliberately not
  /// checkout-scoped, because every partition's symbols need embeddings and the
  /// backfill sweeps them all. The workspace-scoped alternative for read paths
  /// is [getSymbolsByRepo], which does take `checkoutId`.
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

  /// Reads all symbols in a repo, scoped to the [checkoutId] partition
  /// (null = linked checkout).
  Future<List<CodeSymbolsTableData>> getSymbolsByRepo(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => preferCheckout(
    await (select(codeSymbolsTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.repoId.equals(repoId) &
              _mergedCheckoutFilter(t.checkoutId, checkoutId),
        ))
        .get(),
    checkoutId,
  );

  /// Reads symbols in the given [filePaths] of a repo (used to build review
  /// cohorts from a PR's changed files — PRD 18 §1). Scoped to [workspaceId]
  /// and the [checkoutId] partition (null = linked checkout).
  Future<List<CodeSymbolsTableData>> getSymbolsByFiles(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) {
    if (filePaths.isEmpty) {
      return Future.value(const []);
    }
    return (select(codeSymbolsTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.repoId.equals(repoId) &
              _mergedCheckoutFilter(t.checkoutId, checkoutId) &
              t.filePath.isIn(filePaths),
        ))
        .get()
        .then((rows) => preferCheckout(rows, checkoutId));
  }

  /// Reads RESOLVED edges whose source is in the given [filePaths] (used to
  /// link a PR's changed files into semantic cohorts — PRD 18 §1). Only edges
  /// with a bound `targetSymbolId` are returned. Scoped to [workspaceId] and
  /// the [checkoutId] partition (null = linked checkout).
  Future<List<CodeEdgesTableData>> getResolvedEdgesBySourceFiles(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) {
    if (filePaths.isEmpty) {
      return Future.value(const []);
    }
    return (select(codeEdgesTable)..where(
          (e) =>
              e.workspaceId.equals(workspaceId) &
              e.repoId.equals(repoId) &
              _checkoutFilter(e.checkoutId, checkoutId) &
              e.sourceFilePath.isIn(filePaths) &
              e.targetSymbolId.isNotNull(),
        ))
        .get();
  }

  /// Reads RESOLVED edges pointing AT the given [targetSymbolIds] — the
  /// inbound direction, used to find which files (tests included) reference a
  /// PR's changed symbols.
  ///
  /// [getResolvedEdgesBySourceFiles] is the outbound equivalent and cannot
  /// answer this: it starts from the changed files, whereas coverage starts
  /// from everything ELSE that reaches them. Scoped to [workspaceId] and the
  /// [checkoutId] partition (null = linked checkout).
  ///
  /// Chunked because a large PR can change thousands of symbols and SQLite
  /// caps a statement's variable count.
  Future<List<CodeEdgesTableData>> getEdgesIntoSymbols(
    String workspaceId,
    String repoId,
    List<String> targetSymbolIds, {
    String? checkoutId,
    int chunkSize = 500,
  }) async {
    if (targetSymbolIds.isEmpty) {
      return const [];
    }
    final out = <CodeEdgesTableData>[];
    for (var i = 0; i < targetSymbolIds.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, targetSymbolIds.length);
      final chunk = targetSymbolIds.sublist(i, end);
      final rows =
          await (select(codeEdgesTable)..where(
                (e) =>
                    e.workspaceId.equals(workspaceId) &
                    e.repoId.equals(repoId) &
                    _checkoutFilter(e.checkoutId, checkoutId) &
                    e.targetSymbolId.isIn(chunk),
              ))
              .get();
      out.addAll(rows);
    }
    return out;
  }

  /// Edges whose target hasn't been resolved to a symbol id yet (cross-file
  /// references awaiting the name-resolution pass), scoped to the
  /// [checkoutId] partition (null = linked checkout).
  Future<List<CodeEdgesTableData>> getUnresolvedEdges(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) =>
      (select(codeEdgesTable)..where(
            (e) =>
                e.workspaceId.equals(workspaceId) &
                e.repoId.equals(repoId) &
                _checkoutFilter(e.checkoutId, checkoutId) &
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

  /// [setEdgeTarget] for many edges in ONE transaction — the resolution pass
  /// used to issue one auto-committed UPDATE per resolved edge.
  Future<void> setEdgeTargets(
    String workspaceId,
    Map<String, String> edgeIdToTargetId,
  ) {
    if (edgeIdToTargetId.isEmpty) {
      return Future.value();
    }
    // `batch` prepares the statement ONCE and runs it per row inside a single
    // transaction, instead of building and awaiting a separate statement per
    // edge. First index of a large repo resolves tens of thousands of edges.
    return batch((b) {
      for (final entry in edgeIdToTargetId.entries) {
        b.update(
          codeEdgesTable,
          CodeEdgesTableCompanion(targetSymbolId: Value(entry.value)),
          where: (e) =>
              e.id.equals(entry.key) & e.workspaceId.equals(workspaceId),
        );
      }
    });
  }

  /// Number of edges awaiting name resolution in the [checkoutId] partition
  /// (null = linked checkout). O(unresolved) via the
  /// `idx_code_edges_unresolved` partial index — the cheap probe that lets a
  /// run skip [getUnresolvedEdges] and the symbol-name read entirely.
  Future<int> countUnresolvedEdges(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async {
    final count = countAll();
    final row =
        await (selectOnly(codeEdgesTable)
              ..addColumns([count])
              ..where(
                codeEdgesTable.workspaceId.equals(workspaceId) &
                    codeEdgesTable.repoId.equals(repoId) &
                    _checkoutFilter(codeEdgesTable.checkoutId, checkoutId) &
                    codeEdgesTable.targetSymbolId.isNull() &
                    codeEdgesTable.targetName.isNotNull(),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// PROJECTION-ONLY symbol lookup for the reference-resolution pass:
  /// `(id, name, qualified_name, file_path, checkout_id)` for symbols whose
  /// `name` or `qualifiedName` is in [names], as seen from the [checkoutId]
  /// partition (merged base + delta; callers de-duplicate per file path with
  /// worktree-wins semantics, mirroring [preferCheckout]).
  ///
  /// The projection is the point: a full-row read materializes every symbol's
  /// ~1.5KB embedding blob, which made resolution O(all symbols × row size)
  /// even when a handful of names needed resolving.
  Future<List<CodeSymbolNameRow>> getSymbolNameIndex(
    String workspaceId,
    String repoId,
    Set<String> names, {
    String? checkoutId,
  }) async {
    if (names.isEmpty) {
      return const [];
    }
    final out = <CodeSymbolNameRow>[];
    final list = names.toList(growable: false);
    for (var i = 0; i < list.length; i += _maxInListVariables) {
      final chunk = list.sublist(
        i,
        (i + _maxInListVariables).clamp(0, list.length),
      );
      // Scope FIRST, then project: the workspace filter belongs next to the
      // read it guards (and the isolation ratchet reads it there).
      final query = selectOnly(codeSymbolsTable)
        ..where(
          codeSymbolsTable.workspaceId.equals(workspaceId) &
              codeSymbolsTable.repoId.equals(repoId) &
              _mergedCheckoutFilter(codeSymbolsTable.checkoutId, checkoutId) &
              (codeSymbolsTable.name.isIn(chunk) |
                  codeSymbolsTable.qualifiedName.isIn(chunk)),
        )
        ..addColumns([
          codeSymbolsTable.id,
          codeSymbolsTable.name,
          codeSymbolsTable.qualifiedName,
          codeSymbolsTable.filePath,
          codeSymbolsTable.checkoutId,
        ]);
      final rows = await query.get();
      for (final row in rows) {
        out.add(
          CodeSymbolNameRow(
            id: row.read(codeSymbolsTable.id)!,
            name: row.read(codeSymbolsTable.name)!,
            qualifiedName: row.read(codeSymbolsTable.qualifiedName)!,
            filePath: row.read(codeSymbolsTable.filePath)!,
            checkoutId: row.read(codeSymbolsTable.checkoutId),
          ),
        );
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Index checkpoints
  // ---------------------------------------------------------------------------

  /// Reads the checkpoint row(s) visible to the [checkoutId] partition in one
  /// query: the partition's own row plus (for a worktree) the base
  /// partition's, so the caller gets both without a second round trip.
  Future<List<CodeIndexCheckpointsTableData>> getCheckpointRows(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) =>
      (select(codeIndexCheckpointsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.repoId.equals(repoId) &
                _mergedCheckoutFilter(t.checkoutId, checkoutId),
          ))
          .get();

  /// Records (or updates) a partition's index checkpoint.
  Future<void> upsertCheckpoint(CodeIndexCheckpointsTableCompanion row) =>
      into(codeIndexCheckpointsTable).insertOnConflictUpdate(row);

  // ---------------------------------------------------------------------------
  // Search — mirrors MemoryFactDao (FTS5 / vector / RRF hybrid)
  // ---------------------------------------------------------------------------

  /// Full-text search over code symbols via FTS5, scoped to the [checkoutId]
  /// partition (null = linked checkout).
  Future<List<CodeSymbolsTableData>> searchFts(
    String workspaceId,
    String repoId,
    String query, {
    int limit = 20,
    String? checkoutId,
  }) {
    // The MATCH is scoped to [workspaceId] at the index level; the explicit
    // `cs.workspace_id = ?` below remains the authoritative isolation filter,
    // `cs.repo_id = ?` narrows to the repo within that workspace and the
    // checkout predicate selects the partition (IS NULL for the linked
    // checkout — FTS has no checkout column, so the filter rides on the
    // content table like repo_id).
    final match = toWorkspaceScopedFtsMatch(
      query,
      workspaceId,
      textColumns: const ['name', 'qualified_name', 'signature', 'docstring'],
    );
    if (match.isEmpty) {
      return Future.value(const []);
    }
    // Merged partition read: a worktree stores only its delta, so its search has
    // to span the base too. Ranking stays coherent because it is still ONE
    // query — the FTS `rank` orders base and delta rows against each other,
    // rather than two lists being stitched together afterwards.
    return customSelect(
          'SELECT cs.* FROM code_symbols cs '
          'JOIN code_symbols_fts fts ON fts.rowid = cs.rowid '
          'WHERE fts.code_symbols_fts MATCH ? '
          'AND cs.workspace_id = ? '
          'AND cs.repo_id = ? '
          'AND ${checkoutId == null ? 'cs.checkout_id IS NULL' : '(cs.checkout_id IS NULL OR cs.checkout_id = ?)'} '
          'ORDER BY rank '
          'LIMIT ?',
          variables: [
            Variable<String>(match),
            Variable<String>(workspaceId),
            Variable<String>(repoId),
            if (checkoutId != null) Variable<String>(checkoutId),
            // Over-fetch so the post-merge trim still yields `limit` rows.
            Variable<int>(checkoutId == null ? limit : limit * 2),
          ],
          readsFrom: {codeSymbolsTable},
        )
        .map((row) => codeSymbolsTable.map(row.data))
        .get()
        .then((rows) => preferCheckout(rows, checkoutId).take(limit).toList());
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
    String? checkoutId,
  }) {
    final vectorJson =
        '[${queryEmbedding.map((v) => v.toStringAsFixed(6)).join(', ')}]';
    return customSelect(
          'SELECT cs.* FROM code_symbols cs '
          "JOIN vector_full_scan('code_symbols', 'embedding', vector_as_f32(?), ?) AS v "
          'ON cs.rowid = v.rowid '
          'WHERE cs.workspace_id = ? '
          'AND cs.repo_id = ? '
          'AND ${checkoutId == null ? 'cs.checkout_id IS NULL' : '(cs.checkout_id IS NULL OR cs.checkout_id = ?)'} '
          'ORDER BY v.distance '
          'LIMIT ?',
          variables: [
            Variable<String>(vectorJson),
            Variable<int>(limit),
            Variable<String>(workspaceId),
            Variable<String>(repoId),
            if (checkoutId != null) Variable<String>(checkoutId),
            Variable<int>(checkoutId == null ? limit : limit * 2),
          ],
          readsFrom: {codeSymbolsTable},
        )
        .map((row) => codeSymbolsTable.map(row.data))
        .get()
        .then((rows) => preferCheckout(rows, checkoutId).take(limit).toList());
  }

  /// Hybrid BM25 + vector search via RRF fusion (k = 60), identical to the
  /// memory fact path. Scoped to the [checkoutId] partition (null = linked
  /// checkout).
  Future<List<CodeSymbolsTableData>> searchHybrid(
    String workspaceId,
    String repoId,
    String query,
    Float32List queryEmbedding, {
    int limit = 10,
    String? checkoutId,
  }) async {
    // Concurrent: two independent queries whose results are fused, so running
    // them in sequence just adds one's latency to the other's.
    final results = await Future.wait([
      searchFts(workspaceId, repoId, query, checkoutId: checkoutId),
      searchVector(
        workspaceId,
        repoId,
        queryEmbedding,
        limit: 30,
        checkoutId: checkoutId,
      ),
    ]);
    final ftsResults = results[0];
    final vectorResults = results[1];
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
    String? checkoutId,
  }) {
    final names = kinds.map((k) => k.name).toList();
    return customSelect(
          'SELECT cs.* FROM code_edges e '
          'JOIN code_symbols cs ON cs.id = e.target_symbol_id '
          'WHERE e.source_symbol_id = ? AND e.workspace_id = ? '
          'AND ${_edgePartitionSql(checkoutId)} '
          'AND e.kind IN (${_kindPlaceholders(kinds)})'
          '${limit != null ? ' LIMIT ?' : ''}',
          variables: [
            Variable<String>(symbolId),
            Variable<String>(workspaceId),
            if (checkoutId != null) Variable<String>(checkoutId),
            ...names.map(Variable<String>.new),
            if (limit != null) Variable<int>(limit),
          ],
          readsFrom: {codeEdgesTable, codeSymbolsTable},
        )
        .map((row) => codeSymbolsTable.map(row.data))
        .get()
        .then((rows) => preferCheckout(rows, checkoutId));
  }

  /// Symbols that point to [symbolId] via [kinds] edges (incoming), scoped to
  /// [workspaceId].
  Future<List<CodeSymbolsTableData>> getCallers(
    String workspaceId,
    String symbolId, {
    Set<CodeEdgeKind> kinds = const {CodeEdgeKind.calls},
    int? limit,
    String? checkoutId,
  }) {
    final names = kinds.map((k) => k.name).toList();
    return customSelect(
          'SELECT cs.* FROM code_edges e '
          'JOIN code_symbols cs ON cs.id = e.source_symbol_id '
          'WHERE e.target_symbol_id = ? AND e.workspace_id = ? '
          'AND ${_edgePartitionSql(checkoutId)} '
          'AND e.kind IN (${_kindPlaceholders(kinds)})'
          '${limit != null ? ' LIMIT ?' : ''}',
          variables: [
            Variable<String>(symbolId),
            Variable<String>(workspaceId),
            if (checkoutId != null) Variable<String>(checkoutId),
            ...names.map(Variable<String>.new),
            if (limit != null) Variable<int>(limit),
          ],
          readsFrom: {codeEdgesTable, codeSymbolsTable},
        )
        .map((row) => codeSymbolsTable.map(row.data))
        .get()
        .then((rows) => preferCheckout(rows, checkoutId));
  }

  /// Transitive reverse-call closure: everything that (in)directly depends on
  /// [symbolId], up to [depth] hops. Returns the reachable symbols (incl. the
  /// root at depth 0), the edges among them and a depth map.
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
    String? checkoutId,
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
      '    AND ${_edgePartitionSql(checkoutId)}'
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
        if (checkoutId != null) Variable<String>(checkoutId),
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

/// One row of [CodeGraphDao.getSymbolEmbedInputs] — everything needed to decide
/// whether a re-indexed symbol still deserves the vector it already has and
/// nothing that would make asking expensive.
class CodeSymbolEmbedRow {
  /// Creates a [CodeSymbolEmbedRow].
  const CodeSymbolEmbedRow({
    required this.id,
    required this.filePath,
    required this.qualifiedName,
    required this.signature,
    this.docstring,
    required this.hasEmbedding,
  });

  /// Symbol id (deterministic, so it survives a re-extraction of the file).
  final String id;

  /// Repo-relative path of the defining file.
  final String filePath;

  /// Qualified name (`Class.member` / library-prefixed).
  final String qualifiedName;

  /// Declaration signature.
  final String signature;

  /// Doc comment, when the symbol has one.
  final String? docstring;

  /// Whether the stored row already carries an embedding. A row without one has
  /// nothing to reuse (the model was not ready when it was indexed) and must be
  /// embedded on this pass or left for the backfill.
  final bool hasEmbedding;
}

/// One row of [CodeGraphDao.getSymbolNameIndex] — the projection the
/// reference-resolution pass needs, WITHOUT the embedding blob a full
/// `code_symbols` row drags along.
class CodeSymbolNameRow {
  /// Creates a [CodeSymbolNameRow].
  const CodeSymbolNameRow({
    required this.id,
    required this.name,
    required this.qualifiedName,
    required this.filePath,
    required this.checkoutId,
  });

  /// Symbol id.
  final String id;

  /// Simple name.
  final String name;

  /// Qualified name (`Class.member` / library-prefixed).
  final String qualifiedName;

  /// Repo-relative path of the defining file.
  final String filePath;

  /// Partition the row lives in (null = linked checkout).
  final String? checkoutId;
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
