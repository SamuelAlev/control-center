import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/features/governance/domain/entities/agent_runtime_state.dart';
import 'package:cc_domain/features/governance/domain/repositories/agent_runtime_state_repository.dart';
import 'package:cc_domain/features/governance/domain/value_objects/heartbeat_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/runtime_health.dart';

/// Tracks per-agent liveness from heartbeats and detects stuck / lost agents.
///
/// An agent phones home periodically via [recordHeartbeat]; the system tracks
/// alive / idle / stuck and derives 4-state runtime health from the heartbeat
/// age. [stuckAgents] surfaces agents needing attention; [reconcileStale] flips
/// silently-lost agents to `offline` so the roster stays honest.
class HeartbeatMonitorService {
  /// Creates a [HeartbeatMonitorService].
  HeartbeatMonitorService({
    required AgentRuntimeStateRepository repository,
    ActivityLogger? activityLogger,
  }) : _repository = repository,
       _audit = activityLogger;

  final AgentRuntimeStateRepository _repository;
  final ActivityLogger? _audit;

  /// Records a heartbeat for [agentId], updating its reported status and
  /// last-seen time. Returns the persisted state.
  Future<AgentRuntimeState> recordHeartbeat({
    required String workspaceId,
    required String agentId,
    HeartbeatStatus status = HeartbeatStatus.alive,
    String? runId,
    String? note,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final existing = await _repository.getForAgent(workspaceId, agentId);
    final updated =
        (existing ??
                AgentRuntimeState(
                  agentId: agentId,
                  workspaceId: workspaceId,
                  updatedAt: at,
                ))
            .copyWith(
              reportedStatus: status,
              lastHeartbeatAt: at,
              currentRunId: runId,
              removeCurrentRunId: runId == null,
              note: note,
              removeNote: note == null,
              updatedAt: at,
            );
    await _repository.upsert(updated);
    return updated;
  }

  /// Returns the agents in [workspaceId] that need attention: those that
  /// reported `stuck`, and those that last reported `alive` but have since gone
  /// quiet (derived health is recently-lost or offline).
  Future<List<AgentRuntimeState>> stuckAgents(
    String workspaceId, {
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final states = await _repository.listByWorkspace(workspaceId);
    return states
        .where((s) {
          if (s.reportedStatus == HeartbeatStatus.stuck) {
            return true;
          }
          if (s.reportedStatus == HeartbeatStatus.alive) {
            final health = s.healthAt(at);
            return health == RuntimeHealth.recentlyLost ||
                health == RuntimeHealth.offline ||
                health == RuntimeHealth.aboutToGc;
          }
          return false;
        })
        .toList(growable: false);
  }

  /// Flips agents whose heartbeat has gone stale (derived health offline) but
  /// whose reported status still claims liveness to `offline`, so the roster
  /// reflects reality. Returns the number reconciled.
  Future<int> reconcileStale(String workspaceId, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final states = await _repository.listByWorkspace(workspaceId);
    var reconciled = 0;
    for (final s in states) {
      final stale =
          s.healthAt(at) == RuntimeHealth.offline ||
          s.healthAt(at) == RuntimeHealth.aboutToGc;
      if (stale && s.reportedStatus != HeartbeatStatus.offline) {
        await _repository.upsert(
          s.copyWith(reportedStatus: HeartbeatStatus.offline, updatedAt: at),
        );
        _audit?.log(
          actorType: 'system',
          action: 'agent_runtime_lost',
          entityType: 'agent',
          entityId: s.agentId,
          workspaceId: workspaceId,
        );
        reconciled++;
      }
    }
    return reconciled;
  }
}
