import 'dart:typed_data';

import 'package:control_center/core/domain/entities/memory_fact.dart';

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
  /// Fetches facts authored by a specific agent.
  Future<List<MemoryFact>> getByAuthor(String workspaceId, String agentId);

  /// Deletes a fact by id within [workspaceId] so one workspace can never
  /// delete another's fact.
  Future<void> delete(String workspaceId, String id);
}
