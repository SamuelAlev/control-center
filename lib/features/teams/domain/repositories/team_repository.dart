import 'package:control_center/features/teams/domain/entities/team.dart';
import 'package:control_center/features/teams/domain/entities/team_member.dart';

/// Repository interface for persisting teams and their members.
abstract class TeamRepository {
  // ── Teams ──
  /// Persists a new [Team].
  Future<void> insertTeam(Team team);
  /// Updates an existing [Team].
  Future<void> updateTeam(Team team);
  /// Deletes the team with the given [id].
  Future<void> deleteTeam(String id);
  /// Returns the team with the given [id], or `null`.
  Future<Team?> getTeam(String id);
  /// Returns all teams in the given workspace.
  Future<List<Team>> teamsForWorkspace(String workspaceId);
  /// Streams all teams in the given workspace, emitting on changes.
  Stream<List<Team>> watchTeamsForWorkspace(String workspaceId);

  // ── Members ──
  /// Adds a [TeamMember] to a team.
  Future<void> addMember(TeamMember member);
  /// Removes a member from a team.
  Future<void> removeMember(String teamId, String agentId);
  /// Returns all members of the given team.
  Future<List<TeamMember>> membersOf(String teamId);
  /// Streams all members of the given team, emitting on changes.
  Stream<List<TeamMember>> watchMembersOf(String teamId);
}
