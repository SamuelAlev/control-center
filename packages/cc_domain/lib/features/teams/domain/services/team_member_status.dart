import 'package:cc_domain/core/domain/entities/agent_run_log.dart'
    show RunLiveness;
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart'
    show AgentStatus;

/// The collapsed, member-facing status of a team member.
///
/// One value that folds together runtime presence (is the agent's process
/// alive?) and task signals (does it own in-flight work?) so a roster can show
/// at a glance who can take work right now.
enum TeamMemberStatus {
  /// Owns in-flight work, or its dispatch is actively running. Wins over
  /// runtime-health classification (a busy agent reads as working even if its
  /// last run flapped).
  working,

  /// Alive and registered but not currently working — available for new work.
  idle,

  /// Not present in the live registry (never dispatched this session, parked,
  /// or released). Reachable only by a fresh dispatch.
  offline,

  /// Alive but unhealthy — the latest run is looping/stalled/failed/dead, or
  /// the process was hard-aborted. Work assigned here is at risk.
  unstable,

  /// Retired/removed from the team or workspace. Always wins: an archived
  /// member is never shown as working/idle even if a stale run lingers.
  archived;

  /// The storage string for this status.
  String toStorageString() => name;

  /// Parses a [TeamMemberStatus] from its storage string, defaulting to
  /// [offline] for unknown values.
  static TeamMemberStatus fromString(String value) => switch (value) {
    'working' => TeamMemberStatus.working,
    'idle' => TeamMemberStatus.idle,
    'unstable' => TeamMemberStatus.unstable,
    'archived' => TeamMemberStatus.archived,
    _ => TeamMemberStatus.offline,
  };
}

/// A derived status snapshot for one team member: the collapsed [status] plus
/// the signals it was derived from (active work + last-seen time).
class TeamMemberStatusInfo {
  /// Creates a [TeamMemberStatusInfo].
  const TeamMemberStatusInfo({
    required this.agentId,
    required this.status,
    this.activeTicketIds = const [],
    this.lastActiveAt,
  });

  /// The member's agent id.
  final String agentId;

  /// The collapsed five-way status.
  final TeamMemberStatus status;

  /// Ids of the tickets this member is actively working (non-terminal,
  /// assigned to it).
  final List<String> activeTicketIds;

  /// When the member was last observed active (last run output / activity),
  /// or `null` if never observed this session.
  final DateTime? lastActiveAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMemberStatusInfo &&
          runtimeType == other.runtimeType &&
          agentId == other.agentId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(agentId, status);
}

/// Collapses runtime presence + task signals into one [TeamMemberStatus].
///
/// Precedence (highest wins): **archived → working → unstable → offline →
/// idle**. "Working wins over runtime health" — a member with active work or a
/// running dispatch reads as working even when its last run was unhealthy;
/// "archived always wins" — a retired member is never shown as live.
///
/// Inputs:
/// * [archived] — the member was retired/removed (e.g. its agent no longer
///   exists in the workspace, or it was unlinked from the team).
/// * [runtimeStatus] — the agent's live [AgentStatus], or `null` when it is
///   absent from the process registry.
/// * [liveness] — the health classification of its most recent run, if any.
/// * [activeTicketCount] — how many non-terminal tickets it currently owns.
TeamMemberStatus deriveTeamMemberStatus({
  required bool archived,
  required AgentStatus? runtimeStatus,
  RunLiveness? liveness,
  required int activeTicketCount,
}) {
  if (archived) {
    return TeamMemberStatus.archived;
  }
  if (activeTicketCount > 0 || runtimeStatus == AgentStatus.running) {
    return TeamMemberStatus.working;
  }
  const unhealthy = {
    RunLiveness.looping,
    RunLiveness.stalled,
    RunLiveness.failed,
    RunLiveness.dead,
  };
  if (runtimeStatus == AgentStatus.aborted ||
      (liveness != null && unhealthy.contains(liveness))) {
    return TeamMemberStatus.unstable;
  }
  if (runtimeStatus == null || runtimeStatus == AgentStatus.parked) {
    return TeamMemberStatus.offline;
  }
  return TeamMemberStatus.idle;
}
