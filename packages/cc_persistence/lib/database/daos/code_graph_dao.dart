import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_persistence/database/code_index/code_index_database.dart';
import 'package:cc_persistence/database/tables/code_edges.dart';
import 'package:cc_persistence/database/tables/code_files.dart';
import 'package:cc_persistence/database/tables/code_index_checkpoints.dart';
import 'package:cc_persistence/database/tables/code_symbol_embeddings.dart';
import 'package:cc_persistence/database/tables/code_symbols.dart';
import 'package:cc_persistence/database/utils/fts_query_utils.dart';
import 'package:cc_persistence/search/rrf.dart';
import 'package:drift/drift.dart';

part 'code_graph_dao.g.dart';

/// Data access for the code graph: symbols, edges and per-file index state.
///
/// Search mirrors MemoryFactDao exactly — FTS5 (BM25), sqlite_vector KNN,
/// and RRF fusion of the two — scoped by `repoId` and the checkout partition.
/// Graph traversal (callers / callees / impact radius) walks `code_edges`.
/// A symbol row carries no vector (`code_symbol_embeddings` does), so only
/// the vector search and the embedding bookkeeping touch the side table.
///
/// Hangs off one workspace's [CodeIndexDatabase], which holds that workspace's
/// index and nothing else, so no method takes a workspace id: the caller
/// picked the file by it (`WorkspaceDatabaseManager.codeIndexOf`).
@DriftAccessor(
  tables: [
    CodeSymbolsTable,
    CodeSymbolEmbeddingsTable,
    CodeEdgesTable,
    CodeFilesTable,
    CodeIndexCheckpointsTable,
  ],
)
class CodeGraphDao extends DatabaseAccessor<CodeIndexDatabase>
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

  // Ingest

  /// Batch-upserts symbols (deterministic ids → in-place update on re-index).
  ///
  /// An upsert updates in place, so a symbol keeps its vector row; whether
  /// that vector still fits is the caller's call ([putEmbeddings],
  /// [deleteEmbeddings]).
  Future<void> upsertSymbols(List<CodeSymbolsTableCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(codeSymbolsTable, rows));

  /// Stores each vector of [embeddings] (symbol id to FLOAT32 bytes),
  /// replacing the one a symbol had. The symbols must exist: this is the
  /// ingest's write, inside the transaction that just upserted them.
  Future<void> putEmbeddings(Map<String, Uint8List> embeddings) {
    if (embeddings.isEmpty) {
      return Future.value();
    }
    return batch(
      (b) => b.insertAllOnConflictUpdate(codeSymbolEmbeddingsTable, [
        for (final MapEntry(key: id, value: vector) in embeddings.entries)
          CodeSymbolEmbeddingsTableCompanion.insert(
            symbolId: id,
            embedding: vector,
          ),
      ]),
    );
  }

  /// Removes the vectors of the symbols [ids], chunked at
  /// [_maxInListVariables] per statement. The symbol rows stay.
  ///
  /// For a re-index that changed a symbol's text without a vector to go with
  /// it (the model is not installed): the old vector would rank the symbol
  /// for what it no longer says.
  Future<void> deleteEmbeddings(List<String> ids) async {
    for (var i = 0; i < ids.length; i += _maxInListVariables) {
      final chunk = ids.sublist(
        i,
        (i + _maxInListVariables).clamp(0, ids.length),
      );
      await (delete(
        codeSymbolEmbeddingsTable,
      )..where((t) => t.symbolId.isIn(chunk))).go();
    }
  }

  /// Stores each backfilled vector for a symbol that has none yet and whose
  /// stored text is still the text the vector was computed from. Returns how
  /// many were stored.
  ///
  /// The backfill embeds outside any transaction, so by the time it writes a
  /// symbol may be gone (its file was re-indexed), changed, or embedded by an
  /// ingest; each of those is skipped instead of failing the batch on a
  /// foreign key or overwriting a fresher vector.
  Future<int> putBackfilledEmbeddings(
    List<({CodeSymbolsTableData symbol, Uint8List embedding})> embeddings,
  ) => transaction(() async {
    var stored = 0;
    for (final e in embeddings) {
      stored += await customUpdate(
        'INSERT INTO code_symbol_embeddings (symbol_id, embedding) '
        'SELECT id, ? FROM code_symbols '
        'WHERE id = ? AND qualified_name = ? AND signature = ? '
        'AND docstring IS ? '
        'ON CONFLICT (symbol_id) DO NOTHING',
        variables: [
          Variable<Uint8List>(e.embedding),
          Variable<String>(e.symbol.id),
          Variable<String>(e.symbol.qualifiedName),
          Variable<String>(e.symbol.signature),
          Variable<String>(e.symbol.docstring),
        ],
        updates: {codeSymbolEmbeddingsTable},
        updateKind: UpdateKind.insert,
      );
    }
    return stored;
  });

  /// Batch-upserts edges.
  Future<void> upsertEdges(List<CodeEdgesTableCompanion> rows) => batch(
    (b) => b.insertAll(codeEdgesTable, rows, mode: InsertMode.insertOrReplace),
  );

  /// Records (or updates) a file's content hash + symbol count.
  Future<void> upsertFile(CodeFilesTableCompanion row) =>
      into(codeFilesTable).insertOnConflictUpdate(row);

  // Incremental re-index

  /// Reads the code-file index entry for a single file in the [checkoutId]
  /// partition (null = linked checkout).
  Future<CodeFilesTableData?> getFile(
    String repoId,
    String path, {
    String? checkoutId,
  }) =>
      (select(codeFilesTable)..where(
            (t) =>
                t.repoId.equals(repoId) &
                _checkoutFilter(t.checkoutId, checkoutId) &
                t.path.equals(path),
          ))
          .getSingleOrNull();

  /// Whether the [checkoutId] partition holds any indexed file (null = linked
  /// checkout). `LIMIT 1` — the existence probe on the read path, so it never
  /// pays for the full partition the way [getFiles] does.
  Future<bool> hasFiles(String repoId, {String? checkoutId}) async =>
      await (select(codeFilesTable)
            ..where(
              (t) =>
                  t.repoId.equals(repoId) &
                  _checkoutFilter(t.checkoutId, checkoutId),
            )
            ..limit(1))
          .getSingleOrNull() !=
      null;

  /// Reads all code-file index entries for a repo in the [checkoutId]
  /// partition (null = linked checkout).
  Future<List<CodeFilesTableData>> getFiles(
    String repoId, {
    String? checkoutId,
  }) =>
      (select(codeFilesTable)..where(
            (t) =>
                t.repoId.equals(repoId) &
                _checkoutFilter(t.checkoutId, checkoutId),
          ))
          .get();

  /// [getFiles], narrowed to [paths] — the read a TARGETED incremental index
  /// makes instead of dragging the partition's whole `code_files` table through
  /// the row mapper to look at the handful of files that changed.
  ///
  /// A worktree run paid this twice (its own partition and the base's) at ~19k
  /// rows each, on the ONE shared database connection every RPC read also
  /// queues behind. Chunked because the paths ride as bound variables.
  Future<List<CodeFilesTableData>> getFilesByPaths(
    String repoId,
    List<String> paths, {
    String? checkoutId,
  }) async {
    if (paths.isEmpty) {
      return const [];
    }
    final out = <CodeFilesTableData>[];
    for (var i = 0; i < paths.length; i += _maxInListVariables) {
      final chunk = paths.sublist(
        i,
        (i + _maxInListVariables).clamp(0, paths.length),
      );
      out.addAll(
        await (select(codeFilesTable)..where(
              (t) =>
                  t.repoId.equals(repoId) &
                  _checkoutFilter(t.checkoutId, checkoutId) &
                  t.path.isIn(chunk),
            ))
            .get(),
      );
    }
    return out;
  }

  /// Deletes a single file's symbols and edges in one transaction so the FTS
  /// and vector indexes never observe a half-removed file. Scoped to the
  /// [checkoutId] partition (null = linked checkout).
  Future<void> deleteByFile(
    String repoId,
    String filePath, {
    String? checkoutId,
  }) => transaction(
    () => deleteFileRows(repoId, filePath, checkoutId: checkoutId),
  );

  /// The three per-file delete statements of [deleteByFile] WITHOUT the
  /// enclosing transaction, for callers that already hold one (the batched
  /// ingest path) — a nested `transaction()` per file would open a savepoint
  /// per file inside the outer transaction.
  Future<void> deleteFileRows(
    String repoId,
    String filePath, {
    String? checkoutId,
  }) async {
    await (delete(codeSymbolsTable)..where(
          (t) =>
              t.repoId.equals(repoId) &
              _checkoutFilter(t.checkoutId, checkoutId) &
              t.filePath.equals(filePath),
        ))
        .go();
    await (delete(codeEdgesTable)..where(
          (t) =>
              t.repoId.equals(repoId) &
              _checkoutFilter(t.checkoutId, checkoutId) &
              t.sourceFilePath.equals(filePath),
        ))
        .go();
    await (delete(codeFilesTable)..where(
          (t) =>
              t.repoId.equals(repoId) &
              _checkoutFilter(t.checkoutId, checkoutId) &
              t.path.equals(filePath),
        ))
        .go();
  }

  /// The EDGE half of [deleteFileRows] on its own, for the ingest path, which
  /// replaces a file's edges wholesale but must NOT drop its symbol rows — a
  /// surviving symbol has a vector worth keeping, and deleting the symbol
  /// cascades to it (see [getSymbolEmbedInputs]). Edges hold no vector, so
  /// churning them is free.
  Future<void> deleteFileEdgeRows(
    String repoId,
    String filePath, {
    String? checkoutId,
  }) =>
      (delete(codeEdgesTable)..where(
            (t) =>
                t.repoId.equals(repoId) &
                _checkoutFilter(t.checkoutId, checkoutId) &
                t.sourceFilePath.equals(filePath),
          ))
          .go();

  /// Deletes symbols by id, chunked at [_maxInListVariables] per statement.
  ///
  /// The ingest path's replacement for "delete every symbol of this file": it
  /// removes only the symbols a fresh extraction no longer defines, leaving the
  /// rest to be upserted in place. Ids are partition-unique (the hash includes
  /// the checkout), so no further scope is needed. Their vectors go with them
  /// (`ON DELETE CASCADE`).
  Future<void> deleteSymbolsByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    for (var i = 0; i < ids.length; i += _maxInListVariables) {
      final chunk = ids.sublist(
        i,
        (i + _maxInListVariables).clamp(0, ids.length),
      );
      await (delete(codeSymbolsTable)..where((t) => t.id.isIn(chunk))).go();
    }
  }

  /// PROJECTION-ONLY read of what each already-indexed symbol in [filePaths]
  /// was embedded FROM: the id, the three text fields the embed text is built
  /// out of and whether the symbol has a vector (a probe of the side table's
  /// primary key, never a read of the vector).
  ///
  /// This is what lets a re-index skip inference for a symbol whose text did
  /// not change. Reading the vectors to compare them would defeat the point (a
  /// 384-float vector is ~1.5KB and a generated file can hold thousands of
  /// symbols), so the comparison is on the INPUTS.
  ///
  /// Scoped to the EXACT [checkoutId] partition, never merged with base: the
  /// caller is about to rewrite that partition's rows and a base row's
  /// embedding is not a worktree row's to reuse.
  Future<List<CodeSymbolEmbedRow>> getSymbolEmbedInputs(
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) async {
    if (filePaths.isEmpty) {
      return const [];
    }
    final hasEmbedding = existsQuery(
      selectOnly(codeSymbolEmbeddingsTable)
        ..addColumns([codeSymbolEmbeddingsTable.symbolId])
        ..where(
          codeSymbolEmbeddingsTable.symbolId.equalsExp(codeSymbolsTable.id),
        ),
    );
    final out = <CodeSymbolEmbedRow>[];
    for (var i = 0; i < filePaths.length; i += _maxInListVariables) {
      final chunk = filePaths.sublist(
        i,
        (i + _maxInListVariables).clamp(0, filePaths.length),
      );
      final query = selectOnly(codeSymbolsTable)
        ..where(
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

  /// Deletes many files' symbols (and with them their vectors), edges and
  /// file rows in ONE transaction with
  /// `IN (...)` predicates, chunked at [_maxInListVariables] paths per
  /// statement (portable under SQLite's historical 999-variable ceiling).
  /// Replaces the prune path's one-transaction-per-path loop.
  Future<void> deleteFilesBatch(
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
                  t.repoId.equals(repoId) &
                  _checkoutFilter(t.checkoutId, checkoutId) &
                  t.filePath.isIn(chunk),
            ))
            .go();
        await (delete(codeEdgesTable)..where(
              (t) =>
                  t.repoId.equals(repoId) &
                  _checkoutFilter(t.checkoutId, checkoutId) &
                  t.sourceFilePath.isIn(chunk),
            ))
            .go();
        await (delete(codeFilesTable)..where(
              (t) =>
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

  /// Removes the entire index for a repo, vectors included — ALL checkout
  /// partitions (repo
  /// unlink must not strand a worktree partition whose `isolated_repos` row is
  /// already gone).
  ///
  /// Explicit because the rows live in a file of their own and no foreign key
  /// reaches them from `repos`: the code that removes a repo from
  /// `workspace.db` calls this.
  ///
  /// The index CHECKPOINTS go with it and that is load-bearing: a checkpoint
  /// says "this partition is current as of fingerprint X", so leaving one
  /// behind after wiping the rows makes the next run short-circuit on a match
  /// and serve an empty graph forever. Index state and its checkpoint are
  /// deleted together, always.
  Future<void> deleteByRepo(String repoId) => transaction(() async {
    await (delete(
      codeSymbolsTable,
    )..where((t) => t.repoId.equals(repoId))).go();
    await (delete(codeEdgesTable)..where((t) => t.repoId.equals(repoId))).go();
    await (delete(codeFilesTable)..where((t) => t.repoId.equals(repoId))).go();
    await (delete(
      codeIndexCheckpointsTable,
    )..where((t) => t.repoId.equals(repoId))).go();
  });

  /// Removes one worktree partition ([checkoutId], an `isolated_repos` id of
  /// [repoId]) with its vectors and its checkpoint, for the code that deletes the worktree's
  /// row from `workspace.db`. The linked checkout's partition is never
  /// touched: only [deleteByRepo] removes that.
  Future<void> deleteByCheckout(String repoId, String checkoutId) =>
      transaction(() async {
        await (delete(codeSymbolsTable)..where(
              (t) => t.repoId.equals(repoId) & t.checkoutId.equals(checkoutId),
            ))
            .go();
        await (delete(codeEdgesTable)..where(
              (t) => t.repoId.equals(repoId) & t.checkoutId.equals(checkoutId),
            ))
            .go();
        await (delete(codeFilesTable)..where(
              (t) => t.repoId.equals(repoId) & t.checkoutId.equals(checkoutId),
            ))
            .go();
        await (delete(codeIndexCheckpointsTable)..where(
              (t) => t.repoId.equals(repoId) & t.checkoutId.equals(checkoutId),
            ))
            .go();
      });

  // Reads

  /// Reads a symbol by id.
  Future<CodeSymbolsTableData?> getSymbolById(String id) => (select(
    codeSymbolsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Reads symbols matching a name as seen from the [checkoutId] partition
  /// (null = linked checkout): the worktree's delta merged over the base.
  Future<List<CodeSymbolsTableData>> getSymbolsByName(
    String repoId,
    String name, {
    int limit = 20,
    String? checkoutId,
  }) async => preferCheckout(
    await (select(codeSymbolsTable)
          ..where(
            (t) =>
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
    String repoId, {
    String? checkoutId,
  }) =>
      (select(codeSymbolsTable)
            ..where(
              (t) =>
                  t.repoId.equals(repoId) &
                  _mergedCheckoutFilter(t.checkoutId, checkoutId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.filePath)]))
          .watch()
          .map((rows) => preferCheckout(rows, checkoutId));

  /// Symbols that have no vector yet (indexed while the model was missing),
  /// the backfill's work list.
  ///
  /// "No vector" is "no side row": an anti-join probing the side table's
  /// primary key once per symbol.
  ///
  /// CROSS-PARTITION BY DESIGN: neither repo- nor checkout-scoped, because
  /// every partition's symbols need vectors and the backfill sweeps the whole
  /// file, which holds one workspace. The partition-scoped alternative for
  /// read paths is [getSymbolsByRepo].
  Future<List<CodeSymbolsTableData>> getSymbolsWithoutEmbedding({
    int limit = 200,
  }) => customSelect(
    withoutEmbeddingSql,
    variables: [Variable<int>(limit)],
    readsFrom: {codeSymbolsTable, codeSymbolEmbeddingsTable},
  ).map((row) => codeSymbolsTable.map(row.data)).get();

  /// The statement [getSymbolsWithoutEmbedding] runs (public so a test can
  /// assert its plan).
  static const withoutEmbeddingSql =
      'SELECT cs.* FROM code_symbols cs '
      'WHERE NOT EXISTS (SELECT 1 FROM code_symbol_embeddings e '
      'WHERE e.symbol_id = cs.id) '
      'LIMIT ?';

  /// Reads all symbols in a repo, scoped to the [checkoutId] partition
  /// (null = linked checkout).
  Future<List<CodeSymbolsTableData>> getSymbolsByRepo(
    String repoId, {
    String? checkoutId,
  }) async => preferCheckout(
    await (select(codeSymbolsTable)..where(
          (t) =>
              t.repoId.equals(repoId) &
              _mergedCheckoutFilter(t.checkoutId, checkoutId),
        ))
        .get(),
    checkoutId,
  );

  /// Reads symbols in the given [filePaths] of a repo (used to build review
  /// cohorts from a PR's changed files — PRD 18 §1). Scoped to the
  /// [checkoutId] partition (null = linked checkout).
  Future<List<CodeSymbolsTableData>> getSymbolsByFiles(
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) {
    if (filePaths.isEmpty) {
      return Future.value(const []);
    }
    return (select(codeSymbolsTable)..where(
          (t) =>
              t.repoId.equals(repoId) &
              _mergedCheckoutFilter(t.checkoutId, checkoutId) &
              t.filePath.isIn(filePaths),
        ))
        .get()
        .then((rows) => preferCheckout(rows, checkoutId));
  }

  /// Reads RESOLVED edges whose source is in the given [filePaths] (used to
  /// link a PR's changed files into semantic cohorts — PRD 18 §1). Only edges
  /// with a bound `targetSymbolId` are returned. Scoped to the
  /// [checkoutId] partition (null = linked checkout).
  Future<List<CodeEdgesTableData>> getResolvedEdgesBySourceFiles(
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) {
    if (filePaths.isEmpty) {
      return Future.value(const []);
    }
    return (select(codeEdgesTable)..where(
          (e) =>
              e.repoId.equals(repoId) &
              _checkoutFilter(e.checkoutId, checkoutId) &
              e.sourceFilePath.isIn(filePaths) &
              e.targetSymbolId.isNotNull(),
        ))
        .get();
  }

  /// Reads RESOLVED edges pointing AT the given [targetSymbolIds] — the inbound direction,
  /// used to find which files (tests included) reference a PR's changed symbols.
  ///
  /// [getResolvedEdgesBySourceFiles] is the outbound equivalent and cannot answer this: it
  /// starts from the changed files, whereas coverage starts from everything ELSE that reaches
  /// them.
  /// Scoped to the [checkoutId] partition (null = linked checkout).
  Future<List<CodeEdgesTableData>> getEdgesIntoSymbols(
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
    String repoId, {
    String? checkoutId,
  }) =>
      (select(codeEdgesTable)..where(
            (e) =>
                e.repoId.equals(repoId) &
                _checkoutFilter(e.checkoutId, checkoutId) &
                e.targetSymbolId.isNull() &
                e.targetName.isNotNull(),
          ))
          .get();

  /// Binds a previously-unresolved edge to a resolved target symbol id. Keeps
  /// the edge's id stable (id is derived at creation time, not from the
  /// resolved target) so re-index doesn't churn rows.
  Future<void> setEdgeTarget(String edgeId, String targetSymbolId) =>
      (update(codeEdgesTable)..where((e) => e.id.equals(edgeId))).write(
        CodeEdgesTableCompanion(targetSymbolId: Value(targetSymbolId)),
      );

  /// [setEdgeTarget] for many edges in ONE transaction — the resolution pass
  /// used to issue one auto-committed UPDATE per resolved edge.
  Future<void> setEdgeTargets(Map<String, String> edgeIdToTargetId) {
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
          where: (e) => e.id.equals(entry.key),
        );
      }
    });
  }

  /// Number of edges awaiting name resolution in the [checkoutId] partition
  /// (null = linked checkout). O(unresolved) via the
  /// `idx_code_edges_unresolved` partial index — the cheap probe that lets a
  /// run skip [getUnresolvedEdges] and the symbol-name read entirely.
  Future<int> countUnresolvedEdges(String repoId, {String? checkoutId}) async {
    final count = countAll();
    final row =
        await (selectOnly(codeEdgesTable)
              ..addColumns([count])
              ..where(
                codeEdgesTable.repoId.equals(repoId) &
                    _checkoutFilter(codeEdgesTable.checkoutId, checkoutId) &
                    codeEdgesTable.targetSymbolId.isNull() &
                    codeEdgesTable.targetName.isNotNull(),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Deletes the [checkoutId] partition's (null = linked checkout) edges that
  /// are still unresolved after the name-resolution pass — references to
  /// things outside the indexed tree (packages, SDKs, vendor namespaces) or
  /// ambiguous names. Same WHERE as [countUnresolvedEdges] (it walks the same
  /// partial index). Returns the number of rows deleted.
  Future<int> deleteUnresolvedEdges(String repoId, {String? checkoutId}) =>
      (delete(codeEdgesTable)..where(
            (e) =>
                e.repoId.equals(repoId) &
                _checkoutFilter(e.checkoutId, checkoutId) &
                e.targetSymbolId.isNull() &
                e.targetName.isNotNull(),
          ))
          .go();

  /// PROJECTION-ONLY symbol lookup for the reference-resolution pass:
  /// `(id, name, qualified_name, file_path, checkout_id)` for symbols whose
  /// `name` or `qualifiedName` is in [names], as seen from the [checkoutId]
  /// partition (merged base + delta; callers de-duplicate per file path with
  /// worktree-wins semantics, mirroring [preferCheckout]).
  ///
  /// The projection keeps resolution's reads to the five columns it uses: a
  /// full row also carries the signature and doc comment of every candidate.
  Future<List<CodeSymbolNameRow>> getSymbolNameIndex(
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
      final query = selectOnly(codeSymbolsTable)
        ..where(
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

  // Index checkpoints

  /// Reads the checkpoint row(s) visible to the [checkoutId] partition in one
  /// query: the partition's own row plus (for a worktree) the base
  /// partition's, so the caller gets both without a second round trip.
  Future<List<CodeIndexCheckpointsTableData>> getCheckpointRows(
    String repoId, {
    String? checkoutId,
  }) =>
      (select(codeIndexCheckpointsTable)..where(
            (t) =>
                t.repoId.equals(repoId) &
                _mergedCheckoutFilter(t.checkoutId, checkoutId),
          ))
          .get();

  /// Records (or updates) a partition's index checkpoint.
  Future<void> upsertCheckpoint(CodeIndexCheckpointsTableCompanion row) =>
      into(codeIndexCheckpointsTable).insertOnConflictUpdate(row);

  // Search — mirrors MemoryFactDao (FTS5 / vector / RRF hybrid)

  /// Full-text search over code symbols via FTS5, scoped to the [checkoutId]
  /// partition (null = linked checkout).
  Future<List<CodeSymbolsTableData>> searchFts(
    String repoId,
    String query, {
    int limit = 20,
    String? checkoutId,
  }) {
    // `cs.repo_id = ?` narrows to the repo and the checkout predicate
    // selects the partition (IS NULL for the linked checkout — FTS has no
    // checkout column, so the filter rides on the content table like
    // repo_id). Every FTS column is a text column, so the match needs no
    // column filter.
    final match = toFtsOrQuery(query);
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
          'AND cs.repo_id = ? '
          'AND ${checkoutId == null ? 'cs.checkout_id IS NULL' : '(cs.checkout_id IS NULL OR cs.checkout_id = ?)'} '
          'ORDER BY rank '
          'LIMIT ?',
          variables: [
            Variable<String>(match),
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
  /// The scan runs over `code_symbol_embeddings` and yields ITS rowids: each
  /// is matched to its side row in this statement and the symbol is reached
  /// through the `symbol_id` that row stores, never through a rowid of
  /// `code_symbols`.
  ///
  /// The scan has no per-repo partition, so it spans every embedding in the
  /// file and the `cs.repo_id = ?` / checkout filters below select the
  /// partition. `vector_full_scan_stream` yields every row with its distance and
  /// no top-k cut, so those filters run BEFORE the ranking: `vector_full_scan`
  /// takes k up front, ranks across every repo and checkout in the file, and a
  /// repo whose symbols sit outside that global top-k came back empty. CROSS
  /// JOIN pins the scan as the outer loop; as the inner one it would re-run
  /// per candidate row.
  Future<List<CodeSymbolsTableData>> searchVector(
    String repoId,
    Float32List queryEmbedding, {
    int limit = 30,
    String? checkoutId,
  }) {
    final vectorJson =
        '[${queryEmbedding.map((v) => v.toStringAsFixed(6)).join(', ')}]';
    return customSelect(
          'SELECT cs.* FROM '
          "vector_full_scan_stream('code_symbol_embeddings', 'embedding', "
          'vector_as_f32(?)) AS v '
          'CROSS JOIN code_symbol_embeddings e ON e.rowid = v.rowid '
          'CROSS JOIN code_symbols cs ON cs.id = e.symbol_id '
          'WHERE cs.repo_id = ? '
          'AND ${checkoutId == null ? 'cs.checkout_id IS NULL' : '(cs.checkout_id IS NULL OR cs.checkout_id = ?)'} '
          'ORDER BY v.distance '
          'LIMIT ?',
          variables: [
            Variable<String>(vectorJson),
            Variable<String>(repoId),
            if (checkoutId != null) Variable<String>(checkoutId),
            Variable<int>(checkoutId == null ? limit : limit * 2),
          ],
          readsFrom: {codeSymbolsTable, codeSymbolEmbeddingsTable},
        )
        .map((row) => codeSymbolsTable.map(row.data))
        .get()
        .then((rows) => preferCheckout(rows, checkoutId).take(limit).toList());
  }

  /// Hybrid BM25 + vector search via RRF fusion (k = 60), identical to the
  /// memory fact path. Scoped to the [checkoutId] partition (null = linked
  /// checkout).
  Future<List<CodeSymbolsTableData>> searchHybrid(
    String repoId,
    String query,
    Float32List queryEmbedding, {
    int limit = 10,
    String? checkoutId,
  }) async {
    // Concurrent: two independent queries whose results are fused, so running
    // them in sequence just adds one's latency to the other's.
    final results = await Future.wait([
      searchFts(repoId, query, checkoutId: checkoutId),
      searchVector(repoId, queryEmbedding, limit: 30, checkoutId: checkoutId),
    ]);
    final ftsResults = results[0];
    final vectorResults = results[1];
    return reciprocalRankFusion(
      [ftsResults, vectorResults],
      k: 60,
      limit: limit,
    );
  }

  // Graph traversal

  String _kindPlaceholders(Set<CodeEdgeKind> kinds) =>
      List.filled(kinds.length, '?').join(', ');

  /// Symbols that [symbolId] points to via [kinds] edges (outgoing).
  Future<List<CodeSymbolsTableData>> getCallees(
    String symbolId, {
    Set<CodeEdgeKind> kinds = const {CodeEdgeKind.calls},
    int? limit,
    String? checkoutId,
  }) {
    final names = kinds.map((k) => k.name).toList();
    return customSelect(
          'SELECT cs.* FROM code_edges e '
          'JOIN code_symbols cs ON cs.id = e.target_symbol_id '
          'WHERE e.source_symbol_id = ? '
          'AND ${_edgePartitionSql(checkoutId)} '
          'AND e.kind IN (${_kindPlaceholders(kinds)})'
          '${limit != null ? ' LIMIT ?' : ''}',
          variables: [
            Variable<String>(symbolId),
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

  /// Symbols that point to [symbolId] via [kinds] edges (incoming).
  Future<List<CodeSymbolsTableData>> getCallers(
    String symbolId, {
    Set<CodeEdgeKind> kinds = const {CodeEdgeKind.calls},
    int? limit,
    String? checkoutId,
  }) {
    final names = kinds.map((k) => k.name).toList();
    return customSelect(
          'SELECT cs.* FROM code_edges e '
          'JOIN code_symbols cs ON cs.id = e.source_symbol_id '
          'WHERE e.target_symbol_id = ? '
          'AND ${_edgePartitionSql(checkoutId)} '
          'AND e.kind IN (${_kindPlaceholders(kinds)})'
          '${limit != null ? ' LIMIT ?' : ''}',
          variables: [
            Variable<String>(symbolId),
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
      '    AND ${_edgePartitionSql(checkoutId)}'
      '    AND e.kind IN (${_kindPlaceholders(edgeKinds)})'
      ') '
      'SELECT cs.*, MIN(impact.d) AS impact_depth '
      'FROM impact JOIN code_symbols cs ON cs.id = impact.id '
      'GROUP BY cs.id',
      variables: [
        Variable<String>(symbolId),
        Variable<int>(clamped),
        if (checkoutId != null) Variable<String>(checkoutId),
        ...names.map(Variable<String>.new),
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

  /// Whether the symbol already has a vector. One without has nothing to reuse
  /// (the model was not ready when it was indexed) and must be embedded on
  /// this pass or left for the backfill.
  final bool hasEmbedding;
}

/// One row of [CodeGraphDao.getSymbolNameIndex] — the projection the
/// reference-resolution pass needs.
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
