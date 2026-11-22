import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/services/polyphonic_recall.dart';
import 'package:cc_domain/features/memory/domain/services/query_intent.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:cc_persistence/database/daos/episodic_edge_dao.dart';
import 'package:cc_persistence/database/daos/memory_fact_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    as db;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/memory_fact_mapper.dart';
import 'package:cc_persistence/repositories/distinct_rows.dart';
import 'package:cc_persistence/search/rrf.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for memory facts.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).memoryFactDao` per call: facts live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs. The polyphonic recall's graph voice reads the episodic edges from
/// that same file, so a recall never spans workspaces.
class DaoMemoryFactRepository implements MemoryFactRepository {
  /// Creates a [DaoMemoryFactRepository] over the per-workspace databases.
  ///
  /// [_embeddingService] is optional: with none wired (or its model not yet
  /// installed) facts are stored without a vector and search degrades to the
  /// lexical voice.
  DaoMemoryFactRepository(this._dbs, {this._embeddingService});

  final WorkspaceDatabaseManager _dbs;
  final EmbeddingPort? _embeddingService;
  final MemoryFactMapper _mapper = const MemoryFactMapper();

  MemoryFactDao _dao(String workspaceId) => _dbs.of(workspaceId).memoryFactDao;

  EpisodicEdgeDao _edgeDao(String workspaceId) =>
      _dbs.of(workspaceId).episodicEdgeDao;

  @override
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId) =>
      // Deduped: any fact upsert re-runs this and re-ships the whole set.
      distinctRows(
        _dao(workspaceId).watchByWorkspace(workspaceId),
      ).map((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<List<MemoryFact>> getByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .getByWorkspace(workspaceId)
          .then((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<List<MemoryFact>> getActiveByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .getActiveByWorkspace(workspaceId)
          .then((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<MemoryFact?> getById(String workspaceId, String id) =>
      _dao(workspaceId)
          .getById(workspaceId, id)
          .then((row) => row != null ? _mapper.toDomain(row) : null);

  @override
  Future<void> upsert(MemoryFact fact) async {
    // Embedded outside the transaction: inference must not hold the writer.
    final float32 = await _computeFloat32(
      _embedTextOf(fact.topic, fact.content),
    );
    final dao = _dao(fact.workspaceId);
    await dao.transaction(() async {
      if (float32 == null) {
        // Before the fact row changes, while it still holds the text any
        // stored vector was computed from.
        await dao.dropEmbeddingUnlessText(
          fact.id,
          topic: fact.topic,
          content: fact.content,
        );
      }
      await dao.upsert(_companionOf(fact));
      if (float32 != null) {
        await dao.putEmbedding(fact.id, Uint8List.view(float32.buffer));
      }
    });
  }

  /// Stores [fact] without computing a vector, for a write that runs inside
  /// a caller's transaction (inference must not hold the writer): a stored
  /// vector of other text is dropped, and the backfill embeds it later.
  Future<void> writeUnembedded(MemoryFact fact) async {
    final dao = _dao(fact.workspaceId);
    await dao.dropEmbeddingUnlessText(
      fact.id,
      topic: fact.topic,
      content: fact.content,
    );
    await dao.upsert(_companionOf(fact));
  }

  db.MemoryFactsTableCompanion _companionOf(MemoryFact fact) =>
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
        createdAt: Value(fact.createdAt),
        updatedAt: Value(fact.updatedAt),
      );

  /// Embeds the active facts of [workspaceId] that have no vector yet, up to
  /// [batchSize] per round, until none is left. Returns how many vectors were
  /// stored.
  ///
  /// Zero when the model is not installed: there is nothing to embed with,
  /// and search stays keyword-only for those facts until it is. Each round
  /// writes only side rows; a fact that changed or went away while its batch
  /// was being embedded is skipped and comes back in a later round (changed)
  /// or never (deleted).
  Future<int> backfillEmbeddings(
    String workspaceId, {
    int batchSize = 64,
  }) async {
    final service = _embeddingService;
    if (service == null || !service.isReady) {
      return 0;
    }
    final dao = _dao(workspaceId);
    var stored = 0;
    while (true) {
      final pending = await dao.getActiveWithoutEmbedding(
        workspaceId,
        limit: batchSize,
      );
      if (pending.isEmpty) {
        return stored;
      }
      final vectors = await service.embedAll([
        for (final row in pending) _embedTextOf(row.topic, row.content),
      ]);
      final written = await dao.putBackfilledEmbeddings([
        for (final (i, row) in pending.indexed)
          (
            factId: row.id,
            topic: row.topic,
            content: row.content,
            embedding: Uint8List.view(vectors[i].buffer),
          ),
      ]);
      stored += written;
      if (written == 0) {
        // Every fact of the batch changed or went away under it. Stop rather
        // than spin on a list another writer keeps rewriting; the next run
        // picks the rest up.
        return stored;
      }
    }
  }

  /// Embeds fact [factId] of [workspaceId] now, when it is active and has
  /// no vector yet: the follow-up of a [writeUnembedded] once its
  /// transaction committed. The vector is stored only while the fact still
  /// says what was embedded. Returns whether one was stored (false, too,
  /// when the model is not installed: the backfill embeds it later).
  Future<bool> embedIfMissing(String workspaceId, String factId) async {
    final service = _embeddingService;
    if (service == null || !service.isReady) {
      return false;
    }
    final dao = _dao(workspaceId);
    final row = await dao.getById(workspaceId, factId);
    if (row == null || row.supersededBy != null) {
      return false;
    }
    final vector = await service.embed(_embedTextOf(row.topic, row.content));
    return await dao.putBackfilledEmbeddings([
          (
            factId: row.id,
            topic: row.topic,
            content: row.content,
            embedding: Uint8List.view(vector.buffer),
          ),
        ]) ==
        1;
  }

  /// The text a fact is embedded from: the one definition, used on write and
  /// by the backfill so both produce the same vector for the same fact.
  static String _embedTextOf(String topic, String content) => '$topic $content';

  @override
  Future<List<MemoryFact>> getActiveByTopic(String workspaceId, String topic) =>
      _dao(workspaceId)
          .getActiveByTopic(workspaceId, topic)
          .then((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<List<MemoryFact>> search(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
    String? boostRepoSlug,
  }) async {
    if (queryEmbedding != null) {
      // Hybrid BM25 + vector via RRF. Facts with no vector yet are simply
      // absent from the vector voice and still reach the result through FTS.
      // The extension is a required native: a vector query that fails is an
      // error, not a reason to rank by something else.
      final ftsResults = await _dao(workspaceId).searchFts(workspaceId, query);
      final vectorResults = await _vectorVoice(workspaceId, queryEmbedding);
      final fused = reciprocalRankFusion(
        [ftsResults, vectorResults],
        k: 60,
        limit: 10,
      );
      return sortByRepoAffinity<MemoryFact>(
        fused.map(_mapper.toDomain),
        boostRepoSlug,
        domainOf: (f) => f.domain,
      );
    }
    return _dao(workspaceId)
        .searchFts(workspaceId, query)
        .then(
          (rows) => sortByRepoAffinity<MemoryFact>(
            rows.map(_mapper.toDomain),
            boostRepoSlug,
            domainOf: (f) => f.domain,
          ),
        );
  }

  @override
  Future<List<MemoryFact>> recallPolyphonic(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
    int topK = 10,
    bool markRecalled = true,
    String? boostRepoSlug,
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
    register(
      RecallVoice.fact,
      await _dao(workspaceId).searchFts(workspaceId, query),
    );

    // Vector (semantic) voice — sqlite_vector over the fact vectors.
    if (queryEmbedding != null) {
      register(
        RecallVoice.vector,
        await _vectorVoice(workspaceId, queryEmbedding),
      );
    }

    // Temporal (recency) voice — the candidate pool of recent active facts.
    register(
      RecallVoice.temporal,
      await _dao(workspaceId).recentActive(workspaceId),
    );

    // Graph voice — BFS from the strongest lexical/vector seeds.
    final edgeDao = _edgeDao(workspaceId);
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
    final missing = uniqueGraphIds
        .where((id) => !rowsById.containsKey(id))
        .toList();
    if (missing.isNotEmpty) {
      for (final row in await _dao(
        workspaceId,
      ).getActiveByIds(workspaceId, missing)) {
        rowsById[row.id] = row;
      }
    }
    rankedIds[RecallVoice.graph] = uniqueGraphIds
        .where(rowsById.containsKey)
        .toList();

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
        // Repo affinity rides the fused score rather than filtering the
        // candidate pool, so a workspace-wide fact still competes on merit.
        boost: MemoryDomainScope.matchesRepo(fact.domain, boostRepoSlug)
            ? kRepoRecallBoost
            : 1.0,
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

  /// Vector voice: sqlite_vector KNN over the fact vectors.
  Future<List<db.MemoryFactsTableData>> _vectorVoice(
    String workspaceId,
    Float32List queryEmbedding,
  ) => _dao(workspaceId).searchVector(workspaceId, queryEmbedding, limit: 30);

  @override
  Future<void> markRecalled(String workspaceId, List<String> ids) =>
      _dao(workspaceId).markRecalled(workspaceId, ids, DateTime.now());

  @override
  Future<List<MemoryFact>> getByAuthor(String workspaceId, String agentId) =>
      _dao(workspaceId)
          .getByAuthor(workspaceId, agentId)
          .then((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(workspaceId, id);

  /// Computes a Float32 embedding for [text] if the service is available.
  ///
  /// Null means the ENVIRONMENT cannot embed yet: no service wired, or the
  /// on-device model has not been downloaded (`isReady`). A failure after the
  /// service reports ready (worker crash, corrupt model, an onnxruntime that
  /// cannot load) propagates instead of being swallowed — a silent, permanent
  /// keyword-only mode is exactly the invisible degradation a broken native
  /// install produces.
  Future<Float32List?> _computeFloat32(String text) async {
    if (_embeddingService == null || !_embeddingService.isReady) {
      return null;
    }
    return _embeddingService.embed(text);
  }
}
