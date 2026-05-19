import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates teams and their members over the RPC client instead of a
/// local database.
///
/// Backs the web build and the desktop in REMOTE mode. Teams and their members
/// are workspace-scoped and a workspace id selects the database file
/// server-side, so every op names its `workspace_id`: a team id (or a member's
/// `team_id`) resolves only inside its own workspace, and one from another
/// workspace is simply not matched. Mirrors the `team.*` ops + the
/// `team.watchTeamsForWorkspace` / `team.watchMembersOf` subscriptions in the
/// host catalog.
class RemoteTeamRepository {
  /// Creates a [RemoteTeamRepository] over [_client].
  RemoteTeamRepository(this._client);

  final RemoteRpcClient _client;

  /// Persists a new team into [workspaceId] (the host owns persistence).
  Future<void> insertTeam(String workspaceId, TeamDto team) => _client.call(
    'team.insertTeam',
    {'workspace_id': workspaceId, 'team': team.toJson()},
  );

  /// Updates an existing team in [workspaceId].
  Future<void> updateTeam(String workspaceId, TeamDto team) => _client.call(
    'team.updateTeam',
    {'workspace_id': workspaceId, 'team': team.toJson()},
  );

  /// Deletes the team with [id] from [workspaceId].
  Future<void> deleteTeam(String workspaceId, String id) =>
      _client.call('team.deleteTeam', {'workspace_id': workspaceId, 'id': id});

  /// A single team by id within [workspaceId], or null when it does not exist
  /// there.
  Future<TeamDto?> getTeam(String workspaceId, String id) async {
    final data = await _client.call('team.getTeam', {
      'workspace_id': workspaceId,
      'id': id,
    });
    final team = data['team'];
    return team is Map ? TeamDto.fromJson(team.cast<String, dynamic>()) : null;
  }

  /// All teams in [workspaceId].
  Future<List<TeamDto>> teamsForWorkspace(String workspaceId) async {
    final data = await _client.call('team.teamsForWorkspace', {
      'workspace_id': workspaceId,
    });
    return _teams(data);
  }

  /// Adds [member] to its team within [workspaceId].
  Future<void> addMember(String workspaceId, TeamMemberDto member) =>
      _client.call('team.addMember', {
        'workspace_id': workspaceId,
        'member': member.toJson(),
      });

  /// Removes the [agentId] member from [teamId] within [workspaceId].
  Future<void> removeMember(
    String workspaceId,
    String teamId,
    String agentId,
  ) => _client.call('team.removeMember', {
    'workspace_id': workspaceId,
    'team_id': teamId,
    'agent_id': agentId,
  });

  /// All members of [teamId] within [workspaceId].
  Future<List<TeamMemberDto>> membersOf(
    String workspaceId,
    String teamId,
  ) async {
    final data = await _client.call('team.membersOf', {
      'workspace_id': workspaceId,
      'team_id': teamId,
    });
    return _members(data);
  }

  /// Live teams in [workspaceId] — a fresh snapshot on every change.
  Stream<List<TeamDto>> watchTeamsForWorkspace(String workspaceId) => _client
      .subscribe('team.watchTeamsForWorkspace', {'workspace_id': workspaceId})
      .map(_teams);

  /// Live members of [teamId] within [workspaceId] — a fresh snapshot on every
  /// change.
  Stream<List<TeamMemberDto>> watchMembersOf(
    String workspaceId,
    String teamId,
  ) => _client
      .subscribe('team.watchMembersOf', {
        'workspace_id': workspaceId,
        'team_id': teamId,
      })
      .map(_members);

  List<TeamDto> _teams(Map<String, dynamic> data) =>
      ((data['teams'] as List?) ?? const [])
          .whereType<Map>()
          .map((t) => TeamDto.fromJson(t.cast<String, dynamic>()))
          .toList();

  List<TeamMemberDto> _members(Map<String, dynamic> data) =>
      ((data['members'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => TeamMemberDto.fromJson(m.cast<String, dynamic>()))
          .toList();
}
