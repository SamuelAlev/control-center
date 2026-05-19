import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/runtime_health.dart';

/// Runtime reachability of an agent — one of the two orthogonal dimensions of
/// presence (the other being [Workload]).
enum AgentAvailability {
  /// Reachable and healthy.
  online('Online'),

  /// Reachable but flapping (contact recently lost).
  unstable('Unstable'),

  /// Not reachable.
  offline('Offline'),

  /// Retired — intentionally not present.
  archived('Archived');

  /// Creates an [AgentAvailability] with a display [label].
  const AgentAvailability(this.label);

  /// Human-readable display label.
  final String label;
}

/// Task-load of an agent — the second orthogonal dimension of presence.
enum Workload {
  /// At least one task is actively running.
  working('Working'),

  /// No task running, but at least one is queued.
  queued('Queued'),

  /// Nothing running or queued.
  idle('Idle');

  /// Creates a [Workload] with a display [label].
  const Workload(this.label);

  /// Human-readable display label.
  final String label;
}

/// The full presence of an agent: availability × workload, with the running /
/// queued / capacity counts that back the workload.
class AgentPresence {
  /// Creates an [AgentPresence].
  const AgentPresence({
    required this.availability,
    required this.workload,
    required this.runningCount,
    required this.queuedCount,
    required this.capacity,
  });

  /// Runtime reachability dimension.
  final AgentAvailability availability;

  /// Task-load dimension.
  final Workload workload;

  /// Number of tasks currently running.
  final int runningCount;

  /// Number of tasks queued behind the running ones.
  final int queuedCount;

  /// Maximum tasks the agent may run concurrently.
  final int capacity;

  /// Whether the agent is at or beyond its concurrency capacity.
  bool get isAtCapacity => capacity > 0 && runningCount >= capacity;

  /// Whether the agent could accept more work right now.
  bool get hasFreeSlot =>
      availability == AgentAvailability.online &&
      (capacity <= 0 || runningCount < capacity);

  /// A compact, human-readable summary, e.g. `online + working (2/3)`.
  String get summary {
    final cap = capacity > 0 ? '$runningCount/$capacity' : '$runningCount';
    return '${availability.label.toLowerCase()} + '
        '${workload.label.toLowerCase()} ($cap)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentPresence &&
          runtimeType == other.runtimeType &&
          availability == other.availability &&
          workload == other.workload &&
          runningCount == other.runningCount &&
          queuedCount == other.queuedCount &&
          capacity == other.capacity;

  @override
  int get hashCode =>
      Object.hash(availability, workload, runningCount, queuedCount, capacity);
}

/// Derives an [AgentPresence] from an agent's runtime [health], governance
/// [lifecycle] status and its current [runningCount] / [queuedCount] against
/// its [capacity].
AgentPresence deriveAgentPresence({
  required RuntimeHealth health,
  required AgentLifecycleStatus lifecycle,
  required int runningCount,
  required int queuedCount,
  required int capacity,
}) {
  final availability = switch (lifecycle) {
    AgentLifecycleStatus.archived => AgentAvailability.archived,
    _ => switch (health) {
      RuntimeHealth.online => AgentAvailability.online,
      RuntimeHealth.recentlyLost => AgentAvailability.unstable,
      RuntimeHealth.offline ||
      RuntimeHealth.aboutToGc => AgentAvailability.offline,
    },
  };

  final workload = runningCount > 0
      ? Workload.working
      : (queuedCount > 0 ? Workload.queued : Workload.idle);

  return AgentPresence(
    availability: availability,
    workload: workload,
    runningCount: runningCount,
    queuedCount: queuedCount,
    capacity: capacity,
  );
}
