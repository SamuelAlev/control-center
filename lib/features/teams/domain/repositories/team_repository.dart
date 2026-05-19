import 'package:control_center/features/teams/domain/entities/team.dart';
import 'package:control_center/features/teams/domain/entities/team_member.dart';

/// Repository interface for persisting teams and their members.
abstract class TeamRepository {
  // ── Teams ──
  Future<void> insertTeam(Team team);
  Future<void> updateTeam(Team team);
  Future<void> deleteTeam(String id);
  Future<Team?> getTeam(String id);
  Future<List<Team>> teamsForWorkspace(String workspaceId);
  Stream<List<Team>> watchTeamsForWorkspace(String workspaceId);

  // ── Members ──
  Future<void> addMember(TeamMember member);
  Future<void> removeMember(String teamId, String agentId);
  Future<List<TeamMember>> membersOf(String teamId);
  Stream<List<TeamMember>> watchMembersOf(String teamId);
}
