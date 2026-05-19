import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates isolated repos (CoW worktrees) over the RPC client instead of
/// a local database.
///
/// Backs the web build and the desktop in REMOTE mode. A workspace id selects
/// the database file server-side, so every workspace-scoped call names its
/// `workspace_id`. The two cross-workspace teardown lookups
/// ([forSpaceAcrossWorkspaces] / [forTicketAcrossWorkspaces]) are declared
/// exemptions and pass only their id — they run after the space (and its
/// workspace context) is already gone. Mirrors the `isolated_repo.*` ops +
/// `isolated_repo.watchForWorkspace` subscription in the host catalog.
class RemoteIsolatedRepoRepository {
  /// Creates a [RemoteIsolatedRepoRepository] over [_client].
  RemoteIsolatedRepoRepository(this._client);

  final RemoteRpcClient _client;

  /// The worktree for a specific `(workspace, space, repo)`, or null.
  Future<IsolatedRepoDto?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    final data = await _client.call('isolated_repo.forUnitRepo', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'repo_id': repoId,
    });
    final repo = data['repo'];
    return repo is Map
        ? IsolatedRepoDto.fromJson(repo.cast<String, dynamic>())
        : null;
  }

  /// All worktrees for a conversation in [workspaceId].
  Future<List<IsolatedRepoDto>> forSpace(
    String workspaceId,
    String spaceId,
  ) async {
    final data = await _client.call('isolated_repo.forSpace', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
    });
    return _repos(data);
  }

  /// All worktrees for a ticket in [workspaceId].
  Future<List<IsolatedRepoDto>> forTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final data = await _client.call('isolated_repo.forTicket', {
      'workspace_id': workspaceId,
      'ticket_id': ticketId,
    });
    return _repos(data);
  }

  /// CROSS-WORKSPACE BY DESIGN: teardown lookup by globally-unique space id.
  /// Each row carries its own workspace; the server op is workspace-exempt.
  Future<List<IsolatedRepoDto>> forSpaceAcrossWorkspaces(String spaceId) async {
    final data = await _client.call('isolated_repo.forSpaceAcrossWorkspaces', {
      'space_id': spaceId,
    });
    return _repos(data);
  }

  /// CROSS-WORKSPACE BY DESIGN: teardown lookup by ticket id. Each row carries
  /// its own workspace; the server op is workspace-exempt.
  Future<List<IsolatedRepoDto>> forTicketAcrossWorkspaces(
    String ticketId,
  ) async {
    final data = await _client.call('isolated_repo.forTicketAcrossWorkspaces', {
      'ticket_id': ticketId,
    });
    return _repos(data);
  }

  /// Inserts or updates [repo] (the host owns persistence). The workspace comes
  /// from [IsolatedRepoDto.workspaceId] — the row's own workspace is the only
  /// authoritative answer, so it is never threaded separately.
  Future<void> upsert(IsolatedRepoDto repo) => _client.call(
    'isolated_repo.upsert',
    {'workspace_id': repo.workspaceId, 'repo': repo.toJson()},
  );

  /// Deletes the worktree row [id] from [workspaceId].
  Future<void> deleteById(String workspaceId, String id) => _client.call(
    'isolated_repo.deleteById',
    {'workspace_id': workspaceId, 'id': id},
  );

  /// Live worktrees in [workspaceId] — a fresh snapshot on every change.
  Stream<List<IsolatedRepoDto>> watch(String workspaceId) => _client
      .subscribe('isolated_repo.watchForWorkspace', {
        'workspace_id': workspaceId,
      })
      .map(_repos);

  List<IsolatedRepoDto> _repos(Map<String, dynamic> data) =>
      ((data['repos'] as List?) ?? const [])
          .whereType<Map>()
          .map((r) => IsolatedRepoDto.fromJson(r.cast<String, dynamic>()))
          .toList();
}
