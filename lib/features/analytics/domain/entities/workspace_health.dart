/// Health metrics for a workspace.
class WorkspaceHealth {
  /// Creates a new [WorkspaceHealth].
  const WorkspaceHealth({
    required this.workspaceId,
    required this.workspaceName,
    required this.score,
    required this.activityScore,
    required this.throughputScore,
    required this.reviewHealthScore,
    required this.successRateScore,
    required this.activeAgents,
    required this.totalAgents,
    required this.prsMergedThisWeek,
    required this.openPRs,
    required this.stalePRs,
    required this.totalRuns,
    required this.erroredRuns,
  });

  /// Identifier of the workspace.
  final String workspaceId;
  /// Display name of the workspace.
  final String workspaceName;
  /// Overall health score (0–100).
  final double score;
  /// Activity sub-score (0–100).
  final double activityScore;
  /// Throughput sub-score (0–100).
  final double throughputScore;
  /// Review health sub-score (0–100).
  final double reviewHealthScore;
  /// Success rate sub-score (0–100).
  final double successRateScore;
  /// Number of active agents in the workspace.
  final int activeAgents;
  /// Total number of agents in the workspace.
  final int totalAgents;
  /// PRs merged in the last 7 days.
  final int prsMergedThisWeek;
  /// Number of currently open PRs.
  final int openPRs;
  /// Number of stale PRs.
  final int stalePRs;
  /// Total runs in the workspace.
  final int totalRuns;
  /// Total errored runs in the workspace.
  final int erroredRuns;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceHealth &&
          runtimeType == other.runtimeType &&
          workspaceId == other.workspaceId &&
          workspaceName == other.workspaceName &&
          score == other.score &&
          activityScore == other.activityScore &&
          throughputScore == other.throughputScore &&
          reviewHealthScore == other.reviewHealthScore &&
          successRateScore == other.successRateScore &&
          activeAgents == other.activeAgents &&
          totalAgents == other.totalAgents &&
          prsMergedThisWeek == other.prsMergedThisWeek &&
          openPRs == other.openPRs &&
          stalePRs == other.stalePRs &&
          totalRuns == other.totalRuns &&
          erroredRuns == other.erroredRuns;

  @override
  int get hashCode => Object.hash(
    workspaceId,
    workspaceName,
    score,
    activityScore,
    throughputScore,
    reviewHealthScore,
    successRateScore,
    activeAgents,
    totalAgents,
    prsMergedThisWeek,
    openPRs,
    stalePRs,
    totalRuns,
    erroredRuns,
  );
}
