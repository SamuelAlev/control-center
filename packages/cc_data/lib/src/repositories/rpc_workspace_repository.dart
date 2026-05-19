import 'package:cc_data/src/repositories/remote_workspace_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [WorkspaceRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `workspace.*` ops + the
/// `workspace.watchAll` / `workspace.watchReposForWorkspace` subscriptions,
/// mapping the [WorkspaceDto] / [RepoDto] wire shapes back to entities. The host
/// owns persistence; this client never touches a database.
///
/// The workspace entity is itself the unit of isolation, so its CRUD + the
/// switcher list legitimately span workspaces (the `create_workspace` /
/// `list_workspaces` exemptions). The repo-link writes scope to the bound
/// workspace server-side; [watchReposForWorkspace] honors an explicit id so the
/// GitHub-link router can resolve a repo→workspace mapping across workspaces.
class RpcWorkspaceRepository implements WorkspaceRepository {
  /// Creates an [RpcWorkspaceRepository] over [client].
  RpcWorkspaceRepository(RemoteRpcClient client)
    : _remote = RemoteWorkspaceRepository(client);

  final RemoteWorkspaceRepository _remote;

  /// Rebuilds a [Workspace] from its wire DTO. A workspace name must be
  /// non-empty (entity invariant); missing timestamps fall back to the epoch.
  static Workspace _workspaceFromDto(WorkspaceDto d) => Workspace(
    id: d.id,
    name: d.name,
    logoPath: d.logoPath,
    reviewConcurrency: d.reviewConcurrency ?? 3,
    deletedAt: d.deletedAt,
    createdAt: d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        d.updatedAt ?? d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
  );

  static WorkspaceDto _toDto(Workspace w) => WorkspaceDto(
    id: w.id,
    name: w.name,
    logoPath: w.logoPath,
    reviewConcurrency: w.reviewConcurrency,
    deletedAt: w.deletedAt,
    createdAt: w.createdAt,
    updatedAt: w.updatedAt,
  );

  static Repo _repoFromDto(RepoDto d) => Repo(
    id: d.id,
    name: d.name,
    path: d.path,
    githubOwner: d.githubOwner,
    githubRepoName: d.githubRepoName,
    createdAt: d.createdAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.createdAt!),
    updatedAt: d.updatedAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.updatedAt!),
  );

  @override
  Stream<List<Workspace>> watchAll() =>
      _remote.watchAll().map((dtos) => dtos.map(_workspaceFromDto).toList());

  @override
  Future<String> upsert(Workspace workspace) =>
      _remote.upsert(_toDto(workspace));

  @override
  Future<void> delete(String id) => _remote.delete(id);

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) => _remote
      .watchReposForWorkspace(workspaceId)
      .map((dtos) => dtos.map(_repoFromDto).toList());

  @override
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds) =>
      _remote.setReposForWorkspace(workspaceId, repoIds);

  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      _remote.isRepoLinkedToWorkspace(workspaceId, repoId);

  @override
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId) =>
      _remote.linkRepoToWorkspace(workspaceId, repoId);

  @override
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId) =>
      _remote.unlinkRepoFromWorkspace(workspaceId, repoId);
}
