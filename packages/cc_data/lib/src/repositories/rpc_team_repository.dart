import 'package:cc_data/src/repositories/remote_team_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [TeamRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `team.*` ops + the
/// `team.watchTeamsForWorkspace` / `team.watchMembersOf` subscriptions, mapping
/// the [TeamDto] / [TeamMemberDto] wire shapes back to [Team] / [TeamMember].
/// The host owns persistence and validates that the team (and any member's
/// `team_id`) belongs to the bound workspace; this client never touches a
/// database.
class RpcTeamRepository implements TeamRepository {
  /// Creates an [RpcTeamRepository] over [client].
  RpcTeamRepository(RemoteRpcClient client)
    : _remote = RemoteTeamRepository(client);

  final RemoteTeamRepository _remote;

  /// Rebuilds a [Team] from its wire DTO. The timestamp is an ISO-8601 string.
  static Team _teamFromDto(TeamDto d) => Team(
    id: d.id,
    workspaceId: d.workspaceId,
    name: d.name,
    description: d.description,
    createdAt: DateTime.parse(d.createdAt),
  );

  static TeamDto _teamToDto(Team t) => TeamDto(
    id: t.id,
    workspaceId: t.workspaceId,
    name: t.name,
    description: t.description,
    createdAt: t.createdAt.toIso8601String(),
  );

  /// Rebuilds a [TeamMember] from its wire DTO. The role is encoded as `.name`.
  static TeamMember _memberFromDto(TeamMemberDto d) => TeamMember(
    teamId: d.teamId,
    agentId: d.agentId,
    role: TeamMemberRole.fromString(d.role),
  );

  static TeamMemberDto _memberToDto(TeamMember m) => TeamMemberDto(
    teamId: m.teamId,
    agentId: m.agentId,
    role: m.role.toStorageString(),
  );

  @override
  Future<void> insertTeam(Team team) =>
      _remote.insertTeam(_teamToDto(team));

  @override
  Future<void> updateTeam(Team team) =>
      _remote.updateTeam(_teamToDto(team));

  @override
  Future<void> deleteTeam(String id) => _remote.deleteTeam(id);

  @override
  Future<Team?> getTeam(String id) async {
    try {
      final dto = await _remote.getTeam(id);
      return dto == null ? null : _teamFromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<Team>> teamsForWorkspace(String workspaceId) async {
    final dtos = await _remote.teamsForWorkspace();
    return dtos.map(_teamFromDto).toList();
  }

  @override
  Stream<List<Team>> watchTeamsForWorkspace(String workspaceId) => _remote
      .watchTeamsForWorkspace()
      .map((dtos) => dtos.map(_teamFromDto).toList());

  @override
  Future<void> addMember(TeamMember member) =>
      _remote.addMember(_memberToDto(member));

  @override
  Future<void> removeMember(String teamId, String agentId) =>
      _remote.removeMember(teamId, agentId);

  @override
  Future<List<TeamMember>> membersOf(String teamId) async {
    final dtos = await _remote.membersOf(teamId);
    return dtos.map(_memberFromDto).toList();
  }

  @override
  Stream<List<TeamMember>> watchMembersOf(String teamId) => _remote
      .watchMembersOf(teamId)
      .map((dtos) => dtos.map(_memberFromDto).toList());
}
