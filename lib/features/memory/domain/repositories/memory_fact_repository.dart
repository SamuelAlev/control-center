import 'dart:typed_data';

import 'package:control_center/core/domain/entities/memory_fact.dart';

abstract class MemoryFactRepository {
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId);
  Future<List<MemoryFact>> getByWorkspace(String workspaceId);
  Future<MemoryFact?> getById(String id);
  Future<void> upsert(MemoryFact fact);
  Future<List<MemoryFact>> getActiveByTopic(String workspaceId, String topic);

  /// Search facts. If [queryEmbedding] is provided, uses hybrid BM25+vector
  /// via RRF. Otherwise falls back to FTS5-only.
  Future<List<MemoryFact>> search(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
  });
  Future<List<MemoryFact>> getByAuthor(String workspaceId, String agentId);

  Future<void> delete(String id);
}
