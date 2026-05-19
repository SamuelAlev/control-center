import 'package:cc_domain/features/governance/domain/value_objects/heartbeat_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/runtime_health.dart';

/// Per-agent runtime liveness: the last heartbeat and the agent's self-reported
/// status. The derived 4-state [RuntimeHealth] is computed on demand from
/// [lastHeartbeatAt] (see [healthAt]), never stored.
class AgentRuntimeState {
  /// Creates an [AgentRuntimeState].
  const AgentRuntimeState({
    required this.agentId,
    required this.workspaceId,
    this.reportedStatus = HeartbeatStatus.offline,
    this.lastHeartbeatAt,
    this.currentRunId,
    this.note,
    required this.updatedAt,
  });

  /// Agent this state belongs to.
  final String agentId;

  /// Owning workspace.
  final String workspaceId;

  /// Last heartbeat-reported liveness.
  final HeartbeatStatus reportedStatus;

  /// When the agent last phoned home, or null if it never has.
  final DateTime? lastHeartbeatAt;

  /// Run id the agent is currently working under, if any.
  final String? currentRunId;

  /// Optional free-form note from the last heartbeat.
  final String? note;

  /// When this row was last updated.
  final DateTime updatedAt;

  /// Derives the 4-state runtime health relative to [now].
  RuntimeHealth healthAt(DateTime now) =>
      deriveRuntimeHealth(lastSeenAt: lastHeartbeatAt, now: now);

  /// Whether this runtime is stale enough to be reaped by the GC sweep at
  /// [now].
  bool isReadyForGcAt(DateTime now) =>
      isReadyForGc(lastSeenAt: lastHeartbeatAt, now: now);

  /// Returns a copy with the given fields replaced.
  AgentRuntimeState copyWith({
    String? agentId,
    String? workspaceId,
    HeartbeatStatus? reportedStatus,
    DateTime? lastHeartbeatAt,
    bool removeLastHeartbeatAt = false,
    String? currentRunId,
    bool removeCurrentRunId = false,
    String? note,
    bool removeNote = false,
    DateTime? updatedAt,
  }) {
    return AgentRuntimeState(
      agentId: agentId ?? this.agentId,
      workspaceId: workspaceId ?? this.workspaceId,
      reportedStatus: reportedStatus ?? this.reportedStatus,
      lastHeartbeatAt: removeLastHeartbeatAt
          ? null
          : (lastHeartbeatAt ?? this.lastHeartbeatAt),
      currentRunId: removeCurrentRunId
          ? null
          : (currentRunId ?? this.currentRunId),
      note: removeNote ? null : (note ?? this.note),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentRuntimeState &&
          runtimeType == other.runtimeType &&
          agentId == other.agentId &&
          workspaceId == other.workspaceId &&
          reportedStatus == other.reportedStatus &&
          lastHeartbeatAt == other.lastHeartbeatAt &&
          currentRunId == other.currentRunId &&
          note == other.note &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    agentId,
    workspaceId,
    reportedStatus,
    lastHeartbeatAt,
    currentRunId,
    note,
    updatedAt,
  );
}
