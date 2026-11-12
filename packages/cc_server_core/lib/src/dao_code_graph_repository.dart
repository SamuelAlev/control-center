import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_file_ingest.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_index_checkpoint.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_subgraph.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_infra/cc_infra.dart' show EmbeddingService;
import 'package:cc_natives/cc_natives.dart';
import 'package:cc_persistence/database/code_index/code_index_database.dart'
    as db;
import 'package:cc_persistence/database/daos/code_graph_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/code_edge_mapper.dart';
import 'package:cc_persistence/mappers/code_symbol_mapper.dart';
import 'package:drift/drift.dart';

/// [CodeGraphRepository] backed by [CodeGraphDao]. Mirrors
/// `DaoMemoryFactRepository`: embeds on ingest when the model is ready and
/// chooses hybrid vs FTS-only search based on whether a query embedding is
/// supplied.
///
/// Holds the [WorkspaceDatabaseManager] rather than a DAO: the code graph lives
/// in each workspace's own code index file (`code_index.db`), so the
/// `workspaceId` every method already carries picks the file before any SQL
/// runs. The rows themselves carry no workspace.
class DaoCodeGraphRepository implements CodeGraphRepository {
  /// Creates a [DaoCodeGraphRepository] over the per-workspace databases.
  DaoCodeGraphRepository(this._dbs, {this._embeddingService});

  final WorkspaceDatabaseManager _dbs;
  final EmbeddingPort? _embeddingService;

  CodeGraphDao _dao(String workspaceId) =>
      _dbs.codeIndexOf(workspaceId).codeGraphDao;

  final CodeSymbolMapper _symbolMapper = const CodeSymbolMapper();
  final CodeEdgeMapper _edgeMapper = const CodeEdgeMapper();

  @override
  Future<List<CodeSymbol>> search(
    String workspaceId,
    String repoId,
    String query, {
    Float32List? queryEmbedding,
    String? checkoutId,
  }) async {
    final rows = queryEmbedding != null
        ? await _dao(
            workspaceId,
          ).searchHybrid(repoId, query, queryEmbedding, checkoutId: checkoutId)
        : await _dao(
            workspaceId,
          ).searchFts(repoId, query, checkoutId: checkoutId);
    return [
      for (final r in rows) _symbolMapper.toDomain(r, workspaceId: workspaceId),
    ];
  }

  @override
  Future<List<CodeSymbol>> callers(
    String workspaceId,
    String symbolId, {
    int? limit,
    String? checkoutId,
    Set<CodeEdgeKind> kinds = const {CodeEdgeKind.calls},
  }) => _dao(workspaceId)
      .getCallers(symbolId, kinds: kinds, limit: limit, checkoutId: checkoutId)
      .then(
        (rows) => [
          for (final r in rows)
            _symbolMapper.toDomain(r, workspaceId: workspaceId),
        ],
      );

  @override
  Future<List<CodeSymbol>> callees(
    String workspaceId,
    String symbolId, {
    int? limit,
    String? checkoutId,
  }) => _dao(workspaceId)
      .getCallees(symbolId, limit: limit, checkoutId: checkoutId)
      .then(
        (rows) => [
          for (final r in rows)
            _symbolMapper.toDomain(r, workspaceId: workspaceId),
        ],
      );

  @override
  Future<CodeSubgraph> impactRadius(
    String workspaceId,
    String symbolId, {
    int depth = 2,
    String? checkoutId,
  }) async {
    final result = await _dao(
      workspaceId,
    ).getImpactRadius(symbolId, depth: depth, checkoutId: checkoutId);
    if (result.nodes.isEmpty) {
      return const CodeSubgraph.empty();
    }
    final nodes = [
      for (final n in result.nodes)
        _symbolMapper.toDomain(n, workspaceId: workspaceId),
    ];
    final edges = [
      for (final e in result.edges)
        _edgeMapper.toDomain(e, workspaceId: workspaceId),
    ];
    final root = nodes.firstWhere(
      (n) => result.depthById[n.id] == 0,
      orElse: () => nodes.first,
    );
    return CodeSubgraph(
      root: root,
      nodes: nodes,
      edges: edges,
      depthById: result.depthById,
    );
  }

  @override
  Future<CodeSymbol?> getById(String workspaceId, String id) =>
      _dao(workspaceId)
          .getSymbolById(id)
          .then(
            (row) => row == null
                ? null
                : _symbolMapper.toDomain(row, workspaceId: workspaceId),
          );

  @override
  Future<List<CodeSymbol>> getByName(
    String workspaceId,
    String repoId,
    String name, {
    int limit = 20,
    String? checkoutId,
  }) => _dao(workspaceId)
      .getSymbolsByName(repoId, name, limit: limit, checkoutId: checkoutId)
      .then(
        (rows) => [
          for (final r in rows)
            _symbolMapper.toDomain(r, workspaceId: workspaceId),
        ],
      );

  @override
  Future<List<CodeSymbol>> symbolsForRepo(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) => _dao(workspaceId)
      .getSymbolsByRepo(repoId, checkoutId: checkoutId)
      .then(
        (rows) => [
          for (final r in rows)
            _symbolMapper.toDomain(r, workspaceId: workspaceId),
        ],
      );

  @override
  Stream<List<CodeSymbol>> watchByRepo(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) => _dao(workspaceId)
      .watchSymbolsByRepo(repoId, checkoutId: checkoutId)
      .map(
        (rows) => [
          for (final r in rows)
            _symbolMapper.toDomain(r, workspaceId: workspaceId),
        ],
      );

  @override
  Future<Map<String, String>> fileHashes(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async {
    final files = await _dao(
      workspaceId,
    ).getFiles(repoId, checkoutId: checkoutId);
    return {for (final f in files) f.path: f.contentHash};
  }

  @override
  Future<Map<String, ({String contentHash, DateTime indexedAt})>> fileStates(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async {
    final files = await _dao(
      workspaceId,
    ).getFiles(repoId, checkoutId: checkoutId);
    return {
      for (final f in files)
        f.path: (contentHash: f.contentHash, indexedAt: f.indexedAt),
    };
  }

  @override
  Future<Map<String, String>> fileHashesFor(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) async {
    final files = await _dao(
      workspaceId,
    ).getFilesByPaths(repoId, filePaths, checkoutId: checkoutId);
    return {for (final f in files) f.path: f.contentHash};
  }

  @override
  Future<Map<String, ({String contentHash, DateTime indexedAt})>> fileStatesFor(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) async {
    final files = await _dao(
      workspaceId,
    ).getFilesByPaths(repoId, filePaths, checkoutId: checkoutId);
    return {
      for (final f in files)
        f.path: (contentHash: f.contentHash, indexedAt: f.indexedAt),
    };
  }

  @override
  Future<bool> hasIndexedFiles(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) => _dao(workspaceId).hasFiles(repoId, checkoutId: checkoutId);

  @override
  Future<void> deleteFiles(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) =>
      // One transaction with `IN (...)` deletes, not one transaction per path
      // — pruning a big directory used to fsync once per removed file.
      _dao(
        workspaceId,
      ).deleteFilesBatch(repoId, filePaths, checkoutId: checkoutId);

  @override
  Future<int> countUnresolvedEdges(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) => _dao(workspaceId).countUnresolvedEdges(repoId, checkoutId: checkoutId);

  @override
  Future<int> pruneUnresolvedEdges(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) => _dao(workspaceId).deleteUnresolvedEdges(repoId, checkoutId: checkoutId);

  @override
  Future<int> resolvePendingReferences(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async {
    // Cheap probe first (O(unresolved) via the partial index): the common
    // steady-state run has nothing pending and used to pay a full read of
    // every symbol row to find that out.
    final pending = await _dao(
      workspaceId,
    ).countUnresolvedEdges(repoId, checkoutId: checkoutId);
    if (pending == 0) {
      return 0;
    }
    final unresolved = await _dao(
      workspaceId,
    ).getUnresolvedEdges(repoId, checkoutId: checkoutId);
    final names = <String>{
      for (final edge in unresolved)
        if (edge.targetName != null) edge.targetName!,
    };
    // Targeted projection read: only symbols carrying the needed names and
    // only the columns resolution uses. Because the query matches by name,
    // it still returns EVERY symbol with a wanted simple name, so the
    // "unique simple name" ambiguity rule below is exactly as strict as the
    // old load-everything pass.
    final candidates = _preferCheckoutNameRows(
      await _dao(
        workspaceId,
      ).getSymbolNameIndex(repoId, names, checkoutId: checkoutId),
      checkoutId,
    );
    final byQualifiedName = <String, String>{};
    final idsByName = <String, List<String>>{};
    for (final s in candidates) {
      byQualifiedName[s.qualifiedName] = s.id;
      (idsByName[s.name] ??= []).add(s.id);
    }

    final updates = <String, String>{};
    for (final edge in unresolved) {
      final target = edge.targetName;
      if (target == null) {
        continue;
      }
      // Prefer an exact qualified-name match; fall back to a unique simple
      // name. Ambiguous names are left unresolved.
      final byName = idsByName[target];
      final id =
          byQualifiedName[target] ??
          (byName != null && byName.length == 1 ? byName.first : null);
      if (id != null && id != edge.sourceSymbolId) {
        updates[edge.id] = id;
      }
    }
    await _dao(workspaceId).setEdgeTargets(updates);
    return updates.length;
  }

  /// [CodeGraphDao.preferCheckout] for the projected name rows: when a path
  /// appears in both the base and the worktree partition, the worktree's rows
  /// win outright and the base's copies drop.
  static List<CodeSymbolNameRow> _preferCheckoutNameRows(
    List<CodeSymbolNameRow> rows,
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

  @override
  Future<void> ingestFile({
    required String workspaceId,
    required String repoId,
    String? checkoutId,
    required String filePath,
    required String contentHash,
    required List<CodeSymbol> symbols,
    required List<CodeEdge> edges,
    String language = 'dart',
  }) => ingestFiles([
    CodeFileIngest(
      workspaceId: workspaceId,
      repoId: repoId,
      checkoutId: checkoutId,
      filePath: filePath,
      contentHash: contentHash,
      symbols: symbols,
      edges: edges,
      language: language,
    ),
  ]);

  @override
  Future<void> ingestFiles(List<CodeFileIngest> files) async {
    if (files.isEmpty) {
      return;
    }
    final now = DateTime.now();

    // What each partition already holds for the paths in this batch. Read first
    // (a projection, no vectors) because it answers both of the
    // questions the rest of the method asks: which symbols still deserve the
    // vector they have and which stored symbols this extraction dropped.
    final stored = await _storedSymbols(files);

    // Embed text of every stored symbol that actually carries a vector — the
    // only rows with something to reuse.
    final reusable = <String, String>{};
    for (final rows in stored.values) {
      for (final row in rows) {
        if (row.hasEmbedding) {
          reusable[row.id] = _embedTextOf(
            qualifiedName: row.qualifiedName,
            signature: row.signature,
            docstring: row.docstring,
          );
        }
      }
    }

    // Embed only the symbols whose text CHANGED and do it outside any
    // transaction. Inference is on the embedding worker isolate, so this no
    // longer starves the event loop; keeping it outside the transaction matters
    // regardless — the server has ONE shared database connection and a write
    // transaction held open across model inference would queue every RPC read
    // behind it.
    //
    // Re-embedding everything was the single dominant cost of an incremental
    // re-index and it scaled with the SIZE of the changed files rather than
    // with the change: `flutter gen-l10n` rewrites eight generated
    // `app_localizations*.dart` files holding ~30k symbols between them (39% of
    // this repo's whole graph) and at ~1.7ms of inference per symbol that
    // turned a handful of edited ARB keys into a measured 52s run. Keyed on the
    // deterministic symbol id — which is line-independent — an unchanged getter
    // in a rewritten file keeps the vector it already has.
    final pending = <String>[];
    final pendingIndexById = <String, int>{};
    for (final file in files) {
      for (final s in file.symbols) {
        final text = _embedTextOf(
          qualifiedName: s.qualifiedName,
          signature: s.signature,
          docstring: s.docstring,
        );
        if (reusable[s.id] == text) {
          continue;
        }
        pendingIndexById[s.id] = pending.length;
        pending.add(text);
      }
    }
    final embeddings = await _computeEmbeddings(pending);

    // Symbols each partition still holds for these paths that the fresh
    // extraction no longer defines. They are deleted by id rather than by wiping
    // the file's rows, which is what leaves the surviving vectors in place.
    final staleIds = <String, List<String>>{};
    for (final file in files) {
      final key = _partitionFileKey(file);
      final fresh = {for (final s in file.symbols) s.id};
      final gone = [
        for (final row in stored[key] ?? const <CodeSymbolEmbedRow>[])
          if (!fresh.contains(row.id)) row.id,
      ];
      if (gone.isNotEmpty) {
        staleIds[key] = gone;
      }
    }

    // Vectors to write and vectors that no longer fit, per file. A symbol
    // whose text matched its stored vector is in neither: its vector row is
    // left as it is. A changed symbol with no fresh vector (model not ready)
    // loses the stale one and waits for the backfill.
    final perFileVectors = <Map<String, Uint8List>>[];
    final perFileStaleVectors = <List<String>>[];
    final perFileSymbolRows = <List<db.CodeSymbolsTableCompanion>>[];
    final perFileEdgeRows = <List<db.CodeEdgesTableCompanion>>[];
    for (final file in files) {
      final vectors = <String, Uint8List>{};
      final staleVectors = <String>[];
      final symbolRows = <db.CodeSymbolsTableCompanion>[];
      for (final s in file.symbols) {
        final pendingIndex = pendingIndexById[s.id];
        if (pendingIndex != null) {
          final vector = embeddings?[pendingIndex];
          if (vector != null) {
            vectors[s.id] = vector;
          } else if (reusable.containsKey(s.id)) {
            staleVectors.add(s.id);
          }
        }
        symbolRows.add(
          db.CodeSymbolsTableCompanion(
            id: Value(s.id),
            repoId: Value(s.repoId),
            checkoutId: Value(s.checkoutId),
            kind: Value(s.kind.name),
            name: Value(s.name),
            qualifiedName: Value(s.qualifiedName),
            filePath: Value(s.filePath),
            language: Value(s.language),
            startLine: Value(s.startLine),
            endLine: Value(s.endLine),
            signature: Value(s.signature),
            docstring: Value.absentIfNull(s.docstring),
            parentName: Value.absentIfNull(s.parentName),
            updatedAt: Value(now),
          ),
        );
      }
      perFileVectors.add(vectors);
      perFileStaleVectors.add(staleVectors);
      perFileSymbolRows.add(symbolRows);
      perFileEdgeRows.add([
        for (final e in file.edges)
          db.CodeEdgesTableCompanion(
            id: Value(e.id),
            repoId: Value(e.repoId),
            checkoutId: Value(e.checkoutId),
            sourceSymbolId: Value(e.sourceSymbolId),
            sourceFilePath: Value(e.sourceFilePath),
            targetSymbolId: Value.absentIfNull(e.targetSymbolId),
            targetName: Value.absentIfNull(e.targetName),
            kind: Value(e.kind.name),
            metadata: Value.absentIfNull(
              e.metadata == null ? null : jsonEncode(e.metadata),
            ),
          ),
      ]);
    }

    // ONE transaction per workspace touched by the batch: replace each file's
    // prior rows, then write the fresh extraction. The former shape — four
    // auto-committed statements per file — cost a WAL commit per statement; a
    // 5000-file repo was ~20k serialized round trips through the connection.
    //
    // A batch is grouped by workspace because each workspace is a separate
    // database file: a transaction cannot span two of them and a single ingest
    // must not silently write one workspace's symbols into another's file.
    final indicesByWorkspace = <String, List<int>>{};
    for (var i = 0; i < files.length; i++) {
      (indicesByWorkspace[files[i].workspaceId] ??= []).add(i);
    }

    for (final entry in indicesByWorkspace.entries) {
      final dao = _dao(entry.key);
      await dao.transaction(() async {
        for (final i in entry.value) {
          final file = files[i];
          // Edges are replaced wholesale; symbols are NOT, or the vectors the
          // batch just decided to keep would be deleted out from under it. Only
          // the symbols this extraction dropped are removed, by id.
          await dao.deleteFileEdgeRows(
            file.repoId,
            file.filePath,
            checkoutId: file.checkoutId,
          );
          await dao.deleteSymbolsByIds(
            staleIds[_partitionFileKey(file)] ?? const [],
          );
          if (perFileSymbolRows[i].isNotEmpty) {
            await dao.upsertSymbols(perFileSymbolRows[i]);
          }
          // After the symbols: a vector row needs its symbol to exist.
          await dao.deleteEmbeddings(perFileStaleVectors[i]);
          await dao.putEmbeddings(perFileVectors[i]);
          if (perFileEdgeRows[i].isNotEmpty) {
            await dao.upsertEdges(perFileEdgeRows[i]);
          }
          await dao.upsertFile(
            db.CodeFilesTableCompanion(
              id: Value(
                codeFileId(
                  file.workspaceId,
                  file.repoId,
                  file.filePath,
                  checkoutId: file.checkoutId,
                ),
              ),
              repoId: Value(file.repoId),
              checkoutId: Value(file.checkoutId),
              path: Value(file.filePath),
              contentHash: Value(file.contentHash),
              symbolCount: Value(file.symbols.length),
              language: Value(file.language),
              indexedAt: Value(now),
            ),
          );
        }
      });
    }
  }

  @override
  Future<CodeIndexCheckpointView> readCheckpoint(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).getCheckpointRows(repoId, checkoutId: checkoutId);
    CodeIndexCheckpoint? own;
    var baseGeneration = 0;
    for (final row in rows) {
      if (row.checkoutId == checkoutId) {
        own = CodeIndexCheckpoint(
          workspaceId: workspaceId,
          repoId: row.repoId,
          checkoutId: row.checkoutId,
          headSha: row.headSha,
          worktreeDigest: row.worktreeDigest,
          indexerFingerprint: row.indexerFingerprint,
          generation: row.generation,
          baseGeneration: row.baseGeneration,
          indexedAt: row.indexedAt,
        );
      }
      if (row.checkoutId == null) {
        baseGeneration = row.generation;
      }
    }
    return CodeIndexCheckpointView(own: own, baseGeneration: baseGeneration);
  }

  @override
  Future<void> writeCheckpoint(CodeIndexCheckpoint checkpoint) =>
      _dao(checkpoint.workspaceId).upsertCheckpoint(
        db.CodeIndexCheckpointsTableCompanion(
          id: Value(
            codeIndexCheckpointId(
              checkpoint.workspaceId,
              checkpoint.repoId,
              checkoutId: checkpoint.checkoutId,
            ),
          ),
          repoId: Value(checkpoint.repoId),
          checkoutId: Value(checkpoint.checkoutId),
          headSha: Value(checkpoint.headSha),
          worktreeDigest: Value(checkpoint.worktreeDigest),
          indexerFingerprint: Value(checkpoint.indexerFingerprint),
          generation: Value(checkpoint.generation),
          baseGeneration: Value(checkpoint.baseGeneration),
          indexedAt: Value(checkpoint.indexedAt),
        ),
      );

  /// Embeds the symbols of [workspaceId]'s code index that have no vector yet
  /// (indexed while the model was missing), [batchSize] per round, until
  /// none is left. Returns how many vectors were stored.
  ///
  /// Zero when the model is not installed. Each round writes only side rows,
  /// so the symbol rows and their full-text index are not touched; a symbol
  /// that a re-index changed or removed while its batch was being embedded is
  /// skipped (changed ones come back in a later round).
  Future<int> backfillEmbeddings(
    String workspaceId, {
    int batchSize = 64,
  }) async {
    final dao = _dao(workspaceId);
    var stored = 0;
    while (true) {
      final pending = await dao.getSymbolsWithoutEmbedding(limit: batchSize);
      if (pending.isEmpty) {
        return stored;
      }
      final vectors = await _computeEmbeddings([
        for (final row in pending)
          _embedTextOf(
            qualifiedName: row.qualifiedName,
            signature: row.signature,
            docstring: row.docstring,
          ),
      ]);
      if (vectors == null) {
        return stored;
      }
      final written = await dao.putBackfilledEmbeddings([
        for (final (i, row) in pending.indexed)
          (symbol: row, embedding: vectors[i]),
      ]);
      stored += written;
      if (written == 0) {
        // Every symbol of the batch changed or went away under it (an ingest
        // is rewriting these files). Stop rather than spin; the next run
        // picks the rest up.
        return stored;
      }
    }
  }

  /// Computes 384-d embeddings for [texts] in one batch when the on-device
  /// model is ready; null otherwise (search then degrades to FTS-only, exactly
  /// like memory facts).
  ///
  /// The null return covers only the ENVIRONMENT case — no embedding service
  /// wired, or the model has not been downloaded yet ([EmbeddingService.isReady]).
  /// A failure *after* the service reports ready (worker crash, corrupt model,
  /// an inference native that cannot load) deliberately propagates rather than
  /// degrading: swallowing it would drop the index into a silent, permanent
  /// FTS-only mode — exactly the invisible degradation a broken native install
  /// produces.
  Future<List<Uint8List>?> _computeEmbeddings(List<String> texts) async {
    final service = _embeddingService;
    if (service == null || !service.isReady || texts.isEmpty) {
      return null;
    }
    final vectors = await service.embedAll(texts);
    return [for (final v in vectors) Uint8List.view(v.buffer)];
  }

  /// The text a symbol is embedded FROM.
  ///
  /// The ONE definition, called with a fresh symbol's fields and with a stored
  /// row's, because comparing the two is what decides whether inference runs. If
  /// this ever disagrees with itself the reuse check silently inverts: either
  /// nothing is ever reused, or a changed symbol keeps a stale vector.
  String _embedTextOf({
    required String qualifiedName,
    required String signature,
    String? docstring,
  }) => '$qualifiedName\n$signature\n${docstring ?? ''}';

  /// Reads the already-stored symbols for every path in [files], grouped by
  /// [_partitionFileKey].
  ///
  /// One query per (workspace, repo, checkout) partition rather than per file:
  /// an ingest batch is 32 files of the same partition and this runs on the
  /// hot re-index path.
  Future<Map<String, List<CodeSymbolEmbedRow>>> _storedSymbols(
    List<CodeFileIngest> files,
  ) async {
    final pathsByPartition = <String, List<String>>{};
    final partitions = <String, CodeFileIngest>{};
    for (final file in files) {
      final key = _partitionKey(file);
      partitions[key] = file;
      (pathsByPartition[key] ??= []).add(file.filePath);
    }

    final out = <String, List<CodeSymbolEmbedRow>>{};
    for (final entry in pathsByPartition.entries) {
      final sample = partitions[entry.key]!;
      final rows = await _dao(sample.workspaceId).getSymbolEmbedInputs(
        sample.repoId,
        entry.value,
        checkoutId: sample.checkoutId,
      );
      for (final row in rows) {
        (out['${entry.key}\u0000${row.filePath}'] ??= []).add(row);
      }
    }
    return out;
  }

  String _partitionKey(CodeFileIngest file) =>
      '${file.workspaceId}\u0000${file.repoId}\u0000${file.checkoutId ?? ''}';

  String _partitionFileKey(CodeFileIngest file) =>
      '${_partitionKey(file)}\u0000${file.filePath}';
}
