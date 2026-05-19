import 'dart:convert';
import 'dart:typed_data';

import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/database/daos/memory_fact_dao.dart';
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_service.dart';
import 'package:control_center/features/memory/data/mappers/memory_fact_mapper.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for memory facts.
class DaoMemoryFactRepository implements MemoryFactRepository {
  /// Creates a [DaoMemoryFactRepository].
  DaoMemoryFactRepository(
    this._dao, {
    EmbeddingService? embeddingService,
  }) : _embeddingService = embeddingService;

  final MemoryFactDao _dao;
  final EmbeddingService? _embeddingService;
  final MemoryFactMapper _mapper = const MemoryFactMapper();

  @override
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId) =>
      _dao.watchByWorkspace(workspaceId).map(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<List<MemoryFact>> getByWorkspace(String workspaceId) =>
      _dao.getByWorkspace(workspaceId).then(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<MemoryFact?> getById(String workspaceId, String id) => _dao
      .getById(workspaceId, id)
      .then((row) => row != null ? _mapper.toDomain(row) : null);

  @override
  Future<void> upsert(MemoryFact fact) async {
    final embedding = await _computeEmbedding('${fact.topic} ${fact.content}');
    await _dao.upsert(
      db.MemoryFactsTableCompanion(
        id: Value(fact.id),
        workspaceId: Value(fact.workspaceId),
        domain: Value(fact.domain),
        topic: Value(fact.topic),
        content: Value(fact.content),
        sourceObservationIds: Value(jsonEncode(fact.sourceObservationIds)),
        confidence: Value(fact.confidence),
        supersededBy: Value.absentIfNull(fact.supersededBy),
        authoredByAgentId: Value.absentIfNull(fact.authoredByAgentId),
        authoredByRole: Value(fact.authoredByRole?.name),
        embedding: embedding != null ? Value(embedding) : const Value.absent(),
        createdAt: Value(fact.createdAt),
        updatedAt: Value(fact.updatedAt),
      ),
    );
  }

  @override
  Future<List<MemoryFact>> getActiveByTopic(String workspaceId, String topic) =>
      _dao.getActiveByTopic(workspaceId, topic).then(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<List<MemoryFact>> search(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
  }) async {
    if (queryEmbedding != null) {
      final rows = await _dao.searchHybrid(workspaceId, query, queryEmbedding);
      return rows.map(_mapper.toDomain).toList();
    }
    return _dao.searchFts(workspaceId, query).then(
      (rows) => rows.map(_mapper.toDomain).toList(),
    );
  }

  @override
  Future<List<MemoryFact>> getByAuthor(String workspaceId, String agentId) =>
      _dao.getByAuthor(workspaceId, agentId).then(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );
  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao.deleteById(workspaceId, id);

  /// Computes an embedding for the given text if the service is available.
  /// Returns null if the service is not ready (model not downloaded).
  Future<Uint8List?> _computeEmbedding(String text) async {
    if (_embeddingService == null || !_embeddingService.isReady) {
      return null;
    }
    try {
      final float32 = await _embeddingService.embed(text);
      return Uint8List.view(float32.buffer);
    } catch (_) {
      return null;
    }
  }
}
