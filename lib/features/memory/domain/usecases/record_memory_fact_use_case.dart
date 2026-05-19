import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:control_center/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:uuid/uuid.dart';

/// Shared deterministic writer for workspace memory facts. Used by both the
/// `propose_fact` MCP tool (agent-driven) and the cross-feature harvest paths
/// (meeting decisions, ticket outcomes, PR verdicts, orchestration plans), so
/// dedup + domain-resolution + supersession behaviour is identical everywhere.
class RecordMemoryFactUseCase {
  /// Creates a [RecordMemoryFactUseCase].
  const RecordMemoryFactUseCase({
    required MemoryFactRepository factRepository,
    required ResolveOrCreateDomainUseCase resolveDomainUseCase,
  })  : _facts = factRepository,
        _resolveDomain = resolveDomainUseCase;

  final MemoryFactRepository _facts;
  final ResolveOrCreateDomainUseCase _resolveDomain;

  static const _uuid = Uuid();

  /// Records a fact, de-duplicating on normalized (domain, topic, content).
  /// Returns the existing fact on a dedup hit, or the new fact. Returns null
  /// only when [content] is blank.
  Future<MemoryFact?> record({
    required String workspaceId,
    required String domain,
    required String topic,
    required String content,
    double confidence = 1.0,
    String? authoredByAgentId,
    AgentRole authorRole = AgentRole.general,
    String? domainLabel,
    String? domainDescription,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final resolved = await _resolveDomain.execute(
      workspaceId: workspaceId,
      domainInput: domain,
      domainLabel: domainLabel,
      domainDescription: domainDescription,
      authorRole: authorRole,
    );
    final active = await _facts.getActiveByTopic(workspaceId, topic);
    for (final existing in active) {
      if (existing.domain == resolved.name &&
          existing.content.trim() == trimmed) {
        return existing; // dedup hit
      }
    }
    final now = DateTime.now();
    final fact = MemoryFact(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      domain: resolved.name,
      topic: topic,
      content: content,
      confidence: confidence.clamp(0.0, 1.0),
      authoredByAgentId: authoredByAgentId,
      authoredByRole: authorRole,
      createdAt: now,
      updatedAt: now,
    );
    await _facts.upsert(fact);
    return fact;
  }

  /// Supersedes active facts under [topic] whose content is no longer in
  /// [liveContents] (used by harvest paths that replace a topic's facts on
  /// re-run, e.g. re-finalizing a review or re-summarizing a meeting). Marks
  /// them with the `system:harvest` sentinel so provenance is distinguishable.
  Future<void> reconcileTopic({
    required String workspaceId,
    required String topic,
    required Set<String> liveContents,
  }) async {
    final live = liveContents.map((c) => c.trim()).toSet();
    final active = await _facts.getActiveByTopic(workspaceId, topic);
    for (final fact in active) {
      if (!live.contains(fact.content.trim())) {
        await _facts.upsert(
          fact.copyWith(
            supersededBy: 'system:harvest',
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
  }
}
