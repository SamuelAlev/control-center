import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/services/binary_vectors.dart';
import 'package:cc_domain/features/memory/domain/services/polyphonic_recall.dart';
import 'package:cc_domain/features/memory/domain/services/query_intent.dart';
import 'package:cc_persistence/database/app_database.dart' as db;
import 'package:cc_persistence/database/daos/episodic_edge_dao.dart';
import 'package:cc_persistence/database/daos/memory_fact_dao.dart';
import 'package:cc_persistence/mappers/memory_fact_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for memory facts.
class DaoMemoryFactRepository implements MemoryFactRepository {
  /// Creates a [DaoMemoryFactRepository].
  ///
  /// [edgeDao] powers the polyphonic recall's graph voice; when null the graph
  /// voice is simply skipped (the other three voices still fuse).
  DaoMemoryFactRepository(
    this._dao, {
    EmbeddingPort? embeddingService,
    EpisodicEdgeDao? edgeDao,
  })  : _embeddingService = embeddingService,
        _edgeDao = edgeDao;

  final MemoryFactDao _dao;
  final EmbeddingPort? _embeddingService;
  final EpisodicEdgeDao? _edgeDao;
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
  Future<List<MemoryFact>> getActiveByWorkspace(String workspaceId) =>
      _dao.getActiveByWorkspace(workspaceId).then(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<MemoryFact?> getById(String workspaceId, String id) => _dao
      .getById(workspaceId, id)
      .then((row) => row != null ? _mapper.toDomain(row) : null);

  @override
  Future<void> upsert(MemoryFact fact) async {
    final float32 = await _computeFloat32('${fact.topic} ${fact.content}');
    final embedding = float32 != null ? Uint8List.view(float32.buffer) : null;
    final binary =
        float32 != null ? binarizeEmbedding(float32.toList()) : null;
    await _dao.upsert(
      db.MemoryFactsTableCompanion(
        id: Value(fact.id),
        workspaceId: Value(fact.workspaceId),
        domain: Value(fact.domain),
        topic: Value(fact.topic),
        content: Value(fact.content),
        sourceObservationIds: Value(jsonEncode(fact.sourceObservationIds)),
        confidence: Value(fact.confidence),
        supersededBy: Value(fact.supersededBy),
        authoredByAgentId: Value.absentIfNull(fact.authoredByAgentId),
        authoredByRole: Value(fact.authoredByRole?.name),
        memoryType: Value(fact.memoryType.wireName),
        veracity: Value(fact.veracity.wireName),
        validUntil: Value(fact.validUntil),
        recallCount: Value(fact.recallCount),
        lastRecalledAt: Value(fact.lastRecalledAt),
        temporalTags: Value(
          fact.temporalTags.isEmpty ? null : jsonEncode(fact.temporalTags),
        ),
        mentionCount: Value(fact.mentionCount),
        embedding: embedding != null ? Value(embedding) : const Value.absent(),
        binaryEmbedding:
            binary != null ? Value(binary) : const Value.absent(),
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
  Future<List<MemoryFact>> recallPolyphonic(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
    int topK = 10,
    bool markRecalled = true,
  }) async {
    final intent = classifyIntent(query);
    final rowsById = <String, db.MemoryFactsTableData>{};
    final rankedIds = <RecallVoice, List<String>>{};

    void register(RecallVoice voice, List<db.MemoryFactsTableData> rows) {
      rankedIds[voice] = rows.map((r) => r.id).toList();
      for (final r in rows) {
        rowsById.putIfAbsent(r.id, () => r);
      }
    }

    // Fact (lexical) voice.
    register(RecallVoice.fact, await _dao.searchFts(workspaceId, query));

    // Vector (semantic) voice — sqlite_vector, with a Dart Hamming fallback.
    if (queryEmbedding != null) {
      register(
        RecallVoice.vector,
        await _vectorVoice(workspaceId, queryEmbedding),
      );
    }

    // Temporal (recency) voice — the candidate pool of recent active facts.
    register(RecallVoice.temporal, await _dao.recentActive(workspaceId));

    // Graph voice — BFS from the strongest lexical/vector seeds.
    final edgeDao = _edgeDao;
    if (edgeDao != null) {
      final seeds = <String>{
        ...?rankedIds[RecallVoice.fact]?.take(3),
        ...?rankedIds[RecallVoice.vector]?.take(3),
      };
      final graphIds = <String>[];
      for (final seed in seeds) {
        final hops = await edgeDao.findRelated(workspaceId, seed, depth: 2);
        graphIds.addAll(hops.map((h) => h.factId));
      }
      final uniqueGraphIds = <String>[];
      final graphSeen = <String>{};
      for (final id in graphIds) {
        if (graphSeen.add(id)) {
          uniqueGraphIds.add(id);
        }
      }
      // Hydrate any graph-only fact rows not already loaded by another voice.
      final missing =
          uniqueGraphIds.where((id) => !rowsById.containsKey(id)).toList();
      if (missing.isNotEmpty) {
        for (final row in await _dao.getActiveByIds(workspaceId, missing)) {
          rowsById[row.id] = row;
        }
      }
      rankedIds[RecallVoice.graph] =
          uniqueGraphIds.where(rowsById.containsKey).toList();
    }

    final candidates = <String, RecallCandidate<MemoryFact>>{};
    for (final entry in rowsById.entries) {
      final fact = _mapper.toDomain(entry.value);
      candidates[entry.key] = RecallCandidate<MemoryFact>(
        id: fact.id,
        value: fact,
        content: '${fact.topic} ${fact.content}',
        memoryType: fact.memoryType,
        createdAt: fact.createdAt,
        importance: fact.confidence,
      );
    }

    final ranked = fusePolyphonicRecall<MemoryFact>(
      rankedIdsByVoice: rankedIds,
      candidates: candidates,
      intent: intent,
      topK: topK,
    );
    final results = ranked.map((r) => r.value).toList();

    if (markRecalled && results.isNotEmpty) {
      await this.markRecalled(workspaceId, results.map((f) => f.id).toList());
    }
    return results;
  }

  /// Vector voice: sqlite_vector KNN, falling back to in-Dart Hamming over the
  /// packed binary embeddings when the extension is unavailable.
  Future<List<db.MemoryFactsTableData>> _vectorVoice(
    String workspaceId,
    Float32List queryEmbedding,
  ) async {
    try {
      return await _dao.searchVector(workspaceId, queryEmbedding, limit: 30);
    } on Object {
      return _hammingFallback(workspaceId, queryEmbedding, limit: 30);
    }
  }

  Future<List<db.MemoryFactsTableData>> _hammingFallback(
    String workspaceId,
    Float32List queryEmbedding, {
    int limit = 30,
  }) async {
    final queryBinary = binarizeEmbedding(queryEmbedding.toList());
    final dim = queryEmbedding.length;
    final rows = await _dao.getActiveByWorkspace(workspaceId);
    final scored = <({db.MemoryFactsTableData row, double score})>[];
    for (final row in rows) {
      final bin = row.binaryEmbedding;
      if (bin == null) {
        continue;
      }
      final distance = hammingDistance(queryBinary, bin);
      scored.add((row: row, score: hammingScore(distance, dim)));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((e) => e.row).toList();
  }

  @override
  Future<void> markRecalled(String workspaceId, List<String> ids) =>
      _dao.markRecalled(workspaceId, ids, DateTime.now());

  @override
  Future<List<MemoryFact>> getByAuthor(String workspaceId, String agentId) =>
      _dao.getByAuthor(workspaceId, agentId).then(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao.deleteById(workspaceId, id);

  /// Computes a Float32 embedding for [text] if the service is available.
  Future<Float32List?> _computeFloat32(String text) async {
    if (_embeddingService == null || !_embeddingService.isReady) {
      return null;
    }
    try {
      return await _embeddingService.embed(text);
    } catch (_) {
      return null;
    }
  }
}