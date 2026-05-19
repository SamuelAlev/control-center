import 'dart:convert';
import 'dart:typed_data';

import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/database/daos/code_graph_dao.dart';
import 'package:control_center/core/infrastructure/code_index/code_graph_ids.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_service.dart';
import 'package:control_center/features/code_graph/data/mappers/code_edge_mapper.dart';
import 'package:control_center/features/code_graph/data/mappers/code_symbol_mapper.dart';
import 'package:control_center/features/code_graph/domain/entities/code_edge.dart';
import 'package:control_center/features/code_graph/domain/entities/code_subgraph.dart';
import 'package:control_center/features/code_graph/domain/entities/code_symbol.dart';
import 'package:control_center/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:drift/drift.dart';

/// [CodeGraphRepository] backed by [CodeGraphDao]. Mirrors
/// `DaoMemoryFactRepository`: embeds on ingest when the model is ready, and
/// chooses hybrid vs FTS-only search based on whether a query embedding is
/// supplied.
class DaoCodeGraphRepository implements CodeGraphRepository {
  /// Creates a [DaoCodeGraphRepository] backed by `dao`.
  DaoCodeGraphRepository(this._dao, {EmbeddingService? embeddingService})
    : _embeddingService = embeddingService;

  final CodeGraphDao _dao;
  final EmbeddingService? _embeddingService;
  final CodeSymbolMapper _symbolMapper = const CodeSymbolMapper();
  final CodeEdgeMapper _edgeMapper = const CodeEdgeMapper();

  @override
  Future<List<CodeSymbol>> search(
    String workspaceId,
    String repoId,
    String query, {
    Float32List? queryEmbedding,
  }) async {
    final rows = queryEmbedding != null
        ? await _dao.searchHybrid(workspaceId, repoId, query, queryEmbedding)
        : await _dao.searchFts(workspaceId, repoId, query);
    return rows.map(_symbolMapper.toDomain).toList();
  }

  @override
  Future<List<CodeSymbol>> callers(
    String workspaceId,
    String symbolId, {
    int? limit,
  }) => _dao
      .getCallers(workspaceId, symbolId, limit: limit)
      .then((rows) => rows.map(_symbolMapper.toDomain).toList());

  @override
  Future<List<CodeSymbol>> callees(
    String workspaceId,
    String symbolId, {
    int? limit,
  }) => _dao
      .getCallees(workspaceId, symbolId, limit: limit)
      .then((rows) => rows.map(_symbolMapper.toDomain).toList());

  @override
  Future<CodeSubgraph> impactRadius(
    String workspaceId,
    String symbolId, {
    int depth = 2,
  }) async {
    final result = await _dao.getImpactRadius(
      workspaceId,
      symbolId,
      depth: depth,
    );
    if (result.nodes.isEmpty) {
      return const CodeSubgraph.empty();
    }
    final nodes = result.nodes.map(_symbolMapper.toDomain).toList();
    final edges = result.edges.map(_edgeMapper.toDomain).toList();
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
  Future<CodeSymbol?> getById(String workspaceId, String id) => _dao
      .getSymbolById(workspaceId, id)
      .then((row) => row == null ? null : _symbolMapper.toDomain(row));

  @override
  Future<List<CodeSymbol>> getByName(
    String workspaceId,
    String repoId,
    String name, {
    int limit = 20,
  }) => _dao
      .getSymbolsByName(workspaceId, repoId, name, limit: limit)
      .then((rows) => rows.map(_symbolMapper.toDomain).toList());

  @override
  Future<List<CodeSymbol>> symbolsForRepo(String workspaceId, String repoId) =>
      _dao
          .getSymbolsByRepo(workspaceId, repoId)
          .then((rows) => rows.map(_symbolMapper.toDomain).toList());

  @override
  Stream<List<CodeSymbol>> watchByRepo(String workspaceId, String repoId) =>
      _dao
          .watchSymbolsByRepo(workspaceId, repoId)
          .map((rows) => rows.map(_symbolMapper.toDomain).toList());

  @override
  Future<Map<String, String>> fileHashes(
    String workspaceId,
    String repoId,
  ) async {
    final files = await _dao.getFiles(workspaceId, repoId);
    return {for (final f in files) f.path: f.contentHash};
  }

  @override
  Future<void> deleteFiles(
    String workspaceId,
    String repoId,
    List<String> filePaths,
  ) async {
    for (final path in filePaths) {
      await _dao.deleteByFile(workspaceId, repoId, path);
    }
  }

  @override
  Future<int> resolvePendingReferences(
    String workspaceId,
    String repoId,
  ) async {
    final symbols = await _dao.getSymbolsByRepo(workspaceId, repoId);
    final byQualifiedName = <String, String>{};
    final idsByName = <String, List<String>>{};
    for (final s in symbols) {
      byQualifiedName[s.qualifiedName] = s.id;
      (idsByName[s.name] ??= []).add(s.id);
    }

    final unresolved = await _dao.getUnresolvedEdges(workspaceId, repoId);
    var resolved = 0;
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
        await _dao.setEdgeTarget(workspaceId, edge.id, id);
        resolved++;
      }
    }
    return resolved;
  }

  @override
  Future<void> ingestFile({
    required String workspaceId,
    required String repoId,
    required String filePath,
    required String contentHash,
    required List<CodeSymbol> symbols,
    required List<CodeEdge> edges,
    String language = 'dart',
  }) async {
    final now = DateTime.now();

    final symbolRows = <db.CodeSymbolsTableCompanion>[];
    for (final s in symbols) {
      final embedding = await _computeEmbedding(
        '${s.qualifiedName}\n${s.signature}\n${s.docstring ?? ''}',
      );
      symbolRows.add(
        db.CodeSymbolsTableCompanion(
          id: Value(s.id),
          workspaceId: Value(s.workspaceId),
          repoId: Value(s.repoId),
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
          embedding: embedding != null
              ? Value(embedding)
              : const Value.absent(),
          updatedAt: Value(now),
        ),
      );
    }

    final edgeRows = edges
        .map(
          (e) => db.CodeEdgesTableCompanion(
            id: Value(e.id),
            workspaceId: Value(e.workspaceId),
            repoId: Value(e.repoId),
            sourceSymbolId: Value(e.sourceSymbolId),
            sourceFilePath: Value(e.sourceFilePath),
            targetSymbolId: Value.absentIfNull(e.targetSymbolId),
            targetName: Value.absentIfNull(e.targetName),
            kind: Value(e.kind.name),
            metadata: Value.absentIfNull(
              e.metadata == null ? null : jsonEncode(e.metadata),
            ),
          ),
        )
        .toList();

    // Replace the file's prior rows, then write the fresh extraction.
    await _dao.deleteByFile(workspaceId, repoId, filePath);
    if (symbolRows.isNotEmpty) {
      await _dao.upsertSymbols(symbolRows);
    }
    if (edgeRows.isNotEmpty) {
      await _dao.upsertEdges(edgeRows);
    }
    await _dao.upsertFile(
      db.CodeFilesTableCompanion(
        id: Value(codeFileId(workspaceId, repoId, filePath)),
        workspaceId: Value(workspaceId),
        repoId: Value(repoId),
        path: Value(filePath),
        contentHash: Value(contentHash),
        symbolCount: Value(symbols.length),
        language: Value(language),
        indexedAt: Value(now),
      ),
    );
  }

  /// Computes a 384-d embedding when the on-device model is ready; null
  /// otherwise (search then degrades to FTS-only, exactly like memory facts).
  Future<Uint8List?> _computeEmbedding(String text) async {
    final service = _embeddingService;
    if (service == null || !service.isReady) {
      return null;
    }
    try {
      final float32 = await service.embed(text);
      return Uint8List.view(float32.buffer);
    } catch (_) {
      return null;
    }
  }
}
