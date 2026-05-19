import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Base type for memory-stream events, ported from oh-my-pi mnemopi
/// `core/streaming.ts` (MEMORY_ADDED/RECALLED/INVALIDATED/CONSOLIDATED/UPDATED).
///
/// CC already gets live memory-panel updates from Drift `.watch()` streams;
/// these events let *other* features react to memory changes (and drive a
/// bounded replay buffer via `MemoryStream`).
abstract class MemoryEvent implements DomainEvent {
  /// Workspace the event belongs to.
  String get workspaceId;
}

/// A new fact was recorded.
class MemoryFactRecorded implements MemoryEvent {
  /// Creates a [MemoryFactRecorded].
  const MemoryFactRecorded({
    required this.workspaceId,
    required this.factId,
    required this.occurredAt,
  });

  @override
  final String workspaceId;

  /// The recorded fact's id.
  final String factId;

  @override
  final DateTime occurredAt;
}

/// An existing fact was re-asserted (Bayesian confidence bumped).
class MemoryFactUpdated implements MemoryEvent {
  /// Creates a [MemoryFactUpdated].
  const MemoryFactUpdated({
    required this.workspaceId,
    required this.factId,
    required this.occurredAt,
  });

  @override
  final String workspaceId;

  /// The updated fact's id.
  final String factId;

  @override
  final DateTime occurredAt;
}

/// A fact was superseded (by a newer fact or a conflict resolution).
class MemoryFactSuperseded implements MemoryEvent {
  /// Creates a [MemoryFactSuperseded].
  const MemoryFactSuperseded({
    required this.workspaceId,
    required this.factId,
    required this.supersededBy,
    required this.occurredAt,
  });

  @override
  final String workspaceId;

  /// The superseded fact's id.
  final String factId;

  /// What superseded it (a fact id, or a `system:*` sentinel).
  final String supersededBy;

  @override
  final DateTime occurredAt;
}

/// A contradiction was detected between two facts.
class MemoryConflictDetected implements MemoryEvent {
  /// Creates a [MemoryConflictDetected].
  const MemoryConflictDetected({
    required this.workspaceId,
    required this.conflictId,
    required this.winningFactId,
    required this.losingFactId,
    required this.occurredAt,
  });

  @override
  final String workspaceId;

  /// The recorded conflict's id.
  final String conflictId;

  /// The fact that stayed active.
  final String winningFactId;

  /// The fact that was superseded.
  final String losingFactId;

  @override
  final DateTime occurredAt;
}

/// A consolidation (`sleep`) pass rolled working memory into episodic memory.
class MemoryConsolidated implements MemoryEvent {
  /// Creates a [MemoryConsolidated].
  const MemoryConsolidated({
    required this.workspaceId,
    required this.factsCreated,
    required this.factsUpdated,
    required this.occurredAt,
  });

  @override
  final String workspaceId;

  /// How many durable facts were created.
  final int factsCreated;

  /// How many durable facts were re-asserted.
  final int factsUpdated;

  @override
  final DateTime occurredAt;
}

/// Cross-agent SHMR emitted a harmonized belief.
class MemoryBeliefHarmonized implements MemoryEvent {
  /// Creates a [MemoryBeliefHarmonized].
  const MemoryBeliefHarmonized({
    required this.workspaceId,
    required this.beliefId,
    required this.occurredAt,
  });

  @override
  final String workspaceId;

  /// The harmonized belief's id.
  final String beliefId;

  @override
  final DateTime occurredAt;
}