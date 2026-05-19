import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates teams and their members over the RPC client instead of a
/// local database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one and
/// validates that the team (and any member's `team_id`) belongs to that
/// workspace before touching a row. Teams are workspace-scoped; members are
/// keyed only by `team_id`/`agent_id`, so member ops are ownership-checked
/// against the team's workspace server-side. Mirrors the `team.*` ops + the
/// `team.watchTeamsForWorkspace` / `team.watchMembersOf` subscriptions in the
/// host catalog.
class RemoteTeamRepository {
  /// Creates a [RemoteTeamRepository] over [_client].
  RemoteTeamRepository(this._client);

  final RemoteRpcClient _client;

  /// Persists a new team (the host owns persistence).
  Future<void> insertTeam(TeamDto team) =>
      _client.call('team.insertTeam', {'team': team.toJson()});

  /// Updates an existing team.
  Future<void> updateTeam(TeamDto team) =>
      _client.call('team.updateTeam', {'team': team.toJson()});

  /// Deletes the team with [id] (ownership-checked server-side against the
  /// bound workspace).
  Future<void> deleteTeam(String id) =>
      _client.call('team.deleteTeam', {'id': id});

  /// A single team by id (scoped to the bound workspace server-side), or null
  /// when it does not exist.
  Future<TeamDto?> getTeam(String id) async {
    final data = await _client.call('team.getTeam', {'id': id});
    final team = data['team'];
    return team is Map ? TeamDto.fromJson(team.cast<String, dynamic>()) : null;
  }

  /// All teams in the bound workspace.
  Future<List<TeamDto>> teamsForWorkspace() async {
    final data = await _client.call('team.teamsForWorkspace', const {});
    return _teams(data);
  }

  /// Adds [member] to its team (ownership-checked server-side against the
  /// bound workspace via the member's `team_id`).
  Future<void> addMember(TeamMemberDto member) =>
      _client.call('team.addMember', {'member': member.toJson()});

  /// Removes the [agentId] member from [teamId] (ownership-checked
  /// server-side).
  Future<void> removeMember(String teamId, String agentId) => _client.call(
    'team.removeMember',
    {'team_id': teamId, 'agent_id': agentId},
  );

  /// All members of [teamId] (ownership-checked server-side against the bound
  /// workspace).
  Future<List<TeamMemberDto>> membersOf(String teamId) async {
    final data = await _client.call('team.membersOf', {'team_id': teamId});
    return _members(data);
  }

  /// Live teams in the bound workspace — a fresh snapshot on every change.
  Stream<List<TeamDto>> watchTeamsForWorkspace() => _client
      .subscribe('team.watchTeamsForWorkspace', const {})
      .map(_teams);

  /// Live members of [teamId] — a fresh snapshot on every change
  /// (ownership-checked server-side against the bound workspace).
  Stream<List<TeamMemberDto>> watchMembersOf(String teamId) => _client
      .subscribe('team.watchMembersOf', {'team_id': teamId})
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
