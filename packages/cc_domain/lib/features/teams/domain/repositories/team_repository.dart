import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';

/// Repository interface for persisting teams and their members.
abstract class TeamRepository {
  // ── Teams ──
  /// Persists a new [Team].
  Future<void> insertTeam(Team team);

  /// Updates an existing [Team].
  Future<void> updateTeam(Team team);

  /// Deletes the team with the given [id] from [workspaceId]. A team owned by
  /// another workspace is not matched.
  Future<void> deleteTeam(String workspaceId, String id);

  /// Returns the team with the given [id] in [workspaceId], or `null`. The id
  /// resolves only inside that workspace.
  Future<Team?> getTeam(String workspaceId, String id);

  /// Returns all teams in the given workspace.
  Future<List<Team>> teamsForWorkspace(String workspaceId);

  /// Streams all teams in the given workspace, emitting on changes.
  Stream<List<Team>> watchTeamsForWorkspace(String workspaceId);

  // ── Members ──
  /// Adds a [TeamMember] to a team in [workspaceId].
  Future<void> addMember(String workspaceId, TeamMember member);

  /// Removes a member from a team in [workspaceId].
  Future<void> removeMember(String workspaceId, String teamId, String agentId);

  /// Returns all members of the given team in [workspaceId].
  Future<List<TeamMember>> membersOf(String workspaceId, String teamId);

  /// Streams all members of the given team in [workspaceId], emitting on
  /// changes.
  Stream<List<TeamMember>> watchMembersOf(String workspaceId, String teamId);
}
