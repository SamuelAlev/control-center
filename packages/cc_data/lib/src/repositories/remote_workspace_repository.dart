import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates workspaces + their repo links over the RPC client.
///
/// The workspace switcher's list + the session binding use the session-control
/// methods (`session/list_workspaces`, `session/set_workspace`). The full
/// entity stream, CRUD, and repo-link ops go through the `workspace.*` catalog
/// ops/queries (richer than the `{id, name}` switcher summaries). The host owns
/// persistence; the workspace entity is itself the unit of isolation, so its
/// CRUD + list legitimately span workspaces.
class RemoteWorkspaceRepository {
  /// Creates a [RemoteWorkspaceRepository] over [_client].
  RemoteWorkspaceRepository(this._client);

  final RemoteRpcClient _client;

  /// Workspaces this device may switch between (id+name summaries).
  Future<List<WorkspaceDto>> list() async {
    final rows = await _client.listWorkspaces();
    return rows.map(WorkspaceDto.fromJson).toList();
  }

  /// Points the client at [workspaceId] — it rides in every subsequent request
  /// as `workspace_id` (the server is stateless; there is no session binding).
  Future<void> setActive(String workspaceId) async {
    _client.activeWorkspaceId = workspaceId;
  }

  /// Live stream of all workspaces (full entity shape).
  Stream<List<WorkspaceDto>> watchAll() =>
      _client.subscribe('workspace.watchAll', const {}).map(_workspaces);

  /// Upserts a workspace row; returns its id.
  Future<String> upsert(WorkspaceDto workspace) async {
    final data = await _client.call('workspace.upsert', {
      'workspace': workspace.toJson(),
    });
    return data['workspace_id'] as String? ?? workspace.id;
  }

  /// Deletes the workspace [id].
  Future<void> delete(String id) =>
      _client.call('workspace.delete', {'id': id});

  /// Live repos linked to [workspaceId] (oldest link first).
  Stream<List<RepoDto>> watchReposForWorkspace(String workspaceId) => _client
      .subscribe('workspace.watchReposForWorkspace', {
        'workspace_id': workspaceId,
      })
      .map(_repos);

  /// Atomically replaces [workspaceId]'s repo links with [repoIds]. The target
  /// workspace is sent explicitly (not inferred from the session binding) so it
  /// matches the workspace the caller is actually acting on.
  Future<void> setReposForWorkspace(
    String workspaceId,
    List<String> repoIds,
  ) => _client.call('workspace.setReposForWorkspace', {
    'workspace_id': workspaceId,
    'repo_ids': repoIds,
  });

  /// Links [repoId] to [workspaceId] (sent explicitly, not the session binding).
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId) =>
      _client.call('workspace.linkRepoToWorkspace', {
        'workspace_id': workspaceId,
        'repo_id': repoId,
      });

  /// Unlinks [repoId] from [workspaceId].
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId) =>
      _client.call('workspace.unlinkRepoFromWorkspace', {
        'workspace_id': workspaceId,
        'repo_id': repoId,
      });

  /// Whether [repoId] is linked to [workspaceId].
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) async {
    final data = await _client.call('workspace.isRepoLinkedToWorkspace', {
      'workspace_id': workspaceId,
      'repo_id': repoId,
    });
    return data['linked'] as bool? ?? false;
  }

  List<WorkspaceDto> _workspaces(Map<String, dynamic> data) =>
      ((data['workspaces'] as List?) ?? const [])
          .whereType<Map>()
          .map((w) => WorkspaceDto.fromJson(w.cast<String, dynamic>()))
          .toList();

  List<RepoDto> _repos(Map<String, dynamic> data) =>
      ((data['repos'] as List?) ?? const [])
          .whereType<Map>()
          .map((r) => RepoDto.fromJson(r.cast<String, dynamic>()))
          .toList();
}
