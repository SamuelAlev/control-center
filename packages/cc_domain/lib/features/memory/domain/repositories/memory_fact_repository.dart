import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';

/// Repository for [MemoryFact] persistence.
abstract class MemoryFactRepository {
  /// Watches all facts in a workspace.
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId);
  /// Fetches all facts in a workspace.
  Future<List<MemoryFact>> getByWorkspace(String workspaceId);

  /// Looks up a fact by id within [workspaceId]. A fact owned by another
  /// workspace is not found — ids are global UUIDs, so the workspace is the
  /// isolation boundary, not id uniqueness.
  Future<MemoryFact?> getById(String workspaceId, String id);
  /// Inserts or updates a fact.
  Future<void> upsert(MemoryFact fact);
  /// Fetches active (not superseded) facts for a topic.
  Future<List<MemoryFact>> getActiveByTopic(String workspaceId, String topic);

  /// Search facts. If [queryEmbedding] is provided, uses hybrid BM25+vector
  /// via RRF. Otherwise falls back to FTS5-only.
  Future<List<MemoryFact>> search(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
  });

  /// Polyphonic 4-voice recall (vector + graph + fact + temporal), fused with
  /// query-intent-aware weighting, Weibull temporal decay, and MMR diversity
  /// reranking. Returns active facts in ranked order, capped at [topK].
  ///
  /// When [markRecalled] is true, the returned facts' recall counters are bumped
  /// (best-effort telemetry).
  Future<List<MemoryFact>> recallPolyphonic(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
    int topK = 10,
    bool markRecalled = true,
  });

  /// Fetches all active (non-superseded) facts in a workspace.
  Future<List<MemoryFact>> getActiveByWorkspace(String workspaceId);

  /// Bumps the recall counters for the given fact ids (scoped to [workspaceId]).
  Future<void> markRecalled(String workspaceId, List<String> ids);

  /// Fetches facts authored by a specific agent.
  Future<List<MemoryFact>> getByAuthor(String workspaceId, String agentId);

  /// Deletes a fact by id within [workspaceId] so one workspace can never
  /// delete another's fact.
  Future<void> delete(String workspaceId, String id);
}
