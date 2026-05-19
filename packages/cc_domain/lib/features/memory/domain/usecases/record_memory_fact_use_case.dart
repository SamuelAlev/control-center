import 'package:cc_domain/core/domain/entities/episodic_edge.dart';
import 'package:cc_domain/core/domain/entities/memory_conflict.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/memory_events.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/repositories/episodic_edge_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_conflict_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/services/conflict_detector.dart';
import 'package:cc_domain/features/memory/domain/services/episodic_graph.dart';
import 'package:cc_domain/features/memory/domain/services/memory_classifier.dart';
import 'package:cc_domain/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:uuid/uuid.dart';

/// What happened when a fact was recorded.
enum RecordOutcome {
  /// A brand-new fact was created.
  created,

  /// An identical existing fact was re-asserted (Bayesian confidence bumped).
  deduplicated,

  /// The new fact contradicted an existing one and was superseded by it.
  supersededByConflict,
}

/// Result of a [RecordMemoryFactUseCase.record] call.
class RecordFactResult {
  /// Creates a [RecordFactResult].
  const RecordFactResult({
    required this.fact,
    required this.outcome,
    this.conflictsDetected = 0,
  });

  /// The canonical fact (existing on dedup, new otherwise).
  final MemoryFact fact;

  /// What happened.
  final RecordOutcome outcome;

  /// How many contradictions this write resolved.
  final int conflictsDetected;
}

/// Shared deterministic writer for workspace memory facts. Used by the
/// `propose_fact` MCP tool, the consolidation `sleep()` pass, and the
/// cross-feature harvest paths (meeting decisions, ticket outcomes, PR verdicts,
/// orchestration plans), so typing + veracity + dedup + conflict supersession +
/// episodic linking behave identically everywhere.
class RecordMemoryFactUseCase {
  /// Creates a [RecordMemoryFactUseCase].
  ///
  /// [conflictRepository], [edgeRepository], and [eventBus] are optional: when
  /// absent, conflict rows / episodic edges / stream events are simply not
  /// emitted (the fact is still written, deduped, and superseded as needed).
  const RecordMemoryFactUseCase({
    required MemoryFactRepository factRepository,
    required ResolveOrCreateDomainUseCase resolveDomainUseCase,
    MemoryConflictRepository? conflictRepository,
    EpisodicEdgeRepository? edgeRepository,
    DomainEventBus? eventBus,
  })  : _facts = factRepository,
        _resolveDomain = resolveDomainUseCase,
        _conflicts = conflictRepository,
        _edges = edgeRepository,
        _eventBus = eventBus;

  final MemoryFactRepository _facts;
  final ResolveOrCreateDomainUseCase _resolveDomain;
  final MemoryConflictRepository? _conflicts;
  final EpisodicEdgeRepository? _edges;
  final DomainEventBus? _eventBus;

  static const _uuid = Uuid();

  /// How many recent active facts to consider when proposing episodic links.
  static const int _linkCandidatePool = 50;

  /// Max episodic links to create per recorded fact.
  static const int _maxLinksPerFact = 5;

  /// Records a fact. Returns null only when [content] is blank; otherwise a
  /// [RecordFactResult] describing what happened.
  Future<RecordFactResult?> record({
    required String workspaceId,
    required String domain,
    required String topic,
    required String content,
    double confidence = 1.0,
    String? authoredByAgentId,
    AgentRole authorRole = AgentRole.general,
    String? domainLabel,
    String? domainDescription,
    MemoryType? memoryType,
    MemoryVeracity veracity = MemoryVeracity.stated,
    DateTime? validUntil,
    List<String> temporalTags = const [],
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
    final type = memoryType ?? classifyMemory(content).memoryType;
    final activeForTopic = await _facts.getActiveByTopic(workspaceId, topic);
    final sameDomain =
        activeForTopic.where((f) => f.domain == resolved.name).toList();

    // Dedup → Bayesian re-mention.
    for (final existing in sameDomain) {
      if (existing.content.trim().toLowerCase() == trimmed.toLowerCase()) {
        final updated = existing.copyWith(
          confidence: bayesianUpdate(existing.confidence, veracity),
          mentionCount: existing.mentionCount + 1,
          updatedAt: DateTime.now(),
        );
        await _facts.upsert(updated);
        _publish(
          MemoryFactUpdated(
            workspaceId: workspaceId,
            factId: updated.id,
            occurredAt: DateTime.now(),
          ),
        );
        return RecordFactResult(
          fact: updated,
          outcome: RecordOutcome.deduplicated,
        );
      }
    }

    final now = DateTime.now();
    var candidate = MemoryFact(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      domain: resolved.name,
      topic: topic,
      content: content,
      confidence: confidence.clamp(0.0, 1.0),
      authoredByAgentId: authoredByAgentId,
      authoredByRole: authorRole,
      memoryType: type,
      veracity: veracity,
      validUntil: validUntil,
      temporalTags: temporalTags,
      createdAt: now,
      updatedAt: now,
    );
    await _facts.upsert(candidate);

    // Conflict detection + supersession against same-domain, same-topic facts.
    final decisions = detectConflicts(candidate, sameDomain);
    var candidateSuperseded = false;
    for (final decision in decisions) {
      final loser = decision.loser.copyWith(
        supersededBy: decision.winner.id,
        updatedAt: DateTime.now(),
      );
      await _facts.upsert(loser);
      if (loser.id == candidate.id) {
        candidate = loser;
        candidateSuperseded = true;
      }
      await _conflicts?.record(
        MemoryConflict(
          id: _uuid.v4(),
          workspaceId: workspaceId,
          factAId: decision.loser.id,
          factBId: decision.winner.id,
          resolution: 'superseded',
          winningFactId: decision.winner.id,
          resolvedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      _publish(
        MemoryConflictDetected(
          workspaceId: workspaceId,
          conflictId: decision.loser.id,
          winningFactId: decision.winner.id,
          losingFactId: decision.loser.id,
          occurredAt: DateTime.now(),
        ),
      );
      _publish(
        MemoryFactSuperseded(
          workspaceId: workspaceId,
          factId: decision.loser.id,
          supersededBy: decision.winner.id,
          occurredAt: DateTime.now(),
        ),
      );
    }

    // Proactive episodic linking (only for facts that survived).
    if (!candidateSuperseded) {
      await _linkRelated(workspaceId, candidate);
    }

    _publish(
      MemoryFactRecorded(
        workspaceId: workspaceId,
        factId: candidate.id,
        occurredAt: DateTime.now(),
      ),
    );

    return RecordFactResult(
      fact: candidate,
      outcome: candidateSuperseded
          ? RecordOutcome.supersededByConflict
          : RecordOutcome.created,
      conflictsDetected: decisions.length,
    );
  }

  Future<void> _linkRelated(String workspaceId, MemoryFact fact) async {
    final edges = _edges;
    if (edges == null) {
      return;
    }
    final pool = await _facts.getActiveByWorkspace(workspaceId);
    final scored = <({MemoryFact other, double score})>[];
    for (final other in pool) {
      if (other.id == fact.id || other.isSuperseded) {
        continue;
      }
      final score = relatednessScore(fact.content, other.content);
      if (score >= episodicLinkThreshold) {
        scored.add((other: other, score: score));
      }
      if (scored.length >= _linkCandidatePool) {
        break;
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    for (final link in scored.take(_maxLinksPerFact)) {
      await edges.upsert(
        EpisodicEdge(
          id: _uuid.v4(),
          workspaceId: workspaceId,
          sourceFactId: fact.id,
          targetFactId: link.other.id,
          edgeType: EpisodicEdgeTypes.relatedTo,
          weight: link.score,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  void _publish(MemoryEvent event) => _eventBus?.publish(event);

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