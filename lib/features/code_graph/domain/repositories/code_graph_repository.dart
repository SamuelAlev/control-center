import 'dart:typed_data';

import 'package:control_center/features/code_graph/domain/entities/code_edge.dart';
import 'package:control_center/features/code_graph/domain/entities/code_subgraph.dart';
import 'package:control_center/features/code_graph/domain/entities/code_symbol.dart';

/// Repository over the code graph (symbols + edges) for a repository's source.
///
/// Every operation is scoped by `workspaceId` (required): workspaces are
/// isolated worktrees that can share the same `repoId` on different branches,
/// so the graph is partitioned per workspace to prevent one workspace's code
/// from leaking into another's queries.
///
/// Search mirrors the memory fact repository: hybrid BM25 + vector (RRF) when
/// a query embedding is supplied, FTS-only otherwise.
abstract class CodeGraphRepository {
  /// Ranked symbol search scoped to [workspaceId] + [repoId]. Order is the
  /// relevance ranking.
  Future<List<CodeSymbol>> search(
    String workspaceId,
    String repoId,
    String query, {
    Float32List? queryEmbedding,
  });

  /// Symbols that call/depend on [symbolId] (incoming edges), within
  /// [workspaceId]. Capped to [limit] rows when provided.
  Future<List<CodeSymbol>> callers(
    String workspaceId,
    String symbolId, {
    int? limit,
  });

  /// Symbols that [symbolId] calls/depends on (outgoing edges), within
  /// [workspaceId]. Capped to [limit] rows when provided.
  Future<List<CodeSymbol>> callees(
    String workspaceId,
    String symbolId, {
    int? limit,
  });

  /// Transitive reverse-dependency closure of [symbolId] within [workspaceId],
  /// up to [depth] hops.
  Future<CodeSubgraph> impactRadius(
    String workspaceId,
    String symbolId, {
    int depth = 2,
  });

  /// The symbol [id] within [workspaceId], or null.
  Future<CodeSymbol?> getById(String workspaceId, String id);

  /// Symbols matching [name] within [workspaceId] and [repoId], up to [limit].
  Future<List<CodeSymbol>> getByName(
    String workspaceId,
    String repoId,
    String name, {
    int limit,
  });

  /// All symbols indexed for [repoId] in [workspaceId] (used to build code-fact
  /// summaries).
  Future<List<CodeSymbol>> symbolsForRepo(String workspaceId, String repoId);

  /// Stream of all symbols for [repoId] in [workspaceId], updated on changes.
  Stream<List<CodeSymbol>> watchByRepo(String workspaceId, String repoId);

  /// Path → content hash for every indexed file of [repoId] in [workspaceId]
  /// (incremental skip).
  Future<Map<String, String>> fileHashes(String workspaceId, String repoId);

  /// Removes the given files' symbols and edges from the index.
  Future<void> deleteFiles(
    String workspaceId,
    String repoId,
    List<String> filePaths,
  );

  /// Binds cross-file edges (calls/extends/implements) whose target was only a
  /// name to the actual symbol id, now that the whole repo is indexed. Returns
  /// the number of edges resolved.
  Future<int> resolvePendingReferences(String workspaceId, String repoId);

  /// Ingests one parsed file: computes embeddings (when the model is ready),
  /// replaces the file's prior symbols/edges, and records its content hash.
  Future<void> ingestFile({
    required String workspaceId,
    required String repoId,
    required String filePath,
    required String contentHash,
    required List<CodeSymbol> symbols,
    required List<CodeEdge> edges,
    String language,
  });
}
