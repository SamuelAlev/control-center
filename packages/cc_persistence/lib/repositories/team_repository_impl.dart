import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_persistence/database/daos/team_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/team_mappers.dart';

/// Drift-backed implementation of [TeamRepository].
///
/// Teams and their membership rows live in the workspace's own database file. A
/// team id or a `(teamId, agentId)` pair therefore resolves only inside the
/// workspace it is looked up in, which is why every method takes one — a team
/// membership can never straddle two workspaces.
class TeamRepositoryImpl implements TeamRepository {
  /// Creates a [TeamRepositoryImpl] over the per-workspace databases.
  TeamRepositoryImpl(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  TeamDao _dao(String workspaceId) => _dbs.of(workspaceId).teamDao;

  @override
  Future<void> insertTeam(Team team) =>
      _dao(team.workspaceId).insertTeam(teamToCompanion(team));

  @override
  Future<void> updateTeam(Team team) =>
      _dao(team.workspaceId).updateTeam(teamToCompanion(team));

  @override
  Future<void> deleteTeam(String workspaceId, String id) =>
      _dao(workspaceId).deleteTeam(id);

  @override
  Future<Team?> getTeam(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getTeam(id);
    return row != null ? teamFromRow(row) : null;
  }

  @override
  Future<List<Team>> teamsForWorkspace(String workspaceId) async {
    final rows = await _dao(workspaceId).teamsForWorkspace(workspaceId);
    return rows.map(teamFromRow).toList();
  }

  @override
  Stream<List<Team>> watchTeamsForWorkspace(String workspaceId) {
    return _dao(workspaceId)
        .watchTeamsForWorkspace(workspaceId)
        .map((rows) => rows.map(teamFromRow).toList());
  }

  @override
  Future<void> addMember(String workspaceId, TeamMember member) =>
      _dao(workspaceId).addMember(teamMemberToCompanion(member));

  @override
  Future<void> removeMember(
    String workspaceId,
    String teamId,
    String agentId,
  ) => _dao(workspaceId).removeMember(teamId, agentId);

  @override
  Future<List<TeamMember>> membersOf(String workspaceId, String teamId) async {
    final rows = await _dao(workspaceId).membersOf(teamId);
    return rows.map(teamMemberFromRow).toList();
  }

  @override
  Stream<List<TeamMember>> watchMembersOf(String workspaceId, String teamId) {
    return _dao(workspaceId)
        .watchMembersOf(teamId)
        .map((rows) => rows.map(teamMemberFromRow).toList());
  }
}
