import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_persistence/database/daos/team_dao.dart';
import 'package:cc_persistence/mappers/team_mappers.dart';

/// Drift-backed implementation of [TeamRepository].
class TeamRepositoryImpl implements TeamRepository {
  /// Creates a [TeamRepositoryImpl] backed by the given [TeamDao].
  TeamRepositoryImpl(this._dao);
  final TeamDao _dao;

  @override
  Future<void> insertTeam(Team team) =>
      _dao.insertTeam(teamToCompanion(team));

  @override
  Future<void> updateTeam(Team team) =>
      _dao.updateTeam(teamToCompanion(team));

  @override
  Future<void> deleteTeam(String id) => _dao.deleteTeam(id);

  @override
  Future<Team?> getTeam(String id) async {
    final row = await _dao.getTeam(id);
    return row != null ? teamFromRow(row) : null;
  }

  @override
  Future<List<Team>> teamsForWorkspace(String workspaceId) async {
    final rows = await _dao.teamsForWorkspace(workspaceId);
    return rows.map(teamFromRow).toList();
  }

  @override
  Stream<List<Team>> watchTeamsForWorkspace(String workspaceId) {
    return _dao
        .watchTeamsForWorkspace(workspaceId)
        .map((rows) => rows.map(teamFromRow).toList());
  }

  @override
  Future<void> addMember(TeamMember member) =>
      _dao.addMember(teamMemberToCompanion(member));

  @override
  Future<void> removeMember(String teamId, String agentId) =>
      _dao.removeMember(teamId, agentId);

  @override
  Future<List<TeamMember>> membersOf(String teamId) async {
    final rows = await _dao.membersOf(teamId);
    return rows.map(teamMemberFromRow).toList();
  }

  @override
  Stream<List<TeamMember>> watchMembersOf(String teamId) {
    return _dao
        .watchMembersOf(teamId)
        .map((rows) => rows.map(teamMemberFromRow).toList());
  }
}
