import 'package:cc_domain/core/domain/entities/memory_belief.dart';
import 'package:cc_domain/core/domain/entities/memory_conflict.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/memory_events.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_belief_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_conflict_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/services/shmr_harmonizer.dart' as shmr;
import 'package:uuid/uuid.dart';

/// Summary of a harmonization pass.
class HarmonizeSummary {
  /// Creates a [HarmonizeSummary].
  const HarmonizeSummary({
    required this.beliefsEmitted,
    required this.contradictionsFlagged,
  });

  /// Number of harmonized beliefs written.
  final int beliefsEmitted;

  /// Number of cross-agent contradictions recorded as conflicts.
  final int contradictionsFlagged;
}

/// Cross-agent SHMR belief harmonization: clusters semantically-similar active
/// facts across agents, emits corroborated beliefs, and flags cross-agent
/// contradictions as conflicts. Ported from oh-my-pi mnemopi `core/shmr.ts`.
class HarmonizeMemoryUseCase {
  /// Creates a [HarmonizeMemoryUseCase].
  const HarmonizeMemoryUseCase({
    required MemoryFactRepository factRepository,
    required MemoryBeliefRepository beliefRepository,
    MemoryConflictRepository? conflictRepository,
    DomainEventBus? eventBus,
  })  : _facts = factRepository,
        _beliefs = beliefRepository,
        _conflicts = conflictRepository,
        _eventBus = eventBus;

  final MemoryFactRepository _facts;
  final MemoryBeliefRepository _beliefs;
  final MemoryConflictRepository? _conflicts;
  final DomainEventBus? _eventBus;

  static const _uuid = Uuid();

  /// Runs a harmonization pass over the workspace's active facts.
  Future<HarmonizeSummary> harmonize(String workspaceId) async {
    final facts = await _facts.getActiveByWorkspace(workspaceId);
    final items = [
      for (final f in facts)
        shmr.ShmrItem(
          factId: f.id,
          agentId: f.authoredByAgentId ?? '',
          topic: f.topic,
          content: f.content,
          confidence: f.confidence,
        ),
    ];

    final result = shmr.harmonize(items);
    final now = DateTime.now();

    final beliefs = [
      for (final b in result.beliefs)
        MemoryBelief(
          id: _uuid.v4(),
          workspaceId: workspaceId,
          topic: b.topic,
          content: b.content,
          confidence: b.confidence,
          harmonyScore: b.harmonyScore,
          provenanceFactIds: b.provenanceFactIds,
          provenanceAgentIds: b.provenanceAgentIds,
          clusterId: b.clusterId,
          createdAt: now,
          updatedAt: now,
        ),
    ];
    await _beliefs.replaceWorkspace(workspaceId, beliefs);
    for (final belief in beliefs) {
      _eventBus?.publish(
        MemoryBeliefHarmonized(
          workspaceId: workspaceId,
          beliefId: belief.id,
          occurredAt: DateTime.now(),
        ),
      );
    }

    for (final c in result.contradictions) {
      await _conflicts?.record(
        MemoryConflict(
          id: _uuid.v4(),
          workspaceId: workspaceId,
          factAId: c.itemA.factId,
          factBId: c.itemB.factId,
          conflictType: 'cross_agent',
          createdAt: DateTime.now(),
        ),
      );
      _eventBus?.publish(
        MemoryConflictDetected(
          workspaceId: workspaceId,
          conflictId: c.itemA.factId,
          winningFactId: c.itemB.factId,
          losingFactId: c.itemA.factId,
          occurredAt: DateTime.now(),
        ),
      );
    }

    return HarmonizeSummary(
      beliefsEmitted: beliefs.length,
      contradictionsFlagged: result.contradictions.length,
    );
  }
}