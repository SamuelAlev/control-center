import 'dart:typed_data';

import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_file_ingest.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_index_checkpoint.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_subgraph.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';

/// Repository over the code graph (symbols + edges) for a repository's source.
///
/// Every operation is scoped by `workspaceId` (required): workspaces are
/// isolated worktrees that can share the same `repoId` on different branches,
/// so the graph is partitioned per workspace to prevent one workspace's code
/// from leaking into another's queries.
///
/// Within a `(workspaceId, repoId)` pair the graph is further partitioned per
/// CHECKOUT: `checkoutId` is null for the workspace's linked checkout (what
/// `index_code` walks) and an `isolated_repos` row id for a conversation/PR
/// worktree. A worktree checked out at a PR head differs from the linked
/// checkout, so it gets its own partition; searching a conversation resolves
/// its worktree's partition instead of serving the linked checkout's stale
/// symbols. Deleting the `isolated_repos` row FK-cascades the partition away.
///
/// Search mirrors the memory fact repository: hybrid BM25 + vector (RRF) when
/// a query embedding is supplied, FTS-only otherwise.
abstract class CodeGraphRepository {
  /// Ranked symbol search scoped to [workspaceId] + [repoId] + the
  /// [checkoutId] partition (null = linked checkout). Order is the relevance
  /// ranking.
  Future<List<CodeSymbol>> search(
    String workspaceId,
    String repoId,
    String query, {
    Float32List? queryEmbedding,
    String? checkoutId,
  });

  /// Symbols that call/depend on [symbolId] (incoming edges), within
  /// [workspaceId] and as seen from the [checkoutId] partition. Capped to
  /// [limit] rows when provided.
  ///
  /// [checkoutId] is REQUIRED for isolation, not just relevance. Ids alone used
  /// to be enough — every partition held a full copy of the repo, so edges never
  /// pointed outside their own partition. Now a worktree stores only its delta
  /// and its edges resolve into the BASE partition, so base symbol ids appear as
  /// targets of many worktrees' edges. Traversing unscoped would return callers
  /// living in other conversations' worktrees. Passing the reader's checkout
  /// restricts traversal to base edges plus that conversation's own.
  Future<List<CodeSymbol>> callers(
    String workspaceId,
    String symbolId, {
    int? limit,
    String? checkoutId,
  });

  /// Symbols that [symbolId] calls/depends on (outgoing edges), within
  /// [workspaceId]. Capped to [limit] rows when provided.
  Future<List<CodeSymbol>> callees(
    String workspaceId,
    String symbolId, {
    int? limit,
    String? checkoutId,
  });

  /// Transitive reverse-dependency closure of [symbolId] within [workspaceId]
  /// as seen from the [checkoutId] partition, up to [depth] hops. Same
  /// isolation requirement as [callers].
  Future<CodeSubgraph> impactRadius(
    String workspaceId,
    String symbolId, {
    int depth = 2,
    String? checkoutId,
  });

  /// The symbol [id] within [workspaceId], or null.
  Future<CodeSymbol?> getById(String workspaceId, String id);

  /// Symbols matching [name] within [workspaceId] and [repoId], up to [limit].
  /// Scoped to the [checkoutId] partition (null = linked checkout).
  Future<List<CodeSymbol>> getByName(
    String workspaceId,
    String repoId,
    String name, {
    int limit,
    String? checkoutId,
  });

  /// All symbols indexed for [repoId] in [workspaceId] within the [checkoutId]
  /// partition (null = linked checkout; used to build code-fact summaries).
  Future<List<CodeSymbol>> symbolsForRepo(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  });

  /// Stream of all symbols for [repoId] in [workspaceId] within the
  /// [checkoutId] partition (null = linked checkout), updated on changes.
  Stream<List<CodeSymbol>> watchByRepo(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  });

  /// Path → content hash for every indexed file of [repoId] in [workspaceId]
  /// within the [checkoutId] partition (incremental skip).
  Future<Map<String, String>> fileHashes(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  });

  /// Per-file `(contentHash, indexedAt)` for the [checkoutId] partition.
  ///
  /// Feeds the walker's mtime fast-path: a file whose mtime is not newer than
  /// its `indexedAt` cannot have changed, so it is never re-read or re-hashed.
  /// Without it an unchanged checkout still costs a full read + SHA-256 of
  /// every source file on every single index run.
  Future<Map<String, ({String contentHash, DateTime indexedAt})>> fileStates(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  });

  /// Whether the [checkoutId] partition holds any indexed file at all.
  ///
  /// The cheap existence probe every code-graph read runs to decide whether a
  /// worktree partition has been built yet. Deliberately not [fileHashes]: that
  /// loads every row of the partition (thousands, on a real repo) and builds a
  /// map, which is a lot of work to answer "is this empty".
  Future<bool> hasIndexedFiles(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  });

  /// Removes the given files' symbols and edges from the [checkoutId]
  /// partition (null = linked checkout).
  Future<void> deleteFiles(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  });

  /// Binds cross-file edges (calls/extends/implements) whose target was only a
  /// name to the actual symbol id, now that the whole checkout is indexed.
  /// Scoped to the [checkoutId] partition (null = linked checkout). Returns
  /// the number of edges resolved.
  Future<int> resolvePendingReferences(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  });

  /// Ingests one parsed file: computes embeddings (when the model is ready),
  /// replaces the file's prior symbols/edges in the [checkoutId] partition
  /// (null = linked checkout) and records its content hash.
  Future<void> ingestFile({
    required String workspaceId,
    required String repoId,
    String? checkoutId,
    required String filePath,
    required String contentHash,
    required List<CodeSymbol> symbols,
    required List<CodeEdge> edges,
    String language,
  });

  /// Ingests a BATCH of parsed files: embeds every symbol in the batch first
  /// (one embedding round-trip, outside any transaction), then replaces all
  /// the files' prior symbols/edges/file rows in ONE transaction. The batch
  /// path for [ingestFile], which delegates here with a single element.
  Future<void> ingestFiles(List<CodeFileIngest> files);

  /// Number of edges still awaiting name resolution in the [checkoutId]
  /// partition (null = linked checkout). The cheap probe that lets
  /// [resolvePendingReferences] be skipped when nothing is pending.
  Future<int> countUnresolvedEdges(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  });

  /// Reads the [checkoutId] partition's index checkpoint together with the
  /// base partition's current generation (one query).
  Future<CodeIndexCheckpointView> readCheckpoint(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  });

  /// Records (or updates) a partition's index checkpoint after a successful
  /// run.
  Future<void> writeCheckpoint(CodeIndexCheckpoint checkpoint);
}
