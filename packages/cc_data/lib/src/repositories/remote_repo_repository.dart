import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A linked repository and what the server found while linking it that did
/// not stop the link (the App not installed on its owner, the repository
/// not selected in the installation, the accountable person unable to see
/// it or not signed in).
typedef RepoLinkResult = ({String repoId, List<RepoAccessWarning> warnings});

/// Reads/mutates Git-repo registrations over the RPC client.
///
/// Repos are **workspace-scoped**: a checkout is registered into one workspace,
/// so every op carries a `workspace_id` and a repo id means nothing outside its
/// workspace. Mirrors the `repos.*` ops + the `repos.watchAll` subscription in
/// the host catalog. The host owns persistence; this client never touches a
/// database.
class RemoteRepoRepository {
  /// Creates a [RemoteRepoRepository] over [_client].
  RemoteRepoRepository(this._client);

  final RemoteRpcClient _client;

  /// A single repo by id within [workspaceId], or null.
  Future<RepoDto?> get(String workspaceId, String id) async {
    final data = await _client.call('repos.get', {
      'workspace_id': workspaceId,
      'repo_id': id,
    });
    final repo = data['repo'];
    return repo is Map ? RepoDto.fromJson(repo.cast<String, dynamic>()) : null;
  }

  /// The repo registered at [path] within [workspaceId], or null.
  Future<RepoDto?> findByPath(String workspaceId, String path) async {
    final data = await _client.call('repos.findByPath', {
      'workspace_id': workspaceId,
      'path': path,
    });
    final repo = data['repo'];
    return repo is Map ? RepoDto.fromJson(repo.cast<String, dynamic>()) : null;
  }

  /// Whether [id] belongs to [workspaceId].
  Future<bool> exists(String workspaceId, String id) async {
    final data = await _client.call('repos.exists', {
      'workspace_id': workspaceId,
      'repo_id': id,
    });
    return data['exists'] as bool? ?? false;
  }

  /// Inserts or updates [repo] in [workspaceId]; returns the persisted id.
  Future<String> upsert(String workspaceId, RepoDto repo) async =>
      (await link(workspaceId, repo)).repoId;

  /// [upsert], also returning the server's `access_warnings`.
  ///
  /// Throws the server's refusal when the linking person cannot see the
  /// repository or is not signed in to its forge (`needs_sign_in`).
  ///
  /// [relink] re-pins a repository whose path now names a different
  /// repository on its forge (`repo_replaced`): the server re-verifies it
  /// with the admin's own forge sign-in.
  Future<RepoLinkResult> link(
    String workspaceId,
    RepoDto repo, {
    bool relink = false,
  }) async {
    final data = await _client.call('repos.upsert', {
      'workspace_id': workspaceId,
      'repo': repo.toJson(),
      if (relink) 'relink': true,
    });
    return (
      repoId: data['repo_id'] as String? ?? repo.id,
      warnings: RepoAccessWarning.listOf(data['access_warnings']),
    );
  }

  /// Removes the repo [id] from [workspaceId].
  Future<void> delete(String workspaceId, String id) => _client.call(
    'repos.delete',
    {'workspace_id': workspaceId, 'repo_id': id},
  );

  /// Re-sequences [workspaceId]'s repos to match [orderedIds].
  Future<void> reorder(String workspaceId, List<String> orderedIds) =>
      _client.call('repos.reorder', {
        'workspace_id': workspaceId,
        'repo_ids': orderedIds,
      });

  /// Registers a repo by inspecting a git checkout at [path] on the SERVER's
  /// filesystem (`git remote get-url origin` etc.), returning the persisted
  /// repo. The repo is created in [workspaceId]. Throws [RemoteRpcException]
  /// with `RpcErrorCodes.validation` when the path is not a GitHub working tree,
  /// or the linking person cannot see the repository, and the `needs_sign_in`
  /// refusal when they are not signed in to its forge. Problems that do not
  /// stop the link come back as the result's warnings.
  Future<({RepoDto repo, List<RepoAccessWarning> warnings})> addFromPath(
    String workspaceId,
    String path,
  ) async {
    final data = await _client.call('repos.addFromPath', {
      'workspace_id': workspaceId,
      'path': path,
    });
    return (
      repo: RepoDto.fromJson((data['repo'] as Map).cast<String, dynamic>()),
      warnings: RepoAccessWarning.listOf(data['access_warnings']),
    );
  }

  /// Live repos of [workspaceId] — a fresh snapshot on every change, in the
  /// operator's manual order.
  Stream<List<RepoDto>> watchAll(String workspaceId) => _client
      .subscribe('repos.watchAll', {'workspace_id': workspaceId})
      .map(_repos);

  List<RepoDto> _repos(Map<String, dynamic> data) =>
      ((data['repos'] as List?) ?? const [])
          .whereType<Map>()
          .map((r) => RepoDto.fromJson(r.cast<String, dynamic>()))
          .toList();
}
