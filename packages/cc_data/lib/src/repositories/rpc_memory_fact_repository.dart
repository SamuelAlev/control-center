import 'dart:typed_data';

import 'package:cc_data/src/repositories/remote_memory_fact_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [MemoryFactRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `memory_fact.*` ops + the
/// `memory_fact.watchForWorkspace` subscription, mapping the [MemoryFactDto]
/// wire shape back to [MemoryFact]. The host owns persistence (including
/// embedding computation on upsert); this client never touches a database.
/// Reads, watches, and the direct upsert/delete row writes are served.
class RpcMemoryFactRepository implements MemoryFactRepository {
  /// Creates an [RpcMemoryFactRepository] over [client].
  RpcMemoryFactRepository(RemoteRpcClient client)
    : _remote = RemoteMemoryFactRepository(client);

  final RemoteMemoryFactRepository _remote;

  /// Rebuilds a [MemoryFact] from its wire DTO. Enum fields are encoded as
  /// `.name`; missing timestamps fall back to the epoch so the entity stays
  /// valid.
  static MemoryFact _fromDto(MemoryFactDto d) => MemoryFact(
    id: d.id,
    workspaceId: d.workspaceId,
    domain: d.domain,
    topic: d.topic,
    content: d.content,
    sourceObservationIds: d.sourceObservationIds,
    confidence: d.confidence,
    supersededBy: d.supersededBy,
    authoredByAgentId: d.authoredByAgentId,
    authoredByRole: d.authoredByRole == null
        ? null
        : AgentRole.values.asNameMap()[d.authoredByRole],
    memoryType: MemoryType.parse(d.memoryType),
    veracity: MemoryVeracity.parse(d.veracity),
    mentionCount: d.mentionCount,
    createdAt: d.createdAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.createdAt!),
    updatedAt: d.updatedAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.updatedAt!),
  );

  static MemoryFactDto _toDto(MemoryFact f) => MemoryFactDto(
    id: f.id,
    workspaceId: f.workspaceId,
    domain: f.domain,
    topic: f.topic,
    content: f.content,
    sourceObservationIds: f.sourceObservationIds,
    confidence: f.confidence,
    supersededBy: f.supersededBy,
    authoredByAgentId: f.authoredByAgentId,
    authoredByRole: f.authoredByRole?.name,
    memoryType: f.memoryType.wireName,
    veracity: f.veracity.wireName,
    mentionCount: f.mentionCount,
    createdAt: f.createdAt.toIso8601String(),
    updatedAt: f.updatedAt.toIso8601String(),
  );

  @override
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId) =>
      _remote.watch().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<List<MemoryFact>> getByWorkspace(String workspaceId) async {
    final dtos = await _remote.getByWorkspace();
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<MemoryFact?> getById(String workspaceId, String id) async {
    try {
      final dto = await _remote.getById(id);
      return dto == null ? null : _fromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<MemoryFact>> getActiveByTopic(
    String workspaceId,
    String topic,
  ) async {
    final dtos = await _remote.getActiveByTopic(topic);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<List<MemoryFact>> search(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
  }) async {
    if (queryEmbedding != null) {
      // Hybrid BM25+vector search runs on the host with the workspace's stored
      // embeddings; a thin client cannot meaningfully ship a query embedding
      // over the wire. The host serves FTS5-only search via `memory_fact.search`.
      throw UnsupportedError(
        'Embedding-based hybrid search is host-only; the RPC client supports '
        'FTS5 search only (omit queryEmbedding).',
      );
    }
    final dtos = await _remote.search(query);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<List<MemoryFact>> recallPolyphonic(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
    int topK = 10,
    bool markRecalled = true,
  }) async {
    // The full polyphonic engine (vector/graph/temporal voices, Weibull decay,
    // MMR) runs host-side where the embeddings + edge graph live. A thin client
    // degrades to the host's FTS5 search and caps to [topK].
    final dtos = await _remote.search(query);
    return dtos.map(_fromDto).take(topK).toList();
  }

  @override
  Future<List<MemoryFact>> getActiveByWorkspace(String workspaceId) async {
    final dtos = await _remote.getByWorkspace();
    return dtos.map(_fromDto).where((f) => !f.isSuperseded).toList();
  }

  @override
  Future<void> markRecalled(String workspaceId, List<String> ids) async {
    // Best-effort recall telemetry is host-owned; the thin client is a no-op.
  }

  @override
  Future<List<MemoryFact>> getByAuthor(
    String workspaceId,
    String agentId,
  ) async {
    final dtos = await _remote.getByAuthor(agentId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<void> upsert(MemoryFact fact) => _remote.upsert(_toDto(fact));

  @override
  Future<void> delete(String workspaceId, String id) => _remote.delete(id);
}
