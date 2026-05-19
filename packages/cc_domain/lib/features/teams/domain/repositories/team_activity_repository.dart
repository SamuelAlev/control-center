import 'package:cc_domain/features/teams/domain/entities/team_activity.dart';

/// Persists team-leader evaluations (the `team_activity_log`) and answers the
/// dedup query that bounds the re-trigger loop.
abstract class TeamActivityRepository {
  /// Records a leader evaluation.
  Future<void> record(TeamActivity activity);

  /// All evaluations recorded for a ticket, newest first. Workspace-scoped:
  /// a foreign ticket id returns an empty list.
  Future<List<TeamActivity>> forTicket(String workspaceId, String ticketId);

  /// Streams a team's recent evaluations (newest first), workspace-scoped.
  Stream<List<TeamActivity>> watchForTeam(String workspaceId, String teamId);

  /// Whether the team's leader has already recorded a
  /// [TeamActivityKind.noAction] evaluation for the given ticket — the guard
  /// that prevents the leader from being re-woken in a loop once it has
  /// declared there is nothing more to do.
  Future<bool> hasNoActionEvaluationForTicket(
    String workspaceId,
    String teamId,
    String ticketId,
  );
}
